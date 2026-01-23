# 데이터베이스 변경 이력 (Database Changelog)

모든 데이터베이스 스키마 변경사항은 이 문서에 기록됩니다.

버전 관리는 [시맨틱 버저닝](https://semver.org/lang/ko/)을 따릅니다.

---

## [v1.3.0] - 2026-01-17

### 추가됨 (Added)
- **tb_plan_properties**: `numeric_value` 컬럼 추가 (DECIMAL(12,2) NULL)
  - DM 발송 한도, 초과 단가, 통계 보관 일수 등 정량적 값 저장
  - 비즈니스 로직에서 문자열 파싱 없이 직접 계산 가능
- **Seed 데이터**: tb_plans 및 tb_plan_properties 초기 데이터 스크립트 생성
  - 4개 플랜 (FREE, MINIMUM, STARTER, PRO)
  - 플랜별 5개 속성 (DM, TRIGGER, ANALYTICS, CTA, OVER_USAGE)

### 사유 (Rationale)
- 문자열 표시용 컬럼(value_*)과 계산용 컬럼(numeric_value) 분리로 각 목적에 최적화
- DECIMAL 타입으로 정확한 금액 계산 가능 (부동소수점 오류 방지)
- API에서 문자열 파싱 로직 불필요

### 영향 (Impact)
- **API**: PlanProperty API 응답에 `numeric_value` 필드 추가
- **코드**: PlanProperty.js 모델 업데이트 (INTEGER → DECIMAL(12,2))
- **비즈니스 로직**: DM 발송 검증, 초과 요금 계산 시 numeric_value 활용

### 문서
- [v1.3.0_add-numeric-value-to-plan-properties.md](./v1.3.0_add-numeric-value-to-plan-properties.md)
- [v1.3.0_seed-plan-properties.sql](./v1.3.0_seed-plan-properties.sql)

---

## [v1.2.0] - 2026-01-17

### 추가됨 (Added)
- **tb_subscriptions**: 사용자별 구독 정보 테이블 DDL 추가
- **tb_subscription_history**: 구독 변경 이력 테이블 DDL 추가
- **tb_payment_transactions**: 결제 거래 내역 테이블 DDL 추가
- **tb_monthly_usage**: 월별 사용량 테이블 DDL 추가
- **tb_payment_retry_schedule**: 결제 재시도 스케줄 테이블 DDL 추가

### 변경됨 (Changed)
- **tb_subscriptions**: `plan_id` ENUM → `plan_seq` FK (tb_plans.seq 참조)
- **tb_subscriptions**: `pending_plan_id` ENUM → `pending_plan_seq` FK
- **tb_subscriptions**: 기존 `plan_id`, `pending_plan_id` ENUM 컬럼 삭제
- **tb_subscription_history**: `old_plan_id` ENUM → `old_plan_seq` FK
- **tb_subscription_history**: `new_plan_id` ENUM → `new_plan_seq` FK
- **tb_monthly_usage**: `plan_id` ENUM → `plan_seq` FK

### 삭제됨 (Removed)
- **tb_users**: `current_plan_id` 컬럼 제거 (tb_subscriptions.plan_seq로 정규화)

### 사유 (Rationale)
- ENUM 타입 제거로 플랜 추가/변경 시 테이블 구조 변경 불필요
- FK 제약조건으로 참조 무결성 보장
- tb_plans 테이블과의 정규화된 관계 설정

### 영향 (Impact)
- **API**: 플랜 관련 조회 시 plan_seq로 JOIN 필요
- **코드**: Sequelize 모델 4개 수정 (Subscription, SubscriptionHistory, MonthlyUsage, User)
- **마이그레이션**: 기존 ENUM 값을 plan_seq로 변환 필요

### 문서
- [v1.2.0_integrate-plans-with-subscriptions.md](./v1.2.0_integrate-plans-with-subscriptions.md)

---

## [v1.1.0] - 2026-01-17

### 추가됨 (Added)
- **tb_plans**: 요금제 플랜 정보 테이블 신규 생성
  - 다국어 지원 (한국어, 영어, 일본어)
  - 컬럼: plan_code, is_recommended, name_*, description_*, price_*, status 등
  - 제약조건: UNQ_PLAN_01 (plan_code)

- **tb_plan_properties**: 요금제 플랜 속성 테이블 신규 생성
  - EAV 패턴으로 플랜별 기능/제한 관리
  - prop_code: DM, TRIGGER, ANALYTICS, CTA, OVER_USAGE
  - 제약조건: FK_PLANPROPERTIES_PLAN, UNQ_PLANPROPERTIES_01
  - 인덱스: IDX_PLANPROPERTIES_01

### 사유 (Rationale)
- 요금제 정보를 하드코딩에서 DB 관리로 전환
- 배포 없이 요금제 정보 수정 가능
- 다국어 지원으로 글로벌 서비스 대응

### 영향 (Impact)
- **API**: 플랜 목록/상세 조회 API 신규 생성 필요
- **코드**: Sequelize 모델 2개 신규 생성 (Plan.js, PlanProperty.js)
- **프론트엔드**: 요금제 페이지 DB 연동 필요

### 문서
- [v1.1.0_add-pricing-plans.md](./v1.1.0_add-pricing-plans.md)

---

## [v1.0.0] - 2025-12-29

### 추가됨 (Added)
- **tb_instagram_posts**: 인스타그램 포스트 정보 저장 테이블 신규 생성
  - Instagram API에서 가져온 포스트 메타데이터 저장
  - 컬럼: media_id, caption, media_type, media_url, permalink, timestamp, thumbnail_url 등
  - 제약조건: FK_INSTAPOSTS_USER, UNQ_INSTAPOSTS_01

- **tb_post_triggers**: 포스트별 트리거 설정 테이블 신규 생성
  - 1개 포스트에 여러 트리거 설정 가능 (1:N 구조)
  - 컬럼: trigger_word, dm_message, trigger_follow, reply_comment, reply_comment_text 등
  - 제약조건: FK_POSTTRIGGERS_POST, FK_POSTTRIGGERS_USER, UNQ_POSTTRIGGERS_01
  - 인덱스: IDX_POSTTRIGGERS_01, IDX_POSTTRIGGERS_02

### 변경됨 (Changed)
- **tb_trigger_execute_history**: 트리거 실행 이력 테이블 수정
  - `post_seq` 컬럼명을 `trigger_seq`로 변경
  - 외래 키 참조 변경: tb_user_posts.seq → tb_post_triggers.seq
  - 인덱스 추가: IDX_TRIGGERHISTORY_01, IDX_TRIGGERHISTORY_02

### 삭제됨 (Removed)
- **tb_user_posts**: 기존 사용자 포스트 테이블 삭제
  - 포스트 정보는 tb_instagram_posts로 이관
  - 트리거 정보는 tb_post_triggers로 이관
  - 마이그레이션 스크립트를 통해 데이터 보존

### 사유 (Rationale)
- 포스트 정보와 트리거 설정 정보의 책임 분리
- 1개 포스트에 여러 트리거 설정 가능하도록 확장성 개선
- Instagram API 응답 필드를 모두 저장할 수 있도록 스키마 확장
- 댓글 답글 기능 추가 (reply_comment, reply_comment_text)

### 영향 (Impact)
- **API**: 포스트 저장 API 신규 생성, 트리거 API 수정 필요
- **코드**: Sequelize 모델 2개 신규 생성, 1개 수정 필요
- **마이그레이션**: 기존 tb_user_posts 데이터 마이그레이션 필요

### 문서
- [v1.0.0_separate-posts-and-triggers.md](./v1.0.0_separate-posts-and-triggers.md)

---

## 범례 (Legend)

- **추가됨 (Added)**: 새로운 테이블, 컬럼, 인덱스, 제약조건 추가
- **변경됨 (Changed)**: 기존 구조 수정 (컬럼 타입 변경, 인덱스 변경 등)
- **삭제됨 (Removed)**: 테이블, 컬럼, 인덱스, 제약조건 삭제
- **사유 (Rationale)**: 변경 이유 및 비즈니스 목적
- **영향 (Impact)**: 애플리케이션 및 운영에 미치는 영향
- **문서**: 상세 문서 링크
