# 과금 정책 수정 PRD

## 1. 개요

### 1.1 목적
현재 아임포트 기반의 월별 정기결제 시스템을 LemonSqueezy 기반의 사용자별 결제일 정기결제 시스템으로 전환하고, DM 발송 한도 정책을 "초과 과금"에서 "한도 도달 시 발송 차단"으로 변경하여 사용자 예측 가능성을 높이고 비즈니스 모델을 단순화합니다.

**비즈니스 가치:**
- 사용자의 결제 예측 가능성 향상 (초과 과금 제거)
- 글로벌 결제 인프라로 전환 (LemonSqueezy)
- 유연한 구독 관리 (사용자별 결제일 기준)
- 운영 복잡도 감소 (초과 요금 계산/청구 로직 제거)

### 1.2 범위

**포함 범위 (이번 버전):**
- LemonSqueezy 웹훅 시스템 구현
- 사용자별 결제일 기준 구독 관리
- DM 발송 한도 차단 정책 적용
- 90%/100% 한도 경고 이메일 발송
- DB 스키마 변경 (초과 과금 관련 컬럼 삭제)
- 약관 페이지 수정
- 기존 아임포트 시스템 제거

**제외 범위 (이번 버전):**
- 사용자 대시보드 UI 개편 (기존 UI 유지, 데이터만 변경)
- 관리자 대시보드 고도화
- 다국어 이메일 템플릿 (한국어만 우선 지원)
- A/B 테스팅
- 단계별 출시 (전체 사용자 일괄 적용)

**향후 계획:**
- v2.0: 다국어 이메일 템플릿 추가
- v2.1: 사용자 대시보드 UI 개편

### 1.3 이해관계자
- **제품 책임자**: 정책 결정 및 비즈니스 영향 검토
- **백엔드 개발 팀**: LemonSqueezy 연동, 웹훅 처리, DB 마이그레이션
- **프론트엔드 개발 팀**: 약관 페이지 수정, 에러 메시지 UI
- **DevOps 팀**: LemonSqueezy 웹훅 엔드포인트 설정, 환경 변수 관리
- **QA 팀**: 결제 시나리오 테스팅
- **CS 팀**: 기존 사용자 문의 대응
- **사용자**: 모든 플랜 사용자 (FREE, MINIMUM, STARTER, PRO)

### 1.4 플랜별 DM 한도

> **중요**: 아래 한도 값은 현재 기준이며, 추후 변경될 수 있습니다.
> **절대 하드코딩하지 말고** 반드시 `tb_plan_properties` 테이블에서 조회하여 사용해야 합니다.

| 플랜 | 월 DM 발송 한도 | DB 조회 방법 |
|------|---------------|-------------|
| FREE | 50건 | `SELECT numeric_value FROM tb_plan_properties WHERE plan_seq = {FREE_PLAN_SEQ} AND prop_code = 'DM'` |
| MINIMUM | 500건 | `SELECT numeric_value FROM tb_plan_properties WHERE plan_seq = {MINIMUM_PLAN_SEQ} AND prop_code = 'DM'` |
| STARTER | 1,500건 | `SELECT numeric_value FROM tb_plan_properties WHERE plan_seq = {STARTER_PLAN_SEQ} AND prop_code = 'DM'` |
| PRO | 10,000건 | `SELECT numeric_value FROM tb_plan_properties WHERE plan_seq = {PRO_PLAN_SEQ} AND prop_code = 'DM'` |

**코드 예시 (권장):**
```javascript
// 올바른 방법: DB에서 한도 조회
async function getDmQuotaByPlan(planSeq) {
  const property = await PlanProperty.findOne({
    where: { plan_seq: planSeq, prop_code: 'DM' }
  });
  return property?.numeric_value || 0;
}

// 잘못된 방법: 하드코딩 (금지)
const DM_QUOTA = { FREE: 50, MINIMUM: 500 }; // ❌ 절대 금지
```

### 1.5 환경 변수

LemonSqueezy 연동에 필요한 환경 변수:

```bash
# LemonSqueezy API 설정
LEMONSQUEEZY_API_KEY=lmsq_xxxxxxxxxxxx
LEMONSQUEEZY_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx
LEMONSQUEEZY_STORE_ID=123456

# 플랜 Variant ID (LemonSqueezy 대시보드에서 확인)
LEMONSQUEEZY_VARIANT_ID_FREE=0          # 무료 플랜은 LemonSqueezy에 없음
LEMONSQUEEZY_VARIANT_ID_MINIMUM=111111
LEMONSQUEEZY_VARIANT_ID_STARTER=222222
LEMONSQUEEZY_VARIANT_ID_PRO=333333

# 이메일 발송 설정 (기존 설정 유지)
AWS_SES_REGION=ap-northeast-2
AWS_SES_FROM_EMAIL=noreply@autogram.com
```

---

## 2. 사용자 스토리

### 주요 사용자 페르소나

**페르소나 1: 신규 유료 사용자**
- 역할: 처음 유료 플랜을 구독하는 사용자
- 목표: 예측 가능한 비용으로 서비스 이용
- 불만 사항: 초과 과금으로 인한 예상치 못한 비용 발생 우려

**페르소나 2: 기존 유료 사용자**
- 역할: 이미 유료 플랜을 사용 중인 사용자
- 목표: 기존 결제일 유지 또는 공정한 환불
- 불만 사항: 정책 변경으로 인한 불이익 우려

**페르소나 3: FREE 플랜 사용자**
- 역할: 무료 플랜으로 서비스를 테스트하는 사용자
- 목표: 한도 내에서 서비스 충분히 테스트
- 불만 사항: 한도 초과 시 갑작스러운 발송 중단

---

### 사용자 스토리 목록

**에픽 1: 구독 결제 주기 변경**

#### US-001: 신규 유료 구독 (결제일 기준)
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 신규 유료 사용자로서
- 결제한 날짜를 기준으로 매월 같은 날에 자동 결제되기를 원합니다
- 그래서 결제일을 명확히 예측할 수 있도록

**수락 기준:**
- [ ] 신규 유료 플랜 구독 시 결제일이 구독일로 설정된다
- [ ] 다음 결제일이 정확히 1개월 후로 계산된다 (예: 1월 15일 구독 → 다음 결제일 2월 15일)
- [ ] 월말 처리 로직이 정확하다 (예: 1월 31일 구독 → 2월 28일 결제, 3월 31일 결제)
- [ ] 구독 완료 이메일에 다음 결제일이 명시된다
- [ ] tb_subscriptions.next_billing_date가 정확히 업데이트된다

**비고:**
- LemonSqueezy의 구독 생성 API 사용
- 월말 처리는 LemonSqueezy의 기본 로직 활용

---

#### US-002: 기존 사용자 전환 (환불 처리)
**우선순위:** 필수
**예상 공수:** 5일

**사용자 스토리:**
- 기존 유료 사용자로서
- 정책 변경으로 인한 불이익을 받지 않기를 원합니다
- 그래서 남은 기간에 대한 공정한 보상을 받을 수 있도록

**수락 기준:**
- [ ] 기존 사용자의 남은 일수가 정확히 계산된다
- [ ] 일할 계산된 크레딧이 LemonSqueezy 계정에 적용된다
- [ ] 새로운 결제일이 전환일 기준으로 설정된다
- [ ] 사용자에게 전환 완료 이메일이 발송된다 (크레딧 금액, 새 결제일 포함)
- [ ] tb_subscriptions.next_billing_date가 전환일 기준으로 업데이트된다

**기술적 노트:**
- LemonSqueezy의 프로레이션 기능 활용
- 크레딧 적용: `invoice_immediately: false` + 프로레이션 자동 계산
- 마이그레이션 스크립트로 일괄 처리

**환불 정책 (제안):**
```
크레딧 금액 = (기존 월 요금) × (남은 일수 / 30일)

예시:
- STARTER 플랜 (₩15,000/월)
- 다음 결제일까지 15일 남음
- 크레딧: ₩15,000 × (15/30) = ₩7,500
- 다음 첫 결제 시 ₩7,500 차감
```

---

#### US-003: 무료 플랜 사용자 (가입일 기준 리셋)
**우선순위:** 필수
**예상 공수:** 2일

**사용자 스토리:**
- 무료 플랜 사용자로서
- 가입일을 기준으로 매월 한도가 리셋되기를 원합니다
- 그래서 한도를 최대한 활용할 수 있도록

**수락 기준:**
- [ ] 가입일(created_at)을 기준으로 다음 리셋일이 계산된다
- [ ] 리셋일에 tb_monthly_usage 레코드가 새로 생성된다
- [ ] 리셋일이 대시보드에 표시된다 (예: "다음 한도 리셋: 2026-02-15")
- [ ] 무료 플랜 유지 시 자동으로 연장된다
- [ ] 유료 플랜 전환 시 전환일 기준으로 새로 시작한다

---

**에픽 2: DM 발송 한도 정책**

#### US-004: 90% 한도 경고 이메일
**우선순위:** 필수
**예상 공수:** 2일

**사용자 스토리:**
- 플랜 사용자로서
- DM 발송 한도의 90%에 도달하면 이메일로 알림을 받기를 원합니다
- 그래서 한도 초과 전에 대응할 수 있도록

**수락 기준:**
- [ ] 90% 도달 시 즉시 이메일이 발송된다
- [ ] 이메일에는 현재 사용량, 남은 한도, 다음 리셋일이 포함된다
- [ ] 90% 경고는 한 결제 주기당 1회만 발송된다 (중복 방지)
- [ ] FREE 플랜은 업그레이드 CTA 버튼이 포함된다
- [ ] 유료 플랜은 "한도 도달 시 발송 차단" 안내가 포함된다

**이메일 템플릿 요구사항:**
```
제목: [Autogram] DM 발송 한도 90% 도달 안내

본문:
안녕하세요, {userName}님.

현재 {planName} 플랜의 DM 발송 한도의 90%에 도달했습니다.

📊 사용 현황:
- 플랜: {planName}
- 월 한도: {dmQuota}건
- 현재 사용: {dmSentCount}건 (90.0%)
- 남은 한도: {remainingQuota}건
- 다음 리셋: {nextResetDate}

⚠️ 한도 도달 시:
- 100% 도달 시 DM 발송이 자동으로 차단됩니다.
- 계속 발송하려면 플랜 업그레이드를 권장합니다.

[플랜 업그레이드하기] (CTA 버튼)

감사합니다.
Autogram 팀
```

---

#### US-005: 100% 한도 도달 차단
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 플랜 사용자로서
- DM 발송 한도에 도달하면 더 이상 발송되지 않기를 원합니다
- 그래서 예상치 못한 초과 요금이 발생하지 않도록

**수락 기준:**
- [ ] 한도 100% 도달 시 DM 발송 시도가 즉시 차단된다
- [ ] 사용자에게 명확한 에러 메시지가 표시된다 ("한도 초과. 업그레이드 필요")
- [ ] 100% 도달 시 이메일이 발송된다 (한도 도달 안내 + 업그레이드 CTA)
- [ ] 예약된 DM은 "실패" 상태로 처리된다
- [ ] 다음 결제 주기까지 발송이 차단된다
- [ ] 모든 플랜(FREE, MINIMUM, STARTER, PRO)에 동일하게 적용된다

**에러 메시지 (프론트엔드):**
```
❌ DM 발송 실패

이번 달 DM 발송 한도에 도달했습니다.
다음 리셋일: {nextResetDate}

[플랜 업그레이드하기] (버튼)
```

**이메일 템플릿:**
```
제목: [Autogram] DM 발송 한도 도달 - 업그레이드 권장

본문:
안녕하세요, {userName}님.

현재 {planName} 플랜의 DM 발송 한도에 도달하여 추가 발송이 중단되었습니다.

📊 사용 현황:
- 플랜: {planName}
- 월 한도: {dmQuota}건
- 현재 사용: {dmSentCount}건 (100%)
- 다음 리셋: {nextResetDate}

🚫 현재 상태:
- 모든 DM 발송이 일시 중단되었습니다.
- 예약된 DM은 실패 처리됩니다.
- {nextResetDate}에 한도가 자동으로 리셋됩니다.

💡 해결 방법:
1. 다음 리셋일까지 기다리기
2. 상위 플랜으로 즉시 업그레이드 (한도 즉시 리셋)

[플랜 업그레이드하기] (CTA 버튼)

감사합니다.
Autogram 팀
```

---

#### US-006: 업그레이드 즉시 적용
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 플랜 업그레이드 사용자로서
- 업그레이드 즉시 새로운 한도를 사용하고 싶습니다
- 그래서 한도 부족으로 인한 서비스 중단을 최소화할 수 있도록

**수락 기준:**
- [ ] 업그레이드 결제 성공 즉시 새 플랜이 적용된다
- [ ] DM 사용량 카운트가 0으로 리셋된다
- [ ] 다음 결제일이 업그레이드일 기준으로 재설정된다
- [ ] tb_subscriptions.plan_seq가 즉시 업데이트된다
- [ ] tb_monthly_usage에 새 레코드가 생성된다 (dm_sent_count=0)
- [ ] 업그레이드 완료 이메일이 발송된다

**기술적 노트:**
- LemonSqueezy 플랜 변경 API 호출
- `invoice_immediately: true` 옵션 사용 (즉시 결제)
- 프로레이션 자동 계산

---

#### US-007: 다운그레이드 예약 적용
**우선순위:** 필수
**예상 공수:** 2일

**사용자 스토리:**
- 플랜 다운그레이드 사용자로서
- 현재 결제 주기가 끝날 때까지 기존 플랜을 사용하고 싶습니다
- 그래서 이미 결제한 금액을 손해 보지 않도록

**수락 기준:**
- [ ] 다운그레이드 요청 시 즉시 적용되지 않는다
- [ ] tb_subscriptions.pending_plan_seq에 새 플랜이 저장된다
- [ ] 현재 결제 주기 종료 후 새 플랜이 적용된다
- [ ] 다운그레이드 예약 안내 이메일이 발송된다 (적용 예정일 포함)
- [ ] 대시보드에 "다음 결제일부터 {새플랜}으로 변경 예정" 메시지가 표시된다
- [ ] 이미 사용한 DM이 다운그레이드 플랜 한도를 초과해도 문제없다 (현재 주기 유지)

**다운그레이드 시 한도 초과 케이스:**
```
시나리오: STARTER(1,500건) → MINIMUM(500건) 다운그레이드
현재 사용량: 800건

결과:
- 현재 주기: 계속 발송 가능 (STARTER 한도 1,500건 유지)
- 다음 주기: MINIMUM 플랜 적용 (한도 500건으로 리셋)
- 문제 없음: 사용량은 새 주기 시작 시 0으로 리셋되므로 안전
```

---

**에픽 3: LemonSqueezy 웹훅 처리**

#### US-008: 구독 생성 웹훅
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 시스템 관리자로서
- LemonSqueezy에서 구독 생성 시 자동으로 DB가 업데이트되기를 원합니다
- 그래서 수동 작업 없이 구독이 활성화되도록

**수락 기준:**
- [ ] `subscription_created` 웹훅 수신 시 tb_subscriptions 레코드가 생성/업데이트된다
- [ ] subscription_status가 'active'로 설정된다
- [ ] next_billing_date가 1개월 후로 설정된다
- [ ] tb_monthly_usage 레코드가 생성된다
- [ ] tb_subscription_history에 'created' 이벤트가 기록된다
- [ ] 웹훅 서명 검증이 정상 작동한다

**API 엔드포인트:**
```
POST /api/webhooks/lemonsqueezy
Authorization: Webhook 서명 검증
```

---

#### US-009: 구독 갱신 웹훅
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 시스템 관리자로서
- LemonSqueezy에서 자동 결제 성공 시 사용량이 리셋되기를 원합니다
- 그래서 사용자가 계속 서비스를 이용할 수 있도록

**수락 기준:**
- [ ] `subscription_payment_success` 웹훅 수신 시 처리된다
- [ ] tb_monthly_usage의 dm_sent_count가 0으로 리셋된다
- [ ] next_billing_date가 1개월 후로 업데이트된다
- [ ] pending_plan_seq가 있으면 plan_seq로 적용된다
- [ ] tb_payment_transactions에 결제 기록이 생성된다
- [ ] tb_subscription_history에 'renewed' 이벤트가 기록된다
- [ ] 결제 영수증 이메일이 발송된다

---

#### US-010: 구독 실패 웹훅
**우선순위:** 필수
**예상 공수:** 3일

**사용자 스토리:**
- 시스템 관리자로서
- LemonSqueezy에서 자동 결제 실패 시 사용자에게 알림이 가기를 원합니다
- 그래서 사용자가 결제 수단을 업데이트할 수 있도록

**수락 기준:**
- [ ] `subscription_payment_failed` 웹훅 수신 시 처리된다
- [ ] 결제 실패 이메일이 즉시 발송된다 (결제 실패 사유, 재시도 일정 포함)
- [ ] tb_payment_transactions에 실패 기록이 생성된다
- [ ] 3회 실패 시 subscription_status가 'suspended'로 변경된다
- [ ] 일시정지 시 FREE 플랜으로 자동 전환된다
- [ ] 일시정지 안내 이메일이 발송된다

---

#### US-011: 구독 취소 웹훅
**우선순위:** 필수
**예상 공수:** 2일

**사용자 스토리:**
- 시스템 관리자로서
- LemonSqueezy에서 구독 취소 시 DB가 업데이트되기를 원합니다
- 그래서 사용자가 FREE 플랜으로 전환되도록

**수락 기준:**
- [ ] `subscription_cancelled` 웹훅 수신 시 처리된다
- [ ] subscription_status가 'cancelled'로 변경된다
- [ ] plan_seq가 FREE 플랜으로 변경된다
- [ ] next_billing_date가 취소일 기준으로 1개월 후로 설정된다 (가입일 기준 리셋 정책 일관성 유지)
- [ ] 구독 취소 완료 이메일이 발송된다
- [ ] tb_subscription_history에 'cancelled' 이벤트가 기록된다

---

## 3. 기능 명세

### 3.1 기능 상세

#### 기능 1: LemonSqueezy 구독 생성

**설명:**
신규 사용자가 유료 플랜을 구독하면 LemonSqueezy API를 통해 구독을 생성하고, 웹훅을 통해 DB를 업데이트합니다.

**입력값:**
- 필수: user_seq, plan_code, payment_method (LemonSqueezy에서 제공하는 결제 수단)
- 선택: variant_id (플랜 변형, 월/년 단위)

**출력값:**
- 성공: { subscription_id, next_billing_date, checkout_url }
- 실패: { error_code, error_message }

**비즈니스 규칙:**
1. 사용자당 1개의 활성 구독만 허용
2. 구독 생성 즉시 구독 확인 이메일 발송
3. 첫 결제 성공 시 next_billing_date = 구독일 + 1개월

**엣지 케이스:**
- 케이스 1: 이미 활성 구독 존재 → 에러 반환 ("기존 구독을 먼저 취소하세요")
- 케이스 2: 결제 실패 → subscription_status='pending', 재시도 안내 이메일 발송
- 케이스 3: 웹훅 수신 실패 → 재시도 메커니즘 (LemonSqueezy 자동 재시도 활용)

---

#### 기능 2: 사용량 리셋

**설명:**
- **유료 플랜**: LemonSqueezy `subscription_payment_success` 웹훅 수신 시 사용량 리셋 (결제 성공 시점)
- **무료 플랜**: 크론잡으로 가입일 기준 매월 리셋 (결제가 없으므로 별도 처리)

---

**기능 2-1: 유료 플랜 사용량 리셋 (웹훅 기반)**

**트리거:**
- LemonSqueezy `subscription_payment_success` 웹훅 수신

**비즈니스 규칙:**
1. 결제 성공 웹훅 수신 시 해당 사용자의 tb_monthly_usage에 새 레코드 생성 (dm_sent_count=0)
2. tb_subscriptions.next_billing_date = 현재 날짜 + 1개월
3. pending_plan_seq가 있으면 plan_seq로 적용 후 pending_plan_seq = NULL

**기술적 구현:**
```javascript
// 웹훅 핸들러: subscription_payment_success
async function handlePaymentSuccess(payload) {
  const userSeq = payload.meta.custom_data.user_seq;
  const subscription = await Subscription.findOne({ where: { user_seq: userSeq } });

  // 1. 다운그레이드 예약이 있으면 적용
  if (subscription.pending_plan_seq) {
    await subscription.update({
      plan_seq: subscription.pending_plan_seq,
      pending_plan_seq: null
    });
  }

  // 2. 사용량 리셋 (새 레코드 생성)
  await createMonthlyUsageRecord(userSeq, subscription.plan_seq);

  // 3. 다음 결제일 업데이트
  const nextDate = addMonths(new Date(), 1);
  await subscription.update({ next_billing_date: nextDate });
}
```

---

**기능 2-2: 무료 플랜 사용량 리셋 (크론잡 기반)**

**입력값:**
- 크론잡 실행 (매일 오전 0시)

**출력값:**
- 리셋된 사용자 수, 실패 목록

**비즈니스 규칙:**
1. FREE 플랜 사용자 중 next_billing_date = 오늘 날짜인 사용자 조회
2. tb_monthly_usage에 새 레코드 생성 (dm_sent_count=0)
3. tb_subscriptions.next_billing_date = 현재 날짜 + 1개월

**엣지 케이스:**
- 케이스 1: 월말 처리 (1월 31일 → 2월 28일, 3월 31일)
- 케이스 2: 윤년 처리 (2월 29일)
- 케이스 3: 크론잡 실행 실패 → 다음 실행 시 누락된 날짜 보정

**기술적 구현:**
```javascript
// 크론잡: 매일 0시 실행 (무료 플랜 전용)
async function resetFreeUsersUsage() {
  const today = new Date().toISOString().split('T')[0]; // YYYY-MM-DD
  const FREE_PLAN_SEQ = 1; // DB에서 조회 권장

  const subscriptions = await Subscription.findAll({
    where: {
      next_billing_date: today,
      plan_seq: FREE_PLAN_SEQ, // 무료 플랜만
      subscription_status: 'active'
    }
  });

  for (const sub of subscriptions) {
    // 1. 새 사용량 레코드 생성
    await createMonthlyUsageRecord(sub.user_seq, sub.plan_seq);

    // 2. 다음 리셋일 계산
    const nextDate = addMonths(today, 1);
    await sub.update({ next_billing_date: nextDate });
  }
}
```

---

#### 기능 3: DM 발송 한도 체크

**설명:**
DM 발송 전에 현재 사용량을 체크하여 한도 초과 여부를 확인하고, 초과 시 발송을 차단합니다.

**입력값:**
- user_seq, dm_count (발송 예정 건수, 기본값 1)

**출력값:**
- 성공: { allowed: true, remaining_quota }
- 실패: { allowed: false, reason: "QUOTA_EXCEEDED", next_reset_date }

**비즈니스 규칙:**
1. 현재 사용량 = tb_monthly_usage.dm_sent_count
2. 플랜 한도 = tb_plan_properties.numeric_value (prop_code='DM')
3. 허용 조건: (현재 사용량 + 발송 예정 건수) <= 플랜 한도
4. 90% 도달 시: 경고 이메일 발송 (한 번만)
5. 100% 도달 시: 차단 + 이메일 발송

**엣지 케이스:**
- 케이스 1: 한도 정확히 100% (예: 500/500) → 추가 발송 차단
- 케이스 2: 동시 발송 요청 (race condition) → 트랜잭션 처리 + 행 잠금
- 케이스 3: 플랜 업그레이드 직후 → 새 한도 즉시 적용

**기술적 구현:**
```javascript
async function checkDmQuota(userSeq, dmCount = 1) {
  // 트랜잭션으로 동시성 제어
  const transaction = await sequelize.transaction();

  try {
    // 1. 현재 사용량 조회 (행 잠금)
    const usage = await MonthlyUsage.findOne({
      where: { user_seq: userSeq, year_month: getCurrentYearMonth() },
      lock: transaction.LOCK.UPDATE,
      transaction
    });

    // 2. 플랜 한도 조회 (반드시 DB에서 조회 - 하드코딩 금지)
    // getDmQuotaByUser 내부에서 tb_plan_properties 테이블 조회
    const quota = await getDmQuotaByUser(userSeq);

    // 3. 한도 체크
    if (usage.dm_sent_count + dmCount > quota) {
      await transaction.commit();

      // 100% 도달 이메일 발송 (한 번만)
      if (!usage.quota_reached_email_sent) {
        await sendQuotaReachedEmail(userSeq);
        await usage.update({ quota_reached_email_sent: true });
      }

      return { allowed: false, reason: 'QUOTA_EXCEEDED' };
    }

    // 4. 90% 경고 체크
    const usagePercent = ((usage.dm_sent_count + dmCount) / quota) * 100;
    if (usagePercent >= 90 && !usage.warning_email_sent) {
      await sendUsageWarningEmail(userSeq);
      await usage.update({ warning_email_sent: true });
    }

    await transaction.commit();
    return { allowed: true, remaining_quota: quota - usage.dm_sent_count };

  } catch (error) {
    await transaction.rollback();
    throw error;
  }
}
```

---

#### 기능 4: LemonSqueezy 웹훅 처리

**설명:**
LemonSqueezy에서 발생하는 구독 이벤트를 수신하여 DB를 업데이트합니다.

**지원 웹훅 이벤트:**
1. `subscription_created`: 구독 생성
2. `subscription_updated`: 구독 정보 변경 (플랜 변경 등)
3. `subscription_payment_success`: 결제 성공
4. `subscription_payment_failed`: 결제 실패
5. `subscription_cancelled`: 구독 취소
6. `subscription_resumed`: 구독 재개

**입력값:**
```json
{
  "meta": {
    "event_name": "subscription_created",
    "webhook_id": "xxx"
  },
  "data": {
    "id": "123456",
    "attributes": {
      "user_email": "user@example.com",
      "status": "active",
      "variant_id": 789,
      "customer_id": 456,
      "renews_at": "2026-02-15T00:00:00Z"
    }
  }
}
```

**출력값:**
- 성공: HTTP 200 + { received: true }
- 실패: HTTP 400/500 + { error }

**비즈니스 규칙:**
1. 웹훅 서명 검증 필수 (LemonSqueezy 공개키 사용)
2. 멱등성 보장 (동일 이벤트 중복 처리 방지)
3. 처리 실패 시 LemonSqueezy가 자동 재시도 (최대 10회, 지수 백오프)

**엣지 케이스:**
- 케이스 1: 웹훅 중복 수신 → event_id 기준 중복 체크
- 케이스 2: 웹훅 순서 보장 안됨 → timestamp 기준 정렬 처리
- 케이스 3: 서명 검증 실패 → 즉시 거부 (HTTP 401)

---

### 3.2 화면/UI 요구사항

#### 화면 1: DM 발송 실패 에러 메시지

**위치:** DM 발송 시도 시 (대시보드 내 트리거 관리 페이지)

**구성요소:**
- 에러 아이콘 (🚫)
- 에러 제목: "DM 발송 실패"
- 에러 메시지: "이번 달 DM 발송 한도에 도달했습니다."
- 상세 정보: "다음 리셋일: {nextResetDate}"
- CTA 버튼: "플랜 업그레이드하기" (업그레이드 페이지로 이동)

**상호작용:**
- 에러 발생 시 모달 또는 토스트 알림으로 표시
- CTA 버튼 클릭 시 `/dashboard/subscription/upgrade` 페이지로 이동
- 5초 후 자동으로 사라짐 (모달인 경우 수동 닫기 가능)

**반응형:**
- 모바일: 전체 화면 모달
- 태블릿/데스크톱: 중앙 정렬 모달 (최대 너비 400px)

---

#### 화면 2: 약관 페이지 수정

**위치:** `/terms/[locale]` (한국어, 영어, 일본어)

**수정 내용:**
- **제8조 (요금 및 결제)** 섹션:
  - 기존: "초과 사용 시 건당 추가 과금"
  - 변경: "한도 도달 시 발송 자동 중단"

- **제9조 (환불 정책)** 섹션:
  - 추가: "결제 주기 변경 시 일할 계산된 크레딧 적용"

**수정 예시 (한국어):**
```markdown
### 제8조 (요금 및 결제)

4. **DM 발송 한도**
   - 각 플랜별로 월 DM 발송 한도가 설정되어 있습니다.
   - 한도 도달 시 다음 결제 주기까지 DM 발송이 자동으로 중단됩니다.
   - 계속 발송을 원하시면 상위 플랜으로 업그레이드해 주세요.

5. **결제 주기**
   - 유료 플랜은 결제일을 기준으로 1개월 단위로 자동 결제됩니다.
   - 무료 플랜은 가입일을 기준으로 매월 한도가 리셋됩니다.
```

**버전 관리:**
- 최종 수정일 업데이트: 2026-01-24
- 별도 버전 관리 시스템 불필요 (한 번만 수정)
- 사용자 동의 재수집 불필요 (이용 약관 변경이 사용자에게 불리하지 않음)

---

### 3.3 API/데이터 요구사항

#### API 엔드포인트 1: LemonSqueezy 웹훅 수신

**엔드포인트:** `POST /api/webhooks/lemonsqueezy`

**요청 헤더:**
```
Content-Type: application/json
X-Signature: {HMAC-SHA256 서명}
```

**요청 본문:**
```json
{
  "meta": {
    "event_name": "subscription_created",
    "webhook_id": "webhook_123",
    "custom_data": {
      "user_seq": 456
    }
  },
  "data": {
    "id": "789",
    "type": "subscriptions",
    "attributes": {
      "store_id": 12345,
      "customer_id": 67890,
      "status": "active",
      "variant_id": 111,
      "renews_at": "2026-02-15T00:00:00.000000Z",
      "ends_at": null
    }
  }
}
```

**응답:**
```json
{
  "received": true,
  "processed": true,
  "message": "Webhook processed successfully"
}
```

**에러 응답:**
```json
{
  "error": "INVALID_SIGNATURE",
  "message": "Webhook signature verification failed",
  "received": true,
  "processed": false
}
```

---

#### API 엔드포인트 2: DM 발송 한도 체크

**엔드포인트:** `GET /api/users/:userSeq/quota`

**요청 파라미터:**
- `userSeq` (path): 사용자 seq

**응답 (한도 내):**
```json
{
  "allowed": true,
  "quota": 500,
  "used": 350,
  "remaining": 150,
  "usage_percentage": 70.0,
  "next_reset_date": "2026-02-15",
  "plan_code": "MINIMUM"
}
```

**응답 (한도 초과):**
```json
{
  "allowed": false,
  "reason": "QUOTA_EXCEEDED",
  "quota": 500,
  "used": 500,
  "remaining": 0,
  "usage_percentage": 100.0,
  "next_reset_date": "2026-02-15",
  "plan_code": "MINIMUM",
  "message": "이번 달 DM 발송 한도에 도달했습니다. 다음 리셋일까지 기다리거나 플랜을 업그레이드해 주세요."
}
```

---

#### 데이터 모델 변경

**tb_subscriptions 테이블 수정:**
```sql
-- LemonSqueezy 관련 컬럼 추가
ALTER TABLE tb_subscriptions
ADD COLUMN lemon_squeezy_subscription_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 구독 ID',
ADD COLUMN lemon_squeezy_customer_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 고객 ID',
ADD COLUMN lemon_squeezy_variant_id VARCHAR(100) NULL COMMENT 'LemonSqueezy 플랜 변형 ID',
ADD COLUMN pending_plan_seq INT UNSIGNED NULL COMMENT '다운그레이드 예약 시 다음 결제일에 적용될 플랜';

-- 아임포트 관련 컬럼 삭제 (마이그레이션 후)
-- ALTER TABLE tb_subscriptions
-- DROP COLUMN billing_key,
-- DROP COLUMN card_name,
-- DROP COLUMN card_number;
```

**tb_monthly_usage 테이블 수정:**
```sql
-- 초과 과금 관련 컬럼 삭제
ALTER TABLE tb_monthly_usage
DROP COLUMN overage_count,
DROP COLUMN overage_charge,
DROP COLUMN overage_unit_price;

-- 이메일 발송 플래그 추가
ALTER TABLE tb_monthly_usage
ADD COLUMN warning_email_sent TINYINT(1) NOT NULL DEFAULT 0 COMMENT '90% 경고 이메일 발송 여부',
ADD COLUMN quota_reached_email_sent TINYINT(1) NOT NULL DEFAULT 0 COMMENT '100% 한도 도달 이메일 발송 여부';
```

**tb_plan_properties 테이블 수정:**
```sql
-- OVER_USAGE 속성 삭제
DELETE FROM tb_plan_properties WHERE prop_code = 'OVER_USAGE';

-- prop_code ENUM 수정 (향후 적용)
-- ALTER TABLE tb_plan_properties
-- MODIFY COLUMN prop_code ENUM('DM', 'TRIGGER', 'ANALYTICS', 'CTA') NOT NULL;
```

**tb_webhook_events 테이블 생성 (새로 추가):**
```sql
CREATE TABLE `tb_webhook_events` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `provider` ENUM('LEMONSQUEEZY') NOT NULL COMMENT '웹훅 제공자',
  `event_id` VARCHAR(100) NOT NULL COMMENT '웹훅 이벤트 고유 ID (중복 체크용)',
  `event_name` VARCHAR(50) NOT NULL COMMENT '이벤트 이름 (예: subscription_created)',
  `payload` JSON NOT NULL COMMENT '웹훅 페이로드 전체',
  `status` ENUM('pending', 'processed', 'failed') NOT NULL DEFAULT 'pending',
  `processed_at` DATETIME(6) NULL COMMENT '처리 완료 시간',
  `error_message` TEXT NULL COMMENT '처리 실패 사유',
  `retry_count` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '재시도 횟수',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE INDEX `UNQ_WEBHOOK_EVENT_ID` (`provider`, `event_id`),
  INDEX `IDX_WEBHOOK_STATUS` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='웹훅 이벤트 이력 및 멱등성 보장';
```

---

## 4. 비기능 요구사항

### 4.1 성능
- 웹훅 처리 시간: 평균 < 500ms, 최대 < 2초
- DM 한도 체크 시간: < 100ms (캐싱 활용)
- 사용량 리셋 크론잡: 1,000명 기준 < 5분
- 동시 DM 발송 요청: 초당 100건 처리 가능

### 4.2 보안
- **웹훅 서명 검증**: HMAC-SHA256 + LemonSqueezy 공개키
- **API 인증**: JWT 토큰 기반 (기존 방식 유지)
- **데이터 암호화**:
  - LemonSqueezy customer_id, subscription_id 암호화 저장 (AES-256)
  - 결제 정보는 LemonSqueezy에 저장 (PCI-DSS 준수)
- **민감 정보 로깅 금지**: 결제 정보, 개인정보는 로그에서 마스킹

### 4.3 접근성
- 이메일 템플릿: 스크린 리더 호환 (시맨틱 HTML)
- 에러 메시지: 명확하고 이해하기 쉬운 문구 (전문 용어 배제)
- 다국어 지원: 한국어 우선, 영어/일본어 향후 추가

### 4.4 호환성
- **LemonSqueezy API**: v1 (2026년 1월 기준 최신)
- **Node.js**: 18.x 이상
- **MySQL**: 8.0 이상
- **브라우저**: 에러 메시지 표시 (기존 UI 호환)

### 4.5 모니터링 및 로깅
- **웹훅 처리 실패**: Sentry 알림 + Slack 알림
- **결제 실패**: 실시간 알림 (관리자 Slack)
- **한도 도달**: 일일 리포트 (사용자별 한도 도달 현황)
- **크론잡 실행 실패**: PagerDuty 알림

---

## 5. DB 스키마 변경사항

### 5.1 마이그레이션 SQL (Up)

```sql
-- ============================================
-- 마이그레이션: v2.0.0 - 과금 정책 변경
-- 작성일: 2026-01-24
-- 설명: LemonSqueezy 전환 + 초과 과금 제거
-- ============================================

USE `sns_automation`;

-- 1. tb_subscriptions 테이블 수정
-- LemonSqueezy 관련 컬럼 추가 + 다운그레이드 예약 컬럼 추가
ALTER TABLE `tb_subscriptions`
ADD COLUMN `lemon_squeezy_subscription_id` VARCHAR(100) NULL COMMENT 'LemonSqueezy 구독 ID' AFTER `user_seq`,
ADD COLUMN `lemon_squeezy_customer_id` VARCHAR(100) NULL COMMENT 'LemonSqueezy 고객 ID' AFTER `lemon_squeezy_subscription_id`,
ADD COLUMN `lemon_squeezy_variant_id` VARCHAR(100) NULL COMMENT 'LemonSqueezy 플랜 변형 ID' AFTER `lemon_squeezy_customer_id`,
ADD COLUMN `pending_plan_seq` INT UNSIGNED NULL COMMENT '다운그레이드 예약 시 다음 결제일에 적용될 플랜' AFTER `plan_seq`,
ADD INDEX `IDX_SUBSCRIPTIONS_LEMON_SUB_ID` (`lemon_squeezy_subscription_id`);

-- 2. tb_monthly_usage 테이블 수정
-- 초과 과금 관련 컬럼 삭제
ALTER TABLE `tb_monthly_usage`
DROP COLUMN `overage_count`,
DROP COLUMN `overage_charge`,
DROP COLUMN `overage_unit_price`;

-- 이메일 발송 플래그 추가
ALTER TABLE `tb_monthly_usage`
ADD COLUMN `warning_email_sent` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '90% 경고 이메일 발송 여부' AFTER `dm_sent_count`,
ADD COLUMN `quota_reached_email_sent` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '100% 한도 도달 이메일 발송 여부' AFTER `warning_email_sent`;

-- 3. tb_plan_properties 테이블 수정
-- OVER_USAGE 속성 삭제
DELETE FROM `tb_plan_properties` WHERE `prop_code` = 'OVER_USAGE';

-- 4. tb_webhook_events 테이블 생성
CREATE TABLE `tb_webhook_events` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `provider` ENUM('LEMONSQUEEZY') NOT NULL COMMENT '웹훅 제공자',
  `event_id` VARCHAR(100) NOT NULL COMMENT '웹훅 이벤트 고유 ID (중복 체크용)',
  `event_name` VARCHAR(50) NOT NULL COMMENT '이벤트 이름 (예: subscription_created)',
  `payload` JSON NOT NULL COMMENT '웹훅 페이로드 전체',
  `status` ENUM('pending', 'processed', 'failed') NOT NULL DEFAULT 'pending',
  `processed_at` DATETIME(6) NULL COMMENT '처리 완료 시간',
  `error_message` TEXT NULL COMMENT '처리 실패 사유',
  `retry_count` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '재시도 횟수',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  UNIQUE INDEX `UNQ_WEBHOOK_EVENT_ID` (`provider`, `event_id`),
  INDEX `IDX_WEBHOOK_STATUS` (`status`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='웹훅 이벤트 이력 및 멱등성 보장';

-- 5. tb_payment_transactions 테이블 수정
-- LemonSqueezy 관련 컬럼 추가
ALTER TABLE `tb_payment_transactions`
ADD COLUMN `lemon_squeezy_order_id` VARCHAR(100) NULL COMMENT 'LemonSqueezy 주문 ID' AFTER `merchant_uid`,
ADD COLUMN `provider` ENUM('IAMPORT', 'LEMONSQUEEZY') NOT NULL DEFAULT 'IAMPORT' COMMENT '결제 제공자' AFTER `subscription_seq`;

-- transaction_type ENUM 수정 (overage 제거)
ALTER TABLE `tb_payment_transactions`
MODIFY COLUMN `transaction_type` ENUM('subscription', 'refund') NOT NULL DEFAULT 'subscription';

-- 6. 데이터 마이그레이션 준비
-- 기존 사용자의 다음 결제일을 전환일 기준으로 재계산
-- (실제 마이그레이션 스크립트는 별도 작성)

-- ============================================
-- 마이그레이션 완료
-- ============================================
```

### 5.2 마이그레이션 SQL (Down - 롤백용)

```sql
-- ============================================
-- 롤백: v2.0.0 - 과금 정책 변경
-- 작성일: 2026-01-24
-- ============================================

USE `sns_automation`;

-- 1. tb_subscriptions 롤백
ALTER TABLE `tb_subscriptions`
DROP INDEX `IDX_SUBSCRIPTIONS_LEMON_SUB_ID`,
DROP COLUMN `lemon_squeezy_subscription_id`,
DROP COLUMN `lemon_squeezy_customer_id`,
DROP COLUMN `lemon_squeezy_variant_id`,
DROP COLUMN `pending_plan_seq`;

-- 2. tb_monthly_usage 롤백
ALTER TABLE `tb_monthly_usage`
ADD COLUMN `overage_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 건수' AFTER `dm_sent_count`,
ADD COLUMN `overage_charge` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 요금 (원)' AFTER `overage_count`,
ADD COLUMN `overage_unit_price` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 단가 (플랜별)' AFTER `overage_charge`,
DROP COLUMN `warning_email_sent`,
DROP COLUMN `quota_reached_email_sent`;

-- 3. tb_plan_properties 롤백
-- OVER_USAGE 속성 복원 (수동 INSERT 필요)
-- INSERT INTO tb_plan_properties ... (생략)

-- 4. tb_webhook_events 테이블 삭제
DROP TABLE IF EXISTS `tb_webhook_events`;

-- 5. tb_payment_transactions 롤백
ALTER TABLE `tb_payment_transactions`
DROP COLUMN `lemon_squeezy_order_id`,
DROP COLUMN `provider`;

ALTER TABLE `tb_payment_transactions`
MODIFY COLUMN `transaction_type` ENUM('subscription', 'overage', 'refund') NOT NULL DEFAULT 'subscription';

-- ============================================
-- 롤백 완료
-- ============================================
```

### 5.3 데이터 마이그레이션 스크립트

```javascript
/**
 * 기존 사용자 LemonSqueezy 전환 스크립트
 *
 * 실행 순서:
 * 1. 모든 활성 유료 구독 사용자 조회
 * 2. LemonSqueezy에 구독 생성
 * 3. 남은 일수 계산 및 크레딧 적용
 * 4. 새로운 next_billing_date 설정
 * 5. 사용자에게 전환 완료 이메일 발송
 */

async function migrateToLemonSqueezy() {
  const subscriptions = await Subscription.findAll({
    where: {
      subscription_status: 'active',
      plan_seq: { [Op.ne]: FREE_PLAN_SEQ } // FREE 플랜 제외
    },
    include: [{ model: User }, { model: Plan }]
  });

  const results = {
    success: 0,
    failed: 0,
    errors: []
  };

  for (const sub of subscriptions) {
    try {
      // 1. 남은 일수 계산
      const today = new Date();
      const nextBillingDate = new Date(sub.next_billing_date);
      const daysRemaining = Math.ceil((nextBillingDate - today) / (1000 * 60 * 60 * 24));

      // 2. 크레딧 계산
      const creditAmount = Math.round((sub.plan.price * daysRemaining) / 30);

      // 3. LemonSqueezy 구독 생성
      const lemonSubscription = await createLemonSqueezySubscription({
        email: sub.user.email,
        variantId: getLemonSqueezyVariantId(sub.plan.plan_code),
        customData: {
          user_seq: sub.user_seq,
          credit_amount: creditAmount
        }
      });

      // 4. DB 업데이트
      await sub.update({
        lemon_squeezy_subscription_id: lemonSubscription.id,
        lemon_squeezy_customer_id: lemonSubscription.customer_id,
        next_billing_date: today.toISOString().split('T')[0], // 전환일 기준
      });

      // 5. 전환 완료 이메일 발송
      await sendMigrationCompleteEmail(sub.user.email, {
        creditAmount,
        newBillingDate: today,
        planName: sub.plan.name_ko
      });

      results.success++;
      logger.info(`User ${sub.user_seq} migrated successfully`);

    } catch (error) {
      results.failed++;
      results.errors.push({
        user_seq: sub.user_seq,
        error: error.message
      });
      logger.error(`Failed to migrate user ${sub.user_seq}:`, error);
    }
  }

  return results;
}
```

---

## 6. API 변경사항

### 6.1 신규 API

#### 1. LemonSqueezy 웹훅 수신
- **경로**: `POST /api/webhooks/lemonsqueezy`
- **인증**: 웹훅 서명 검증
- **설명**: LemonSqueezy 이벤트 수신 및 처리

#### 2. 사용자 한도 조회
- **경로**: `GET /api/users/:userSeq/quota`
- **인증**: JWT 토큰
- **설명**: 현재 사용자의 DM 발송 한도 및 사용량 조회

#### 3. 구독 마이그레이션 (관리자용)
- **경로**: `POST /api/admin/subscriptions/migrate-to-lemonsqueezy`
- **인증**: 관리자 토큰
- **설명**: 기존 사용자를 LemonSqueezy로 일괄 전환

### 6.2 수정 API

#### 1. DM 발송 API
- **경로**: `POST /api/dm/send`
- **변경사항**:
  - 한도 체크 로직 강화 (100% 도달 시 즉시 차단)
  - 초과 과금 로직 제거
  - 에러 응답에 `next_reset_date` 추가

#### 2. 구독 생성 API
- **경로**: `POST /api/subscriptions`
- **변경사항**:
  - 아임포트 → LemonSqueezy API 호출로 변경
  - 응답에 `checkout_url` 추가 (LemonSqueezy 결제 페이지)

#### 3. 구독 변경 API
- **경로**: `PATCH /api/subscriptions/:subscriptionSeq`
- **변경사항**:
  - 업그레이드 시 즉시 적용 + 사용량 리셋
  - 다운그레이드 시 `pending_plan_seq`에 저장

### 6.3 삭제 API

#### 1. 초과 요금 조회 API (삭제)
- **경로**: `GET /api/users/:userSeq/overage` ❌
- **사유**: 초과 과금 정책 제거

#### 2. 초과 요금 결제 API (삭제)
- **경로**: `POST /api/payments/overage` ❌
- **사유**: 초과 과금 정책 제거

---

## 7. 프론트엔드 변경사항

### 7.1 약관 페이지 수정

**파일 경로:** `/web/app/terms/[locale]/page.tsx`

**수정 내용:**
- 제8조 (요금 및 결제) 섹션 수정
- 최종 수정일 업데이트: 2026-01-24

**수정 전 (기존):**
```tsx
<section>
  <h2>제8조 (요금 및 결제)</h2>
  <ol>
    <li>유료 플랜 사용 시 월 기본 요금이 부과됩니다.</li>
    <li>플랜별 DM 발송 한도를 초과하는 경우 건당 추가 요금이 부과됩니다.</li>
    <li>초과 요금은 다음 결제일에 기본 요금과 함께 청구됩니다.</li>
  </ol>
</section>
```

**수정 후 (신규):**
```tsx
<section>
  <h2>제8조 (요금 및 결제)</h2>
  <ol>
    <li>유료 플랜 사용 시 월 기본 요금이 부과됩니다.</li>
    <li>결제는 구독일을 기준으로 매월 자동으로 진행됩니다.</li>
    <li>
      <strong>DM 발송 한도:</strong> 각 플랜별로 월 DM 발송 한도가 설정되어 있습니다.
      <ul>
        <li>한도 90% 도달 시: 이메일 경고 알림 발송</li>
        <li>한도 100% 도달 시: 다음 결제 주기까지 DM 발송 자동 중단</li>
        <li>계속 발송을 원하시면 상위 플랜으로 업그레이드해 주세요.</li>
      </ul>
    </li>
    <li>무료 플랜은 가입일을 기준으로 매월 한도가 자동으로 리셋됩니다.</li>
  </ol>
</section>
```

### 7.2 에러 메시지 UI

**파일 경로:** `/web/components/dm/ErrorModal.tsx` (신규 생성)

**컴포넌트 명세:**
```tsx
interface ErrorModalProps {
  isOpen: boolean;
  onClose: () => void;
  error: {
    code: 'QUOTA_EXCEEDED' | 'PAYMENT_FAILED' | 'UNKNOWN';
    message: string;
    nextResetDate?: string;
  };
}

export function ErrorModal({ isOpen, onClose, error }: ErrorModalProps) {
  // 에러 코드별 UI 렌더링
  // QUOTA_EXCEEDED: 한도 초과 UI + 업그레이드 CTA
  // PAYMENT_FAILED: 결제 실패 UI + 결제 수단 업데이트 CTA
  // UNKNOWN: 일반 에러 UI
}
```

**디자인 요구사항:**
- 에러 아이콘: 빨간색 🚫 (32px)
- 제목: 볼드체, 18px
- 메시지: 일반체, 14px, gray-600
- CTA 버튼: primary 색상, 전체 너비
- 모달 배경: semi-transparent black (0.5 opacity)

---

## 8. 이메일 템플릿 요구사항

### 8.1 90% 경고 이메일

**파일명:** `usage-warning-90.html`

**변수:**
- `{userName}`: 사용자 이름
- `{planName}`: 플랜 이름 (무료, 미니멈, 스타터, 프로)
- `{dmQuota}`: 월 DM 한도
- `{dmSentCount}`: 현재 사용량
- `{remainingQuota}`: 남은 한도
- `{usagePercentage}`: 사용률 (%)
- `{nextResetDate}`: 다음 리셋일 (YYYY-MM-DD)
- `{isFree}`: FREE 플랜 여부 (boolean)

**제목:**
```
[Autogram] DM 발송 한도 90% 도달 안내
```

**본문 (HTML):**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <style>
    body { font-family: 'Apple SD Gothic Neo', sans-serif; }
    .container { max-width: 600px; margin: 0 auto; padding: 40px 20px; }
    .header { text-align: center; margin-bottom: 30px; }
    .stats-box { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; }
    .stat-row { display: flex; justify-content: space-between; margin: 10px 0; }
    .warning-box { background: #fff3cd; border-left: 4px solid #ffc107; padding: 15px; margin: 20px 0; }
    .cta-button {
      display: inline-block;
      background: #007bff;
      color: white;
      padding: 12px 30px;
      border-radius: 6px;
      text-decoration: none;
      margin: 20px 0;
    }
    .footer { text-align: center; color: #6c757d; font-size: 12px; margin-top: 40px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🔔 DM 발송 한도 90% 도달</h1>
      <p>안녕하세요, {{userName}}님.</p>
    </div>

    <p>현재 <strong>{{planName}}</strong> 플랜의 DM 발송 한도의 <strong>90%</strong>에 도달했습니다.</p>

    <div class="stats-box">
      <h3>📊 사용 현황</h3>
      <div class="stat-row">
        <span>플랜:</span>
        <strong>{{planName}}</strong>
      </div>
      <div class="stat-row">
        <span>월 한도:</span>
        <strong>{{dmQuota}}건</strong>
      </div>
      <div class="stat-row">
        <span>현재 사용:</span>
        <strong>{{dmSentCount}}건 ({{usagePercentage}}%)</strong>
      </div>
      <div class="stat-row">
        <span>남은 한도:</span>
        <strong>{{remainingQuota}}건</strong>
      </div>
      <div class="stat-row">
        <span>다음 리셋:</span>
        <strong>{{nextResetDate}}</strong>
      </div>
    </div>

    <div class="warning-box">
      <h3>⚠️ 한도 도달 시</h3>
      <ul>
        <li>100% 도달 시 DM 발송이 자동으로 중단됩니다.</li>
        <li>다음 리셋일까지 대기하거나 플랜 업그레이드를 권장합니다.</li>
      </ul>
    </div>

    {{#if isFree}}
    <div style="text-align: center;">
      <p><strong>유료 플랜으로 업그레이드하고 더 많은 DM을 발송하세요!</strong></p>
      <a href="https://autogram.com/dashboard/subscription/upgrade" class="cta-button">
        플랜 업그레이드하기
      </a>
    </div>
    {{else}}
    <div style="text-align: center;">
      <p>상위 플랜으로 업그레이드하여 더 많은 한도를 확보하세요.</p>
      <a href="https://autogram.com/dashboard/subscription/upgrade" class="cta-button">
        플랜 업그레이드하기
      </a>
    </div>
    {{/if}}

    <div class="footer">
      <p>감사합니다.</p>
      <p><strong>Autogram 팀</strong></p>
      <p style="margin-top: 20px;">
        <a href="https://autogram.com/terms">이용약관</a> |
        <a href="https://autogram.com/privacy">개인정보처리방침</a>
      </p>
    </div>
  </div>
</body>
</html>
```

---

### 8.2 100% 한도 도달 이메일

**파일명:** `quota-reached-100.html`

**변수:** (90% 경고 이메일과 동일)

**제목:**
```
[Autogram] DM 발송 한도 도달 - 업그레이드 권장
```

**본문 (HTML):**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <style>
    /* (90% 이메일과 동일한 스타일) */
    .danger-box { background: #f8d7da; border-left: 4px solid #dc3545; padding: 15px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>🚫 DM 발송 한도 도달</h1>
      <p>안녕하세요, {{userName}}님.</p>
    </div>

    <p>현재 <strong>{{planName}}</strong> 플랜의 DM 발송 한도에 도달하여 <strong>추가 발송이 중단</strong>되었습니다.</p>

    <div class="stats-box">
      <h3>📊 사용 현황</h3>
      <div class="stat-row">
        <span>플랜:</span>
        <strong>{{planName}}</strong>
      </div>
      <div class="stat-row">
        <span>월 한도:</span>
        <strong>{{dmQuota}}건</strong>
      </div>
      <div class="stat-row">
        <span>현재 사용:</span>
        <strong>{{dmSentCount}}건 (100%)</strong>
      </div>
      <div class="stat-row">
        <span>다음 리셋:</span>
        <strong>{{nextResetDate}}</strong>
      </div>
    </div>

    <div class="danger-box">
      <h3>🚫 현재 상태</h3>
      <ul>
        <li>모든 DM 발송이 일시 중단되었습니다.</li>
        <li>예약된 DM은 실패 처리됩니다.</li>
        <li><strong>{{nextResetDate}}</strong>에 한도가 자동으로 리셋됩니다.</li>
      </ul>
    </div>

    <div style="background: #e7f3ff; padding: 20px; border-radius: 8px; margin: 20px 0;">
      <h3>💡 해결 방법</h3>
      <ol>
        <li><strong>다음 리셋일까지 기다리기:</strong> {{nextResetDate}}에 자동 리셋</li>
        <li><strong>즉시 업그레이드:</strong> 상위 플랜으로 업그레이드 시 한도 즉시 리셋</li>
      </ol>
    </div>

    <div style="text-align: center;">
      <p><strong>플랜을 업그레이드하고 지금 바로 DM 발송을 재개하세요!</strong></p>
      <a href="https://autogram.com/dashboard/subscription/upgrade" class="cta-button">
        플랜 업그레이드하기
      </a>
    </div>

    <div class="footer">
      <p>감사합니다.</p>
      <p><strong>Autogram 팀</strong></p>
      <p style="margin-top: 20px;">
        <a href="https://autogram.com/terms">이용약관</a> |
        <a href="https://autogram.com/privacy">개인정보처리방침</a>
      </p>
    </div>
  </div>
</body>
</html>
```

---

### 8.3 전환 완료 이메일 (기존 사용자용)

**파일명:** `migration-complete.html`

**변수:**
- `{userName}`: 사용자 이름
- `{planName}`: 플랜 이름
- `{creditAmount}`: 적용된 크레딧 금액 (원)
- `{newBillingDate}`: 새로운 결제일 (YYYY-MM-DD)
- `{nextBillingDate}`: 다음 결제 예정일 (YYYY-MM-DD)

**제목:**
```
[Autogram] 구독 정책 변경 안내 및 크레딧 적용 완료
```

**본문:**
```html
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <style>
    /* (위와 동일한 스타일) */
    .info-box { background: #d1ecf1; border-left: 4px solid #17a2b8; padding: 15px; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>📢 구독 정책 변경 안내</h1>
      <p>안녕하세요, {{userName}}님.</p>
    </div>

    <p>Autogram의 구독 정책이 변경되어 안내 드립니다.</p>

    <div class="info-box">
      <h3>🔄 주요 변경사항</h3>
      <ul>
        <li><strong>결제 주기 변경:</strong> 모든 사용자는 구독일 기준으로 매월 결제됩니다.</li>
        <li><strong>초과 과금 제거:</strong> DM 한도 도달 시 추가 과금 없이 발송이 중단됩니다.</li>
        <li><strong>한도 경고 알림:</strong> 90% 도달 시 이메일로 알림을 받으실 수 있습니다.</li>
      </ul>
    </div>

    <div class="stats-box">
      <h3>💰 크레딧 적용 완료</h3>
      <p>남은 구독 기간에 대한 크레딧이 자동으로 적용되었습니다.</p>
      <div class="stat-row">
        <span>적용된 크레딧:</span>
        <strong>₩{{creditAmount}}</strong>
      </div>
      <div class="stat-row">
        <span>다음 첫 결제 시:</span>
        <strong>크레딧 차감 후 청구</strong>
      </div>
    </div>

    <div class="stats-box">
      <h3>📅 새로운 결제 일정</h3>
      <div class="stat-row">
        <span>현재 플랜:</span>
        <strong>{{planName}}</strong>
      </div>
      <div class="stat-row">
        <span>결제일 기준:</span>
        <strong>{{newBillingDate}}</strong>
      </div>
      <div class="stat-row">
        <span>다음 결제일:</span>
        <strong>{{nextBillingDate}}</strong>
      </div>
    </div>

    <p style="margin-top: 30px;">더 나은 서비스를 제공하기 위한 변경이오니 양해 부탁드립니다.</p>

    <div style="text-align: center; margin: 30px 0;">
      <a href="https://autogram.com/dashboard/subscription" class="cta-button">
        구독 정보 확인하기
      </a>
    </div>

    <div class="footer">
      <p>문의사항이 있으시면 언제든지 고객센터로 연락 주세요.</p>
      <p><strong>Autogram 팀</strong></p>
      <p style="margin-top: 20px;">
        <a href="https://autogram.com/terms">이용약관</a> |
        <a href="https://autogram.com/privacy">개인정보처리방침</a>
      </p>
    </div>
  </div>
</body>
</html>
```

---

## 9. 태스크 분해

### 에픽 1: LemonSqueezy 인프라 구축

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-001** | LemonSqueezy 계정 및 제품 설정 | LemonSqueezy 판매자 계정 생성, 4개 플랜 제품/변형 생성, API 키 발급 | 필수 | 0.5일 | DevOps | - |
| **T-002** | 웹훅 엔드포인트 설정 | `/api/webhooks/lemonsqueezy` 라우팅 설정, HTTPS 인증서 확인 | 필수 | 0.5일 | 백엔드 | T-001 |
| **T-003** | 웹훅 서명 검증 구현 | HMAC-SHA256 서명 검증 로직 구현 | 필수 | 1일 | 백엔드 | T-002 |
| **T-004** | 웹훅 이벤트 저장 모델 | `tb_webhook_events` 테이블 생성 및 Sequelize 모델 정의 | 필수 | 0.5일 | 백엔드 | - |

---

### 에픽 2: DB 마이그레이션

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-101** | 마이그레이션 SQL 작성 | Up/Down SQL 스크립트 작성 (컬럼 추가/삭제) | 필수 | 1일 | DBA | - |
| **T-102** | 로컬 환경 마이그레이션 테스트 | 로컬 DB에서 Up/Down 스크립트 실행 및 검증 | 필수 | 0.5일 | DBA | T-101 |
| **T-103** | 스테이징 환경 마이그레이션 | 스테이징 DB 마이그레이션 실행 | 필수 | 0.5일 | DevOps | T-102 |
| **T-104** | Sequelize 모델 업데이트 | MonthlyUsage, Subscription 모델 수정 | 필수 | 0.5일 | 백엔드 | T-101 |

---

### 에픽 3: LemonSqueezy 웹훅 처리

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-201** | 웹훅 핸들러 베이스 구현 | 웹훅 수신, 서명 검증, 이벤트 저장 공통 로직 | 필수 | 2일 | 백엔드 | T-003, T-004 |
| **T-202** | `subscription_created` 핸들러 | 구독 생성 이벤트 처리 로직 | 필수 | 2일 | 백엔드 | T-201 |
| **T-203** | `subscription_payment_success` 핸들러 | 결제 성공 이벤트 처리 (사용량 리셋) | 필수 | 2일 | 백엔드 | T-201 |
| **T-204** | `subscription_payment_failed` 핸들러 | 결제 실패 이벤트 처리 (재시도 스케줄) | 필수 | 2일 | 백엔드 | T-201 |
| **T-205** | `subscription_cancelled` 핸들러 | 구독 취소 이벤트 처리 (FREE 플랜 전환) | 필수 | 1일 | 백엔드 | T-201 |
| **T-206** | `subscription_updated` 핸들러 | 구독 업데이트 이벤트 처리 (플랜 변경) | 중요 | 2일 | 백엔드 | T-201 |

---

### 에픽 4: DM 발송 한도 정책 구현

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-301** | 한도 체크 로직 수정 | `checkDmQuota()` 함수에서 초과 차단 로직 강화 | 필수 | 1일 | 백엔드 | T-104 |
| **T-302** | 90% 경고 로직 구현 | `shouldSendUsageWarning()` 로직 + 중복 발송 방지 | 필수 | 1일 | 백엔드 | T-301 |
| **T-303** | 100% 차단 로직 구현 | 한도 도달 시 DM 발송 차단 + 에러 반환 | 필수 | 1일 | 백엔드 | T-301 |
| **T-304** | 초과 과금 로직 제거 | `overageCalculator.js` 관련 코드 삭제 | 필수 | 0.5일 | 백엔드 | T-303 |
| **T-305** | 업그레이드 즉시 적용 로직 | 플랜 변경 시 사용량 리셋 + next_billing_date 재설정 | 필수 | 2일 | 백엔드 | T-303 |
| **T-306** | 다운그레이드 예약 로직 | `pending_plan_seq` 설정 + 다음 결제일 적용 | 필수 | 1.5일 | 백엔드 | T-305 |

---

### 에픽 5: 이메일 시스템

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-401** | 이메일 템플릿 작성 | 90% 경고, 100% 차단, 전환 완료 3종 HTML 템플릿 | 필수 | 1일 | 프론트엔드 | - |
| **T-402** | 이메일 발송 서비스 연동 | AWS SES 또는 SendGrid 연동 | 필수 | 1일 | 백엔드 | T-401 |
| **T-403** | 90% 경고 이메일 발송 로직 | `sendUsageWarningEmail()` 구현 + 중복 방지 | 필수 | 1일 | 백엔드 | T-302, T-402 |
| **T-404** | 100% 차단 이메일 발송 로직 | `sendQuotaReachedEmail()` 구현 + 중복 방지 | 필수 | 1일 | 백엔드 | T-303, T-402 |
| **T-405** | 전환 완료 이메일 발송 로직 | `sendMigrationCompleteEmail()` 구현 | 필수 | 0.5일 | 백엔드 | T-402 |

---

### 에픽 6: 프론트엔드 UI

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-501** | 약관 페이지 수정 | 제8조 (요금 및 결제) 섹션 수정, 최종 수정일 업데이트 | 필수 | 0.5일 | 프론트엔드 | - |
| **T-502** | 에러 모달 컴포넌트 구현 | `ErrorModal.tsx` 컴포넌트 생성 (한도 초과 UI) | 필수 | 1일 | 프론트엔드 | - |
| **T-503** | DM 발송 API 에러 핸들링 | `QUOTA_EXCEEDED` 에러 발생 시 모달 표시 | 필수 | 0.5일 | 프론트엔드 | T-502 |
| **T-504** | 업그레이드 CTA 연결 | 에러 모달의 "업그레이드" 버튼 클릭 시 업그레이드 페이지로 이동 | 중요 | 0.5일 | 프론트엔드 | T-502 |

---

### 에픽 7: 데이터 마이그레이션

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-601** | 마이그레이션 스크립트 작성 | 기존 사용자 LemonSqueezy 전환 스크립트 작성 | 필수 | 2일 | 백엔드 | T-202 |
| **T-602** | 마이그레이션 테스트 (스테이징) | 스테이징 환경에서 소수 사용자 대상 테스트 | 필수 | 1일 | 백엔드 | T-601 |
| **T-603** | 마이그레이션 실행 (프로덕션) | 프로덕션 환경에서 전체 사용자 마이그레이션 | 필수 | 0.5일 | DevOps | T-602 |
| **T-604** | 마이그레이션 검증 | 마이그레이션 결과 검증 (성공/실패 리포트) | 필수 | 0.5일 | 백엔드 | T-603 |

---

### 에픽 8: 테스팅 및 QA

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-701** | 유닛 테스트 작성 | 웹훅 핸들러, 한도 체크 로직 유닛 테스트 | 필수 | 2일 | 백엔드 | T-206, T-303 |
| **T-702** | 통합 테스트 작성 | LemonSqueezy 웹훅 → DB 업데이트 E2E 테스트 | 필수 | 2일 | 백엔드 | T-701 |
| **T-703** | 결제 시나리오 테스트 | 구독 생성, 갱신, 취소, 실패 시나리오 테스트 | 필수 | 2일 | QA | T-206 |
| **T-704** | 한도 차단 시나리오 테스트 | 90% 경고, 100% 차단, 업그레이드 후 리셋 테스트 | 필수 | 2일 | QA | T-306 |
| **T-705** | 이메일 발송 테스트 | 모든 이메일 템플릿 실제 발송 테스트 | 중요 | 1일 | QA | T-405 |
| **T-706** | 부하 테스트 | 동시 DM 발송 요청 부하 테스트 (초당 100건) | 선택 | 1일 | QA | T-703 |

---

### 에픽 9: 모니터링 및 배포

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-801** | 웹훅 처리 실패 알림 설정 | Sentry + Slack 알림 설정 | 필수 | 0.5일 | DevOps | T-206 |
| **T-802** | 결제 실패 알림 설정 | 실시간 Slack 알림 설정 | 필수 | 0.5일 | DevOps | T-204 |
| **T-803** | 크론잡 모니터링 설정 | 사용량 리셋 크론잡 실패 시 PagerDuty 알림 | 필수 | 0.5일 | DevOps | T-203 |
| **T-804** | 스테이징 배포 | 스테이징 환경 배포 및 검증 | 필수 | 0.5일 | DevOps | T-702, T-706 |
| **T-805** | 프로덕션 배포 | 프로덕션 환경 배포 (블루-그린 배포) | 필수 | 1일 | DevOps | T-804 |
| **T-806** | 배포 후 모니터링 | 24시간 모니터링 (에러율, 응답 시간, 웹훅 처리율) | 필수 | 1일 | DevOps | T-805 |

---

### 에픽 10: 문서화 및 교육

| 태스크 ID | 태스크명 | 설명 | 우선순위 | 예상 공수 | 담당자 | 선행 태스크 |
|---------|--------|------|---------|---------|-------|----------|
| **T-901** | 개발자 문서 작성 | LemonSqueezy 웹훅 처리 가이드, API 명세 업데이트 | 중요 | 1일 | 백엔드 | T-206 |
| **T-902** | CS 팀 가이드 작성 | 정책 변경 FAQ, 사용자 문의 대응 가이드 | 필수 | 0.5일 | PM | T-805 |
| **T-903** | CS 팀 교육 세션 | 새로운 정책 및 대응 방법 교육 | 필수 | 0.5일 | PM | T-902 |
| **T-904** | 사용자 공지 작성 | 블로그 포스트, 대시보드 배너 문구 작성 | 선택 | 0.5일 | PM | T-805 |

---

## 10. 일정 및 마일스톤

### 전체 일정 (6주 예상)

| 단계 | 기간 | 주요 산출물 | 담당팀 |
|-----|------|----------|-------|
| **1단계: 설계 및 준비** | Week 1 (1주) | PRD, DB 마이그레이션 SQL, API 명세 | PM, DBA, 백엔드 |
| **2단계: 인프라 구축** | Week 2 (1주) | LemonSqueezy 설정, 웹훅 엔드포인트, DB 마이그레이션 | DevOps, DBA, 백엔드 |
| **3단계: 백엔드 개발** | Week 3-4 (2주) | 웹훅 핸들러, 한도 정책 로직, 이메일 시스템 | 백엔드 |
| **4단계: 프론트엔드 개발** | Week 4 (1주) | 약관 페이지, 에러 모달, UI 변경 | 프론트엔드 |
| **5단계: 테스팅** | Week 5 (1주) | 유닛/통합/E2E 테스트, QA 검증 | 백엔드, QA |
| **6단계: 마이그레이션 및 배포** | Week 6 (1주) | 데이터 마이그레이션, 프로덕션 배포, 모니터링 | DevOps, 백엔드 |

---

### 주요 마일스톤

**M1: 2026-02-07 (Week 2 종료) - 인프라 준비 완료**
- LemonSqueezy 계정 및 제품 설정 완료
- 웹훅 엔드포인트 구축 완료
- DB 마이그레이션 완료 (스테이징)
- **승인 기준**: 웹훅 테스트 이벤트 수신 성공

**M2: 2026-02-21 (Week 4 종료) - 개발 완료**
- 모든 웹훅 핸들러 구현 완료
- DM 한도 정책 로직 구현 완료
- 이메일 시스템 구현 완료
- 프론트엔드 UI 변경 완료
- **승인 기준**: 로컬 환경에서 전체 플로우 테스트 통과

**M3: 2026-02-28 (Week 5 종료) - 테스팅 완료**
- 유닛/통합 테스트 통과율 95% 이상
- QA 시나리오 테스트 100% 통과
- 부하 테스트 통과 (초당 100건)
- **승인 기준**: QA 팀 최종 승인

**M4: 2026-03-07 (Week 6 종료) - 프로덕션 배포 완료**
- 데이터 마이그레이션 완료 (성공률 99% 이상)
- 프로덕션 배포 완료 (제로 다운타임)
- 24시간 모니터링 완료 (에러율 < 0.1%)
- **승인 기준**: 제품 책임자 최종 승인

---

## 11. 위험 및 이슈

| 위험 | 영향도 | 발생 가능성 | 완화 방안 |
|-----|-------|-----------|---------|
| **LemonSqueezy 웹훅 지연** | 높음 | 중간 | 웹훅 재시도 메커니즘 구현, 타임아웃 설정 (30초), 실패 시 Slack 알림 |
| **데이터 마이그레이션 실패** | 높음 | 낮음 | 스테이징 환경 충분한 테스트, 롤백 스크립트 준비, 배치 단위로 마이그레이션 (100명씩) |
| **기존 사용자 불만** | 중간 | 중간 | 크레딧 자동 적용, 친절한 안내 이메일 발송, CS 팀 FAQ 준비 |
| **LemonSqueezy API 장애** | 높음 | 낮음 | 아임포트 시스템 일시 유지 (1주간), LemonSqueezy 상태 페이지 모니터링 |
| **동시성 이슈 (한도 체크)** | 중간 | 중간 | 트랜잭션 + 행 잠금 적용, 부하 테스트로 검증 |
| **이메일 발송 실패** | 낮음 | 낮음 | 재시도 로직 구현 (최대 3회), 실패 시 로그 기록 (사용자에게 영향 없음) |
| **월말 처리 버그** | 중간 | 낮음 | 윤년/월말 케이스 충분한 유닛 테스트, 모든 월말 시나리오 테스트 |
| **프로덕션 배포 중 장애** | 높음 | 낮음 | 블루-그린 배포, 카나리 배포 (10% → 50% → 100%), 즉시 롤백 가능 |

**알려진 이슈:**
- **이슈 1**: LemonSqueezy 웹훅 순서 보장 안됨
  - **영향**: 드물게 이벤트가 순서대로 처리되지 않을 수 있음
  - **해결 계획**: 웹훅 페이로드의 `created_at` timestamp 기준 정렬 처리

- **이슈 2**: 아임포트 시스템 제거 시점
  - **영향**: 마이그레이션 중 결제 실패 가능
  - **해결 계획**: 마이그레이션 완료 후 1주간 아임포트 시스템 유지, 점진적 제거

---

## 12. 성공 지표 (KPI)

| 지표 | 현재값 | 목표값 | 측정 방법 |
|-----|-------|-------|---------|
| **웹훅 처리 성공률** | - | 99.5% 이상 | CloudWatch Logs + Datadog |
| **결제 성공률** | 95% (아임포트) | 97% 이상 | LemonSqueezy Dashboard |
| **데이터 마이그레이션 성공률** | - | 99% 이상 | 마이그레이션 스크립트 로그 |
| **한도 도달 사용자 비율** | - | < 5% | tb_monthly_usage 쿼리 |
| **90% 경고 이메일 발송률** | - | 100% | 이메일 발송 로그 |
| **100% 차단 이메일 발송률** | - | 100% | 이메일 발송 로그 |
| **업그레이드 전환율** | - | > 10% | 한도 도달 후 7일 내 업그레이드 |
| **CS 문의 증가율** | - | < 20% | Zendesk 티켓 수 |
| **에러율 (API)** | 0.05% | < 0.1% | Sentry + Datadog |
| **평균 응답 시간 (웹훅)** | - | < 500ms | Datadog APM |

**정성적 지표:**
- **사용자 만족도**: NPS 설문 (배포 후 2주 내 실시)
- **사용성**: 한도 도달 후 사용자 행동 분석 (업그레이드 vs 이탈)
- **CS 팀 만족도**: 대응 난이도 설문 (배포 후 1주 내 실시)

---

## 13. 기존 사용자 환불 정책 제안

### 13.1 LemonSqueezy 프로레이션 정책 검토 결과

**LemonSqueezy 공식 정책:**
1. 업그레이드 시: 자동으로 일할 계산된 차액을 다음 결제 시 청구 또는 즉시 청구
2. 다운그레이드 시: 크레딧으로 전환하여 다음 결제 시 차감
3. 취소 시: 미사용 기간에 대한 환불 없음 (판매자 정책에 따라 다름)

**참고 문서:**
- [Lemon Squeezy Subscriptions Guide](https://docs.lemonsqueezy.com/help/products/subscriptions)
- [Changing a Subscriber's Plan](https://docs.lemonsqueezy.com/guides/tutorials/change-subscriber-plan)
- [Refunds and Chargebacks](https://docs.lemonsqueezy.com/help/payments/refunds-chargebacks)

### 13.2 환불 정책 제안

**제안 1: 크레딧 적용 방식 (권장)**

**장점:**
- LemonSqueezy 자동 프로레이션 활용 가능
- 환불 처리 부담 없음
- 사용자는 다음 결제 시 자동 차감

**단점:**
- 사용자가 즉시 현금 환불을 원할 수 있음

**구현 방법:**
```javascript
// LemonSqueezy API 호출 예시
await lemonsqueezy.subscriptions.update(subscriptionId, {
  variant_id: newVariantId, // 새 플랜 변형 ID
  invoice_immediately: false, // 다음 결제일에 차액 처리
  // LemonSqueezy가 자동으로 프로레이션 계산
});
```

**크레딧 계산 공식:**
```
크레딧 금액 = (기존 월 요금) × (남은 일수 / 30일)

예시:
- STARTER 플랜 (₩15,000/월)
- 다음 결제일까지 15일 남음
- 크레딧: ₩15,000 × (15/30) = ₩7,500
- 다음 첫 결제: ₩15,000 - ₩7,500 = ₩7,500 청구
```

---

**제안 2: 즉시 현금 환불 방식**

**장점:**
- 사용자 신뢰도 향상
- 명확하고 투명한 정책

**단점:**
- 환불 처리 부담 증가
- LemonSqueezy API로 수동 환불 필요
- 환불 수수료 발생 가능 (LemonSqueezy 정책에 따라)

**구현 방법:**
```javascript
// LemonSqueezy 환불 API 호출
await lemonsqueezy.subscriptionInvoices.refund(invoiceId, {
  amount: refundAmount // 일할 계산된 금액
});
```

---

**제안 3: 하이브리드 방식 (권장)**

**정책:**
- 기본: 크레딧 적용
- 옵션: 사용자가 명시적으로 요청 시 현금 환불

**장점:**
- 대부분 자동 처리 (크레딧)
- 사용자 선택권 보장
- 환불 처리 부담 최소화

**구현:**
1. 기본적으로 크레딧 자동 적용
2. CS 팀이 요청 시 수동 환불 처리
3. 환불 정책을 약관에 명시

---

### 13.3 최종 권장 정책

**권장: 제안 3 (하이브리드 방식)**

**이유:**
1. LemonSqueezy의 자동 프로레이션 기능 최대 활용
2. 사용자 선택권 보장으로 신뢰도 유지
3. 환불 처리 부담 최소화 (대부분 자동)
4. 글로벌 SaaS 표준 관행과 일치

**구현 단계:**
1. 마이그레이션 시 모든 사용자에게 크레딧 자동 적용
2. 전환 완료 이메일에 크레딧 금액 및 정책 안내
3. 사용자가 현금 환불 요청 시 CS 팀이 수동 처리 (7일 이내)
4. 약관에 환불 정책 명시

**약관 추가 문구:**
```markdown
### 제9조 (환불 정책)

3. **구독 정책 변경 시 환불**
   - 구독 정책 변경으로 인한 전환 시, 남은 구독 기간에 대한 크레딧이 자동으로 적용됩니다.
   - 크레딧은 다음 결제 시 자동으로 차감됩니다.
   - 현금 환불을 원하시는 경우, 전환일로부터 7일 이내에 고객센터로 요청해 주세요.
   - 환불 금액은 일할 계산되며, 영업일 기준 5~7일 이내에 처리됩니다.
```

---

## 14. 부록

### 14.1 용어집
- **LemonSqueezy**: 글로벌 SaaS 결제 플랫폼 (구독, 결제, 세금 자동 처리)
- **웹훅 (Webhook)**: 서버 간 이벤트 알림 메커니즘
- **프로레이션 (Proration)**: 일할 계산 (사용 기간에 비례한 금액 계산)
- **크레딧 (Credit)**: 다음 결제 시 차감되는 금액
- **결제일 기준**: 사용자마다 다른 결제일 (예: A 사용자는 매월 15일, B 사용자는 매월 20일)
- **한도 (Quota)**: 플랜별 월 DM 발송 가능 건수
- **리셋 (Reset)**: 사용량을 0으로 초기화

### 14.2 참고 자료
- [LemonSqueezy 공식 문서](https://docs.lemonsqueezy.com)
- [LemonSqueezy API 레퍼런스](https://docs.lemonsqueezy.com/api)
- [LemonSqueezy 웹훅 가이드](https://docs.lemonsqueezy.com/help/webhooks)
- [현재 아임포트 구현 코드](/api/src/services/iamportService.js)
- [현재 과금 정책 문서](/docs/bm/Autogram_가격플랜_기획서.md)

### 14.3 변경 이력
| 날짜 | 버전 | 변경사항 | 작성자 |
|------|------|---------|-------|
| 2026-01-24 | 1.0 | 초안 작성 | Claude (PRD Analyst) |

---

**문서 종료**
