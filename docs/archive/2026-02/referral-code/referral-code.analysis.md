# Gap Analysis: referral-code (v2 - 양쪽 쿠폰 발급 반영)

## Analysis Summary

- **Analysis Date**: 2026-02-09
- **Overall Match Rate**: 93% (PASS)
- **Architecture Compliance**: 100%
- **Convention Compliance**: 100%

## Score by Category

| Category | Score | Status |
|----------|:-----:|:------:|
| API Endpoint | 100% | PASS |
| Data Model | 100% | PASS |
| Service Layer | 92% | PASS |
| Controller | 100% | PASS |
| Route | 100% | PASS |
| Error Code | 95% | PASS |
| Frontend UI | 95% | PASS |
| i18n | 90% | PASS |
| Migration | 100% | PASS |
| Webhook Integration | 100% | PASS |
| Quota Integration | 100% | PASS |
| Scheduler | 100% | PASS |

## Primary Gap: issueCoupon 양쪽 발급

| 항목 | 설계 | 구현 | 영향도 |
|------|------|------|--------|
| 쿠폰 수령자 | 피추천인만 (1건) | 피추천인 + 추천인 (2건) | Medium |
| referrer 쿠폰 에러 처리 | N/A | 별도 try-catch, UniqueConstraint 안전 처리 | Low |
| 반환값 | 단일 쿠폰/null | refereeCoupon만 반환 (referrer는 fire-and-forget) | Low |

## Missing (설계 O, 구현 X) - 3건, 모두 Low

| 항목 | 설명 | 비고 |
|------|------|------|
| OAuth welcome modal | 가입 시 추천코드 입력 모달 | 의도적 미구현 (설정 페이지 대체) |
| `coupon.empty` i18n 키 | 쿠폰 없음 메시지 | 섹션 자체가 숨겨짐 |
| `coupon.errors.*` i18n 키 | 쿠폰 에러 3개 키 | API 에러 메시지 직접 사용 |

## Added (설계 X, 구현 O) - 6건

| 항목 | 설명 | 비고 |
|------|------|------|
| 추천인 쿠폰 발급 | issueCoupon에서 양쪽 발급 | 비즈니스 확장 |
| `registerSuccess` i18n | 등록 성공 토스트 | UX 개선 |
| `registerFailed` i18n | 등록 실패 토스트 | UX 개선 |
| `coupon.applyFailed` i18n | 적용 실패 토스트 | UX 개선 |
| Scheduler timezone | `Asia/Seoul` 명시 | 운영 개선 |
| `executeCouponExpiry()` export | 수동 실행/테스트용 | 테스트성 개선 |

## Changed (설계 != 구현) - 6건

| 항목 | 설계 | 구현 | 영향도 |
|------|------|------|--------|
| issueCoupon 수령자 | 피추천인만 | 양쪽 모두 | Medium |
| 에러코드 네이밍 | `INVALID_REFERRAL_CODE` 등 | `REFERRAL_INVALID_CODE` 등 (prefix 통일) | Low |
| `registeredMessage` | `{name} 님의 추천으로 가입` | `추천인이 등록되어 있습니다` (정적) | Low |
| `isValidUserCode` | regex만 | typeof + regex (방어적) | Low |
| `setReferrer` 검증 순서 | format→self→already→exists | format→user→already→self→exists | Low |
| Migration placeholder | 위치 기반 `?` | 이름 기반 `:code` | Low |

## Recommendation

설계 문서에 양쪽 쿠폰 발급 변경사항을 반영하면 Match Rate 97%+ 달성 가능.
