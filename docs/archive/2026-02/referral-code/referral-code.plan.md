# Plan: 추천인 코드 시스템 (referral-code)

> **Phase**: Plan
> **Created**: 2026-02-08
> **PRD Reference**: `docs/prd-referral-system.md` (v1.3 기반, 보상 방식 전면 변경)
> **Status**: Phase 1~2 구현 완료, Phase 3 확정

---

## 1. 목표

사용자 추천 프로그램을 통해 바이럴 마케팅을 유도한다.
피추천인의 최초 유료 결제 시 **피추천인에게 DM 발송량 보너스 쿠폰**을 자체 발급한다.

## 2. 보상 방식 변경 경위

### 검토한 방식들과 탈락 이유

| 방식 | 결과 | 탈락 이유 |
|------|------|---------|
| 적립금 + 부분환불 (PRD v1.3) | 탈락 | 복잡도 높음 (원장, 정합성 배치, 수수료 손실) |
| LemonSqueezy % 할인 쿠폰 | 탈락 | **기존 구독 자동 갱신에 쿠폰 적용 불가** (Update Subscription API에 discount 필드 없음) |
| **자체 DM 발송량 쿠폰** | **채택** | LemonSqueezy 의존성 없음, 자체 통제 가능, 사용자가 원할 때 적용 |

### 확정된 방향
- **보상 형태**: DM 발송량 추가 쿠폰 (자체 발급/관리)
- **보상 대상**: 피추천인만
- **보상 시점**: 피추천인 최초 유료 결제 시 1회
- **적용 시점**: 사용자가 "사용 시작" 버튼 클릭 시 현재 월에 즉시 적용
- **보상량**: 기본 100건 (env로 조정 가능)
- **유효기간**: 발급일로부터 30일 (env로 조정 가능)
- **복수 적용**: 가능 (여러 쿠폰 동시 적용)
- **UI 위치**: 설정 페이지 추천 섹션 내
- **LemonSqueezy 연동**: 없음 (결제 시스템과 완전 분리)

## 3. 현재 상태 분석

### 3.1 존재하는 것
- LemonSqueezy 결제 연동 완료 (`lemonSqueezyService.js`)
- 웹훅 처리 파이프라인 (`lemonSqueezyWebhookService.js`)
- User 모델 (`tb_users`) - 추천인 관련 컬럼 없음
- MonthlyUsage 모델 (`tb_monthly_usage`) - 월별 사용량 관리
- 구독/결제 플로우 구현 완료

### 3.2 필요한 것
- `tb_users`: `user_code`, `referrer_user_seq` 컬럼 추가
- 자체 쿠폰 테이블 (발급/사용 이력)
- 추천인 코드 입력 API
- 쿠폰 발급/적용 API
- 프론트엔드 UI (추천인 코드 입력, 유저코드 조회, 쿠폰 관리)

## 4. 구현 범위

### 4.1 확정 (변경 없음)
| # | 기능 | 우선순위 |
|---|------|---------|
| 1 | DB: `tb_users`에 `user_code`, `referrer_user_seq` 추가 | 필수 |
| 2 | 유저코드 자동 생성 (`[A-Z0-9]{8}`, 회원가입 시) | 필수 |
| 3 | 기존 회원 유저코드 일괄 생성 마이그레이션 | 필수 |
| 4 | 추천인 코드 입력 API (`POST /api/referrals/set-referrer`) | 필수 |
| 5 | 프론트: 내 유저코드 조회 + 복사 | 필수 |
| 6 | 프론트: 추천인 코드 입력 (설정 페이지 + OAuth 모달) | 필수 |

### 4.2 확정 (Phase 3 - 쿠폰 보상)
| # | 기능 | 상세 |
|---|------|------|
| 7 | 쿠폰 테이블 (`tb_referral_coupons`) | 발급/사용 이력 관리 |
| 8 | 쿠폰 발급 (피추천인 최초 결제 시) | 웹훅 `isFirstPayment` 트리거, +100건 (env), 30일 유효 (env) |
| 9 | 쿠폰 적용 (사용자 "사용 시작" 클릭) | 현재 월 `tb_monthly_usage.bonus_dm_count`에 즉시 반영 |
| 10 | 복수 쿠폰 동시 적용 | 여러 쿠폰을 한 번에 적용 가능 |
| 11 | 프론트: 쿠폰 목록 + 적용 UI | 설정 페이지 추천 섹션 내 |

### 4.3 제거 (이전 방식)
- ~~적립금 시스템 (tb_referral_ledger, total_referral_credit)~~
- ~~LemonSqueezy Discount API 연동~~
- ~~부분 환불 (Refund API)~~
- ~~정합성 배치 검증~~

## 5. 기술 결정사항

### 5.1 유저코드 생성 (확정)
- 형식: `[A-Z0-9]{8}` (36^8 = 약 28억 조합)
- 중복 시 최대 10회 재시도
- DB UNIQUE 인덱스로 최종 보장

### 5.2 보상 방식: 자체 DM 발송량 쿠폰 (확정)
- **장점**: LemonSqueezy 의존 없음, 수수료 손실 없음, 사용자가 원할 때 적용
- **보상 대상**: 피추천인만
- **보상량**: 기본 100건 (`REFERRAL_COUPON_DM_AMOUNT`, env 설정 가능)
- **유효기간**: 발급일로부터 30일 (`REFERRAL_COUPON_EXPIRY_DAYS`, env 설정 가능)
- **복수 적용**: 가능 (보유 쿠폰 여러 개 동시 적용)
- **적용 방식**: 사용자가 "사용 시작" 버튼 클릭 → 현재 월 `bonus_dm_count`에 즉시 반영
- **발급 트리거**: `lemonSqueezyWebhookService.js` → `handleSubscriptionPaymentSuccess()` → `isFirstPayment === true`
- **쿼터 체크 통합**: `quotaService.checkQuota()`에서 `quota + bonus_dm_count` 합산

## 6. 대략적 구현 순서

```
Phase 1: DB + 유저코드 (2일) ← 확정, 바로 착수 가능
  ├── tb_users ALTER (user_code, referrer_user_seq)
  ├── User.js 모델 업데이트
  ├── 유저코드 생성 유틸
  ├── 회원가입 서비스 통합
  └── 기존 회원 마이그레이션

Phase 2: 추천인 코드 입력 (1일) ← 확정, 바로 착수 가능
  ├── POST /api/referrals/set-referrer API
  ├── 검증 (존재, 본인, 중복)
  └── 프론트: 설정 페이지 + OAuth 모달

Phase 3: 쿠폰 발급/적용 (확정)
  ├── tb_referral_coupons 테이블 + 마이그레이션
  ├── tb_monthly_usage.bonus_dm_count 컬럼 추가
  ├── couponService.js (발급/적용/만료 로직)
  ├── 웹훅 통합 (isFirstPayment → 쿠폰 자동 발급)
  ├── quotaService 통합 (quota + bonus 합산)
  ├── 쿠폰 API (조회, 적용)
  └── 프론트: 설정 페이지 쿠폰 목록 + 사용 시작 UI
```

## 7. 위험 요소

| 위험 | 영향 | 완화 |
|------|------|------|
| 유저코드 생성 충돌 | 낮음 | 10회 재시도 + UNIQUE 인덱스 |
| 웹훅 중복 → 쿠폰 중복 지급 | 중간 | 추천인-피추천인 쌍 UNIQUE 인덱스 |
| 쿠폰 남용 (다계정) | 중간 | IP/디바이스 기반 제한 검토 |

## 8. 성공 지표

| 지표 | 목표 |
|------|------|
| 추천 가입률 | 신규 가입자 중 20% |
| 추천인당 평균 추천 수 | 3명 |
| 쿠폰 사용률 | 70% |
| 추천 전환율 (가입 → 유료) | 15% |

---

## 9. Phase 3 상세 정의

### 9.1 핵심 결정 요약

| 항목 | 결정 | 비고 |
|------|------|------|
| 보상 대상 | 피추천인만 | 추천인은 미포함 |
| 보상량 | +100건 DM | env `REFERRAL_COUPON_DM_AMOUNT` (기본 100) |
| 유효기간 | 발급일+30일 | env `REFERRAL_COUPON_EXPIRY_DAYS` (기본 30) |
| 발급 시점 | 피추천인 최초 유료 결제 | `isFirstPayment === true` |
| 적용 방식 | 사용자 "사용 시작" 클릭 | 현재 월 즉시 반영 |
| 복수 적용 | 가능 | 여러 쿠폰 동시 적용 OK |
| 보유 제한 | 없음 (유효기간으로 자연 소멸) | - |
| UI 위치 | 설정 > 추천 섹션 | 기존 추천 코드 UI 아래 |

### 9.2 DB 설계 방향

**새 테이블**: `tb_referral_coupons`
- 쿠폰 발급/사용 이력 관리
- 피추천인-추천인 쌍 UNIQUE 인덱스 (중복 발급 방지)
- 상태: AVAILABLE → USED / EXPIRED

**기존 테이블 수정**: `tb_monthly_usage`
- `bonus_dm_count` 컬럼 추가 (쿠폰으로 추가된 DM 발송량)
- `quotaService.checkQuota()`에서 `quota + bonus_dm_count` 합산

### 9.3 서비스 설계 방향

**새 서비스**: `couponService.js`
- `issueCoupon(refereeUserSeq)` - 피추천인에게 쿠폰 발급
- `applyCoupons(userSeq, couponSeqs[])` - 선택한 쿠폰들 적용 (현재 월 bonus_dm_count에 합산)
- `getUserCoupons(userSeq)` - 보유 쿠폰 목록 조회
- `expireCoupons()` - 만료 쿠폰 일괄 처리 (스케줄러/배치)

**기존 서비스 수정**:
- `lemonSqueezyWebhookService.js` → `handleSubscriptionPaymentSuccess()` 내 `isFirstPayment` 분기에 쿠폰 발급 호출 추가
- `quotaService.js` → `checkQuota()`, `incrementDmCount()`에서 bonus_dm_count 합산
- `usageService.js` → `getCurrentUsage()`에서 bonus_dm_count 포함 반환

### 9.4 API 설계 방향

| 메서드 | 엔드포인트 | 설명 |
|--------|-----------|------|
| GET | `/api/referrals/coupons` | 내 쿠폰 목록 조회 |
| POST | `/api/referrals/coupons/apply` | 쿠폰 적용 (사용 시작) |

### 9.5 프론트엔드 설계 방향

설정 페이지 추천 섹션 내 쿠폰 영역:
```
┌─────────────────────────────────────────┐
│ [기존] 내 추천 코드: XYZ98765 [복사]     │
│ [기존] 추천인 코드 입력 / 등록 완료 상태   │
├─────────────────────────────────────────┤
│ 보너스 쿠폰 (2개 보유)                    │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ DM +100건  만료: 2026-03-10        │ │
│ │ [사용 시작]                         │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ DM +100건  만료: 2026-03-15        │ │
│ │ [사용 시작]                         │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ * 사용 시 현재 월 DM 한도에 즉시 추가됩니다 │
└─────────────────────────────────────────┘
```

### 9.6 env 설정값

```env
# 추천 쿠폰 설정
REFERRAL_COUPON_DM_AMOUNT=100       # 쿠폰당 추가 DM 발송량
REFERRAL_COUPON_EXPIRY_DAYS=30      # 쿠폰 유효기간 (일)
```

---

> **Next Step**: `/pdca design referral-code` (Phase 3 상세 설계) → `/pdca do referral-code` (Phase 3 구현)
