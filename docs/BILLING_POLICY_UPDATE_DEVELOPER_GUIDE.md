# 과금 정책 수정 - 개발자 가이드

> **작성일**: 2026-01-24
> **버전**: 1.0
> **PRD**: `/docs/prd-billing-policy-update.md`
> **태스크**: `/docs/tasks-billing-policy-update.md`

## 목차

1. [개요](#개요)
2. [아키텍처 변경사항](#아키텍처-변경사항)
3. [DB 스키마 변경](#db-스키마-변경)
4. [API 변경사항](#api-변경사항)
5. [프론트엔드 변경사항](#프론트엔드-변경사항)
6. [마이그레이션 가이드](#마이그레이션-가이드)
7. [테스트 가이드](#테스트-가이드)
8. [배포 가이드](#배포-가이드)
9. [모니터링](#모니터링)
10. [트러블슈팅](#트러블슈팅)

---

## 개요

### 변경 목적

기존 아임포트(iamport) 기반 결제 시스템을 LemonSqueezy로 전환하고, DM 발송 한도 정책을 "초과 과금"에서 "한도 도달 시 차단"으로 변경합니다.

### 주요 변경사항

| 항목 | 기존 | 변경 후 |
|-----|------|--------|
| **결제 시스템** | 아임포트 (iamport) | LemonSqueezy |
| **과금 정책** | 한도 초과 시 초과 요금 부과 | 한도 도달 시 발송 차단 |
| **알림 정책** | 90% 도달 시 이메일 알림 | 90% 도달 시 이메일 알림 (유지) |
| **환불 정책** | 환불 불가 | 정책 변경 시 크레딧/환불 제공 |

---

## 아키텍처 변경사항

### 결제 시스템 흐름

#### 기존 (아임포트)

```
[사용자] -> [프론트엔드] -> [백엔드] -> [아임포트 API]
                                    <- [아임포트 웹훅]
```

#### 변경 후 (LemonSqueezy)

```
[사용자] -> [프론트엔드] -> [LemonSqueezy Checkout URL]
                                    -> [LemonSqueezy]
                                    <- [웹훅] -> [백엔드]
```

### DM 발송 한도 체크 흐름

#### 기존

```
[DM 발송 요청]
  -> [한도 체크]
    -> 한도 미달: 발송 + 사용량 증가
    -> 한도 초과: 발송 + 초과 요금 기록
```

#### 변경 후

```
[DM 발송 요청]
  -> [한도 체크]
    -> 한도 미달: 발송 + 사용량 증가
    -> 한도 도달: 에러 반환 (QUOTA_EXCEEDED)
```

---

## DB 스키마 변경

### `tb_subscriptions` 테이블

#### 추가 컬럼

```sql
ALTER TABLE tb_subscriptions
ADD COLUMN lemon_squeezy_subscription_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 구독 ID',
ADD COLUMN lemon_squeezy_customer_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 고객 ID',
ADD COLUMN lemon_squeezy_variant_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 제품 Variant ID';
```

#### 인덱스 추가

```sql
ALTER TABLE tb_subscriptions
ADD INDEX idx_lemon_squeezy_subscription_id (lemon_squeezy_subscription_id),
ADD INDEX idx_lemon_squeezy_customer_id (lemon_squeezy_customer_id);
```

### `tb_dm_usage` 테이블

변경사항 없음 (기존 테이블 유지)

---

## API 변경사항

### 1. LemonSqueezy 웹훅 엔드포인트

#### 새로운 라우트

```javascript
// /api/src/routes/webhookRoutes.js
router.post('/lemonsqueezy', webhookController.handleLemonSqueezyWebhook);
```

#### 처리 이벤트

- `subscription_created`: 구독 생성
- `subscription_updated`: 구독 변경 (플랜 변경, 상태 변경)
- `subscription_cancelled`: 구독 취소
- `subscription_resumed`: 구독 재개
- `subscription_payment_success`: 결제 성공

#### 예제 코드

```javascript
// /api/src/controllers/webhookController.js
exports.handleLemonSqueezyWebhook = async (req, res) => {
  try {
    // 1. 서명 검증
    const signature = req.headers['x-signature'];
    const isValid = verifyWebhookSignature(req.body, signature);
    if (!isValid) {
      return res.status(401).json({ error: 'Invalid signature' });
    }

    // 2. 이벤트 타입별 처리
    const event = req.body;
    switch (event.meta.event_name) {
      case 'subscription_created':
        await handleSubscriptionCreated(event.data);
        break;
      // ...
    }

    res.sendStatus(200);
  } catch (error) {
    console.error('Webhook error:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
};
```

### 2. DM 발송 API 에러 응답

#### 에러 응답 형식

```json
{
  "code": "QUOTA_EXCEEDED",
  "message": "이번 달 DM 발송 한도에 도달했습니다.",
  "nextResetDate": "2026-02-01T00:00:00.000Z"
}
```

#### 에러 코드

| 코드 | 설명 | HTTP Status |
|-----|------|-------------|
| `QUOTA_EXCEEDED` | DM 발송 한도 초과 | 403 |
| `UNAUTHORIZED` | 인증 실패 | 401 |
| `FORBIDDEN` | 권한 부족 | 403 |
| `NOT_FOUND` | 리소스를 찾을 수 없음 | 404 |
| `VALIDATION_ERROR` | 입력 검증 실패 | 400 |
| `INSTAGRAM_API_ERROR` | Instagram API 에러 | 502 |
| `SERVER_ERROR` | 서버 에러 | 500 |

### 3. 구독 관리 API

#### GET `/api/subscription/status`

현재 사용자의 구독 정보 조회

**응답:**
```json
{
  "planId": "starter",
  "planName": "Starter",
  "status": "active",
  "nextBillingDate": "2026-02-01",
  "cancelAtPeriodEnd": false,
  "dmQuota": {
    "limit": 1500,
    "used": 1200,
    "remaining": 300,
    "percentage": 80
  }
}
```

#### POST `/api/subscription/checkout`

LemonSqueezy Checkout URL 생성

**요청:**
```json
{
  "planId": "starter"
}
```

**응답:**
```json
{
  "checkoutUrl": "https://autogram.lemonsqueezy.com/checkout/buy/..."
}
```

#### POST `/api/subscription/cancel`

구독 취소 (기간 종료 시)

**응답:**
```json
{
  "success": true,
  "message": "구독이 취소되었습니다. 2026-02-01까지 사용 가능합니다."
}
```

---

## 프론트엔드 변경사항

### 1. ErrorModal 컴포넌트

DM 발송 한도 초과 시 표시되는 모달

**위치:** `/web/components/dm/ErrorModal.tsx`

**사용 예제:**
```tsx
import ErrorModal from '@/components/dm/ErrorModal';
import { useDMErrorModal } from '@/hooks/useDMErrorModal';

function MyComponent() {
  const { isOpen, errorData, handleError, closeModal } = useDMErrorModal();

  const handleSendDM = async () => {
    try {
      await api.post('/api/dm/send', data);
    } catch (error) {
      const isQuotaExceeded = handleError(error);
      if (!isQuotaExceeded) {
        // 다른 에러 처리
      }
    }
  };

  return (
    <>
      <Button onClick={handleSendDM}>DM 발송</Button>
      <ErrorModal
        isOpen={isOpen}
        onClose={closeModal}
        message={errorData.message}
        nextResetDate={errorData.nextResetDate}
      />
    </>
  );
}
```

### 2. 약관 페이지 수정

**위치:** `/web/app/terms/[locale]/page.tsx`

**변경사항:**
- 제8조: "요금 및 결제" 섹션 수정
- 제9조: "환불 정책" 추가
- 제10조 이후: 조 번호 재조정
- 최종 수정일: 2026년 1월 24일

### 3. Pricing 페이지

**위치:** `/web/app/dashboard/pricing/page.tsx`

기존 코드 유지. ErrorModal에서 업그레이드 버튼 클릭 시 자동으로 이동됩니다.

---

## 마이그레이션 가이드

### 1. 사전 준비

#### 환경 변수 설정

```env
# LemonSqueezy
LEMONSQUEEZY_API_KEY=lmsq_xxxxxxxxxxxx
LEMONSQUEEZY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
LEMONSQUEEZY_STORE_ID=123456
LEMONSQUEEZY_VARIANT_ID_MINIMUM=111111
LEMONSQUEEZY_VARIANT_ID_STARTER=222222
LEMONSQUEEZY_VARIANT_ID_PRO=333333
```

#### DB 백업

```bash
mysqldump -u root -p sns_automation > backup_$(date +%Y%m%d_%H%M%S).sql
```

### 2. DB 마이그레이션

```bash
cd /path/to/api
node src/scripts/runMigrations.js
```

### 3. 데이터 마이그레이션

#### Dry-run (권장)

```bash
node src/scripts/migrateToLemonSqueezy.js --dry-run
```

#### 실제 마이그레이션

```bash
node src/scripts/migrateToLemonSqueezy.js
```

#### 롤백 (필요시)

```bash
node src/scripts/rollbackLemonSqueezyMigration.js --report=migration-report-1234567890.json
```

### 4. 검증

```sql
-- 마이그레이션된 구독 수 확인
SELECT COUNT(*) FROM tb_subscriptions
WHERE lemon_squeezy_subscription_id IS NOT NULL;

-- 아임포트 빌링키가 남아있는 구독 확인 (0이어야 함)
SELECT COUNT(*) FROM tb_subscriptions
WHERE billing_key IS NOT NULL
AND lemon_squeezy_subscription_id IS NOT NULL;
```

---

## 테스트 가이드

### 1. 단위 테스트

#### DM 한도 체크 서비스

```javascript
// /api/tests/services/dmQuotaService.test.js
describe('checkQuota', () => {
  it('한도 미달 시 true 반환', async () => {
    const result = await dmQuotaService.checkQuota(userSeq);
    expect(result.allowed).toBe(true);
  });

  it('한도 도달 시 false 반환', async () => {
    const result = await dmQuotaService.checkQuota(userSeq);
    expect(result.allowed).toBe(false);
    expect(result.code).toBe('QUOTA_EXCEEDED');
  });

  it('90% 도달 시 shouldNotify = true', async () => {
    const result = await dmQuotaService.checkQuota(userSeq);
    expect(result.shouldNotify).toBe(true);
  });
});
```

#### LemonSqueezy 웹훅 서비스

```javascript
// /api/tests/services/lemonSqueezyWebhookService.test.js
describe('handleSubscriptionCreated', () => {
  it('새 구독 생성', async () => {
    const event = {
      data: {
        id: 'sub_123',
        attributes: { customer_id: 'cus_123', variant_id: '111111' }
      }
    };
    await service.handleSubscriptionCreated(event.data);

    const subscription = await Subscription.findOne({
      where: { lemon_squeezy_subscription_id: 'sub_123' }
    });
    expect(subscription).toBeDefined();
  });
});
```

### 2. 통합 테스트

#### DM 발송 API

```javascript
// /api/tests/integration/dm.test.js
describe('POST /api/dm/send', () => {
  it('한도 미달 시 성공', async () => {
    const res = await request(app)
      .post('/api/dm/send')
      .send({ recipientId: '123', message: 'Hello' })
      .expect(200);
  });

  it('한도 도달 시 QUOTA_EXCEEDED 에러', async () => {
    const res = await request(app)
      .post('/api/dm/send')
      .send({ recipientId: '123', message: 'Hello' })
      .expect(403);

    expect(res.body.code).toBe('QUOTA_EXCEEDED');
    expect(res.body.nextResetDate).toBeDefined();
  });
});
```

### 3. E2E 테스트

#### 구독 변경 플로우

1. FREE 플랜 사용자 로그인
2. Pricing 페이지 이동
3. STARTER 플랜 선택
4. LemonSqueezy Checkout 페이지 이동
5. 결제 완료
6. 웹훅 수신 확인
7. 구독 상태 확인
8. DM 한도 확인 (1,500건)

---

## 배포 가이드

### 1. 배포 전 체크리스트

- [ ] LemonSqueezy 제품 설정 완료
- [ ] 환경 변수 설정 완료 (프로덕션)
- [ ] DB 백업 완료
- [ ] Dry-run 마이그레이션 테스트 완료
- [ ] 웹훅 엔드포인트 HTTPS 인증서 확인
- [ ] 이메일 템플릿 검토 완료

### 2. 배포 순서

1. **백엔드 배포**
   ```bash
   # DB 마이그레이션
   npm run migrate

   # 서버 재시작
   pm2 restart api
   ```

2. **프론트엔드 배포**
   ```bash
   # 빌드
   npm run build

   # 배포
   pm2 restart web
   ```

3. **데이터 마이그레이션**
   ```bash
   # 실제 마이그레이션
   node src/scripts/migrateToLemonSqueezy.js
   ```

4. **검증**
   - LemonSqueezy 대시보드에서 구독 수 확인
   - 테스트 계정으로 DM 발송 테스트
   - 한도 초과 시 에러 모달 확인

### 3. 롤백 계획

#### 백엔드 롤백

```bash
# 이전 버전으로 복원
git checkout <previous-commit>
npm install
pm2 restart api
```

#### DB 롤백

```bash
# 백업 복원
mysql -u root -p sns_automation < backup_20260124_120000.sql
```

#### 데이터 마이그레이션 롤백

```bash
node src/scripts/rollbackLemonSqueezyMigration.js --report=migration-report-1234567890.json
```

---

## 모니터링

### 1. 주요 지표

#### DM 발송 한도 도달률

```sql
SELECT
  DATE(dm.created_at) AS date,
  COUNT(DISTINCT dm.user_seq) AS users_reached_quota,
  COUNT(*) AS total_quota_exceeded_attempts
FROM tb_dm_usage dm
JOIN tb_subscriptions s ON dm.user_seq = s.user_seq
JOIN tb_plans p ON s.plan_seq = p.seq
WHERE dm.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
GROUP BY DATE(dm.created_at)
HAVING COUNT(*) >= (SELECT monthly_dm_limit FROM tb_plan_properties WHERE plan_seq = p.seq)
ORDER BY date DESC;
```

#### LemonSqueezy 구독 전환율

```sql
SELECT
  COUNT(*) AS total_active_subscriptions,
  SUM(CASE WHEN lemon_squeezy_subscription_id IS NOT NULL THEN 1 ELSE 0 END) AS lemonsqueezy_subscriptions,
  ROUND(
    SUM(CASE WHEN lemon_squeezy_subscription_id IS NOT NULL THEN 1 ELSE 0 END) * 100.0 / COUNT(*),
    2
  ) AS conversion_percentage
FROM tb_subscriptions
WHERE subscription_status = 'active'
AND plan_seq != 1; -- FREE 플랜 제외
```

### 2. 알림 설정

#### Slack 알림

- DM 한도 초과 시도 급증 (시간당 100건 이상)
- LemonSqueezy 웹훅 에러 (5분간 3회 이상)
- 마이그레이션 실패 (1건이라도 발생 시)

#### 이메일 알림

- 일일 마이그레이션 리포트
- 주간 구독 통계 리포트

### 3. 로그 모니터링

```bash
# LemonSqueezy 웹훅 로그
tail -f /var/log/api/lemonsqueezy-webhook.log

# DM 발송 한도 체크 로그
tail -f /var/log/api/dm-quota.log

# 마이그레이션 로그
tail -f /var/log/api/migration.log
```

---

## 트러블슈팅

### 1. LemonSqueezy 웹훅이 수신되지 않음

**증상:**
- 결제 완료 후 구독 상태가 업데이트되지 않음

**원인:**
- 웹훅 URL이 잘못 설정됨
- HTTPS 인증서 문제
- 서명 검증 실패

**해결 방법:**
```bash
# 웹훅 URL 확인
curl -X GET https://api.lemonsqueezy.com/v1/webhooks \
  -H "Authorization: Bearer $LEMONSQUEEZY_API_KEY"

# 로그 확인
tail -f /var/log/nginx/access.log | grep "POST /api/webhooks/lemonsqueezy"

# 서명 검증 로직 확인
# /api/src/services/lemonSqueezyWebhookService.js
```

### 2. DM 발송 한도가 리셋되지 않음

**증상:**
- 다음 결제일이 지났는데도 한도가 리셋되지 않음

**원인:**
- Cron job이 실행되지 않음
- `next_billing_date`가 잘못 설정됨

**해결 방법:**
```sql
-- next_billing_date 확인
SELECT user_seq, next_billing_date, plan_seq
FROM tb_subscriptions
WHERE next_billing_date < CURDATE()
AND subscription_status = 'active';

-- 수동 리셋
UPDATE tb_dm_usage
SET monthly_sent = 0
WHERE user_seq = ? AND month = DATE_FORMAT(NOW(), '%Y-%m');
```

### 3. 마이그레이션 실패

**증상:**
- 마이그레이션 스크립트 실행 중 에러 발생

**원인:**
- Variant ID가 잘못됨
- LemonSqueezy API Rate Limiting
- DB 연결 에러

**해결 방법:**
```bash
# Dry-run으로 먼저 테스트
node src/scripts/migrateToLemonSqueezy.js --dry-run

# 배치 크기를 줄이고 재시도
node src/scripts/migrateToLemonSqueezy.js --batch-size=50 --delay=2000

# 실패한 사용자만 다시 마이그레이션
# migration-report.json에서 실패한 사용자 확인 후 수동 처리
```

### 4. ErrorModal이 표시되지 않음

**증상:**
- DM 한도 초과 시 모달이 표시되지 않음

**원인:**
- API 에러 응답 형식이 다름
- `useDMErrorModal` 훅이 제대로 연결되지 않음

**해결 방법:**
```javascript
// API 응답 형식 확인
console.log('API Error:', error.response?.data);

// 올바른 에러 코드 확인
if (error.response?.data?.code === 'QUOTA_EXCEEDED') {
  // 모달 표시
}
```

---

## 참고 자료

### 문서

- [PRD: 과금 정책 수정](/docs/prd-billing-policy-update.md)
- [태스크 목록](/docs/tasks-billing-policy-update.md)
- [LemonSqueezy API 문서](https://docs.lemonsqueezy.com/api)
- [마이그레이션 스크립트 README](/api/src/scripts/README.md)
- [ErrorModal 컴포넌트 README](/web/components/dm/README.md)

### 주요 파일

#### 백엔드

- `/api/src/controllers/webhookController.js` - 웹훅 핸들러
- `/api/src/services/lemonSqueezyWebhookService.js` - 웹훅 처리 서비스
- `/api/src/services/dmQuotaService.js` - DM 한도 체크 서비스
- `/api/src/scripts/migrateToLemonSqueezy.js` - 마이그레이션 스크립트

#### 프론트엔드

- `/web/components/dm/ErrorModal.tsx` - 에러 모달
- `/web/hooks/useDMErrorModal.ts` - 에러 모달 훅
- `/web/lib/dm-error-handler.ts` - 에러 핸들링 유틸
- `/web/app/terms/[locale]/page.tsx` - 약관 페이지

---

## 변경 이력

| 날짜 | 버전 | 변경 내용 | 작성자 |
|-----|------|----------|--------|
| 2026-01-24 | 1.0 | 최초 작성 | Claude |
