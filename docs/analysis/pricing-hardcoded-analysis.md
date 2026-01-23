# Pricing 하드코딩 분석 보고서

**프로젝트**: sns_automation (Autogram)
**분석일**: 2026-01-17
**목적**: pricing/plan 관련 하드코딩된 부분을 찾아 tb_plans, tb_plan_properties 테이블 기반으로 수정 방향 제시

---

## 📋 목차

1. [하드코딩된 파일 목록](#1-하드코딩된-파일-목록)
2. [하드코딩된 값 상세 분석](#2-하드코딩된-값-상세-분석)
3. [수정이 필요한 파일과 함수](#3-수정이-필요한-파일과-함수)
4. [수정 방향 제안](#4-수정-방향-제안)
5. [우선순위 및 영향도](#5-우선순위-및-영향도)

---

## 1. 하드코딩된 파일 목록

### 1.1 백엔드 (API)

| 파일 경로 | 하드코딩된 내용 | 영향도 |
|---------|---------------|-------|
| `/api/src/utils/pricing.js` | **모든 플랜 정보** (가격, 한도, 기능) | ⚠️ **매우 높음** |
| `/api/src/utils/overageCalculator.js` | pricing.js 의존 (간접적) | 중간 |
| `/api/src/utils/proratedBilling.js` | pricing.js 의존 (간접적) | 중간 |
| `/api/src/middleware/usageCheck.js` | pricing.js 의존 (간접적) | 중간 |
| `/api/src/services/usageService.js` | pricing.js 의존 (간접적) | 중간 |
| `/api/src/controllers/planController.js` | pricing.js 의존 (간접적) | 중간 |

### 1.2 프론트엔드 (Web)

| 파일 경로 | 하드코딩된 내용 | 영향도 |
|---------|---------------|-------|
| `/web/app/pricing/page.tsx` | **전체 플랜 데이터** + 비교 테이블 | ⚠️ **매우 높음** |
| `/web/types/plan.ts` | 타입 정의 (수정 필요 없음) | 낮음 |
| `/web/types/subscription.ts` | 타입 정의 (수정 필요 없음) | 낮음 |
| `/web/components/pricing/PlanCard.tsx` | 플랜 순서 배열 하드코딩 | 낮음 |

---

## 2. 하드코딩된 값 상세 분석

### 2.1 `/api/src/utils/pricing.js` (핵심 파일)

이 파일은 **모든 플랜 정보의 단일 진실 원천(Single Source of Truth)**으로 사용되고 있습니다.

#### 하드코딩된 상수

```javascript
// 플랜 ID 열거형
export const PLAN_IDS = {
  FREE: 'free',
  MINIMUM: 'minimum',
  STARTER: 'starter',
  PRO: 'pro',
};

// 플랜 상세 정보 (28~116라인)
export const PLANS = {
  [PLAN_IDS.FREE]: {
    id: PLAN_IDS.FREE,
    name: 'Free',
    displayName: '무료',
    description: '서비스 테스트 및 소규모 개인 계정용',
    price: 0,                    // ← 하드코딩
    dmQuota: 50,                 // ← 하드코딩
    dmUnitPrice: 0,              // ← 하드코딩
    overageAllowed: false,       // ← 하드코딩
    overageUnitPrice: 0,         // ← 하드코딩
    features: {
      activeTriggers: '무제한',   // ← 하드코딩
      statsRetention: 1,         // ← 하드코딩
      ctaButton: false,          // ← 하드코딩
      prioritySupport: false,    // ← 하드코딩
    },
    limitations: [
      '한도 초과 시 발송 중단',    // ← 하드코딩
      '1일간 통계만 조회 가능',
      'CTA 버튼 미지원',
    ],
    recommended: false,          // ← 하드코딩
    sortOrder: 1,                // ← 하드코딩
  },
  // MINIMUM, STARTER, PRO도 동일 패턴
};
```

#### 하드코딩된 값 목록

**Free 플랜 예시:**
- `price`: 0
- `dmQuota`: 50 (⚠️ 실제 DB는 100)
- `dmUnitPrice`: 0
- `overageAllowed`: false
- `overageUnitPrice`: 0
- `features.activeTriggers`: "무제한"
- `features.statsRetention`: 1
- `features.ctaButton`: false
- `features.prioritySupport`: false
- `limitations`: 배열 (3개 항목)
- `recommended`: false
- `sortOrder`: 1

**Minimum 플랜 예시:**
- `price`: 10000
- `dmQuota`: 500
- `overageUnitPrice`: 50
- `features.statsRetention`: 30

**Starter 플랜 예시:**
- `price`: 15000
- `dmQuota`: 1500
- `overageUnitPrice`: 30
- `recommended`: **true** (추천 플랜)

**Pro 플랜 예시:**
- `price`: 50000
- `dmQuota`: 10000
- `overageUnitPrice`: 10
- `features.statsRetention`: 90
- `features.prioritySupport`: **true**

---

### 2.2 `/web/app/pricing/page.tsx`

프론트엔드에서도 플랜 정보를 **완전히 중복 하드코딩**하고 있습니다.

```tsx
// 플랜 데이터 (19~56라인)
const plansData = [
  {
    key: 'free',
    price: '0',
    dmCount: 100,                    // ← 하드코딩 (백엔드와 다름!)
    statsRetentionDays: 1,
    overagePrice: null,
    ctaSupported: false,
    popular: false,
  },
  {
    key: 'minimum',
    price: '10,000',
    dmCount: 500,
    statsRetentionDays: 30,
    overagePrice: 50,
    ctaSupported: true,
    popular: false,
  },
  // ... starter, pro
];

// 비교 테이블 데이터 (59~65라인)
const comparisonData = {
  prices: ['₩0', '₩10,000', '₩15,000', '₩50,000'],
  dmCounts: ['100', '500', '1,500', '10,000'],
  pricePerDm: ['-', '₩20', '₩10', '₩5'],
  overage: ['stop', '₩50', '₩30', '₩10'],
  statsRetention: ['1', '30', '30', '90'],
};
```

**문제점:**
- 백엔드와 프론트엔드에서 **중복 관리**
- Free 플랜 DM 한도가 백엔드(50)와 프론트엔드(100)에서 **불일치**
- 가격/한도 변경 시 **2곳을 수정**해야 함
- 비교 테이블 데이터도 **별도로 하드코딩**

---

### 2.3 `/web/components/pricing/PlanCard.tsx`

```tsx
// 플랜 순서 정의 (171~173라인)
function getPlansOrder() {
  return ['free', 'minimum', 'starter', 'pro'];
}
```

**문제점:**
- 플랜 추가/삭제 시 수정 필요
- DB의 `sort_num` 필드를 활용하지 않음

---

## 3. 수정이 필요한 파일과 함수

### 3.1 즉시 수정 필요 (우선순위: 높음)

#### 파일: `/api/src/utils/pricing.js`

**수정 대상 함수:**

| 함수명 | 현재 동작 | 수정 후 동작 |
|-------|---------|------------|
| `PLAN_IDS` | 상수 객체 | DB 조회 결과로 동적 생성 |
| `PLANS` | 상수 객체 | DB 조회 결과로 동적 생성 |
| `getPlan(planId)` | 메모리 상수 반환 | DB 조회 (캐싱 필요) |
| `getAllPlans(options)` | 메모리 상수 반환 | DB 조회 (캐싱 필요) |

**유지 가능한 함수** (비즈니스 로직):
- `isValidPlanId()` - DB 조회 결과로 검증
- `isPaidPlan()` - 로직 유지
- `isUpgrade()`, `isDowngrade()` - 로직 유지
- `formatPlanPrice()` - 로직 유지

**DB 조회 추가 필요:**
- `getPlanSeqByPlanId()` - 이미 DB 조회 중 ✅
- `getPlanIdByPlanSeq()` - 이미 DB 조회 중 ✅
- `getPlanFromDb()` - 이미 DB 조회 중 ✅
- `getPlanBySeq()` - 이미 DB 조회 중 ✅

#### 파일: `/web/app/pricing/page.tsx`

**수정 내용:**
- `plansData` 상수 → API 호출 (`/api/v1/plans`)로 대체
- `comparisonData` 상수 → API 조회 결과에서 동적 생성
- 서버 컴포넌트이므로 `await plansApi.getPlans()` 호출

---

### 3.2 영향도가 높은 의존 파일 (우선순위: 중간)

#### 파일: `/api/src/services/usageService.js`

**수정 필요 함수:**

| 함수명 | 의존성 | 수정 내용 |
|-------|-------|---------|
| `getUserPlanId()` | pricing.js | DB 조회로 전환 |
| `getCurrentUsage()` | `pricingUtil.getPlan()` | DB 조회 API 사용 |
| `incrementDmCount()` | `pricingUtil.getPlan()` | DB 조회 API 사용 |
| `checkQuotaLimit()` | `pricingUtil.getPlan()` | DB 조회 API 사용 |

#### 파일: `/api/src/middleware/usageCheck.js`

**수정 필요 함수:**

| 함수명 | 의존성 | 수정 내용 |
|-------|-------|---------|
| `getUserPlanId()` | pricing.js | DB 조회로 전환 |
| `requirePlan()` | `pricingUtil.getPlan()` | DB 조회 API 사용 |

---

### 3.3 간접 의존 파일 (우선순위: 낮음)

다음 파일들은 `pricing.js`를 간접적으로 사용하지만, `pricing.js`가 DB 조회로 전환되면 **코드 수정 없이** 자동으로 DB 기반으로 동작합니다:

- `/api/src/utils/overageCalculator.js`
- `/api/src/utils/proratedBilling.js`
- `/api/src/controllers/planController.js`

---

## 4. 수정 방향 제안

### 4.1 아키텍처 설계 원칙

#### 원칙 1: Single Source of Truth (단일 진실 원천)
- ✅ **DB를 유일한 진실 원천으로** 사용
- ❌ 코드 상수와 DB 데이터 이원화 방지

#### 원칙 2: 캐싱 전략
- **메모리 캐시**: 요청당 플랜 정보 조회 최소화
- **Redis 캐시** (선택): 플랜 정보는 자주 변경되지 않으므로 TTL 1시간 권장
- **무효화**: 플랜 정보 수정 시 캐시 삭제

#### 원칙 3: 하위 호환성
- 기존 API 응답 형식 유지
- `plan_id` (문자열) ↔ `plan_seq` (숫자) 변환 계층 유지

---

### 4.2 DB 스키마 매핑

#### tb_plans 테이블 → PLANS 객체 매핑

| DB 컬럼 | 코드 필드 | 변환 로직 |
|---------|---------|----------|
| `plan_code` | `id` | `toLowerCase()` (FREE → free) |
| `name_ko` | `displayName` | 다국어 지원 시 locale 기반 선택 |
| `name_en` | `name` | - |
| `description_ko` | `description` | 다국어 지원 시 locale 기반 선택 |
| `price_ko` | `price` | 통화 기반 선택 (KRW) |
| `is_recommended` | `recommended` | `TINYINT(1) → boolean` |
| `sort_num` | `sortOrder` | - |

#### tb_plan_properties 테이블 → features/limitations 매핑

| prop_code | 매핑 대상 | 변환 로직 |
|-----------|---------|----------|
| `DM` | `dmQuota`, `dmUnitPrice`, `overageAllowed`, `overageUnitPrice` | `value_ko` 파싱 (JSON 또는 구분자) |
| `TRIGGER` | `features.activeTriggers` | `display_ko` 사용 |
| `ANALYTICS` | `features.statsRetention` | `value_ko` → `parseInt()` |
| `CTA` | `features.ctaButton` | `is_support` → boolean |
| `OVER_USAGE` | `overageAllowed`, `overageUnitPrice` | `value_ko` 파싱 |

---

### 4.3 구현 계획

#### Phase 1: 백엔드 리팩토링 (핵심)

**1단계: PlanService 생성**

```javascript
// /api/src/services/planService.js

import { Plan, PlanProperty } from '../models/index.js';
import logger from '../utils/logger.js';

// 메모리 캐시 (간단한 구현)
let plansCache = null;
let cacheTimestamp = null;
const CACHE_TTL = 3600000; // 1시간

/**
 * DB에서 모든 플랜 정보 조회 (캐싱 포함)
 */
export async function getAllPlansFromDb() {
  // 캐시 확인
  if (plansCache && cacheTimestamp && Date.now() - cacheTimestamp < CACHE_TTL) {
    return plansCache;
  }

  // DB 조회
  const plansData = await Plan.findAll({
    where: { status: 'ACTIVATED' },
    include: [{
      model: PlanProperty,
      as: 'properties',
      order: [['sort_num', 'ASC']]
    }],
    order: [['sort_num', 'ASC']]
  });

  // 변환
  const plans = plansData.map(transformPlanToLegacyFormat);

  // 캐시 저장
  plansCache = plans;
  cacheTimestamp = Date.now();

  return plans;
}

/**
 * DB 레코드를 레거시 PLANS 객체 형식으로 변환
 */
function transformPlanToLegacyFormat(planRecord) {
  const props = planRecord.properties || [];

  // DM 속성 파싱
  const dmProp = props.find(p => p.prop_code === 'DM');
  const dmData = parseDmProperty(dmProp);

  // ANALYTICS 속성 파싱
  const analyticsProp = props.find(p => p.prop_code === 'ANALYTICS');
  const statsRetention = analyticsProp ? parseInt(analyticsProp.value_ko) : 1;

  // CTA 속성
  const ctaProp = props.find(p => p.prop_code === 'CTA');
  const ctaButton = ctaProp ? Boolean(ctaProp.is_support) : false;

  // OVER_USAGE 속성
  const overUsageProp = props.find(p => p.prop_code === 'OVER_USAGE');
  const overageData = parseOverageProperty(overUsageProp);

  // 제한사항 생성 (로직 기반)
  const limitations = [];
  if (!dmData.overageAllowed) {
    limitations.push('한도 초과 시 발송 중단');
  }
  if (statsRetention === 1) {
    limitations.push('1일간 통계만 조회 가능');
  }
  if (!ctaButton) {
    limitations.push('CTA 버튼 미지원');
  }

  return {
    id: planRecord.plan_code.toLowerCase(),
    name: planRecord.name_en,
    displayName: planRecord.name_ko,
    description: planRecord.description_ko,
    price: parseFloat(planRecord.price_ko),
    dmQuota: dmData.quota,
    dmUnitPrice: dmData.unitPrice,
    overageAllowed: overageData.allowed,
    overageUnitPrice: overageData.unitPrice,
    features: {
      activeTriggers: props.find(p => p.prop_code === 'TRIGGER')?.display_ko || '무제한',
      statsRetention,
      ctaButton,
      prioritySupport: planRecord.plan_code === 'PRO', // 또는 별도 prop_code 추가
    },
    limitations,
    recommended: Boolean(planRecord.is_recommended),
    sortOrder: planRecord.sort_num,
  };
}

/**
 * DM 속성 파싱
 * 예: value_ko = "500|20" (quota|unitPrice)
 */
function parseDmProperty(dmProp) {
  if (!dmProp) {
    return { quota: 0, unitPrice: 0, overageAllowed: false };
  }

  const [quota, unitPrice] = dmProp.value_ko.split('|').map(v => parseInt(v) || 0);
  return {
    quota,
    unitPrice,
    overageAllowed: quota > 0, // Free는 quota=0으로 설정
  };
}

/**
 * 초과 사용 속성 파싱
 * 예: value_ko = "1|50" (allowed|unitPrice)
 */
function parseOverageProperty(overUsageProp) {
  if (!overUsageProp) {
    return { allowed: false, unitPrice: 0 };
  }

  const [allowed, unitPrice] = overUsageProp.value_ko.split('|').map(v => parseInt(v) || 0);
  return {
    allowed: Boolean(allowed),
    unitPrice,
  };
}

/**
 * 캐시 무효화
 */
export function invalidatePlansCache() {
  plansCache = null;
  cacheTimestamp = null;
  logger.info('Plans cache invalidated');
}
```

**2단계: pricing.js 리팩토링**

```javascript
// /api/src/utils/pricing.js

import * as planService from '../services/planService.js';
import Plan from '../models/Plan.js';

// 플랜 ID는 여전히 상수로 유지 (타입 안전성)
export const PLAN_IDS = {
  FREE: 'free',
  MINIMUM: 'minimum',
  STARTER: 'starter',
  PRO: 'pro',
};

/**
 * PLANS 객체는 더 이상 상수가 아니라 함수로 변경
 * @deprecated getAllPlans() 사용 권장
 */
export const PLANS = null; // 기존 코드 호환성을 위해 null로 유지

/**
 * 플랜 정보 조회 (DB 기반)
 */
export async function getPlan(planId) {
  const plans = await planService.getAllPlansFromDb();
  return plans.find(p => p.id === planId) || null;
}

/**
 * 모든 플랜 목록 조회 (DB 기반)
 */
export async function getAllPlans(options = {}) {
  const { excludeFree = false, currentPlanId = null } = options;

  let plans = await planService.getAllPlansFromDb();

  if (excludeFree) {
    plans = plans.filter(plan => plan.id !== PLAN_IDS.FREE);
  }

  if (currentPlanId) {
    plans = plans.map(plan => ({
      ...plan,
      isCurrent: plan.id === currentPlanId,
    }));
  }

  return plans.sort((a, b) => a.sortOrder - b.sortOrder);
}

/**
 * 플랜 ID 유효성 검증 (DB 기반)
 */
export async function isValidPlanId(planId) {
  const plans = await planService.getAllPlansFromDb();
  return plans.some(p => p.id === planId);
}

// 나머지 함수들은 getPlan()을 async로 호출하도록 수정
export async function isPaidPlan(planId) {
  return planId !== PLAN_IDS.FREE && await isValidPlanId(planId);
}

export async function getDmQuota(planId) {
  const plan = await getPlan(planId);
  return plan ? plan.dmQuota : 0;
}

// ... 기타 함수들도 동일 패턴
```

**3단계: 호출 코드 수정**

```javascript
// Before (동기)
const plan = pricingUtil.getPlan(planId);

// After (비동기)
const plan = await pricingUtil.getPlan(planId);
```

---

#### Phase 2: 프론트엔드 리팩토링

**1단계: pricing/page.tsx 수정**

```tsx
// /web/app/pricing/page.tsx

import { plansApi } from '@/lib/api/plans';

export default async function PricingPage() {
  // API 호출로 플랜 정보 조회
  const plans = await plansApi.getPlans();

  // 비교 테이블 데이터 동적 생성
  const comparisonData = {
    prices: plans.map(p => p.price === 0 ? '₩0' : `₩${p.price.toLocaleString()}`),
    dmCounts: plans.map(p => p.dmQuota.toLocaleString()),
    pricePerDm: plans.map(p => p.dmUnitPrice ? `₩${p.dmUnitPrice}` : '-'),
    overage: plans.map(p => p.overageAllowed ? `₩${p.overageUnitPrice}` : 'stop'),
    statsRetention: plans.map(p => p.features.statsRetention.toString()),
  };

  return (
    // ... 기존 JSX (plansData → plans 사용)
  );
}
```

**2단계: PlanCard.tsx 수정**

```tsx
// /web/components/pricing/PlanCard.tsx

function getPlansOrder() {
  // DB의 sortOrder를 사용하도록 변경 (또는 제거)
  return ['free', 'minimum', 'starter', 'pro'];
}
```

→ `sortOrder` 필드를 직접 비교하는 로직으로 변경 권장

---

### 4.4 데이터 마이그레이션

#### tb_plan_properties의 value_ko 포맷 정의

현재 `value_ko` 컬럼에 들어갈 데이터 형식을 정의해야 합니다.

**옵션 1: 파이프 구분자 (|)**

```sql
-- DM 속성
INSERT INTO tb_plan_properties (plan_seq, prop_code, display_ko, value_ko, is_support, sort_num)
VALUES
  (1, 'DM', 'DM 발송 한도', '50|0', 1, 1),           -- Free: 50건, 단가 0원
  (2, 'DM', 'DM 발송 한도', '500|20', 1, 1),        -- Minimum: 500건, 단가 20원
  (3, 'DM', 'DM 발송 한도', '1500|10', 1, 1),       -- Starter: 1500건, 단가 10원
  (4, 'DM', 'DM 발송 한도', '10000|5', 1, 1);       -- Pro: 10000건, 단가 5원

-- OVER_USAGE 속성
INSERT INTO tb_plan_properties (plan_seq, prop_code, display_ko, value_ko, is_support, sort_num)
VALUES
  (1, 'OVER_USAGE', '초과 사용', '0|0', 0, 5),      -- Free: 초과 불가
  (2, 'OVER_USAGE', '초과 사용', '1|50', 1, 5),     -- Minimum: 50원/건
  (3, 'OVER_USAGE', '초과 사용', '1|30', 1, 5),     -- Starter: 30원/건
  (4, 'OVER_USAGE', '초과 사용', '1|10', 1, 5);     -- Pro: 10원/건

-- ANALYTICS 속성
INSERT INTO tb_plan_properties (plan_seq, prop_code, display_ko, value_ko, is_support, sort_num)
VALUES
  (1, 'ANALYTICS', '통계 보관 기간', '1', 1, 3),
  (2, 'ANALYTICS', '통계 보관 기간', '30', 1, 3),
  (3, 'ANALYTICS', '통계 보관 기간', '30', 1, 3),
  (4, 'ANALYTICS', '통계 보관 기간', '90', 1, 3);
```

**옵션 2: JSON 형식**

```sql
-- value_ko를 JSON으로 저장
UPDATE tb_plan_properties
SET value_ko = '{"quota": 500, "unitPrice": 20}'
WHERE prop_code = 'DM' AND plan_seq = 2;
```

→ **권장: 옵션 1 (파이프 구분자)** - 간단하고 파싱 비용 낮음

---

### 4.5 테스트 계획

#### 단위 테스트

```javascript
// /api/tests/services/planService.test.js

describe('PlanService', () => {
  describe('getAllPlansFromDb', () => {
    it('should return all active plans', async () => {
      const plans = await planService.getAllPlansFromDb();
      expect(plans).toHaveLength(4);
      expect(plans[0].id).toBe('free');
    });

    it('should cache plans for 1 hour', async () => {
      const plans1 = await planService.getAllPlansFromDb();
      const plans2 = await planService.getAllPlansFromDb();
      expect(plans1).toBe(plans2); // 동일 참조
    });
  });

  describe('transformPlanToLegacyFormat', () => {
    it('should transform DB record to legacy format', () => {
      const dbRecord = {
        plan_code: 'FREE',
        name_ko: '무료',
        price_ko: 0,
        properties: [
          { prop_code: 'DM', value_ko: '50|0' },
          { prop_code: 'ANALYTICS', value_ko: '1' },
        ]
      };

      const result = transformPlanToLegacyFormat(dbRecord);

      expect(result.id).toBe('free');
      expect(result.dmQuota).toBe(50);
      expect(result.features.statsRetention).toBe(1);
    });
  });
});
```

#### 통합 테스트

```javascript
// /api/tests/integration/pricing.test.js

describe('Pricing Integration', () => {
  it('GET /api/v1/plans should return plans from DB', async () => {
    const response = await request(app)
      .get('/api/v1/plans')
      .expect(200);

    expect(response.body.data.plans).toHaveLength(4);
    expect(response.body.data.plans[0]).toHaveProperty('id');
    expect(response.body.data.plans[0]).toHaveProperty('price');
  });
});
```

---

## 5. 우선순위 및 영향도

### 5.1 수정 우선순위

| 순위 | 파일/작업 | 이유 | 예상 시간 |
|-----|---------|------|----------|
| 1 | `planService.js` 생성 | 핵심 서비스 계층 | 4시간 |
| 2 | `pricing.js` 리팩토링 | 모든 로직의 기반 | 3시간 |
| 3 | `usageService.js` 수정 | DM 발송 로직에 직접 영향 | 2시간 |
| 4 | `usageCheck.js` 미들웨어 수정 | API 요청마다 실행 | 1시간 |
| 5 | `planController.js` 수정 | 이미 DB 조회 중 (최소 수정) | 0.5시간 |
| 6 | 프론트엔드 `pricing/page.tsx` | 사용자 대면 | 2시간 |
| 7 | 프론트엔드 `PlanCard.tsx` | 우선순위 낮음 | 0.5시간 |
| 8 | 단위/통합 테스트 작성 | 안정성 보장 | 4시간 |

**총 예상 시간: 17시간** (2~3일 소요)

---

### 5.2 영향도 분석

#### High (높음) - 즉시 수정 필요

- ⚠️ **데이터 불일치**: Free 플랜 DM 한도가 백엔드(50)와 프론트엔드(100)에서 다름
- ⚠️ **유지보수 비용**: 가격/한도 변경 시 2곳(백엔드 + 프론트엔드) 수정 필요
- ⚠️ **확장성 제약**: 새 플랜 추가 시 코드 수정 필수

#### Medium (중간)

- 플랜 정보 변경 시 **배포 없이 DB만 수정**할 수 없음
- 다국어 지원 시 언어별 하드코딩 추가 필요

#### Low (낮음)

- 플랜 순서 변경의 어려움 (낮은 빈도)

---

### 5.3 리스크 및 완화 전략

| 리스크 | 확률 | 영향도 | 완화 전략 |
|-------|------|-------|----------|
| DB 조회 성능 저하 | 중간 | 높음 | 메모리 캐싱 (TTL 1시간) |
| 캐시 무효화 실패 | 낮음 | 중간 | Admin API에 캐시 삭제 엔드포인트 추가 |
| 레거시 코드 호환성 | 중간 | 중간 | 응답 형식 동일하게 유지 |
| 동기 함수 → 비동기 변환 | 높음 | 낮음 | 점진적 마이그레이션 (호출부 순차 수정) |
| 프론트엔드 빌드 실패 | 낮음 | 높음 | SSR/SSG 고려, API 호출 에러 핸들링 |

---

## 6. 결론 및 권장사항

### 6.1 요약

1. **현재 상황**: 모든 플랜 정보가 `/api/src/utils/pricing.js`와 `/web/app/pricing/page.tsx`에 하드코딩되어 있음
2. **문제점**:
   - 백엔드와 프론트엔드 간 데이터 불일치 (Free 플랜 DM 한도)
   - 유지보수 비용 증가 (2곳 수정 필요)
   - 확장성 제약 (새 플랜 추가 시 코드 수정 + 배포 필수)
3. **해결책**: `tb_plans`, `tb_plan_properties` 테이블을 단일 진실 원천으로 사용

### 6.2 권장 순서

#### Week 1: 백엔드 리팩토링
1. **Day 1-2**: `planService.js` 생성 + 단위 테스트
2. **Day 2-3**: `pricing.js` 리팩토링 (동기 → 비동기)
3. **Day 3-4**: `usageService.js`, `usageCheck.js` 수정
4. **Day 4-5**: 통합 테스트 + 수동 QA

#### Week 2: 프론트엔드 리팩토링 + 배포
1. **Day 1**: `pricing/page.tsx` API 호출로 전환
2. **Day 2**: `PlanCard.tsx` 및 기타 컴포넌트 수정
3. **Day 3**: 프론트엔드 E2E 테스트
4. **Day 4**: Staging 배포 + QA
5. **Day 5**: Production 배포

### 6.3 추가 고려사항

#### 1. Redis 캐싱 (선택 사항)
- 현재는 메모리 캐시로 충분
- 트래픽 증가 시 Redis 도입 검토

#### 2. Admin API 추가
```javascript
// POST /api/v1/admin/plans/cache/invalidate
// 플랜 정보 수정 후 캐시 무효화용
```

#### 3. 다국어 지원 준비
- `name_ko`, `name_en`, `name_ja` 활용
- `locale` 파라미터에 따라 동적 반환

#### 4. 플랜 변경 이력
- 플랜 정보 변경 시 `tb_plan_change_history` 테이블 고려 (감사 로그)

---

## 부록

### A. 파일별 수정 체크리스트

#### 백엔드

- [ ] `/api/src/services/planService.js` 생성
- [ ] `/api/src/utils/pricing.js` 리팩토링
  - [ ] `getPlan()` 비동기 전환
  - [ ] `getAllPlans()` 비동기 전환
  - [ ] `isValidPlanId()` 비동기 전환
  - [ ] 기타 함수들 비동기 전환
- [ ] `/api/src/services/usageService.js` 수정
  - [ ] `getUserPlanId()` 수정
  - [ ] `getCurrentUsage()` 수정
  - [ ] `incrementDmCount()` 수정
  - [ ] `checkQuotaLimit()` 수정
- [ ] `/api/src/middleware/usageCheck.js` 수정
  - [ ] `getUserPlanId()` 수정
  - [ ] `requirePlan()` 수정
- [ ] `/api/src/controllers/planController.js` 검토 (최소 수정)

#### 프론트엔드

- [ ] `/web/app/pricing/page.tsx` 리팩토링
  - [ ] `plansData` 제거
  - [ ] `comparisonData` 동적 생성
  - [ ] API 호출 추가
- [ ] `/web/components/pricing/PlanCard.tsx` 수정
  - [ ] `getPlansOrder()` 로직 개선

#### 테스트

- [ ] `/api/tests/services/planService.test.js` 작성
- [ ] `/api/tests/utils/pricing.test.js` 업데이트
- [ ] `/api/tests/integration/pricing.test.js` 작성
- [ ] 수동 QA 시나리오 작성

#### 배포

- [ ] 데이터 마이그레이션 스크립트 작성
- [ ] Staging 배포
- [ ] Production 배포
- [ ] 캐시 무효화 확인

---

### B. 주요 코드 스니펫

#### DB 조회 최적화 예시

```javascript
// 캐싱 전략: 메모리 캐시 + TTL
class PlanCache {
  constructor(ttl = 3600000) { // 1시간
    this.cache = null;
    this.timestamp = null;
    this.ttl = ttl;
  }

  get() {
    if (!this.cache || !this.timestamp) return null;
    if (Date.now() - this.timestamp > this.ttl) {
      this.clear();
      return null;
    }
    return this.cache;
  }

  set(data) {
    this.cache = data;
    this.timestamp = Date.now();
  }

  clear() {
    this.cache = null;
    this.timestamp = null;
  }
}

export const plansCache = new PlanCache();
```

---

**보고서 끝**
