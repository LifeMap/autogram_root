# Plans API 문서

## 개요
Autogram의 가격 플랜 정보를 조회하는 Public API입니다. 인증 없이 접근 가능하며, 4개의 플랜(FREE, MINIMUM, STARTER, PRO) 정보를 제공합니다.

## 주요 기능
- 전체 플랜 목록 조회
- 특정 플랜 상세 정보 조회
- 다국어 지원 (한국어, 영어, 일본어)
- 선택적 속성 포함/제외
- 로그인 사용자의 경우 현재 구독 중인 플랜 표시

## 엔드포인트

### 1. 플랜 목록 조회

#### 요청
- **메서드**: `GET`
- **경로**: `/api/v1/plans`
- **인증**: 선택 (비로그인 사용자도 접근 가능)

#### 쿼리 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `locale` | string | 아니오 | `ko` | 언어 코드 (`ko`, `en`, `ja`) |
| `include_properties` | boolean | 아니오 | `true` | 플랜 속성(features) 포함 여부 |

#### 성공 응답 (200 OK)

##### include_properties=true (기본값)
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
        "sortOrder": 1,
        "isCurrent": false
      },
      {
        "id": "minimum",
        "name": "Minimum",
        "displayName": "미니멈",
        "description": "1인 크리에이터 및 소규모 인플루언서용",
        "price": 10000,
        "dmQuota": 500,
        "overageAllowed": true,
        "overageUnitPrice": 50,
        "features": {
          "activeTriggers": "무제한",
          "statsRetention": 30,
          "ctaButton": true,
          "prioritySupport": false
        },
        "recommended": false,
        "sortOrder": 2,
        "isCurrent": false
      },
      {
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
        "sortOrder": 3,
        "isCurrent": true
      },
      {
        "id": "pro",
        "name": "Pro",
        "displayName": "프로",
        "description": "에이전시, 브랜드, 대규모 마케팅 운영용",
        "price": 50000,
        "dmQuota": 10000,
        "overageAllowed": true,
        "overageUnitPrice": 10,
        "features": {
          "activeTriggers": "무제한",
          "statsRetention": 90,
          "ctaButton": true,
          "prioritySupport": true
        },
        "recommended": false,
        "sortOrder": 4,
        "isCurrent": false
      }
    ],
    "total_count": 4
  },
  "errors": [],
  "meta": {
    "executed_time": "2024-11-29T10:30:00+09:00"
  }
}
```

##### include_properties=false
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
        "recommended": false,
        "sortOrder": 1,
        "isCurrent": false
      }
      // ... 나머지 플랜
    ],
    "total_count": 4
  },
  "errors": [],
  "meta": {
    "executed_time": "2024-11-29T10:30:00+09:00"
  }
}
```

#### 응답 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 플랜 ID (`free`, `minimum`, `starter`, `pro`) |
| `name` | string | 플랜 영문명 |
| `displayName` | string | 플랜 표시명 (locale에 따라 변경) |
| `description` | string | 플랜 설명 (locale에 따라 변경) |
| `price` | number | 월 구독료 (원/USD/JPY - locale에 따라 변경) |
| `dmQuota` | number | 월별 DM 발송 한도 |
| `overageAllowed` | boolean | 한도 초과 허용 여부 (FREE는 false) |
| `overageUnitPrice` | number | 초과 시 건당 요금 |
| `features` | object | 플랜 기능 상세 (include_properties=true일 때만) |
| `features.activeTriggers` | string | 활성 트리거 수 제한 |
| `features.statsRetention` | number | 통계 보관 기간 (일) |
| `features.ctaButton` | boolean | CTA 버튼 지원 여부 |
| `features.prioritySupport` | boolean | 우선 지원 여부 (PRO만 true) |
| `recommended` | boolean | 추천 플랜 여부 (인기 뱃지 표시용) |
| `sortOrder` | number | 정렬 순서 |
| `isCurrent` | boolean | 현재 사용자의 플랜인지 여부 (로그인 시에만 추가) |

### 2. 플랜 상세 조회

#### 요청
- **메서드**: `GET`
- **경로**: `/api/v1/plans/:plan_code`
- **인증**: 선택 (비로그인 사용자도 접근 가능)

#### 경로 파라미터

| 파라미터 | 타입 | 필수 | 설명 |
|---------|------|------|------|
| `plan_code` | string | 예 | 플랜 코드 (`FREE`, `MINIMUM`, `STARTER`, `PRO` - 대소문자 무관) |

#### 쿼리 파라미터

| 파라미터 | 타입 | 필수 | 기본값 | 설명 |
|---------|------|------|--------|------|
| `locale` | string | 아니오 | `ko` | 언어 코드 (`ko`, `en`, `ja`) |

#### 성공 응답 (200 OK)

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
  },
  "errors": [],
  "meta": {
    "executed_time": "2024-11-29T10:30:00+09:00"
  }
}
```

#### 오류 응답

##### 400 Bad Request - plan_code 누락
```json
{
  "result": true,
  "data": null,
  "errors": [],
  "meta": {
    "error": "plan_code is required",
    "executed_time": "2024-11-29T10:30:00+09:00"
  }
}
```

##### 404 Not Found - 존재하지 않는 플랜
```json
{
  "result": true,
  "data": null,
  "errors": [],
  "meta": {
    "error": "Plan 'INVALID' not found",
    "executed_time": "2024-11-29T10:30:00+09:00"
  }
}
```

## 비즈니스 로직

### 플랜 계층 구조
플랜은 가격 순으로 다음과 같이 계층화되어 있습니다:
1. **FREE** (₩0/월) - 기본 플랜
2. **MINIMUM** (₩10,000/월) - 엔트리 유료 플랜
3. **STARTER** (₩15,000/월) - 추천 플랜
4. **PRO** (₩50,000/월) - 프리미엄 플랜

### DM 한도 및 초과 요금 정책

| 플랜 | 월 한도 | 초과 허용 | 초과 단가 |
|------|---------|----------|----------|
| FREE | 50건 | ❌ | - |
| MINIMUM | 500건 | ✅ | ₩50/건 |
| STARTER | 1,500건 | ✅ | ₩30/건 |
| PRO | 10,000건 | ✅ | ₩10/건 |

- **FREE 플랜**: 한도 초과 시 발송 자동 중단
- **유료 플랜**: 한도 초과 시 추가 요금 부과 (익월 청구)

### 다국어 지원
- **한국어 (ko)**: 기본 언어, KRW 가격 표시
- **영어 (en)**: USD 가격 표시
- **일본어 (ja)**: JPY 가격 표시

locale 파라미터에 따라 `name`, `displayName`, `description`, `price` 필드가 해당 언어로 반환됩니다.

### 현재 플랜 표시 (isCurrent)
- **로그인 사용자**: 구독 테이블(tb_subscriptions)을 조회하여 현재 플랜에 `isCurrent: true` 추가
- **비로그인 사용자**: 모든 플랜에 `isCurrent: false` (또는 미포함)

### 추천 플랜 (recommended)
- DB의 `is_recommended` 필드 기반으로 결정
- 기본값: STARTER 플랜이 추천 플랜 (`recommended: true`)
- 프론트엔드에서 "인기" 뱃지 표시에 활용

## 엣지 케이스

### 1. 잘못된 locale 입력
```
GET /api/v1/plans?locale=invalid
```
- **처리**: 기본값 `ko`로 fallback
- **동작**: 정상 응답 (한국어 정보 반환)

### 2. plan_code 대소문자 무관
```
GET /api/v1/plans/starter
GET /api/v1/plans/STARTER
GET /api/v1/plans/Starter
```
- **처리**: 모두 동일하게 처리 (내부적으로 소문자 변환)
- **동작**: 정상 응답

### 3. 존재하지 않는 plan_code
```
GET /api/v1/plans/enterprise
```
- **처리**: 404 Not Found 반환
- **응답**: `{ "error": "Plan 'enterprise' not found" }`

### 4. include_properties 다양한 입력
```
include_properties=false  → features 제외
include_properties=true   → features 포함
include_properties=0      → features 포함 (문자열 'false'가 아니므로)
(파라미터 없음)           → features 포함 (기본값)
```

### 5. 캐싱 동작
- planService는 메모리 캐시 사용 (TTL: 1시간)
- 플랜 정보 변경 시 최대 1시간 후 자동 반영
- 즉시 반영 필요 시 서버 재시작 또는 캐시 클리어 API 호출 필요

## 데이터베이스 스키마
플랜 데이터는 다음 테이블에 저장됩니다:
- **tb_plans**: 플랜 기본 정보 (이름, 가격, 설명 등)
- **tb_plan_properties**: 플랜별 속성 (DM 한도, 통계 보관 일수, CTA 지원 등)

자세한 스키마 정보는 [/docs/dba/plans-schema.md](/docs/dba/plans-schema.md)를 참조하세요.

## 관련 API
- [Subscriptions API](./subscriptions-api.md) - 사용자 구독 관리
- [Usage API](./usage-api.md) - DM 사용량 조회
- [Payments API](./payments-api.md) - 결제 및 청구 관리

## 구현 상세

### 파일 구조
```
api/src/
├── controllers/
│   └── planController.js       # 컨트롤러 (요청/응답 처리)
├── routes/
│   └── planRoutes.js           # 라우트 정의
├── services/
│   └── planService.js          # 비즈니스 로직 (캐싱, DB 조회)
├── models/
│   ├── Plan.js                 # tb_plans 모델
│   └── PlanProperty.js         # tb_plan_properties 모델
└── utils/
    └── pricing.js              # 플랜 헬퍼 함수
```

### 주요 함수
- `planController.getPlans()`: 플랜 목록 조회 컨트롤러
- `planController.getPlanByCode()`: 플랜 상세 조회 컨트롤러
- `planService.getAllPlans(locale)`: DB에서 모든 플랜 조회 (캐싱)
- `planService.getPlanByCode(planCode)`: 특정 플랜 조회

### 성능 최적화
1. **메모리 캐싱**: planService에서 1시간 TTL 캐시 적용
2. **Eager Loading**: Plan과 PlanProperty를 한 번에 조회
3. **인덱싱**: plan_code에 UNIQUE 인덱스 설정

## 테스트 시나리오

### 기본 테스트
```bash
# 1. 전체 플랜 목록 조회 (한국어)
curl http://localhost:8000/api/v1/plans

# 2. 영어로 플랜 목록 조회
curl http://localhost:8000/api/v1/plans?locale=en

# 3. 속성 제외 플랜 목록 조회
curl http://localhost:8000/api/v1/plans?include_properties=false

# 4. 특정 플랜 상세 조회
curl http://localhost:8000/api/v1/plans/starter

# 5. 대소문자 무관 조회
curl http://localhost:8000/api/v1/plans/STARTER
curl http://localhost:8000/api/v1/plans/Starter

# 6. 존재하지 않는 플랜 조회 (404)
curl http://localhost:8000/api/v1/plans/invalid
```

### 인증 테스트
```bash
# 로그인 사용자 - isCurrent 플래그 포함
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  http://localhost:8000/api/v1/plans
```

## 변경 이력
| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2024-01-17 | 1.0.0 | 초기 API 구현 및 문서화 |
