# 추천인 시스템 PRD

## 1. 개요

### 1.1 목적
사용자 추천 프로그램을 통해 자연스러운 바이럴 마케팅을 유도하고, 추천인과 피추천인 모두에게 혜택을 제공하여 사용자 기반을 확대하고 고객 유지율을 향상시킵니다.

### 1.2 범위

**포함 범위:**
- 유저코드(추천인 코드) 자동 생성 시스템
- 기존 회원 대상 유저코드 일괄 생성 마이그레이션
- 회원가입 시 추천인 코드 입력 기능
- 설정 페이지에서 추천인 코드 입력 기능
- 추천인 리워드 적립 시스템 (최초 결제 + 월별 갱신)
- 적립금 자동 사용 시스템 (결제 시 차감)
- 추천인 대시보드 (내 추천 현황 조회)
- 관리자 추천인 통계 페이지

**제외 범위:**
- 적립금 현금 환급 기능
- 추천인 랭킹 시스템
- 추천인 코드 커스터마이징 기능
- 추천인별 다단계(2단계 이상) 보상 시스템

**향후 계획:**
- 추천인 코드 분석 및 전환율 추적
- 추천 이벤트 및 프로모션 기능
- 소셜 공유 기능 (카카오톡, 트위터 등)

### 1.3 이해관계자
- **제품 책임자**: 비즈니스 요구사항 정의 및 승인
- **백엔드 개발팀**: API 및 비즈니스 로직 구현
- **프론트엔드 개발팀**: UI/UX 구현
- **DBA**: 데이터베이스 스키마 설계 및 마이그레이션
- **사용자**: 추천인 및 피추천인

---

## 2. 사용자 스토리

### 주요 사용자 페르소나

**페르소나 1: 신규 가입자 (피추천인)**
- 역할: 서비스에 처음 가입하는 사용자
- 목표: 추천인 코드를 입력하여 가입 (선택사항)
- 불만 사항: 추천인 코드를 나중에 입력할 수 없음

**페르소나 2: 기존 무료 사용자**
- 역할: FREE 플랜을 사용 중인 기존 회원
- 목표: 유료 플랜 전환 시 추천인 코드 입력을 통해 혜택 제공
- 불만 사항: 추천인 코드를 입력할 기회가 없음

**페르소나 3: 추천인**
- 역할: 다른 사용자를 추천하고 리워드를 받는 사용자
- 목표: 내 유저코드를 공유하여 적립금을 받고, 추천 현황을 확인
- 불만 사항: 추천 실적과 적립금 내역이 투명하게 보이지 않음

**페르소나 4: 관리자**
- 역할: 추천인 프로그램 운영 및 모니터링
- 목표: 추천인 통계, 적립금 현황, 이상 패턴 감지
- 불만 사항: 추천인 데이터 조회가 어려움

### 사용자 스토리 목록

---

**에픽 1: 유저코드 생성 및 관리**

#### US-001: 신규 회원가입 시 유저코드 자동 생성
**사용자 스토리:**
- 신규 가입자로서
- 회원가입과 동시에 고유한 8자리 유저코드(A-Z0-9)를 자동으로 받고 싶습니다
- 그래서 다른 사람에게 나를 추천할 수 있는 코드를 즉시 사용할 수 있습니다

**수락 기준:**
- [ ] 회원가입 완료 시(`tb_users` INSERT) 유저코드가 자동 생성됩니다
- [ ] 유저코드는 정규식 `[A-Z0-9]{8}` 형식을 따릅니다 (대문자 영문 + 숫자 8자리)
- [ ] 생성된 유저코드는 전체 시스템에서 유니크해야 합니다
- [ ] 유저코드 생성 실패 시 최대 10회까지 재시도합니다
- [ ] 10회 재시도 후에도 실패하면 에러를 발생시킵니다

**우선순위:** 필수
**예상 공수:** 2일
**종속성:** 없음

---

#### US-002: 기존 회원 유저코드 일괄 생성
**사용자 스토리:**
- 관리자로서
- 기존에 가입한 모든 회원들에게 유저코드를 일괄 생성하고 싶습니다
- 그래서 모든 사용자가 추천인 프로그램에 참여할 수 있도록 합니다

**수락 기준:**
- [ ] 유저코드가 없는 모든 기존 회원(`user_code IS NULL`)에게 유저코드를 생성합니다
- [ ] 유저코드 중복 체크를 수행하고, 중복 시 재생성합니다
- [ ] 마이그레이션 스크립트는 트랜잭션으로 안전하게 처리됩니다
- [ ] 생성 결과(성공/실패)를 로그로 기록합니다
- [ ] 대량 데이터 처리 시 배치 단위(1000명씩)로 처리합니다

**우선순위:** 필수
**예상 공수:** 1일
**종속성:** US-001 완료 후

---

#### US-003: 내 유저코드 조회
**사용자 스토리:**
- 로그인한 사용자로서
- 내 유저코드를 확인하고 복사할 수 있어야 합니다
- 그래서 다른 사람에게 쉽게 공유할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 내 유저코드를 확인할 수 있습니다
- [ ] "복사하기" 버튼을 클릭하면 클립보드에 복사됩니다
- [ ] 복사 성공 시 토스트 메시지를 표시합니다
- [ ] 유저코드는 읽기 전용으로 표시됩니다 (수정 불가)

**우선순위:** 필수
**예상 공수:** 0.5일
**종속성:** US-001 완료 후

---

**에픽 2: 추천인 코드 입력**

#### US-004: 회원가입 시 추천인 코드 입력
**사용자 스토리:**
- 신규 가입자로서
- 회원가입 시 추천인 코드를 입력할 수 있어야 합니다
- 그래서 나를 추천한 사람이 리워드를 받을 수 있습니다

**수락 기준:**
- [ ] 회원가입 폼에 "추천인 코드 (선택사항)" 필드가 표시됩니다
- [ ] 추천인 코드는 선택사항이며, 입력하지 않아도 가입이 가능합니다
- [ ] 입력한 추천인 코드가 존재하지 않으면 에러 메시지를 표시합니다 ("유효하지 않은 추천인 코드입니다")
- [ ] 본인의 유저코드를 입력하면 에러 메시지를 표시합니다 ("본인의 추천인 코드는 사용할 수 없습니다")
- [ ] 회원가입 완료 시 `tb_users.referrer_user_seq`에 추천인의 seq를 저장합니다
- [ ] 추천인 코드는 대소문자를 구분하지 않습니다 (자동으로 대문자로 변환)

**우선순위:** 필수
**예상 공수:** 1일
**종속성:** US-001 완료 후

---

#### US-005: 설정 페이지에서 추천인 코드 입력
**사용자 스토리:**
- 기존 회원으로서
- 회원가입 시 추천인 코드를 입력하지 않았다면, 설정 페이지에서 나중에 입력하고 싶습니다
- 그래서 추천인에게 혜택을 제공할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 "추천인 코드 입력" 섹션이 표시됩니다
- [ ] 이미 추천인 코드를 입력한 경우 "추천인: [이름]"이 표시되고 입력 필드가 숨겨집니다
- [ ] 추천인 코드를 입력하지 않은 경우에만 입력 필드가 표시됩니다
- [ ] 입력한 추천인 코드 검증 (존재 여부, 본인 여부)이 수행됩니다
- [ ] 한 번 입력한 추천인 코드는 수정할 수 없습니다
- [ ] 추천인 코드 저장 성공 시 성공 메시지를 표시합니다

**우선순위:** 필수
**예상 공수:** 1일
**종속성:** US-001, US-004 완료 후

---

**에픽 3: 추천인 리워드 적립**

#### US-006: 유료 결제 성공 시 추천인 리워드 적립
**사용자 스토리:**
- 추천인으로서
- 내가 추천한 사용자의 유료 플랜 결제가 성공할 때마다 실 결제 금액의 5%를 적립금으로 받고 싶습니다
- 그래서 추천 활동에 대한 지속적인 보상을 받을 수 있습니다

**수락 기준:**
- [ ] 피추천인의 유료 플랜 결제가 성공할 때마다(`subscription_payment_success` 웹훅) 리워드를 적립합니다
- [ ] 최초 결제, 월별 갱신, 플랜 변경 등 모든 성공 결제에 대해 적립합니다
- [ ] 리워드는 실 결제 금액(`amount`)의 5%입니다 (소수점 버림)
- [ ] 적립금은 `tb_referral_ledger` 테이블에 `type='earn'`으로 기록됩니다
- [ ] 적립 성공 시 추천인의 `tb_users.total_referral_credit`을 업데이트합니다
- [ ] 적립 실패 시 로그를 남기고, 재시도 로직을 수행합니다
- [ ] `payment_transaction_seq` 기준 UNIQUE 인덱스로 동일 결제에 대한 중복 적립을 방지합니다

**우선순위:** 필수
**예상 공수:** 2일
**종속성:** US-004, US-005 완료 후

---

#### US-008: ~~피추천인 탈퇴 시 적립금 삭제~~ (삭제됨)

> **변경사항**: 피추천인이 탈퇴하더라도 추천인에게 이미 적립된 리워드는 유지합니다. 별도 처리 불필요.

---

**에픽 4: 적립금 사용**

#### US-009: 유료 플랜 결제 시 적립금 자동 사용
**사용자 스토리:**
- 적립금이 있는 사용자로서
- 유료 플랜 결제 시 적립금이 자동으로 사용되어 결제 금액이 차감되기를 원합니다
- 그래서 별도의 설정 없이 자동으로 할인 혜택을 받을 수 있습니다

**수락 기준:**
- [ ] 유료 플랜 결제 시 사용자의 `total_referral_credit`을 확인합니다
- [ ] 적립금 사용 한도는 **플랜 금액의 최대 50%**입니다
- [ ] 적립금이 플랜 금액의 50% 이상이면 50%만 사용하고 나머지는 PG로 결제합니다
- [ ] 적립금이 플랜 금액의 50% 미만이면 적립금 전액을 사용하고 나머지를 PG로 결제합니다
- [ ] 적립금 전액(100%) 결제는 불가합니다 — 최소 50%는 PG 결제 필요
- [ ] 적립금 사용 내역은 `tb_referral_ledger` 테이블에 `type='use'`로 기록됩니다
- [ ] `tb_payment_transactions.credit_used_amount`에 사용된 적립금을 기록합니다
- [ ] 적립금 사용 후 `tb_users.total_referral_credit`을 업데이트합니다

**우선순위:** 필수
**예상 공수:** 2일
**종속성:** US-006, US-007 완료 후

---

#### US-010: 적립금 사용 내역 조회
**사용자 스토리:**
- 사용자로서
- 내가 언제, 얼마의 적립금을 사용했는지 조회하고 싶습니다
- 그래서 적립금 사용 내역을 투명하게 확인할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 "적립금 사용 내역" 섹션이 표시됩니다
- [ ] 사용 날짜, 사용 금액, 결제 내역이 리스트로 표시됩니다
- [ ] 페이지네이션 또는 무한 스크롤로 내역을 로드합니다
- [ ] 최신 내역이 먼저 표시됩니다

**우선순위:** 중요
**예상 공수:** 1일
**종속성:** US-009 완료 후

---

**에픽 5: 추천인 대시보드**

#### US-011: 내 추천 현황 조회
**사용자 스토리:**
- 추천인으로서
- 내가 추천한 사람 수, 누적 적립금, 현재 사용 가능한 적립금을 한눈에 보고 싶습니다
- 그래서 추천 활동의 성과를 확인할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에 "내 추천 현황" 섹션이 표시됩니다
- [ ] 다음 정보가 표시됩니다:
  - 총 추천 인원 (현재 활성 회원 수)
  - 누적 적립금 (전체 적립된 금액)
  - 사용 가능한 적립금 (현재 잔액)
  - 사용한 적립금 (총 사용 금액)
- [ ] 통계는 실시간으로 계산되거나 캐싱됩니다

**우선순위:** 중요
**예상 공수:** 1.5일
**종속성:** US-006, US-007, US-009 완료 후

---

#### US-012: 추천 적립 내역 조회
**사용자 스토리:**
- 추천인으로서
- 언제, 누구로부터, 얼마의 적립금을 받았는지 상세 내역을 보고 싶습니다
- 그래서 적립 내역을 투명하게 확인할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 "적립 내역" 섹션이 표시됩니다
- [ ] 적립 날짜, 적립 금액이 리스트로 표시됩니다
- [ ] 피추천인의 이름은 개인정보 보호를 위해 마스킹 처리합니다 (예: "홍*동")
- [ ] 최신 내역이 먼저 표시됩니다
- [ ] 페이지네이션 또는 무한 스크롤로 내역을 로드합니다

**우선순위:** 중요
**예상 공수:** 1.5일
**종속성:** US-006, US-007 완료 후

---

**에픽 6: 관리자 기능**

#### US-013: 관리자 추천인 통계 조회
**사용자 스토리:**
- 관리자로서
- 전체 추천인 통계(총 추천 건수, 총 적립금, 상위 추천인 등)를 조회하고 싶습니다
- 그래서 추천인 프로그램의 성과를 모니터링할 수 있습니다

**수락 기준:**
- [ ] 관리자 페이지에 "추천인 통계" 메뉴가 추가됩니다
- [ ] 다음 정보가 표시됩니다:
  - 전체 추천 건수
  - 전체 적립금 총액
  - 상위 추천인 TOP 10 (추천 인원 기준)
  - 상위 추천인 TOP 10 (적립금 기준)
  - 월별 추천 트렌드 차트
- [ ] 날짜 범위 필터를 지원합니다
- [ ] 데이터는 CSV로 다운로드 가능합니다

**우선순위:** 선택 사항
**예상 공수:** 2일
**종속성:** US-006, US-007 완료 후

---

## 3. 기능 명세

### 3.1 기능 상세

#### 기능 1: 유저코드 생성

**설명:**
모든 사용자는 회원가입 시 A-Z0-9 조합의 8자리 유니크한 유저코드를 자동으로 받습니다. 이 코드는 다른 사용자에게 추천인 코드로 공유될 수 있습니다.

**입력값:**
- 필수: 없음 (시스템이 자동 생성)

**출력값:**
- 성공: 8자리 유저코드 (예: `A1B2C3D4`)
- 실패: 중복 코드 생성 시 재시도, 10회 초과 시 에러 발생

**비즈니스 규칙:**
1. 유저코드는 대문자 영문(A-Z) + 숫자(0-9) 8자리로 구성됩니다
2. 유저코드는 전체 시스템에서 유니크해야 합니다
3. 중복 발생 시 최대 10회까지 재생성을 시도합니다
4. 유저코드는 한 번 생성되면 변경할 수 없습니다
5. 대소문자를 구분하지 않으며, 항상 대문자로 저장됩니다

**엣지 케이스:**
- 케이스 1: 10회 재시도 후에도 유니크한 코드를 생성하지 못한 경우 → 에러 로그 기록 후 500 에러 반환, 관리자에게 알림 발송
- 케이스 2: 동시에 여러 사용자가 회원가입하여 코드 충돌 가능성 → DB 유니크 인덱스로 방지, 충돌 시 재생성

---

#### 기능 2: 추천인 코드 입력

**설명:**
사용자는 회원가입 시 또는 설정 페이지에서 추천인 코드를 입력할 수 있습니다. 추천인 코드는 다른 사용자의 유저코드입니다.

**입력값:**
- 필수: `referral_code` (string, 8자리, A-Z0-9)

**출력값:**
- 성공: 추천인 정보 저장 완료, 추천인 이름 반환
- 실패:
  - "유효하지 않은 추천인 코드입니다" (코드가 존재하지 않음)
  - "본인의 추천인 코드는 사용할 수 없습니다" (본인 코드 입력)
  - "이미 추천인 코드를 입력하셨습니다" (중복 입력 시도)

**비즈니스 규칙:**
1. 추천인 코드는 선택사항입니다 (입력하지 않아도 가입 가능)
2. 추천인 코드는 대소문자를 구분하지 않습니다
3. 본인의 유저코드를 입력할 수 없습니다
4. 한 번 입력한 추천인 코드는 수정할 수 없습니다
5. 회원가입 후 설정 페이지에서 언제든 입력할 수 있습니다 (아직 입력하지 않은 경우)

**엣지 케이스:**
- 케이스 1: 존재하지 않는 코드 입력 → "유효하지 않은 추천인 코드입니다" 에러 메시지
- 케이스 2: 본인 코드 입력 → "본인의 추천인 코드는 사용할 수 없습니다" 에러 메시지
- 케이스 3: 이미 추천인 코드를 입력한 사용자가 다시 입력 시도 → "이미 추천인 코드를 입력하셨습니다" 에러 메시지
- 케이스 4: 탈퇴한 사용자의 코드 입력 → "유효하지 않은 추천인 코드입니다" 에러 메시지

---

#### 기능 3: 추천인 리워드 적립

**설명:**
피추천인이 유료 플랜을 최초 결제하거나 월별 갱신할 때, 추천인에게 실 결제 금액의 5%를 적립금으로 지급합니다.

**입력값:**
- 필수:
  - `referred_user_seq` (피추천인 user_seq)
  - `payment_transaction_seq` (결제 거래 seq)
  - `payment_amount` (실 결제 금액)

**출력값:**
- 성공: 적립금 지급 완료, 적립 금액 반환
- 실패: 에러 로그 기록 및 재시도

**비즈니스 규칙:**
1. 리워드는 실 결제 금액(`tb_payment_transactions.amount`)의 5%입니다
2. 결제가 성공할 때마다 적립합니다 (`reward_type = 'payment'`) — 최초/갱신 구분 없음
3. 적립금은 소수점 버림 처리합니다 (예: 10,000원의 5% = 500원)
4. 적립 한도나 제한은 없습니다
5. LemonSqueezy 웹훅(`subscription_payment_success`) 수신 시 적립 처리
6. 결제 성공 시에만 적립합니다 (`status = 'completed'`)
7. 동일 결제에 대한 중복 적립 방지 (`payment_transaction_seq` UNIQUE)

**엣지 케이스:**
- 케이스 1: 피추천인이 결제 직후 즉시 탈퇴 → 탈퇴 처리 시 적립금 삭제 (US-008)
- 케이스 2: 피추천인이 플랜 취소 후 재가입 → 플랜 취소 시 적립금 유지, 재가입 후 결제 성공 시 다시 적립
- 케이스 3: 피추천인이 플랜 다운그레이드 → 다운그레이드된 금액 기준으로 5% 적립
- 케이스 4: 웹훅 중복 수신 → `payment_transaction_seq`를 기준으로 중복 적립 방지
- 케이스 5: 적립금 계산 오류 → 에러 로그 기록, 관리자 알림 발송

---

#### 기능 4: 적립금 자동 사용

**설명:**
유료 플랜 결제 시 사용자의 적립금을 자동으로 사용하여 결제 금액을 차감합니다.

**입력값:**
- 필수:
  - `user_seq` (사용자 seq)
  - `plan_amount` (플랜 금액)

**출력값:**
- 성공:
  - `credit_used_amount` (사용된 적립금)
  - `final_payment_amount` (실제 결제 금액)
- 실패: 적립금 차감 오류

**비즈니스 규칙:**
1. 적립금은 자동으로 사용됩니다 (최대 플랜 금액의 50%까지)
2. 적립금 전액(100%) 결제는 불가합니다 — 최소 50%는 PG 결제 필요
3. 적립금이 플랜 금액의 50% 이상이면, 50%만 적립금 사용 + 50% PG 결제
4. 적립금이 플랜 금액의 50% 미만이면, 적립금 전액 사용 + 나머지 PG 결제
5. 적립금 사용 후 잔액은 `tb_users.total_referral_credit`에 반영됩니다
6. 적립금 사용 내역은 `tb_referral_ledger` 테이블에 `type='use'`로 기록됩니다
7. 적립금 유효기간은 없습니다

**엣지 케이스:**
- 케이스 1: 적립금 10,000원, 플랜 금액 9,900원 → 최대 4,950원 사용, PG 결제 4,950원, 잔액 5,050원
- 케이스 2: 적립금 3,000원, 플랜 금액 9,900원 → 3,000원 사용 (50% 한도인 4,950원 미만이므로 전액 사용), PG 결제 6,900원
- 케이스 3: 적립금이 0원 → 전액 PG 결제
- 케이스 4: 적립금 차감 중 오류 발생 → 트랜잭션 롤백, 결제 실패 처리

---

### 3.2 화면/UI 요구사항

#### 화면 1: 회원가입 페이지

**위치:** `/signup` 또는 `/register`
**구성요소:**
- 이메일 입력 필드
- 비밀번호 입력 필드
- 이름 입력 필드
- **추천인 코드 입력 필드 (선택사항)** ← 신규 추가
  - 플레이스홀더: "추천인 코드 (선택사항)"
  - 설명 텍스트: "친구의 추천인 코드가 있다면 입력해주세요"
  - 8자리 입력 제한
  - 대소문자 자동 변환 (대문자로)
- 회원가입 버튼

**상호작용:**
- 추천인 코드 입력 시 포커스 아웃 시 유효성 검사 (실시간 검증)
- 유효하지 않은 코드 입력 시 에러 메시지 표시
- 회원가입 버튼 클릭 시 추천인 코드 포함하여 API 호출

**반응형:** 모바일/태블릿/데스크톱 지원

---

#### 화면 1-1: OAuth 가입 후 추천인 코드 입력 모달

**트리거:** Google/Instagram OAuth 가입 완료 직후
**구성요소:**
- 모달 다이얼로그
- 추천인 코드 입력 필드 (8자리, A-Z0-9)
- "등록" 버튼
- "건너뛰기" 버튼 (닫기)
- 설명 텍스트: "추천인 코드가 있다면 입력해주세요"

**상호작용:**
- OAuth 가입 완료 후 자동으로 모달 표시
- "건너뛰기" 클릭 시 모달 닫기 (추천인 미등록)
- "등록" 클릭 시 `POST /api/referrals/set-referrer` 호출
- 성공 시 모달 닫기 + 토스트 메시지
- 실패 시 에러 메시지 표시 (모달 유지)

**반응형:** 모바일/태블릿/데스크톱 지원

---

#### 화면 2: 설정 페이지 - 추천인 섹션

**위치:** `/dashboard/settings`
**구성요소:**
- **내 유저코드**
  - 유저코드 표시 (읽기 전용)
  - "복사하기" 버튼
  - 공유 가이드 텍스트: "이 코드를 친구에게 공유하세요"

- **추천인 코드 입력** (이미 입력한 경우 숨김)
  - 추천인 코드 입력 필드
  - "저장" 버튼
  - 이미 입력한 경우: "추천인: [이름]" 표시

- **내 추천 현황**
  - 총 추천 인원
  - 누적 적립금
  - 사용 가능한 적립금
  - 사용한 적립금

- **리워드 내역** (탭 또는 아코디언) — `tb_referral_ledger` 기반
  - 거래 날짜
  - 유형 (적립/사용)
  - 금액
  - 잔액
  - 페이지네이션

**상호작용:**
- 복사하기 버튼 클릭 시 클립보드에 복사, 토스트 메시지 표시
- 추천인 코드 저장 시 확인 모달 표시
- 적립 내역/사용 내역 탭 전환

**반응형:** 모바일/태블릿/데스크톱 지원

---

#### 화면 3: 관리자 - 추천인 통계 페이지

**위치:** `/admin/referrals`
**구성요소:**
- 전체 통계 카드
  - 총 추천 건수
  - 총 적립금
  - 총 사용 적립금
  - 총 잔여 적립금

- 상위 추천인 테이블
  - 순위
  - 사용자 이름 (마스킹)
  - 추천 인원
  - 누적 적립금

- 월별 추천 트렌드 차트 (Line Chart)
  - X축: 월
  - Y축: 추천 건수

- 날짜 범위 필터
- CSV 다운로드 버튼

**상호작용:**
- 날짜 범위 선택 시 통계 업데이트
- CSV 다운로드 시 필터링된 데이터 다운로드

**반응형:** 데스크톱 전용 (관리자 페이지)

---

### 3.3 API/데이터 요구사항

#### API 엔드포인트:

**1. 추천인 코드 등록**
- `POST /api/referrals/set-referrer`
- 설명: 추천인 코드 검증 및 저장 (단일 API로 처리)
- 인증: JWT 필요
- 보안: IP 기반 rate limiting 적용 (분당 10회 제한) — 유저코드 열거 공격 방지
- 참고: 별도의 유저 조회/검증 API는 제공하지 않음. 추천인 등록 API에서 검증과 저장을 함께 처리
- 요청:
  ```json
  {
    "referral_code": "A1B2C3D4"
  }
  ```
- 응답 (성공):
  ```json
  {
    "success": true,
    "message": "추천인 코드가 저장되었습니다"
  }
  ```
- 응답 (실패 - 유효하지 않은 코드):
  ```json
  {
    "success": false,
    "message": "유효하지 않은 추천인 코드입니다"
  }
  ```
- 응답 (실패 - 이미 등록):
  ```json
  {
    "success": false,
    "message": "이미 추천인 코드를 입력하셨습니다"
  }
  ```
- UI 표시: 추천인이 없는 경우 "추천인 없음"으로 표시, 입력 필드 노출

**3. 내 추천 현황 조회**
- `GET /api/referrals/my-stats`
- 설명: 내 추천 통계 조회
- 인증: JWT 필요
- 응답:
  ```json
  {
    "success": true,
    "data": {
      "user_code": "A1B2C3D4",
      "total_referrals": 10,
      "total_earned": 50000,
      "available_credit": 30000,
      "total_used": 20000
    }
  }
  ```

**4. 적립 내역 조회**
- `GET /api/referrals/rewards?page=1&limit=20`
- 설명: 내 적립 내역 조회
- 인증: JWT 필요
- 응답:
  ```json
  {
    "success": true,
    "data": {
      "rewards": [
        {
          "seq": 1,
          "reward_type": "first_payment",
          "amount": 500,
          "referred_user_name": "홍*동",
          "created_at": "2026-01-15T10:30:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 100
      }
    }
  }
  ```

**5. 적립금 사용 내역 조회**
- `GET /api/referrals/credit-usage?page=1&limit=20`
- 설명: 내 적립금 사용 내역 조회
- 인증: JWT 필요
- 응답:
  ```json
  {
    "success": true,
    "data": {
      "usage": [
        {
          "seq": 1,
          "amount": 5000,
          "payment_transaction_seq": 123,
          "used_at": "2026-01-20T14:00:00Z"
        }
      ],
      "pagination": {
        "page": 1,
        "limit": 20,
        "total": 50
      }
    }
  }
  ```

**6. 관리자 - 추천인 통계 조회**
- `GET /api/admin/referrals/stats?start_date=2026-01-01&end_date=2026-01-31`
- 설명: 전체 추천인 통계 조회
- 인증: JWT 필요 (관리자 권한)
- 응답:
  ```json
  {
    "success": true,
    "data": {
      "total_referrals": 500,
      "total_earned_credit": 2500000,
      "total_used_credit": 1000000,
      "top_referrers": [
        {
          "user_seq": 1,
          "user_name": "홍*동",
          "total_referrals": 50,
          "total_earned": 250000
        }
      ],
      "monthly_trend": [
        {
          "month": "2026-01",
          "referral_count": 100
        }
      ]
    }
  }
  ```

**7. 회원가입 시 추천인 코드 등록**
- 별도 API 없음. 위 `POST /api/referrals/set-referrer`를 동일하게 사용
- 가입 완료 → 로그인 → 온보딩 또는 설정에서 추천인 코드 입력 → `set-referrer` API 호출
- Google/Instagram OAuth 가입 플로우에서도 동일하게 사용 가능

---

#### 데이터 모델:

**엔티티: tb_users (수정)**
- `user_code`: VARCHAR(8) NOT NULL UNIQUE - 유저코드
- `referrer_user_seq`: INT UNSIGNED NULL - 추천인 user_seq
- `total_referral_credit`: INT UNSIGNED NOT NULL DEFAULT 0 - 총 사용 가능한 적립금
- 관계:
  - `referrer_user_seq` → `tb_users.seq` (자기 참조)

**엔티티: tb_referral_ledger (신규) — 원장(Ledger) 방식**
- `seq`: INT UNSIGNED AUTO_INCREMENT PRIMARY KEY
- `user_seq`: INT UNSIGNED NOT NULL - 리워드 대상 유저 (추천인)
- `type`: ENUM('earn', 'use') NOT NULL - 'earn': 적립, 'use': 사용(차감)
- `plan_seq`: INT UNSIGNED NULL - 결제한 요금제 seq
- `plan_amount`: INT UNSIGNED NULL - 결제 시점의 요금제 금액 (원)
- `amount`: INT UNSIGNED NOT NULL - 리워드 거래 금액 (earn: 적립금, use: 차감금)
- `balance`: INT UNSIGNED NOT NULL - 거래 후 총액 (running balance)
- `referred_user_seq`: INT UNSIGNED NULL - 적립 시 추천인 등록자 user_seq (use 시 NULL)
- `payment_transaction_seq`: INT UNSIGNED NULL - 관련 결제 거래 seq
- `created_at`: DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6)
- 관계:
  - `user_seq` → `tb_users.seq`
  - `referred_user_seq` → `tb_users.seq`
  - `payment_transaction_seq` → `tb_payment_transactions.seq`
- 설계 원칙:
  - **INSERT ONLY** — 레코드를 수정/삭제하지 않음
  - 적립 시: `type='earn'`, `amount=적립금`, `balance=이전balance+amount`
  - 사용 시: `type='use'`, `amount=차감금`, `balance=이전balance-amount`
  - `tb_users.total_referral_credit`은 최신 `balance`와 동기화
  - 매일 배치로 `tb_referral_ledger`의 마지막 `balance`와 `tb_users.total_referral_credit` 정합성 검증

**엔티티: tb_payment_transactions (수정)**
- `credit_used_amount`: INT UNSIGNED NULL DEFAULT 0 - 적립금 사용 금액

---

## 4. DB 스키마 변경사항

### 4.1 테이블 수정

#### tb_users 테이블 컬럼 추가
```sql
ALTER TABLE `tb_users`
  ADD COLUMN `user_code` VARCHAR(8) NULL COMMENT '유저코드 (추천인 코드로 사용, A-Z0-9 8자리)' AFTER `name`,
  ADD COLUMN `referrer_user_seq` INT UNSIGNED NULL COMMENT '추천인 user_seq (자기 참조)' AFTER `user_code`,
  ADD COLUMN `total_referral_credit` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '총 사용 가능한 적립금 (원)' AFTER `referrer_user_seq`,
  ADD UNIQUE INDEX `UNQ_USERS_USER_CODE` (`user_code`),
  ADD INDEX `IDX_USERS_REFERRER` (`referrer_user_seq`),
  ADD CONSTRAINT `FK_USERS_REFERRER` FOREIGN KEY (`referrer_user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE SET NULL;
```

#### tb_payment_transactions 테이블 컬럼 추가
```sql
ALTER TABLE `tb_payment_transactions`
  ADD COLUMN `credit_used_amount` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '적립금 사용 금액 (원)' AFTER `amount`;
```

### 4.2 신규 테이블 생성

#### tb_referral_ledger 테이블 (원장 방식 — INSERT ONLY)
```sql
CREATE TABLE `tb_referral_ledger` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '리워드 대상 유저 seq (추천인)',
  `type` ENUM('earn', 'use') NOT NULL COMMENT 'earn: 적립, use: 사용(차감)',
  `plan_seq` INT UNSIGNED NULL COMMENT '결제한 요금제 seq (tb_plans.seq)',
  `plan_amount` INT UNSIGNED NULL COMMENT '결제 시점의 요금제 금액 (원)',
  `amount` INT UNSIGNED NOT NULL COMMENT '리워드 거래 금액 (원). earn: 적립금, use: 차감금',
  `balance` INT UNSIGNED NOT NULL COMMENT '거래 후 총액 (running balance)',
  `referred_user_seq` INT UNSIGNED NULL COMMENT '적립 시 추천인 등록자 user_seq (use 시 NULL)',
  `payment_transaction_seq` INT UNSIGNED NULL COMMENT '관련 결제 거래 seq',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '거래 시간',
  CONSTRAINT `FK_REFERRAL_LEDGER_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_REFERRAL_LEDGER_REFERRED` FOREIGN KEY (`referred_user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE SET NULL,
  CONSTRAINT `FK_REFERRAL_LEDGER_TRANSACTION` FOREIGN KEY (`payment_transaction_seq`) REFERENCES `tb_payment_transactions` (`seq`) ON DELETE SET NULL,
  INDEX `IDX_REFERRAL_LEDGER_USER` (`user_seq`, `created_at`),
  INDEX `IDX_REFERRAL_LEDGER_USER_TYPE` (`user_seq`, `type`),
  INDEX `IDX_REFERRAL_LEDGER_TRANSACTION` (`payment_transaction_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='추천인 리워드 원장 (INSERT ONLY). earn=적립, use=사용. balance는 거래 후 잔액';
```

#### 일일 정합성 검증 배치
```sql
-- 매일 실행: tb_referral_ledger의 최신 balance와 tb_users.total_referral_credit 비교
-- 불일치 시 알림 발송 및 로그 기록
SELECT
  u.seq AS user_seq,
  u.total_referral_credit AS user_credit,
  l.balance AS ledger_balance
FROM tb_users u
JOIN (
  SELECT user_seq, balance
  FROM tb_referral_ledger l1
  WHERE seq = (SELECT MAX(seq) FROM tb_referral_ledger l2 WHERE l2.user_seq = l1.user_seq)
) l ON l.user_seq = u.seq
WHERE u.total_referral_credit != l.balance;
```

### 4.3 데이터 마이그레이션 스크립트

#### 기존 회원 유저코드 일괄 생성 스크립트
```sql
-- 마이그레이션 스크립트: 기존 회원 유저코드 생성
-- 파일명: migrations/20260131000000-generate-user-codes.js

/**
 * 유저코드 생성 함수 (JavaScript)
 */
function generateUserCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}

/**
 * 유니크한 유저코드 생성 (최대 10회 재시도)
 */
async function generateUniqueUserCode(queryInterface, Sequelize) {
  for (let attempt = 0; attempt < 10; attempt++) {
    const code = generateUserCode();
    const [results] = await queryInterface.sequelize.query(
      `SELECT COUNT(*) as count FROM tb_users WHERE user_code = :code`,
      {
        replacements: { code },
        type: Sequelize.QueryTypes.SELECT
      }
    );

    if (results.count === 0) {
      return code;
    }
  }

  throw new Error('Failed to generate unique user code after 10 attempts');
}

/**
 * Up 마이그레이션
 */
async function up(queryInterface, Sequelize) {
  // 유저코드가 없는 모든 사용자 조회
  const [users] = await queryInterface.sequelize.query(
    `SELECT seq FROM tb_users WHERE user_code IS NULL AND status != 'SUSPENDED'`
  );

  console.log(`Found ${users.length} users without user codes`);

  // 배치 단위로 처리 (1000명씩)
  const batchSize = 1000;
  let successCount = 0;
  let failureCount = 0;

  for (let i = 0; i < users.length; i += batchSize) {
    const batch = users.slice(i, i + batchSize);

    for (const user of batch) {
      try {
        const userCode = await generateUniqueUserCode(queryInterface, Sequelize);

        await queryInterface.sequelize.query(
          `UPDATE tb_users SET user_code = :userCode WHERE seq = :seq`,
          {
            replacements: { userCode, seq: user.seq }
          }
        );

        successCount++;
      } catch (error) {
        console.error(`Failed to generate user code for user ${user.seq}:`, error);
        failureCount++;
      }
    }

    console.log(`Processed ${Math.min(i + batchSize, users.length)}/${users.length} users`);
  }

  console.log(`Migration completed: ${successCount} succeeded, ${failureCount} failed`);
}

/**
 * Down 마이그레이션
 */
async function down(queryInterface, Sequelize) {
  await queryInterface.sequelize.query(
    `UPDATE tb_users SET user_code = NULL WHERE user_code IS NOT NULL`
  );
}
```

---

## 5. 프론트엔드 변경사항

### 5.1 신규 페이지 및 컴포넌트

#### 1. 회원가입 페이지 수정
**파일:** `web/app/(auth)/register/page.tsx`

**변경사항:**
- 추천인 코드 입력 필드 추가
- 추천인 코드 실시간 검증 로직 추가
- 에러 메시지 처리

**예상 변경 코드:**
```typescript
// 추천인 코드 필드 추가
<FormField
  control={form.control}
  name="referralCode"
  render={({ field }) => (
    <FormItem>
      <FormLabel>추천인 코드 (선택사항)</FormLabel>
      <FormControl>
        <Input
          placeholder="예: A1B2C3D4"
          maxLength={8}
          {...field}
          onChange={(e) => {
            field.onChange(e.target.value.toUpperCase());
          }}
        />
      </FormControl>
      <FormDescription>
        친구의 추천인 코드가 있다면 입력해주세요
      </FormDescription>
      <FormMessage />
    </FormItem>
  )}
/>
```

---

#### 2. 설정 페이지 - 추천인 섹션
**파일:** `web/app/dashboard/settings/referral/page.tsx` (신규)

**구성요소:**
- 내 유저코드 카드 (복사 버튼 포함)
- 추천인 코드 입력 카드 (미입력 시)
- 추천 현황 카드 (통계)
- 적립 내역 테이블 (페이지네이션)
- 적립금 사용 내역 테이블 (페이지네이션)

**신규 컴포넌트:**
- `components/referral/UserCodeCard.tsx` - 내 유저코드 카드
- `components/referral/ReferrerInputCard.tsx` - 추천인 코드 입력 카드
- `components/referral/ReferralStatsCard.tsx` - 추천 통계 카드
- `components/referral/RewardHistoryTable.tsx` - 적립 내역 테이블
- `components/referral/CreditUsageTable.tsx` - 적립금 사용 내역 테이블

---

#### 3. 관리자 추천인 통계 페이지
**파일:** `web/app/dashboard/admin/referrals/page.tsx` (신규)

**구성요소:**
- 전체 통계 카드 (4개: 총 추천, 총 적립금, 총 사용, 잔여)
- 상위 추천인 테이블
- 월별 추천 트렌드 차트
- 날짜 범위 필터
- CSV 다운로드 버튼

**신규 컴포넌트:**
- `components/admin/referral/StatsOverview.tsx` - 통계 개요 카드
- `components/admin/referral/TopReferrersTable.tsx` - 상위 추천인 테이블
- `components/admin/referral/MonthlyTrendChart.tsx` - 월별 트렌드 차트

---

### 5.2 API 클라이언트 추가

**파일:** `web/lib/api/referral.ts` (신규)

**API 함수:**
- `validateReferralCode(code: string)` - 추천인 코드 검증
- `setReferrer(code: string)` - 추천인 코드 저장
- `getMyReferralStats()` - 내 추천 통계 조회
- `getRewardHistory(page: number, limit: number)` - 적립 내역 조회
- `getCreditUsageHistory(page: number, limit: number)` - 적립금 사용 내역 조회
- `getAdminReferralStats(startDate?: string, endDate?: string)` - 관리자 통계 조회

---

### 5.3 상태 관리 (Zustand)

**파일:** `web/store/referralStore.ts` (신규)

**상태:**
- `userCode: string | null` - 내 유저코드
- `referrerUserSeq: number | null` - 추천인 seq
- `totalReferrals: number` - 총 추천 인원
- `totalEarned: number` - 누적 적립금
- `availableCredit: number` - 사용 가능 적립금
- `totalUsed: number` - 사용한 적립금

**액션:**
- `fetchMyReferralStats()` - 통계 조회 및 상태 업데이트
- `setReferrer(code: string)` - 추천인 코드 저장

---

## 6. 레몬스퀴지(LemonSqueezy) 연동 고려사항

### 6.1 웹훅 이벤트 처리

LemonSqueezy는 다음 웹훅 이벤트를 발생시킵니다:

**관련 웹훅 이벤트:**
1. `subscription_payment_success` - 구독 결제 성공 (최초 + 갱신)
2. `subscription_created` - 구독 생성
3. `subscription_updated` - 구독 업데이트
4. `subscription_cancelled` - 구독 취소

**추천인 리워드 적립 시점:**
- `subscription_payment_success` 웹훅 수신 시 리워드 적립
- 웹훅 페이로드에서 `user_seq` 추출 → 추천인 조회 → 리워드 적립

**주의사항:**
- 웹훅 중복 수신 방지: `payment_transaction_seq`를 기준으로 중복 적립 방지
- 웹훅 재시도 로직: LemonSqueezy는 실패 시 최대 10회까지 재시도

---

### 6.2 LemonSqueezy 제약 사항

**Discount API 검토 결과 — 사용 불가:**
- Discount API는 checkout 시점에만 할인 적용 가능
- 기존 활성 구독에 할인을 동적으로 추가/변경하는 API 없음 (Update Subscription에 discount 필드 없음)
- `duration="forever"`는 고정 금액만 가능 — 매월 변동하는 적립금 잔액에 맞출 수 없음
- 적립금 변동 시 구독을 취소 후 재생성해야 하므로 비현실적

**Checkout API 제약:**
- `custom_price`: 양의 정수(센트)만 허용, 0 불가
- 자동 갱신 결제에는 미적용

**결론:** Discount API, custom_price 모두 적립금 사용 수단으로 부적합

---

### 6.3 적립금 적용 전략 — 부분 환불 방식 (확정)

모든 결제(최초/자동 갱신 동일)에서 **정가 전액 결제 → 부분 환불** 방식으로 적립금을 사용합니다.

**플로우:**
1. LemonSqueezy에서 **정가 전액 결제** (최초 checkout 또는 자동 갱신)
2. `subscription_payment_success` 웹훅 수신
3. 백엔드에서 해당 유저의 적립금 잔액 확인
4. 적립금이 있으면:
   - 사용 금액 계산: `MIN(적립금 잔액, 플랜 금액 × 50%)`
   - LemonSqueezy **Refund API**로 해당 금액 부분 환불
   - `tb_referral_ledger`에 `type='use'` 기록
   - `tb_users.total_referral_credit` 차감
5. 적립금이 없으면: 별도 처리 없음

**수수료 손실:**
- LemonSqueezy 수수료: 거래당 **5% + 50¢ (약 700원)**
- 환불 시 수수료는 반환되지 않음
- 9,900원 플랜, 적립금 4,950원(50%) 사용 시 약 **248원/건** 수수료 손실
- 비즈니스 비용으로 감수

```javascript
// 적립금 사용 예시 (웹훅 핸들러 내)
async function handleSubscriptionPaymentSuccess(webhook) {
  const userSeq = webhook.meta.custom_data.user_seq;
  const user = await User.findByPk(userSeq);

  if (user.total_referral_credit > 0) {
    const planAmount = webhook.data.attributes.total;
    const maxCredit = Math.floor(planAmount * 0.5); // 최대 50%
    const creditToUse = Math.min(user.total_referral_credit, maxCredit);

    // LemonSqueezy 부분 환불
    await lemonSqueezyClient.issueRefund({
      order_id: webhook.data.attributes.order_id,
      amount: creditToUse, // 센트 단위
    });

    // 원장 기록
    await ReferralLedger.create({
      user_seq: userSeq,
      type: 'use',
      amount: creditToUse,
      balance: user.total_referral_credit - creditToUse,
      payment_transaction_seq: transactionSeq,
    });

    // 잔액 업데이트
    await user.decrement('total_referral_credit', { by: creditToUse });
  }
}
```

---

### 6.4 구현 시 확인 필요 사항

1. **웹훅 중복 수신 방지**
   - `payment_transaction_seq`를 기준으로 중복 적립/환불 방지
   - 웹훅 페이로드의 `order_id` 또는 `subscription_payment_id`를 키로 사용

2. **환율 및 통화 처리**
   - LemonSqueezy는 USD 기반이지만, 프로젝트는 KRW 기반
   - 적립금 계산 시 환율 고려 필요 여부 확인

3. **구독 취소 시 적립금 처리**
   - 구독 취소 시 적립금은 유지하는 것으로 확정
   - 별도 처리 불필요

4. **부분 환불 Refund API 동작 확인**
   - 구독 갱신 결제에 대해 부분 환불이 정상 동작하는지 테스트 필요
   - 부분 환불 후 구독 상태가 active로 유지되는지 확인

---

## 7. 우선순위 및 구현 순서

### 7.1 구현 단계

| 단계 | 기간 | 작업 내용 | 우선순위 | 담당자 |
|-----|------|---------|---------|-------|
| **1단계: DB 설계 및 마이그레이션** | 2일 | - DB 스키마 설계 및 리뷰<br>- 마이그레이션 스크립트 작성<br>- 기존 회원 유저코드 생성 스크립트<br>- 테스트 DB 적용 및 검증 | 필수 | DBA, 백엔드 |
| **2단계: 유저코드 생성** | 2일 | - 유저코드 생성 로직 구현<br>- 회원가입 시 자동 생성<br>- 기존 회원 마이그레이션 실행<br>- 단위 테스트 작성 | 필수 | 백엔드 |
| **3단계: 추천인 코드 입력** | 3일 | - 추천인 코드 검증 API<br>- 추천인 코드 저장 API<br>- 회원가입 폼 수정 (프론트)<br>- 설정 페이지 추천인 섹션 (프론트)<br>- 통합 테스트 | 필수 | 백엔드, 프론트엔드 |
| **4단계: 추천인 리워드 적립** | 4일 | - 리워드 적립 로직 구현<br>- LemonSqueezy 웹훅 연동<br>- 최초 결제/월별 갱신 처리<br>- 중복 적립 방지 로직<br>- 단위 테스트 및 웹훅 테스트 | 필수 | 백엔드 |
| **5단계: 적립금 사용** | 3일 | - 웹훅 핸들러에 적립금 확인 + 부분 환불 로직 구현<br>- LemonSqueezy Refund API 연동<br>- `tb_referral_ledger`에 `type='use'` 기록<br>- 부분 환불 후 구독 상태 유지 테스트<br>- 결제 플로우 통합 테스트 | 필수 | 백엔드 |
| **6단계: 추천인 대시보드** | 3일 | - 추천 현황 조회 API<br>- 적립 내역 조회 API<br>- 적립금 사용 내역 조회 API<br>- 설정 페이지 UI 구현<br>- 페이지네이션 처리 | 중요 | 백엔드, 프론트엔드 |
| **7단계: ~~피추천인 탈퇴 처리~~** | - | (삭제됨 — 피추천인 탈퇴 시 적립금 유지로 변경, 별도 처리 불필요) | - | - |
| **8단계: 관리자 통계 페이지** | 3일 | - 관리자 통계 API<br>- 관리자 페이지 UI 구현<br>- 차트 라이브러리 연동<br>- CSV 다운로드 기능 | 선택 사항 | 백엔드, 프론트엔드 |
| **9단계: QA 및 버그 수정** | 3일 | - E2E 테스팅<br>- 버그 수정<br>- 성능 테스트<br>- 보안 검토 | 필수 | QA, 전체 팀 |
| **10단계: 배포 및 모니터링** | 1일 | - 프로덕션 배포<br>- 모니터링 설정<br>- 로그 모니터링 | 필수 | DevOps, 백엔드 |

**총 예상 기간:** 약 26일 (약 5주)

---

### 7.2 마일스톤

| 마일스톤 | 날짜 | 설명 |
|---------|------|------|
| **M1: DB 마이그레이션 완료** | D+2 | DB 스키마 변경 및 기존 회원 유저코드 생성 완료 |
| **M2: 추천인 코드 입력 기능 완료** | D+7 | 회원가입 및 설정에서 추천인 코드 입력 가능 |
| **M3: 리워드 적립 기능 완료** | D+11 | LemonSqueezy 웹훅 연동 및 리워드 적립 로직 완료 |
| **M4: 적립금 사용 기능 완료** | D+14 | 결제 시 적립금 자동 차감 기능 완료 |
| **M5: MVP 완료** | D+17 | 필수 기능 모두 완료 (대시보드 제외) |
| **M6: 전체 기능 완료** | D+23 | 관리자 통계 페이지 포함 모든 기능 완료 |
| **M7: 프로덕션 배포** | D+26 | QA 완료 및 프로덕션 배포 |

---

## 8. 엣지 케이스 및 비즈니스 룰

### 8.1 엣지 케이스

| 케이스 | 시나리오 | 처리 방법 |
|-------|---------|---------|
| **유저코드 생성 실패** | 10회 재시도 후에도 유니크한 코드 생성 실패 | 에러 로그 기록, 관리자 알림 발송, 회원가입 실패 처리 (500 에러) |
| **본인 추천인 코드 입력** | 사용자가 자신의 유저코드를 추천인 코드로 입력 | "본인의 추천인 코드는 사용할 수 없습니다" 에러 반환 |
| **중복 추천인 코드 입력** | 이미 추천인 코드를 입력한 사용자가 다시 입력 시도 | "이미 추천인 코드를 입력하셨습니다" 에러 반환, 기존 값 유지 |
| **탈퇴한 사용자의 코드 입력** | 탈퇴한 사용자의 유저코드를 추천인 코드로 입력 | "유효하지 않은 추천인 코드입니다" 에러 반환 |
| **피추천인 탈퇴** | 피추천인이 회원 탈퇴 | 추천인에게 이미 적립된 리워드는 유지. 별도 처리 불필요 |
| **피추천인 플랜 취소** | 피추천인이 유료 플랜 취소 | 적립금 유지, 재가입 후 결제 성공 시 다시 적립 |
| **피추천인 플랜 다운그레이드** | 피추천인이 STARTER → MINIMUM으로 다운그레이드 | 다운그레이드된 금액 기준으로 5% 적립 (예: 9,900원 → 495원) |
| **피추천인 플랜 업그레이드** | 피추천인이 MINIMUM → STARTER로 업그레이드 | 업그레이드된 금액 기준으로 5% 적립 (예: 29,900원 → 1,495원) |
| **웹훅 중복 수신** | LemonSqueezy가 동일한 결제에 대해 웹훅 2회 발송 | `payment_transaction_seq`를 기준으로 중복 적립 방지 (UNIQUE 인덱스) |
| **적립금 50% 한도 초과** | 적립금이 플랜 금액의 50%를 초과 | 최대 50%까지만 적립금 사용, 나머지 50% 이상은 PG 결제. 100% 적립금 결제 불가 |
| **적립금 차감 중 오류** | 적립금 차감 중 DB 오류 발생 | 트랜잭션 롤백, 결제 실패 처리, 에러 로그 기록 |
| **결제 실패 후 재시도** | 결제 실패 후 사용자가 재시도 | 새로운 `payment_transaction`으로 처리, 적립금은 최신 잔액 기준으로 차감 |
| **적립금이 음수가 되는 경우** | 적립금 차감 시 음수 발생 가능성 | 0 미만으로 내려가지 않도록 보호 (`total_referral_credit = MAX(0, current_credit - used_amount)`) |
| **동시 결제 요청** | 동일 사용자가 동시에 2개의 결제 요청 | DB 트랜잭션 격리 수준(READ COMMITTED)으로 처리, 먼저 처리된 요청만 성공 |

---

### 8.2 비즈니스 룰 요약

| 규칙 | 내용 |
|-----|------|
| **유저코드 형식** | A-Z0-9 조합 8자리, 대문자만 허용 |
| **유저코드 유니크** | 전체 시스템에서 유니크, 중복 시 재생성 (최대 10회) |
| **추천인 코드 입력** | 선택사항, 한 번 입력 후 수정 불가, 언제든 입력 가능 (미입력 시) |
| **본인 코드 입력 금지** | 본인의 유저코드를 추천인 코드로 입력 불가 |
| **리워드 비율** | 실 결제 금액의 5% (소수점 버림) |
| **리워드 적립 시점** | 유료 플랜 결제가 성공할 때마다 (매회) |
| **적립 한도** | 없음 (무제한) |
| **적립금 사용** | 자동 사용, 최대 플랜 금액의 50%까지 |
| **적립금 100% 결제** | 불가 — 최소 50%는 PG 결제 필요 |
| **적립금 유효기간** | 없음 (영구) |
| **적립금 환급** | 불가 (서비스 내에서만 사용) |
| **피추천인 탈퇴 시** | 적립된 리워드 유지 (삭제하지 않음) |
| **피추천인 플랜 취소 시** | 적립금 유지 |
| **중복 적립 방지** | `payment_transaction_seq` 기준 UNIQUE 인덱스 |

---

## 9. 위험 및 이슈

| 위험 | 영향도 | 발생 가능성 | 완화 방안 |
|-----|-------|-----------|---------|
| **부분 환불 시 수수료 손실** | 낮음 | 높음 | 적립금 사용 건마다 약 248원 손실 (9,900원 플랜 기준). 비즈니스 비용으로 감수. 스케일 커지면 재검토 |
| **부분 환불 후 구독 상태** | 중간 | 낮음 | 구독 갱신 결제에 부분 환불 시 구독이 active 유지되는지 사전 테스트 필요 |
| **유저코드 생성 충돌** | 중간 | 낮음 | 최대 10회 재시도 로직, DB 유니크 인덱스, 충돌 시 에러 로그 및 관리자 알림 |
| **웹훅 중복 수신** | 중간 | 중간 | `payment_transaction_seq` UNIQUE 인덱스로 중복 방지, 웹훅 재시도 시 멱등성 보장 |
| **적립금 계산 오류** | 높음 | 낮음 | 단위 테스트 및 통합 테스트로 철저히 검증, 계산 로직 단순화 |
| **동시성 문제** | 중간 | 중간 | DB 트랜잭션 및 격리 수준 설정, 낙관적 락 또는 비관적 락 적용 |
| **대량 마이그레이션 실패** | 높음 | 낮음 | 배치 단위(1000명)로 처리, 실패 시 로그 기록 및 재시도, 테스트 DB에서 사전 검증 |
| **성능 저하** | 중간 | 중간 | 인덱스 최적화, 쿼리 성능 모니터링, 필요 시 캐싱 적용 |

**알려진 이슈:**
- **이슈 1**: LemonSqueezy 부분 환불 후 구독 상태 유지 여부 확인 필요 → **해결 계획**: 테스트 환경에서 구독 갱신 결제 → 부분 환불 → 구독 상태 확인
- **이슈 2**: 기존 회원 마이그레이션 시 대량 데이터 처리 → **해결 계획**: 배치 처리 및 테스트 DB에서 사전 검증

---

## 10. 알림 및 UX 정책

| 항목 | 정책 |
|------|------|
| **알림/통지** | 없음. 리워드 적립 시 별도 알림(이메일, 푸시 등)을 보내지 않음 |
| **OAuth 가입 후** | 가입 완료 직후 추천인 코드 입력 모달을 자동으로 표시. 건너뛰기 가능 |
| **자동 갱신 결제 시 리워드 적립** | 추천 유저의 자동 갱신 결제 성공 웹훅 수신 즉시, 피추천인에게 리워드 적립 |
| **자동 갱신 결제 시 적립금 사용** | 정가 전액 결제 후 부분 환불 방식으로 확정. 수수료 손실 감수 |

---

## 11. 성공 지표 (KPI)

| 지표 | 현재값 | 목표값 | 측정 방법 |
|-----|-------|-------|---------|
| **추천 가입률** | 0% | 20% | 신규 가입자 중 추천인 코드 입력 비율 |
| **추천인당 평균 추천 수** | 0명 | 3명 | 전체 추천 건수 / 추천인 수 |
| **적립금 사용률** | 0% | 80% | 사용된 적립금 / 총 적립금 |
| **추천인 활성 비율** | 0% | 50% | 1명 이상 추천한 사용자 / 전체 사용자 |
| **추천 전환율** | 0% | 15% | 추천으로 가입한 사용자 중 유료 전환 비율 |
| **월별 추천 성장률** | 0% | 10% | 전월 대비 추천 건수 증가율 |

**정성적 지표:**
- **사용자 만족도**: 추천인 프로그램 관련 설문조사 실시 (NPS 점수 목표: 8점 이상)
- **사용성**: 추천인 코드 입력 및 적립금 사용 과정에서 발생하는 오류율 (목표: 5% 이하)
- **투명성**: 추천 현황 및 적립 내역의 가시성에 대한 사용자 피드백 (목표: 긍정적 피드백 90% 이상)

---

## 12. 부록

### 12.1 용어집
- **유저코드(User Code)**: 모든 사용자에게 부여되는 8자리 고유 코드 (A-Z0-9). 다른 사용자에게 추천인 코드로 공유됩니다.
- **추천인 코드(Referral Code)**: 다른 사용자의 유저코드. 회원가입 시 또는 설정에서 입력합니다.
- **추천인 등록자**: 다른 유저의 유저코드를 입력하는 유저. 1명만 등록 가능, 수정 불가.
- **추천인/피추천인(Referrer)**: 자신의 유저코드를 입력받은 유저. 여러 명의 추천인 등록자를 가질 수 있음 (1:N).
- **리워드(Reward)**: 추천인 등록자의 유료 결제 성공 시, 피추천인에게 지급되는 적립금 (실 결제 금액의 5%).
- **적립금(Credit)**: 추천으로 받은 리워드 잔액. 유료 플랜 결제 후 부분 환불 형태로 사용됩니다 (최대 50%).
- **원장(Ledger)**: `tb_referral_ledger` 테이블. INSERT ONLY 방식으로 적립(earn)/사용(use) 내역과 잔액(balance)을 기록.
- **LemonSqueezy**: 프로젝트에서 사용하는 결제 플랫폼.

### 12.2 참고 자료
- [LemonSqueezy API 문서](https://docs.lemonsqueezy.com/api)
- [LemonSqueezy 웹훅 가이드](https://docs.lemonsqueezy.com/guides/webhooks)
- [프로젝트 DB 스키마](/Volumes/Dev/workspaces/twms/sns_automation/docs/dba/init.sql)
- [프로젝트 README](/Volumes/Dev/workspaces/twms/sns_automation/api/README.md)

### 12.3 미결 항목

| # | 항목 | 확인 방법 | 영향 |
|---|------|----------|------|
| 1 | LemonSqueezy 부분 환불 후 구독 상태 유지 여부 | 테스트 모드에서 구독 갱신 → 부분 환불 → 구독 상태 확인 | 불가 시 방안 C(자체 크레딧 관리)로 전환 |

### 12.4 변경 이력
| 날짜 | 버전 | 변경사항 | 작성자 |
|------|------|---------|-------|
| 2026-01-31 | 1.0 | 초안 작성 | Product Requirements Analyst |
| 2026-01-31 | 1.1 | 리워드 적립 기준 변경 (매 결제 성공 시), 피추천인 탈퇴 시 적립금 유지, 적립금 최대 50% 할인 제한, API 통합 (set-referrer 단일 API), validate API 제거 및 보안 강화 | - |
| 2026-01-31 | 1.2 | 원장(Ledger) 방식으로 DB 설계 변경 (tb_referral_ledger, INSERT ONLY), 매일 배치 정합성 검증, OAuth 가입 후 추천인 입력 모달, 알림 없음 확정, 요금제 정보(plan_seq, plan_amount) 추가 | - |
| 2026-01-31 | 1.3 | LemonSqueezy Discount API 사용 불가 확정, 부분 환불 방식으로 적립금 사용 확정, 수수료 손실(약 248원/건) 감수 | - |
