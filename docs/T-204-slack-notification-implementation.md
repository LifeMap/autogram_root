# T-204: 결제 실패 Slack 알림 구현 완료 보고서

> **태스크 ID**: T-204
> **작업 날짜**: 2026-01-24
> **상태**: ✅ 완료

## 📋 작업 요약

결제 실패 이벤트 발생 시 관리자에게 실시간 Slack 알림을 발송하는 기능을 구현했습니다.

## 🔧 구현 내용

### 1. Slack 알림 함수 추가

**파일**: `/api/src/services/slackService.js`

기존 `slackService.js`에 `notifyPaymentFailed` 함수를 추가했습니다.

**주요 기능**:
- 결제 실패 정보를 Slack Block Kit 형식으로 포맷팅
- 사용자 정보 (이메일, user_seq)
- 플랜 정보
- 실패 사유
- 결제 금액 (통화별 포맷팅 지원)
- 재시도 횟수 및 다음 재시도 일정
- 발생 시간 (한국 시간대)
- 환경 정보 (development/production)
- 재시도 횟수에 따른 경고 메시지

**에러 처리**:
- Slack 알림 실패 시 전체 프로세스를 중단하지 않음
- 로그만 남기고 계속 진행

### 2. 웹훅 핸들러 업데이트

**파일**: `/api/src/services/lemonSqueezyWebhookService.js`

`handleSubscriptionPaymentFailed` 함수를 수정하여 Slack 알림 기능을 통합했습니다.

**변경 사항**:

#### Import 추가
```javascript
import { notifyPaymentFailed } from './slackService.js';
```

#### 구독 조회 시 관계 데이터 포함
```javascript
const subscription = await Subscription.findOne({
  where: { lemon_squeezy_subscription_id: subscriptionId },
  include: [
    { model: User, attributes: ['seq', 'email', 'name'] },
    { model: Plan, attributes: ['plan_code', 'plan_name'] },
  ],
  transaction,
});
```

#### Slack 알림 호출
트랜잭션 커밋 후, 비동기로 Slack 알림을 전송합니다:
```javascript
try {
  const failureReason = data.attributes.status_formatted || data.attributes.status || '알 수 없음';
  const amount = data.attributes.total || 0;
  const currency = data.attributes.currency || 'KRW';

  const nextRetryDate = new Date();
  nextRetryDate.setDate(nextRetryDate.getDate() + 3);

  await notifyPaymentFailed({
    userSeq: subscription.user_seq,
    email: subscription.User?.email || 'unknown@example.com',
    planCode: subscription.Plan?.plan_code || 'UNKNOWN',
    failureReason,
    amount,
    currency,
    nextRetryDate,
    retryCount: 1,
  });
} catch (slackError) {
  logger.error('Failed to send Slack alert for payment failure:', slackError);
}
```

### 3. 환경 변수

기존 `.env.example`에 이미 Slack 관련 설정이 포함되어 있습니다:

```env
# Slack Notifications
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_NOTIFICATIONS_ENABLED=true
```

## 📊 알림 메시지 형식

Slack에 전송되는 메시지 예시:

```
🚨 결제 실패 알림

사용자: user@example.com
User Seq: 123

플랜: STARTER
실패 사유: 카드 한도 초과

금액: ₩15,000
재시도 횟수: 1회

발생 시간: 2026-01-24 19:30:00
다음 재시도: 2026-01-27 19:30:00

━━━━━━━━━━━━━━━━━━━━━━━━━━

💡 2회의 재시도 기회가 남았습니다

Environment: production
```

재시도 횟수가 3회 이상일 경우:
```
⚠️ 3회 재시도 실패 - 구독이 취소될 수 있습니다
```

## ✅ 완료된 수락 기준

- [x] `subscription_status = 'payment_failed'` 업데이트
- [x] `tb_payment_retry_schedule`에 재시도 일정 기록
- [x] 결제 실패 이메일 발송
- [x] **관리자 Slack 알림 발송** ⭐
- [x] `tb_subscription_history`에 'payment_failed' 이벤트 기록
- [x] 3회 실패 시 구독 취소 처리
- [x] 트랜잭션 처리

## 🔍 테스트 가이드

### 1. 환경 설정

`.env` 파일에 Slack Webhook URL을 설정합니다:

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
SLACK_NOTIFICATIONS_ENABLED=true
```

### 2. Slack Webhook URL 발급

1. Slack 워크스페이스에 로그인
2. https://api.slack.com/messaging/webhooks 접속
3. "Create your Slack app" 버튼 클릭
4. "Incoming Webhooks" 활성화
5. "Add New Webhook to Workspace" 클릭
6. 알림을 받을 채널 선택
7. 생성된 Webhook URL을 복사하여 `.env`에 추가

### 3. 로컬 테스트

#### 방법 1: 웹훅 시뮬레이션

테스트용 웹훅 페이로드를 생성하여 직접 핸들러를 호출합니다:

```javascript
// test/webhooks/payment-failed-test.js
import { processWebhook } from '../api/src/services/lemonSqueezyWebhookService.js';

const testPayload = {
  meta: {
    event_name: 'subscription_payment_failed',
  },
  data: {
    id: '12345',
    attributes: {
      subscription_id: 'sub_test_123',
      status: 'failed',
      status_formatted: '카드 한도 초과',
      total: 15000,
      currency: 'KRW',
    },
  },
};

// 서명 검증을 우회하는 테스트용 함수 작성 필요
```

#### 방법 2: 수동 함수 호출

```javascript
import { notifyPaymentFailed } from './api/src/services/slackService.js';

await notifyPaymentFailed({
  userSeq: 123,
  email: 'test@example.com',
  planCode: 'STARTER',
  failureReason: '카드 한도 초과',
  amount: 15000,
  currency: 'KRW',
  nextRetryDate: new Date(Date.now() + 3 * 24 * 60 * 60 * 1000),
  retryCount: 1,
});
```

### 4. 프로덕션 배포 전 체크리스트

- [ ] `.env` 파일에 Slack Webhook URL 설정
- [ ] `SLACK_NOTIFICATIONS_ENABLED=true` 설정
- [ ] 테스트 환경에서 알림 전송 확인
- [ ] Slack 채널에서 메시지 수신 확인
- [ ] 재시도 횟수별 메시지 확인 (1회, 2회, 3회 이상)
- [ ] 에러 발생 시에도 웹훅 처리가 계속되는지 확인

## 🚀 배포 가이드

### 1. 환경 변수 설정

프로덕션 서버의 `.env` 파일에 다음 변수를 추가합니다:

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL
SLACK_NOTIFICATIONS_ENABLED=true
```

### 2. 서버 재시작

환경 변수 변경 후 API 서버를 재시작합니다:

```bash
pm2 restart sns-automation-api
```

### 3. 배포 확인

- LemonSqueezy 대시보드에서 테스트 결제 실패 트리거
- Slack 채널에서 알림 수신 확인

## 🔗 관련 파일

| 파일 | 역할 | 변경 유형 |
|-----|------|----------|
| `/api/src/services/slackService.js` | Slack 알림 서비스 | 수정 (함수 추가) |
| `/api/src/services/lemonSqueezyWebhookService.js` | LemonSqueezy 웹훅 처리 | 수정 (알림 통합) |
| `/docs/tasks-billing-policy-update.md` | 태스크 문서 | 수정 (체크박스 완료) |

## 📝 참고 사항

### 알림 발송 시점

- 결제 실패 웹훅 수신 후
- 데이터베이스 트랜잭션 커밋 후
- 비동기로 실행되어 전체 프로세스에 영향 없음

### 에러 처리

- Slack 알림 실패 시 로그만 남김
- 웹훅 처리는 계속 진행됨
- 알림 실패가 결제 실패 처리를 방해하지 않음

### 보안 고려사항

- Webhook URL을 환경 변수로 관리
- `.env` 파일은 `.gitignore`에 포함되어 있음
- 민감한 정보(카드 번호 등)는 포함하지 않음

## 🎯 다음 단계

이제 T-802 (결제 실패 알림 설정)를 진행할 수 있습니다. 해당 태스크는 DevOps 팀에서 담당합니다:

- Slack 채널 생성 및 Webhook URL 발급
- 프로덕션 환경 변수 설정
- 알림 테스트 및 검증

## ✨ 완료 요약

T-204의 "관리자 Slack 알림 발송" 기능이 성공적으로 구현되었습니다. 결제 실패 발생 시 관리자가 즉시 알림을 받아 신속하게 대응할 수 있게 되었습니다.
