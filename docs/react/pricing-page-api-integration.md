# Pricing 페이지 API 통합 문서

## 개요

프론트엔드 pricing 페이지를 하드코딩된 데이터에서 백엔드 API 호출 방식으로 변경하여 데이터 일관성 문제를 해결했습니다.

## 변경 사항 요약

### 문제점
- 백엔드와 프론트엔드 데이터 불일치 (예: Free 플랜 DM 한도 - 백엔드 50건, 프론트엔드 100건)
- 가격 변경 시 프론트엔드와 백엔드를 모두 수정해야 하는 문제
- 유지보수성 저하

### 해결 방법
- 백엔드 API `/api/plans` 엔드포인트에서 플랜 데이터 조회
- Server Component를 활용하여 서버에서 직접 API 호출
- API 호출 실패 시 fallback 데이터 제공

## 수정된 파일

### 1. `/web/lib/api/plans.ts`

백엔드 API 응답 형식에 맞는 타입 정의 및 API 클라이언트 함수 추가

```typescript
export interface PlanFeatures {
  activeTriggers: string;
  statsRetention: number;
  ctaButton: boolean;
  prioritySupport: boolean;
}

export interface BackendPlan {
  id: string;
  name: string;
  displayName: string;
  description: string;
  price: number;
  dmQuota: number;
  overageAllowed: boolean;
  overageUnitPrice: number;
  features: PlanFeatures;
  recommended: boolean;
  sortOrder: number;
  isCurrent?: boolean;
}

export const plansApi = {
  async getPlans(locale = 'ko'): Promise<BackendPlan[]> {
    const response = await apiClient.get<PlansApiResponse>('/plans', {
      params: { locale },
    });
    return response.data.data.plans;
  },

  async getPlanByCode(planCode: string, locale = 'ko'): Promise<BackendPlan> {
    const response = await apiClient.get(
      `/plans/${planCode}`,
      { params: { locale } }
    );
    return response.data.data.plan;
  },
};
```

**주요 변경사항:**
- `BackendPlan` 인터페이스: 백엔드 API 응답 구조에 맞춘 타입 정의
- `getPlans()`: 모든 플랜 목록 조회, locale 파라미터 지원
- `getPlanByCode()`: 특정 플랜 조회

### 2. `/web/types/plan.ts`

타입 정의를 백엔드 API 응답 형식에 맞게 수정

**변경 전:**
```typescript
export interface Plan {
  id: PlanId;
  dmUnitPrice: number; // 기존 필드
  limitations: string[]; // 기존 필드
  // ...
}
```

**변경 후:**
```typescript
export interface Plan {
  id: string; // PlanId에서 string으로 변경
  dmQuota: number; // dmUnitPrice 제거, dmQuota 사용
  overageAllowed: boolean; // 새로운 필드
  overageUnitPrice: number; // 새로운 필드
  // limitations 필드 제거 (백엔드 API에 없음)
}
```

**주요 변경사항:**
- `id`: `PlanId` → `string` (유연성 향상)
- `dmUnitPrice` 제거, `overageUnitPrice` 사용
- `limitations` 필드 제거 (백엔드에 해당 필드 없음)
- `overageAllowed` 필드 추가 (초과 허용 여부)

### 3. `/web/app/pricing/page.tsx`

하드코딩된 데이터를 API 호출로 대체

#### 주요 함수

**`getPlansFromAPI(locale: string)`**
```typescript
async function getPlansFromAPI(locale: string): Promise<Plan[]> {
  try {
    const apiUrl = process.env.NEXT_PUBLIC_API_URL || 'http://localhost:3000/api';
    const response = await fetch(`${apiUrl}/plans?locale=${locale}`, {
      cache: 'no-store', // 항상 최신 데이터 조회
    });

    if (!response.ok) {
      throw new Error(`Failed to fetch plans: ${response.status}`);
    }

    const result = await response.json();

    if (!result.result || !result.data?.plans) {
      throw new Error('Invalid API response format');
    }

    return result.data.plans;
  } catch (error) {
    console.error('Error fetching plans:', error);
    return getFallbackPlans(); // 에러 시 fallback 데이터 반환
  }
}
```

**특징:**
- Server Component에서 직접 `fetch` 사용
- `cache: 'no-store'` 옵션으로 항상 최신 데이터 조회
- 에러 발생 시 fallback 데이터 반환 (서비스 안정성 확보)

**`getFallbackPlans()`**
```typescript
function getFallbackPlans(): Plan[] {
  return [
    {
      id: 'free',
      name: 'Free',
      displayName: '무료',
      description: '서비스 테스트 및 소규모 개인 계정용',
      price: 0,
      dmQuota: 50,
      overageAllowed: false,
      overageUnitPrice: 0,
      features: {
        activeTriggers: '무제한',
        statsRetention: 1,
        ctaButton: false,
        prioritySupport: false,
      },
      recommended: false,
      sortOrder: 1,
    },
    // ... 기타 플랜
  ];
}
```

**특징:**
- API 호출 실패 시 사용할 기본 데이터
- 백엔드 DB의 실제 데이터와 동일한 구조

#### 데이터 변환

**플랜 카드 데이터 변환:**
```typescript
const plansData = plans.map((plan) => ({
  key: plan.id,
  price: plan.price.toLocaleString(),
  dmCount: plan.dmQuota,
  statsRetentionDays: plan.features.statsRetention,
  overagePrice: plan.overageAllowed ? plan.overageUnitPrice : null,
  ctaSupported: plan.features.ctaButton,
  popular: plan.recommended,
}));
```

**비교 테이블 데이터 생성:**
```typescript
const comparisonData = {
  prices: plans.map((p) => `₩${p.price.toLocaleString()}`),
  dmCounts: plans.map((p) => p.dmQuota.toLocaleString()),
  pricePerDm: plans.map((p) =>
    p.price === 0 ? '-' : `₩${Math.round(p.price / p.dmQuota)}`
  ),
  overage: plans.map((p) =>
    !p.overageAllowed ? 'stop' : `₩${p.overageUnitPrice}`
  ),
  statsRetention: plans.map((p) => String(p.features.statsRetention)),
  ctaSupport: plans.map((p) => p.features.ctaButton),
};
```

**특징:**
- API 응답 데이터를 UI에 맞게 동적으로 변환
- 가격, DM 단가 등을 자동 계산
- 비교 테이블도 동적으로 생성

### 4. 기타 컴포넌트 수정

#### `/web/components/pricing/PlanCard.tsx`
```typescript
// limitations 필드 사용 부분 주석 처리
{/* plan.limitations && plan.limitations.length > 0 && (
  <div className="pt-3 border-t">
    <div className="text-xs font-semibold text-muted-foreground mb-2">제한사항</div>
    <ul className="space-y-1">
      {plan.limitations.map((limitation: string, index: number) => (
        <li key={index} className="text-xs text-muted-foreground">
          • {limitation}
        </li>
      ))}
    </ul>
  </div>
)} */}
```

#### `/web/components/subscription/ChangePlanModal.tsx`
```typescript
// Plan.id가 string이므로 타입 단언 추가
const isPlanUpgrade = planOrder.indexOf(plan.id as PlanId) > planOrder.indexOf(currentPlanId);
const isPlanDowngrade = planOrder.indexOf(plan.id as PlanId) < planOrder.indexOf(currentPlanId);
onClick={() => setSelectedPlanId(plan.id as PlanId)}
```

#### `/web/app/dashboard/subscription/checkout/page.tsx`
```typescript
// PlanId 타입 임포트 추가
import type { Plan, PlanId } from '@/types';

// 타입 단언 추가
await createSubscription.mutateAsync({
  planId: selectedPlan.id as PlanId,
  billingKey: billingResponse.impUid,
  cardInfo,
});
```

## API 엔드포인트

### GET `/api/plans`

**쿼리 파라미터:**
- `locale` (optional): 언어 코드 (ko, en, ja, 기본값: ko)
- `include_properties` (optional): 속성 포함 여부 (기본값: true)

**응답 형식:**
```json
{
  "result": true,
  "data": {
    "plans": [
      {
        "id": "free",
        "name": "Free",
        "displayName": "무료",
        "description": "서비스 테스트 및 소규모 개인 계정용",
        "price": 0,
        "dmQuota": 50,
        "overageAllowed": false,
        "overageUnitPrice": 0,
        "features": {
          "activeTriggers": "무제한",
          "statsRetention": 1,
          "ctaButton": false,
          "prioritySupport": false
        },
        "recommended": false,
        "sortOrder": 1
      }
    ],
    "total_count": 4
  }
}
```

### GET `/api/plans/:plan_code`

**경로 파라미터:**
- `plan_code`: 플랜 코드 (free, minimum, starter, pro)

**쿼리 파라미터:**
- `locale` (optional): 언어 코드 (ko, en, ja, 기본값: ko)

**응답 형식:**
```json
{
  "result": true,
  "data": {
    "plan": {
      "id": "starter",
      "name": "Starter",
      "displayName": "스타터",
      "description": "소규모 비즈니스 및 활발한 크리에이터용",
      "price": 15000,
      "dmQuota": 1500,
      "overageAllowed": true,
      "overageUnitPrice": 30,
      "features": {
        "activeTriggers": "무제한",
        "statsRetention": 30,
        "ctaButton": true,
        "prioritySupport": false
      },
      "recommended": true,
      "sortOrder": 3
    }
  }
}
```

## 에러 처리

### 1. API 호출 실패
- `getPlansFromAPI()` 함수에서 try-catch로 에러 처리
- 에러 발생 시 `getFallbackPlans()` 반환하여 서비스 지속

### 2. 네트워크 오류
- fetch 실패 시 자동으로 fallback 데이터 사용
- 사용자는 페이지가 정상 작동하는 것처럼 경험

### 3. 잘못된 응답 형식
- API 응답 검증 로직 추가
- `result` 및 `data.plans` 존재 여부 확인

## 성능 최적화

### 1. Server Component 활용
- 페이지 로드 시 서버에서 API 호출
- 클라이언트 번들 크기 감소
- SEO 친화적

### 2. 캐싱 전략
- `cache: 'no-store'` 옵션으로 항상 최신 데이터 보장
- 필요시 `cache: 'force-cache'` 또는 revalidate 옵션 추가 가능

### 3. 백엔드 캐싱
- 백엔드에서 플랜 데이터를 메모리 캐싱 (TTL: 1시간)
- DB 조회 부하 감소

## 데이터 일관성

### Before (하드코딩)
| 플랜 | 프론트엔드 DM 한도 | 백엔드 DM 한도 | 일치 여부 |
|------|-------------------|---------------|----------|
| Free | 100건 | 50건 | ❌ 불일치 |
| Minimum | 500건 | 500건 | ✅ 일치 |
| Starter | 1,500건 | 1,500건 | ✅ 일치 |
| Pro | 10,000건 | 10,000건 | ✅ 일치 |

### After (API 통합)
| 플랜 | 프론트엔드 DM 한도 | 백엔드 DM 한도 | 일치 여부 |
|------|-------------------|---------------|----------|
| Free | 50건 | 50건 | ✅ 일치 |
| Minimum | 500건 | 500건 | ✅ 일치 |
| Starter | 1,500건 | 1,500건 | ✅ 일치 |
| Pro | 10,000건 | 10,000건 | ✅ 일치 |

**결과:** 모든 플랜 데이터가 백엔드 DB와 일치하도록 개선

## 향후 개선 사항

### 1. ISR (Incremental Static Regeneration) 적용
```typescript
const response = await fetch(`${apiUrl}/plans?locale=${locale}`, {
  next: { revalidate: 3600 } // 1시간마다 재생성
});
```

### 2. 다국어 지원 강화
- 현재 locale 파라미터만 전달
- 번역 파일과 API 응답 데이터 조합하여 완전한 다국어 지원

### 3. 플랜 비교 기능 추가
- 사용자가 여러 플랜을 선택하여 직접 비교
- 차이점 강조 표시

### 4. A/B 테스트
- 플랜 가격 및 기능 변경 시 A/B 테스트 지원
- 백엔드에서 실험 그룹별 다른 플랜 데이터 반환

## 테스트

### 수동 테스트
1. `/pricing` 페이지 접속
2. 플랜 카드에 올바른 데이터 표시 확인
3. 비교 테이블에 올바른 데이터 표시 확인
4. 네트워크 차단 후 fallback 데이터 작동 확인

### TypeScript 타입 체크
```bash
cd web && npx tsc --noEmit
```
✅ 모든 타입 오류 해결 완료

## 관련 문서
- [백엔드 플랜 API 문서](/docs/api/plans.md)
- [가격 플랜 기획서](/docs/bm/Autogram_가격플랜_기획서.md)
- [구독 시스템 문서](/docs/api/subscriptions.md)

## 참고 사항

### 환경 변수
- `NEXT_PUBLIC_API_URL`: API 기본 URL (기본값: http://localhost:3000/api)

### 의존성
- `next-intl`: 다국어 지원
- `axios`: API 클라이언트 (클라이언트 컴포넌트용)
- `fetch`: Server Component에서 직접 사용

## 마이그레이션 가이드

기존 하드코딩 방식에서 API 방식으로 마이그레이션하는 다른 페이지를 위한 가이드:

### 1. API 클라이언트 함수 작성
`/web/lib/api/` 디렉토리에 API 클라이언트 함수 작성

### 2. 타입 정의 업데이트
`/web/types/` 디렉토리에서 백엔드 응답에 맞는 타입 정의

### 3. Server Component에서 fetch 사용
```typescript
async function getData() {
  const res = await fetch('url', { cache: 'no-store' });
  return res.json();
}
```

### 4. fallback 데이터 준비
API 실패 시 사용할 기본 데이터 준비

### 5. 에러 처리
try-catch로 안전하게 에러 처리

## 작성자
- Claude Code (AI Assistant)
- 작성일: 2026-01-17
