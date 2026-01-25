# 결제 정책 변경 시 기존 사용자 보상 방식 분석

## 문서 정보
- **작성일**: 2026-01-25
- **대상**: 결제 정책 변경으로 영향받는 기존 유료 사용자
- **목적**: 두 가지 보상 방식의 백엔드 구현 복잡도 및 타당성 비교

---

## 1. 배경 및 보상 대상

### 1.1 변경 사항
- **기존**: 월 1일 일괄 결제 (아임포트)
- **신규**: 사용자별 가입일 기준 결제 (LemonSqueezy)

### 1.2 보상 대상 사용자
- 1월 1일에 이미 결제를 완료한 유료 플랜 사용자
- 1월 15일 마이그레이션 시점 기준, **남은 구독 기간**: 1월 16일 ~ 1월 31일 (16일)

### 1.3 보상 옵션
| 옵션 | 방식 | 사용자 경험 |
|-----|------|-----------|
| **옵션 A** | 결제 시 할인 (금전적 크레딧) | 다음 결제 금액 차감 |
| **옵션 B** | DM Quota 이월 | 남은 DM 발송 건수를 다음 달로 이월 |

---

## 2. 옵션 A: 결제 시 할인 (금전적 크레딧)

### 2.1 개념
남은 구독 기간(16일)에 대해 일할 계산하여 다음 결제 금액에서 차감합니다.

**계산 예시 (MINIMUM 플랜: ₩15,000/월):**
```
남은 기간 크레딧 = (15,000 ÷ 30) × 16 = ₩8,000
다음 결제 금액 = 15,000 - 8,000 = ₩7,000
```

### 2.2 LemonSqueezy 프로레이션 기능 활용

LemonSqueezy는 **자동 프로레이션(Automatic Proration)** 기능을 제공합니다:

```javascript
// LemonSqueezy API를 통한 프로레이션 적용
const response = await fetch('https://api.lemonsqueezy.com/v1/subscriptions/{subscription_id}', {
  method: 'PATCH',
  headers: {
    'Authorization': `Bearer ${LEMONSQUEEZY_API_KEY}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    data: {
      type: 'subscriptions',
      id: subscriptionId,
      attributes: {
        // 플랜 변경 시 자동으로 크레딧 적용
        variant_id: newVariantId,
        // LemonSqueezy가 자동으로 일할 계산 수행
      }
    }
  })
});
```

**LemonSqueezy의 자동 처리:**
- 기존 플랜의 남은 기간을 자동 계산
- 크레딧을 다음 결제 시 자동 차감
- 별도의 크레딧 관리 테이블 불필요

### 2.3 구현 방법

#### 2.3.1 데이터베이스 스키마 변경
**변경 불필요** - LemonSqueezy가 자체적으로 크레딧 관리

기존 `tb_subscriptions` 테이블 그대로 사용 가능:
```sql
-- 기존 테이블 활용 (변경 없음)
CREATE TABLE tb_subscriptions (
  seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_seq INT UNSIGNED NOT NULL,
  plan_seq INT UNSIGNED NOT NULL,
  lemon_squeezy_subscription_id VARCHAR(100),
  lemon_squeezy_customer_id VARCHAR(100),
  lemon_squeezy_variant_id VARCHAR(100),
  next_billing_date DATE,
  last_billing_amount INT UNSIGNED,
  -- 기존 컬럼들 유지
);
```

#### 2.3.2 마이그레이션 스크립트
```javascript
// scripts/applyCompensation-optionA.js
import { Subscription, User, Plan } from '../src/models/index.js';
import fetch from 'node-fetch';

/**
 * 옵션 A: LemonSqueezy 프로레이션을 통한 크레딧 보상
 */
async function applyProrationCredit() {
  // 1. 마이그레이션 대상 사용자 조회 (1월 1일 결제 완료 사용자)
  const eligibleSubscriptions = await Subscription.findAll({
    where: {
      subscription_status: 'active',
      // 아임포트 빌링키가 있고, 아직 LemonSqueezy로 마이그레이션 안 된 사용자
      billing_key: { [Op.ne]: null },
      lemon_squeezy_subscription_id: null,
    },
    include: [
      { model: User, attributes: ['seq', 'email', 'name'] },
      { model: Plan, attributes: ['plan_code', 'plan_name'] }
    ]
  });

  console.log(`대상 사용자: ${eligibleSubscriptions.length}명`);

  for (const subscription of eligibleSubscriptions) {
    try {
      const user = subscription.User;
      const plan = subscription.Plan;

      // 2. LemonSqueezy에 구독 생성 (checkout URL 생성)
      const checkoutUrl = await createLemonSqueezyCheckout({
        userSeq: user.seq,
        email: user.email,
        planCode: plan.plan_code,
      });

      // 3. 사용자에게 마이그레이션 안내 이메일 발송
      await sendMigrationEmail({
        to: user.email,
        userName: user.name,
        planName: plan.plan_name,
        checkoutUrl: checkoutUrl,
        creditAmount: calculateCredit(subscription),
      });

      console.log(`✅ 마이그레이션 안내 발송: ${user.email}`);
    } catch (error) {
      console.error(`❌ 실패 (user_seq: ${subscription.user_seq}):`, error);
    }
  }
}

/**
 * 남은 기간 크레딧 계산
 */
function calculateCredit(subscription) {
  const now = new Date();
  const endOfMonth = new Date(now.getFullYear(), now.getMonth() + 1, 0);
  const remainingDays = Math.ceil((endOfMonth - now) / (1000 * 60 * 60 * 24));

  const monthlyPrice = subscription.last_billing_amount || 15000;
  const credit = Math.floor((monthlyPrice / 30) * remainingDays);

  return credit;
}

/**
 * LemonSqueezy Checkout URL 생성
 *
 * @note LemonSqueezy는 구독 생성 시 자동으로 프로레이션을 처리합니다.
 *       마이그레이션 시점에 기존 구독을 취소하고 새 구독을 생성하면,
 *       LemonSqueezy가 남은 기간을 자동 크레딧으로 적용합니다.
 */
async function createLemonSqueezyCheckout({ userSeq, email, planCode }) {
  const variantId = getVariantIdByPlanCode(planCode);

  const response = await fetch('https://api.lemonsqueezy.com/v1/checkouts', {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${process.env.LEMONSQUEEZY_API_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      data: {
        type: 'checkouts',
        attributes: {
          store_id: process.env.LEMONSQUEEZY_STORE_ID,
          variant_id: variantId,
          custom_data: {
            user_seq: userSeq,
            migration: true, // 마이그레이션 플래그
          },
          checkout_data: {
            email: email,
            custom: {
              user_seq: userSeq.toString()
            }
          }
        }
      }
    })
  });

  const data = await response.json();
  return data.data.attributes.url;
}

export default applyProrationCredit;
```

#### 2.3.3 웹훅 핸들러 수정
**변경 불필요** - 기존 `lemonSqueezyWebhookService.js`가 자동으로 크레딧 처리

```javascript
// src/services/lemonSqueezyWebhookService.js

/**
 * subscription_payment_success 이벤트 핸들러
 *
 * @note LemonSqueezy가 자동으로 크레딧을 차감한 금액을 전송합니다.
 */
const handleSubscriptionPaymentSuccess = async (payload) => {
  // ... (기존 코드 그대로 사용)

  // LemonSqueezy가 이미 크레딧 차감된 금액을 payload.data.attributes.total에 포함
  const paidAmount = data.attributes.total; // 크레딧 차감 후 금액

  await PaymentTransaction.create({
    user_seq: subscription.user_seq,
    amount: paidAmount, // LemonSqueezy가 자동 계산한 금액
    // ...
  });
};
```

### 2.4 구현 복잡도 분석

| 항목 | 복잡도 | 세부 사항 |
|------|--------|----------|
| **DB 스키마 변경** | ⭐ 낮음 | 변경 불필요 (LemonSqueezy가 관리) |
| **비즈니스 로직** | ⭐ 낮음 | LemonSqueezy API 호출만으로 처리 |
| **기존 로직 호환성** | ⭐⭐⭐ 높음 | 기존 결제 로직 그대로 활용 |
| **엣지 케이스** | ⭐ 낮음 | LemonSqueezy가 자동 처리 |
| **유지보수성** | ⭐⭐⭐ 높음 | 별도 관리 코드 불필요 |

### 2.5 엣지 케이스 및 예외 처리

#### 2.5.1 마이그레이션 실패 시
```javascript
// 사용자가 마이그레이션 안내 이메일을 받았지만 결제하지 않은 경우
async function handleMigrationTimeout() {
  const now = new Date();
  const migrationDeadline = new Date('2026-01-31'); // 1월 말까지

  if (now > migrationDeadline) {
    // 기존 아임포트 구독을 FREE 플랜으로 다운그레이드
    await downgradeToFreePlan(userSeq);

    // 알림 이메일 발송
    await sendDowngradeNotification(userSeq);
  }
}
```

#### 2.5.2 부분 환불 요청
```javascript
// 사용자가 크레딧 대신 환불을 요청하는 경우
async function processRefundRequest(userSeq) {
  const subscription = await Subscription.findOne({
    where: { user_seq: userSeq }
  });

  const refundAmount = calculateCredit(subscription);

  // 아임포트를 통한 부분 환불
  await iamportService.refundPayment({
    impUid: subscription.last_imp_uid,
    amount: refundAmount,
    reason: '결제 정책 변경으로 인한 부분 환불'
  });
}
```

### 2.6 장점 및 단점

#### 장점
✅ **구현 복잡도 최소화**: LemonSqueezy가 자동으로 크레딧 관리
✅ **기존 로직 100% 재사용**: 별도 코드 추가 불필요
✅ **사용자 이해 용이**: 금전적 보상이 직관적
✅ **유지보수 부담 없음**: 크레딧 만료, 소멸 등 관리 불필요
✅ **정확한 정산**: LemonSqueezy가 자동 계산 (오차 없음)

#### 단점
❌ **LemonSqueezy 의존성**: 플랫폼 정책 변경 시 영향
❌ **사용자 행동 유도 필요**: 마이그레이션 안내 후 직접 결제해야 함
❌ **즉시 보상 불가**: 다음 결제 시점에 반영

---

## 3. 옵션 B: DM Quota 이월

### 3.1 개념
남은 구독 기간에 해당하는 **사용하지 않은 DM 발송 건수**를 다음 달로 이월합니다.

**계산 예시 (MINIMUM 플랜: 500건/월):**
```
월 한도: 500건
1월 사용: 200건
남은 건수: 300건

→ 2월 한도: 500건 (기본) + 300건 (이월) = 800건
```

### 3.2 구현 방법

#### 3.2.1 데이터베이스 스키마 변경

**옵션 1: 기존 테이블에 컬럼 추가 (권장)**
```sql
-- tb_monthly_usage 테이블 수정
ALTER TABLE tb_monthly_usage
ADD COLUMN rollover_quota INT UNSIGNED DEFAULT 0 COMMENT '이월된 DM 한도 (전월 미사용분)';

-- 인덱스 추가 (조회 성능 최적화)
CREATE INDEX idx_monthly_usage_rollover
ON tb_monthly_usage(user_seq, usage_month, rollover_quota);
```

**스키마 구조:**
```sql
CREATE TABLE tb_monthly_usage (
  seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_seq INT UNSIGNED NOT NULL,
  plan_seq INT UNSIGNED NOT NULL,
  usage_month CHAR(7) NOT NULL COMMENT 'YYYY-MM',
  dm_sent_count INT UNSIGNED DEFAULT 0 COMMENT '실제 발송 건수',
  rollover_quota INT UNSIGNED DEFAULT 0 COMMENT '이월된 DM 한도', -- 신규 추가
  warning_email_sent TINYINT DEFAULT 0,
  quota_reached_email_sent TINYINT DEFAULT 0,
  created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),

  UNIQUE KEY UNQ_USAGE_USER_MONTH (user_seq, usage_month)
);
```

**옵션 2: 별도 테이블 생성 (복잡한 이월 정책 시)**
```sql
-- 이월 내역 추적 테이블 (향후 확장 고려)
CREATE TABLE tb_quota_rollovers (
  seq INT UNSIGNED PRIMARY KEY AUTO_INCREMENT,
  user_seq INT UNSIGNED NOT NULL,
  from_month CHAR(7) NOT NULL COMMENT '이월 원천 월',
  to_month CHAR(7) NOT NULL COMMENT '이월 대상 월',
  rollover_amount INT UNSIGNED NOT NULL COMMENT '이월 건수',
  used_amount INT UNSIGNED DEFAULT 0 COMMENT '이월분 중 사용한 건수',
  expire_date DATE COMMENT '이월 소멸 기한 (선택)',
  status ENUM('active', 'used', 'expired') DEFAULT 'active',
  created_at DATETIME(6) DEFAULT CURRENT_TIMESTAMP(6),

  INDEX idx_rollover_user_month (user_seq, to_month),
  INDEX idx_rollover_status (status, expire_date)
);
```

#### 3.2.2 마이그레이션 스크립트
```javascript
// scripts/applyCompensation-optionB.js
import { Subscription, MonthlyUsage, Plan, PlanProperty } from '../src/models/index.js';
import sequelize from '../src/config/database.js';

/**
 * 옵션 B: DM Quota 이월 보상
 */
async function applyQuotaRollover() {
  const transaction = await sequelize.transaction();

  try {
    // 1. 1월 사용량 데이터 조회
    const currentMonth = '2026-01';
    const nextMonth = '2026-02';

    const januaryUsages = await MonthlyUsage.findAll({
      where: {
        usage_month: currentMonth
      },
      include: [
        { model: Plan, attributes: ['seq', 'plan_code'] }
      ],
      transaction
    });

    console.log(`대상 사용자: ${januaryUsages.length}명`);

    for (const usage of januaryUsages) {
      try {
        // 2. 플랜 한도 조회 (tb_plan_properties에서)
        const quotaProperty = await PlanProperty.findOne({
          where: {
            plan_seq: usage.plan_seq,
            prop_code: 'DM'
          },
          transaction
        });

        if (!quotaProperty) {
          console.warn(`⚠️ DM quota not found for plan ${usage.plan_seq}`);
          continue;
        }

        const monthlyQuota = parseInt(quotaProperty.numeric_value, 10);
        const usedCount = usage.dm_sent_count;
        const remainingQuota = Math.max(0, monthlyQuota - usedCount);

        // 3. 남은 한도가 있으면 이월
        if (remainingQuota > 0) {
          // 2월 사용량 레코드 생성 또는 업데이트
          const [februaryUsage, created] = await MonthlyUsage.findOrCreate({
            where: {
              user_seq: usage.user_seq,
              usage_month: nextMonth
            },
            defaults: {
              user_seq: usage.user_seq,
              plan_seq: usage.plan_seq,
              usage_month: nextMonth,
              dm_sent_count: 0,
              rollover_quota: remainingQuota, // 이월 한도 설정
              warning_email_sent: 0,
              quota_reached_email_sent: 0
            },
            transaction
          });

          if (!created) {
            // 이미 존재하면 이월 한도만 업데이트
            await februaryUsage.update({
              rollover_quota: remainingQuota
            }, { transaction });
          }

          console.log(`✅ 이월 완료 (user_seq: ${usage.user_seq}): ${remainingQuota}건`);

          // 4. 이력 기록 (선택)
          await QuotaRollover.create({
            user_seq: usage.user_seq,
            from_month: currentMonth,
            to_month: nextMonth,
            rollover_amount: remainingQuota,
            status: 'active'
          }, { transaction });

          // 5. 사용자 알림 이메일 발송 (비동기)
          setImmediate(() => {
            sendRolloverNotification({
              userSeq: usage.user_seq,
              rolloverAmount: remainingQuota,
              nextMonth: nextMonth
            }).catch(err => {
              console.error(`이메일 발송 실패 (user_seq: ${usage.user_seq}):`, err);
            });
          });
        } else {
          console.log(`ℹ️ 이월 대상 아님 (user_seq: ${usage.user_seq}): 사용량 100%`);
        }
      } catch (error) {
        console.error(`❌ 이월 실패 (user_seq: ${usage.user_seq}):`, error);
        // 개별 사용자 실패는 스킵하고 계속 진행
      }
    }

    await transaction.commit();
    console.log('✅ DM Quota 이월 완료');
  } catch (error) {
    await transaction.rollback();
    console.error('❌ DM Quota 이월 실패:', error);
    throw error;
  }
}

export default applyQuotaRollover;
```

#### 3.2.3 Quota 서비스 로직 수정

```javascript
// src/services/quotaService.js

/**
 * DM 발송 가능 여부 확인 (이월 한도 포함)
 *
 * @param {number} userSeq - 사용자 seq
 * @param {number} dmCount - 발송 예정 DM 건수
 * @returns {Promise<object>} { allowed, reason, currentUsage, quota, rolloverQuota, totalQuota, remaining }
 */
export async function checkQuota(userSeq, dmCount = 1) {
  // ... (기존 검증 로직)

  const subscription = await getUserSubscription(userSeq);

  // 1. 플랜 기본 한도 조회
  const baseQuota = await getPlanQuota(subscription.plan_seq);

  // 2. 현재 월 사용량 조회
  const now = new Date();
  const usageMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;
  const usage = await getOrCreateMonthlyUsage(userSeq, subscription.plan_seq, usageMonth);

  // 3. 이월 한도 포함한 총 한도 계산
  const rolloverQuota = usage.rollover_quota || 0;
  const totalQuota = baseQuota + rolloverQuota;

  const currentCount = usage.dm_sent_count;
  const remaining = Math.max(0, totalQuota - currentCount);
  const willExceed = currentCount + dmCount > totalQuota;

  // 4. 한도 초과 체크 (이월 포함)
  if (willExceed) {
    logger.warn(`DM quota exceeded for user ${userSeq}: ${currentCount + dmCount}/${totalQuota} (base: ${baseQuota}, rollover: ${rolloverQuota})`);

    return {
      allowed: false,
      reason: 'QUOTA_EXCEEDED',
      message: `월간 DM 발송 한도(${totalQuota}건)를 초과했습니다.`,
      currentUsage: {
        dm_sent_count: currentCount,
        base_quota: baseQuota,
        rollover_quota: rolloverQuota,
        total_quota: totalQuota,
        remaining: remaining,
        usage_percentage: Math.round((currentCount / totalQuota) * 100)
      },
      plan: {
        plan_code: subscription.plan_code,
        plan_name: subscription.plan_name
      }
    };
  }

  // 5. 발송 가능
  return {
    allowed: true,
    reason: null,
    message: '발송 가능합니다.',
    currentUsage: {
      dm_sent_count: currentCount,
      base_quota: baseQuota,
      rollover_quota: rolloverQuota,
      total_quota: totalQuota,
      remaining: remaining,
      usage_percentage: Math.round((currentCount / totalQuota) * 100)
    },
    plan: {
      plan_code: subscription.plan_code,
      plan_name: subscription.plan_name
    }
  };
}

/**
 * 현재 사용량 조회 (이월 한도 포함)
 */
export async function getCurrentUsage(userSeq) {
  // ... (기존 로직)

  const baseQuota = await getPlanQuota(subscription.plan_seq);
  const rolloverQuota = usage.rollover_quota || 0;
  const totalQuota = baseQuota + rolloverQuota;

  const currentCount = usage.dm_sent_count;
  const remaining = Math.max(0, totalQuota - currentCount);
  const usagePercentage = Math.round((currentCount / totalQuota) * 100);

  return {
    user_seq: userSeq,
    usage_month: usageMonth,
    dm_sent_count: currentCount,
    base_quota: baseQuota,
    rollover_quota: rolloverQuota,
    total_quota: totalQuota,
    remaining: remaining,
    usage_percentage: usagePercentage,
    plan: {
      plan_seq: subscription.plan_seq,
      plan_code: subscription.plan_code,
      plan_name: subscription.plan_name
    },
    warning_email_sent: usage.warning_email_sent === 1,
    quota_reached_email_sent: usage.quota_reached_email_sent === 1
  };
}
```

#### 3.2.4 경고 이메일 로직 수정

```javascript
// src/services/quotaService.js

/**
 * DM 발송 후 사용량 증가 및 이메일 발송 (이월 한도 포함)
 */
export async function incrementDmCount(userSeq, dmCount = 1) {
  // ... (기존 트랜잭션 로직)

  const baseQuota = await getPlanQuota(subscription.plan_seq);
  const rolloverQuota = usage.rollover_quota || 0;
  const totalQuota = baseQuota + rolloverQuota;

  // 사용량 증가
  const newCount = usage.dm_sent_count + dmCount;
  await usage.update({ dm_sent_count: newCount }, { transaction });

  await transaction.commit();

  // 비동기로 경고 이메일 발송 체크 (총 한도 기준)
  const usagePercentage = (newCount / totalQuota) * 100;

  // 90% 도달 시 경고 이메일
  if (usagePercentage >= 90 && usage.warning_email_sent === 0) {
    setImmediate(() => {
      sendWarningEmail(userSeq, newCount, totalQuota, subscription.plan_name, rolloverQuota)
        .catch(err => logger.error(`Failed to send warning email for user ${userSeq}:`, err));
    });
  }

  // 100% 도달 시 차단 안내 이메일
  if (usagePercentage >= 100 && usage.quota_reached_email_sent === 0) {
    setImmediate(() => {
      sendQuotaReachedEmail(userSeq, totalQuota, subscription.plan_name, rolloverQuota)
        .catch(err => logger.error(`Failed to send quota reached email for user ${userSeq}:`, err));
    });
  }

  return {
    dm_sent_count: newCount,
    base_quota: baseQuota,
    rollover_quota: rolloverQuota,
    total_quota: totalQuota,
    remaining: Math.max(0, totalQuota - newCount),
    usage_percentage: Math.round(usagePercentage),
    plan_code: subscription.plan_code,
    plan_name: subscription.plan_name
  };
}

/**
 * 90% 경고 이메일 발송 (이월 한도 안내 포함)
 */
async function sendWarningEmail(userSeq, currentCount, totalQuota, planName, rolloverQuota) {
  const user = await User.findByPk(userSeq);
  if (!user || !user.email) {
    logger.warn(`User email not found for warning email: ${userSeq}`);
    return;
  }

  const usagePercentage = Math.round((currentCount / totalQuota) * 100);

  await emailService.sendQuotaWarningEmail({
    to: user.email,
    userName: user.name || user.email,
    planName: planName,
    currentCount: currentCount,
    quota: totalQuota,
    rolloverQuota: rolloverQuota, // 이월 한도 정보 추가
    usagePercentage: usagePercentage,
    remaining: totalQuota - currentCount
  });

  // 플래그 업데이트
  const now = new Date();
  const usageMonth = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

  await MonthlyUsage.update(
    { warning_email_sent: 1 },
    {
      where: {
        user_seq: userSeq,
        usage_month: usageMonth
      }
    }
  );

  logger.info(`90% warning email sent to user ${userSeq} (${user.email})`);
}
```

### 3.3 구현 복잡도 분석

| 항목 | 복잡도 | 세부 사항 |
|------|--------|----------|
| **DB 스키마 변경** | ⭐⭐ 중간 | `tb_monthly_usage`에 `rollover_quota` 컬럼 추가 필요 |
| **비즈니스 로직** | ⭐⭐⭐ 높음 | 이월 계산, 총 한도 산정, 경고 기준 변경 |
| **기존 로직 호환성** | ⭐⭐ 중간 | `quotaService.js` 전면 수정 필요 |
| **엣지 케이스** | ⭐⭐⭐ 높음 | 이월 소멸, 플랜 변경 시 처리 등 |
| **유지보수성** | ⭐⭐ 중간 | 매월 이월 로직 실행 필요 |

### 3.4 엣지 케이스 및 예외 처리

#### 3.4.1 플랜 다운그레이드 시 이월 처리
```javascript
/**
 * 플랜 변경 시 이월 한도 조정
 *
 * 시나리오: STARTER (1,500건) → MINIMUM (500건) 다운그레이드
 * 이월 한도: 800건
 *
 * 문제: 2월 총 한도 = 500 + 800 = 1,300건 (다운그레이드 의미 없음)
 * 해결: 이월 한도를 새 플랜 한도 이하로 제한
 */
async function adjustRolloverOnPlanChange(userSeq, newPlanSeq, currentMonth) {
  const newPlanQuota = await getPlanQuota(newPlanSeq);

  const usage = await MonthlyUsage.findOne({
    where: {
      user_seq: userSeq,
      usage_month: currentMonth
    }
  });

  if (usage && usage.rollover_quota > 0) {
    // 이월 한도를 새 플랜 한도의 50%로 제한 (정책)
    const maxRollover = Math.floor(newPlanQuota * 0.5);
    const adjustedRollover = Math.min(usage.rollover_quota, maxRollover);

    await usage.update({
      rollover_quota: adjustedRollover
    });

    logger.info(`Rollover adjusted for user ${userSeq}: ${usage.rollover_quota} → ${adjustedRollover}`);
  }
}
```

#### 3.4.2 이월 한도 소멸 (2개월 후)
```javascript
/**
 * 이월 한도 소멸 정책
 *
 * 규칙: 이월 한도는 다음 달에만 사용 가능, 그 다음 달에는 소멸
 * 예: 1월 이월분 → 2월 사용 가능 → 3월 소멸
 */
async function expireRollovers() {
  const twoMonthsAgo = new Date();
  twoMonthsAgo.setMonth(twoMonthsAgo.getMonth() - 2);
  const expireMonth = `${twoMonthsAgo.getFullYear()}-${String(twoMonthsAgo.getMonth() + 1).padStart(2, '0')}`;

  // 2개월 전 이월분을 소멸 상태로 변경
  await QuotaRollover.update(
    { status: 'expired' },
    {
      where: {
        from_month: expireMonth,
        status: 'active'
      }
    }
  );

  logger.info(`Expired rollovers from ${expireMonth}`);
}

// 매월 1일 00:00 크론잡 실행
// cron: '0 0 1 * *'
```

#### 3.4.3 부분 사용 시 이월분 우선 소진
```javascript
/**
 * DM 사용 시 이월분 우선 소진 (FIFO)
 *
 * 규칙: 기본 한도보다 이월 한도를 먼저 사용
 */
async function trackRolloverUsage(userSeq, usageMonth, dmCount) {
  const usage = await MonthlyUsage.findOne({
    where: { user_seq: userSeq, usage_month: usageMonth }
  });

  if (!usage || usage.rollover_quota === 0) {
    return; // 이월 한도 없음
  }

  const rollover = await QuotaRollover.findOne({
    where: {
      user_seq: userSeq,
      to_month: usageMonth,
      status: 'active'
    }
  });

  if (rollover) {
    const usedFromRollover = Math.min(dmCount, rollover.rollover_amount - rollover.used_amount);

    if (usedFromRollover > 0) {
      await rollover.update({
        used_amount: rollover.used_amount + usedFromRollover
      });

      // 이월분을 모두 사용하면 상태 변경
      if (rollover.used_amount >= rollover.rollover_amount) {
        await rollover.update({ status: 'used' });
      }
    }
  }
}
```

#### 3.4.4 이월 한도 표시 (프론트엔드)
```javascript
/**
 * API 응답 예시
 */
{
  "success": true,
  "data": {
    "dm_sent_count": 450,
    "base_quota": 500,
    "rollover_quota": 300,
    "total_quota": 800,
    "remaining": 350,
    "usage_percentage": 56,
    "breakdown": {
      "base_used": 450,
      "rollover_used": 0,
      "base_remaining": 50,
      "rollover_remaining": 300
    }
  }
}
```

### 3.5 장점 및 단점

#### 장점
✅ **사용자 가치 명확**: 실제 사용 가능한 서비스 제공
✅ **금전 환불 불필요**: 결제 플랫폼과 무관
✅ **사용률 증가 유도**: 더 많은 DM 발송 → 서비스 활용도 상승
✅ **유연한 정책 적용**: 이월 소멸 기간, 플랜 변경 시 처리 등 커스터마이징 가능

#### 단점
❌ **높은 구현 복잡도**: DB 스키마 변경, 비즈니스 로직 전면 수정
❌ **엣지 케이스 다수**: 플랜 변경, 이월 소멸, 우선 소진 등 고려 사항 많음
❌ **유지보수 부담**: 매월 이월 로직 실행, 소멸 처리 크론잡 관리
❌ **테스트 복잡도 증가**: 다양한 시나리오에 대한 통합 테스트 필요
❌ **사용자 이해 어려움**: "이월 한도"라는 개념이 직관적이지 않을 수 있음
❌ **다운그레이드 시 불공정**: 낮은 플랜으로 변경해도 높은 이월 한도 유지 가능

---

## 4. 비교 분석

### 4.1 복잡도 비교

| 구분 | 옵션 A (결제 할인) | 옵션 B (DM 이월) |
|-----|-----------------|----------------|
| **DB 스키마 변경** | 없음 (LemonSqueezy 관리) | `rollover_quota` 컬럼 추가 |
| **마이그레이션 스크립트** | LemonSqueezy API 호출 | 사용량 계산 + DB 업데이트 |
| **quotaService.js 수정** | 불필요 | 전면 수정 필요 (총 한도 계산) |
| **웹훅 핸들러** | 기존 코드 재사용 | 기존 코드 재사용 |
| **경고 이메일 로직** | 기존 로직 유지 | 총 한도 기준으로 변경 |
| **크론잡** | 불필요 | 이월 소멸 처리 크론잡 필요 |
| **테스트 케이스** | 5개 | 15개 이상 |

### 4.2 개발 공수 예상

| 작업 | 옵션 A | 옵션 B |
|-----|--------|--------|
| **DB 마이그레이션** | 0.5일 | 1일 |
| **비즈니스 로직 구현** | 1일 | 3일 |
| **API 응답 수정** | 0.5일 | 1일 |
| **이메일 템플릿** | 0.5일 | 1일 |
| **테스트 코드 작성** | 1일 | 3일 |
| **QA 테스팅** | 1일 | 2일 |
| **문서화** | 0.5일 | 1일 |
| **총 개발 기간** | **5일** | **12일** |

### 4.3 엣지 케이스 처리

| 시나리오 | 옵션 A | 옵션 B |
|---------|--------|--------|
| **플랜 업그레이드** | LemonSqueezy 자동 처리 | 이월 한도 유지 |
| **플랜 다운그레이드** | LemonSqueezy 자동 처리 | 이월 한도 조정 로직 필요 |
| **구독 해지** | 크레딧 소멸 (LemonSqueezy 정책) | 이월 한도 소멸 |
| **다음 달 구독 재개** | 크레딧 재적용 (LemonSqueezy) | 이월 한도 소멸 후 재시작 |
| **부분 환불 요청** | LemonSqueezy 환불 API | 이월 한도 회수 로직 필요 |
| **이월분 소멸** | 해당 없음 | 2개월 후 소멸 크론잡 |

### 4.4 유지보수성

#### 옵션 A (결제 할인)
```javascript
// 유지보수 포인트: 거의 없음
// - LemonSqueezy가 자동으로 크레딧 관리
// - 별도 크론잡 불필요
// - 정책 변경 시 LemonSqueezy 대시보드에서 설정만 변경
```

#### 옵션 B (DM 이월)
```javascript
// 유지보수 포인트: 다수
// 1. 매월 이월 로직 크론잡 모니터링
// 2. 이월 소멸 크론잡 모니터링
// 3. 플랜 변경 시 이월 한도 조정 로직 검증
// 4. 이월 한도 관련 버그 대응
// 5. 정책 변경 시 코드 수정 필요
```

### 4.5 사용자 경험

#### 옵션 A (결제 할인)
**장점:**
- 금전적 보상이 명확하고 직관적
- "다음 달 ₩8,000 할인"처럼 구체적 안내 가능

**단점:**
- 다음 결제 시점까지 대기 필요
- 마이그레이션 안내 후 사용자가 직접 결제해야 함

**예상 사용자 반응:**
> "돈으로 돌려받으니 공정하고 좋다. 다음 달 결제가 저렴해지네!"

#### 옵션 B (DM 이월)
**장점:**
- 즉시 혜택 제공 (다음 달부터 이월 한도 사용 가능)
- 서비스 활용도 증가

**단점:**
- "이월 한도"라는 개념이 복잡할 수 있음
- 다운그레이드 시 불공정 문제 발생 가능

**예상 사용자 반응:**
> "이월 한도가 뭐지? 복잡한데... 그냥 돈으로 돌려주면 안 되나?"

---

## 5. 최종 권장안

### 5.1 권장: **옵션 A (결제 시 할인 - LemonSqueezy 프로레이션)**

### 5.2 권장 이유

#### 1️⃣ **구현 복잡도 최소화**
- DB 스키마 변경 불필요
- LemonSqueezy가 자동으로 크레딧 관리
- 기존 `quotaService.js` 코드 100% 재사용
- 개발 기간: **5일** (옵션 B의 절반)

#### 2️⃣ **유지보수 부담 최소화**
- 별도 크론잡 불필요
- 엣지 케이스 처리를 LemonSqueezy에 위임
- 정책 변경 시 코드 수정 불필요

#### 3️⃣ **사용자 경험 우수**
- 금전적 보상이 직관적이고 명확
- "다음 달 ₩8,000 할인" 같은 구체적 안내 가능
- 공정성에 대한 이의 제기 최소화

#### 4️⃣ **비즈니스 리스크 최소화**
- LemonSqueezy의 검증된 프로레이션 기능 활용
- 정산 오류 발생 가능성 낮음
- 환불 요청 시 LemonSqueezy API로 간단히 처리

#### 5️⃣ **확장성**
- 향후 다른 결제 정책 변경 시에도 동일한 방식 적용 가능
- 글로벌 결제 표준 (LemonSqueezy) 준수

### 5.3 구현 로드맵

#### Phase 1: 마이그레이션 준비 (1일)
- [ ] LemonSqueezy 웹훅 엔드포인트 설정
- [ ] 환경 변수 설정 (`LEMONSQUEEZY_*`)
- [ ] 마이그레이션 안내 이메일 템플릿 작성

#### Phase 2: 마이그레이션 스크립트 개발 (2일)
- [ ] `applyCompensation-optionA.js` 구현
- [ ] 크레딧 계산 로직 작성
- [ ] LemonSqueezy Checkout URL 생성 로직

#### Phase 3: 테스트 (1일)
- [ ] 단위 테스트: 크레딧 계산 로직
- [ ] 통합 테스트: LemonSqueezy API 호출
- [ ] 시나리오 테스트: 마이그레이션 전체 플로우

#### Phase 4: 배포 및 모니터링 (1일)
- [ ] 프로덕션 배포
- [ ] 마이그레이션 안내 이메일 일괄 발송
- [ ] 사용자 피드백 모니터링
- [ ] Slack 알림 설정 (마이그레이션 진행 상황)

### 5.4 예외적으로 옵션 B를 고려할 경우

다음 조건이 **모두** 충족되는 경우에만 옵션 B를 고려:

1. **사용자 요구**: 대다수 사용자가 금전 보상보다 DM 이월을 선호
2. **개발 리소스 충분**: 12일 이상의 개발 기간 확보 가능
3. **장기 정책**: 이월 제도를 향후에도 상시 운영할 계획
4. **복잡성 감수**: 유지보수 부담을 감수할 수 있는 팀 역량

**현재 상황에서는 위 조건이 충족되지 않으므로 옵션 A를 강력히 권장합니다.**

---

## 6. 리스크 및 대응 방안

### 6.1 옵션 A의 리스크

#### 리스크 1: 사용자가 마이그레이션을 완료하지 않음
**대응:**
- 마감 기한 설정 (1월 31일)
- 마감 후 자동으로 FREE 플랜으로 다운그레이드
- 사전 안내 이메일 3회 발송 (1월 15일, 20일, 25일)

#### 리스크 2: LemonSqueezy 프로레이션 정책 변경
**대응:**
- LemonSqueezy 공식 문서 및 changelog 모니터링
- 백업 플랜: 수동 크레딧 적용 스크립트 준비

#### 리스크 3: 크레딧 금액 오차
**대응:**
- 테스트 환경에서 다양한 시나리오 검증
- 소액 오차 발생 시 사용자에게 유리하게 반올림

### 6.2 옵션 B의 리스크

#### 리스크 1: 이월 로직 버그
**대응:**
- 철저한 단위/통합 테스트
- 프로덕션 배포 전 스테이징 환경에서 검증

#### 리스크 2: 플랜 변경 시 불공정 문제
**대응:**
- 이월 한도 조정 정책 명확히 수립
- 사용자 약관에 명시

#### 리스크 3: 이월 소멸 크론잡 실패
**대응:**
- 크론잡 모니터링 알림 설정
- 실패 시 자동 재시도 로직

---

## 7. 결론

### 최종 권장안: **옵션 A (결제 시 할인 - LemonSqueezy 프로레이션)**

**핵심 근거:**
1. **구현 복잡도 최소화**: 5일 vs 12일
2. **유지보수 부담 최소화**: 크론잡, 엣지 케이스 처리 불필요
3. **사용자 경험 우수**: 금전적 보상이 직관적
4. **비즈니스 리스크 최소화**: LemonSqueezy의 검증된 기능 활용

**다음 단계:**
1. 이해관계자 승인 획득
2. Phase 1 (마이그레이션 준비) 착수
3. 1월 15일 마이그레이션 안내 이메일 발송
4. 1월 31일까지 마이그레이션 완료 모니터링

---

## 8. 부록

### 8.1 참고 자료
- LemonSqueezy Proration 공식 문서: https://docs.lemonsqueezy.com/help/subscriptions/proration
- 현재 코드베이스: `api/src/services/lemonSqueezyWebhookService.js`
- 일할 계산 로직: `api/src/utils/proratedBilling.js`

### 8.2 용어 정의
- **프로레이션 (Proration)**: 구독 기간의 일부만 사용한 경우 비용을 일할 계산하는 것
- **크레딧 (Credit)**: 다음 결제 시 차감될 금액
- **이월 (Rollover)**: 사용하지 않은 할당량을 다음 기간으로 이전하는 것

### 8.3 FAQ

**Q1: 옵션 A에서 크레딧이 소멸되나요?**
A: LemonSqueezy 정책에 따라 구독이 취소되면 크레딧도 소멸됩니다. 단, 구독이 유지되면 다음 결제 시 자동으로 적용됩니다.

**Q2: 옵션 B에서 이월 한도는 언제까지 유효한가요?**
A: 기본 정책은 "다음 달에만 사용 가능, 그 다음 달에 소멸"입니다. (예: 1월 이월분 → 2월 사용 → 3월 소멸)

**Q3: 두 옵션을 혼용할 수 있나요?**
A: 기술적으로는 가능하지만, 사용자 혼란 및 운영 복잡도 증가로 권장하지 않습니다.

**Q4: 옵션 A 적용 시 FREE 플랜 사용자는?**
A: FREE 플랜 사용자는 기존에 결제한 내역이 없으므로 보상 대상이 아닙니다.

**Q5: 환불을 요청하는 사용자는?**
A: 옵션 A의 경우 LemonSqueezy 환불 API로 처리 가능. 옵션 B의 경우 이월 한도를 취소하고 아임포트로 부분 환불.
