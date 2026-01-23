-- ============================================
-- SNS Automation Database Schema
-- Version: 1.3.0
-- Last Updated: 2026-01-17
-- ============================================

-- Database Creation
CREATE DATABASE IF NOT EXISTS `sns_automation`
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE `sns_automation`;

-- ============================================
-- Table: tb_users
-- Description: 사용자 정보 테이블
-- ============================================
CREATE TABLE `tb_users` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `email` VARCHAR(255) NOT NULL COMMENT '사용자 이메일',
  `auth_type` ENUM('EMAIL', 'GOOGLE', 'APPLE', 'KAKAO', 'INSTAGRAM', 'TIKTOK') NOT NULL COMMENT '인증 방식',
  `oauth_id` VARCHAR(300) NULL COMMENT 'SNS 로그인에 필요한 OAuth ID. INSTAGRAM 연동 계정의 경우 instagram_user_id',
  `name` VARCHAR(100) NOT NULL COMMENT '유저이름. INSTAGRAM 연동 계정의 경우 instagram_username',
  `refresh_token` VARCHAR(500) NULL COMMENT 'JWT로 생성된 refresh_token',
  `email_verify_code` CHAR(6) NOT NULL COMMENT 'EMAIL 인증 코드',
  `email_code_sent_at` DATETIME(6) NULL COMMENT '인증 코드 발송 시간',
  `login_failed_count` TINYINT NOT NULL DEFAULT 0 COMMENT '로그인 실패 횟수',
  `locked_until` DATETIME(6) NULL COMMENT '계정 잠금 해제 시간',
  `status` ENUM('VERIFYING', 'ACTIVATED', 'SUSPENDED') NOT NULL DEFAULT 'VERIFYING' COMMENT 'VERIFYING: 이메일 인증 전, ACTIVATED: 이메일 인증완료, SUSPENDED: 회원탈퇴',
  `verified_at` DATETIME(6) NULL COMMENT '이메일 인증 완료 시간',
  `suspended_at` DATETIME(6) NULL DEFAULT '2000-01-01 00:00:00.000000' COMMENT '회원 탈퇴 시간',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '가입 시간',
  UNIQUE INDEX `UNQ_USERS_01` (`email`, `status`, `suspended_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='사용자 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_user_passwords
-- Description: 이메일 가입 사용자의 비밀번호 테이블
-- Note: 동일한 user_seq에 대해 MAX(seq)의 값이 현재 비밀번호
--       UPDATE 하지 않고 INSERT로 비밀번호 이력 관리
-- ============================================
CREATE TABLE `tb_user_passwords` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '사용자 SEQ (tb_users.seq)',
  `password` VARCHAR(500) NOT NULL COMMENT '암호화된 비밀번호',
  `is_temp` TINYINT NOT NULL DEFAULT 0 COMMENT '임시 비밀번호 여부 (0: 정규, 1: 임시)',
  `temp_expired` DATETIME(6) NULL COMMENT '임시 비밀번호 만료 시간',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '비밀번호 생성 시간',
  CONSTRAINT `FK_USERPASSWORDS_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  INDEX `IDX_USERPASSWORDS_01` (`user_seq`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='EMAIL로 가입한 유저의 비밀번호 이력을 저장하는 테이블';

-- ============================================
-- Table: tb_user_oauth
-- Description: SNS 플랫폼 연동 정보 테이블
-- Note: 사용자당 플랫폼별 1개 계정만 연동 가능 (1:1)
-- ============================================
CREATE TABLE `tb_user_oauth` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '사용자 SEQ (tb_users.seq)',
  `platform_type` ENUM('INSTAGRAM', 'TIKTOK') NOT NULL COMMENT '연동 플랫폼',
  `oauth_id` VARCHAR(300) NOT NULL COMMENT 'OAuth ID (회원가입을 INSTAGRAM, TIKTOK으로 한 경우 동일한 값 저장)',
  `username` VARCHAR(100) NULL COMMENT 'SNS 플랫폼 username (@username 형태)',
  `api_access_token` TEXT NOT NULL COMMENT 'API Access Token',
  `api_refresh_token` TEXT NOT NULL COMMENT 'API Refresh Token',
  `api_token_expired_at` DATETIME NOT NULL COMMENT 'API Token 만료 시간',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '연동 시간',
  CONSTRAINT `FK_USEROAUTH_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  UNIQUE INDEX `UNQ_USEROAUTH_01` (`platform_type`, `oauth_id`),
  INDEX `IDX_USEROAUTH_01` (`user_seq`, `platform_type`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='가입유저가 API를 호출할 SNS 계정 정보를 저장하는 테이블 (1:1 관계)';

-- ============================================
-- Table: tb_instagram_posts
-- Description: 인스타그램 포스트 정보 테이블
-- Note: Instagram API에서 가져온 포스트 메타데이터 저장
-- ============================================
CREATE TABLE `tb_instagram_posts` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '포스트 소유자 (tb_users.seq)',
  `media_id` VARCHAR(500) NOT NULL COMMENT 'Instagram Media ID (고유 식별자)',
  `caption` TEXT NULL COMMENT '포스트 캡션',
  `media_type` ENUM('IMAGE', 'VIDEO', 'CAROUSEL_ALBUM') NOT NULL COMMENT '미디어 타입',
  `media_url` TEXT NOT NULL COMMENT '미디어 원본 URL',
  `permalink` TEXT NOT NULL COMMENT 'Instagram 포스트 permalink (공유 링크)',
  `timestamp` DATETIME(6) NULL COMMENT 'Instagram에서 게시된 시간',
  `thumbnail_url` TEXT NULL COMMENT '썸네일 URL (비디오용)',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '데이터베이스 저장 시간',
  `last_synced_at` DATETIME(6) NULL COMMENT '마지막 동기화 시간',
  CONSTRAINT `FK_INSTAPOSTS_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  UNIQUE INDEX `UNQ_INSTAPOSTS_01` (`user_seq`, `media_id`),
  INDEX `IDX_INSTAPOSTS_01` (`user_seq`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='인스타그램에서 가져온 포스트 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_post_triggers
-- Description: 포스트별 트리거 설정 테이블
-- Note: 1개 포스트에 여러 트리거 설정 가능 (1:N 구조)
-- ============================================
CREATE TABLE `tb_post_triggers` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `post_seq` INT UNSIGNED NOT NULL COMMENT '트리거를 설정할 포스트 (tb_instagram_posts.seq)',
  `user_seq` INT UNSIGNED NOT NULL COMMENT '트리거 소유자 (tb_users.seq)',
  `trigger_word` VARCHAR(30) NOT NULL COMMENT 'DM을 보낼 트리거 단어 (1개만)',
  `dm_message` VARCHAR(1000) NOT NULL COMMENT '자동으로 발송할 DM 메시지',
  `trigger_follow` TINYINT NOT NULL DEFAULT 0 COMMENT '팔로워만 응답 여부 (0: 아니오, 1: 예)',
  `reply_comment` TINYINT NOT NULL DEFAULT 0 COMMENT '댓글 답글 여부 (0: 아니오, 1: 예)',
  `reply_comment_text` VARCHAR(1000) NULL COMMENT '댓글 답글 내용',
  `status` ENUM('ACTIVATED', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVATED' COMMENT '트리거 상태',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '트리거 생성 시간',
  `last_updated_at` DATETIME(6) NULL ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '마지막 수정 시간',
  `suspended_at` DATETIME(6) NULL COMMENT '트리거 중단 시간',
  CONSTRAINT `FK_POSTTRIGGERS_POST` FOREIGN KEY (`post_seq`) REFERENCES `tb_instagram_posts` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_POSTTRIGGERS_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  UNIQUE INDEX `UNQ_POSTTRIGGERS_01` (`post_seq`, `trigger_word`, `status`),
  INDEX `IDX_POSTTRIGGERS_01` (`user_seq`, `status`),
  INDEX `IDX_POSTTRIGGERS_02` (`post_seq`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='인스타그램 포스트에 설정된 트리거 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_trigger_execute_history
-- Description: 트리거 실행 이력 테이블
-- Note: 댓글 트리거 발생 시 DM 발송 이력 기록
-- ============================================
CREATE TABLE `tb_trigger_execute_history` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `trigger_seq` INT UNSIGNED NOT NULL COMMENT '트리거 SEQ (tb_post_triggers.seq)',
  `user_id` VARCHAR(100) NOT NULL COMMENT 'DM을 보내야 할 (댓글을 남긴) 유저의 ID',
  `comment_id` VARCHAR(500) NOT NULL COMMENT '유저가 남긴 댓글 ID',
  `user_comment` VARCHAR(1000) NOT NULL COMMENT '유저가 남긴 댓글 내용',
  `status` ENUM('PENDING', 'DUPLICATED', 'SENT', 'FAIL') NOT NULL COMMENT 'PENDING: 대기, DUPLICATED: 중복, SENT: 발송완료, FAIL: 실패',
  `sent_at` DATETIME(6) NULL COMMENT 'DM 발송 완료 시간',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '이력 생성 시간',
  CONSTRAINT `FK_TRIGGERHISTORY_TRIGGER` FOREIGN KEY (`trigger_seq`) REFERENCES `tb_post_triggers` (`seq`) ON DELETE CASCADE,
  INDEX `IDX_TRIGGERHISTORY_01` (`trigger_seq`, `status`),
  INDEX `IDX_TRIGGERHISTORY_02` (`user_id`, `created_at`),
  INDEX `IDX_TRIGGERHISTORY_03` (`comment_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='트리거 실행 이력 및 DM 발송 이력을 저장하는 테이블';

-- ============================================
-- Table: tb_plans
-- Description: 요금제 플랜 정보 테이블
-- Note: 다국어 지원 (한국어, 영어, 일본어)
-- ============================================
CREATE TABLE `tb_plans` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `plan_code` VARCHAR(10) NOT NULL COMMENT '플랜 코드 (FREE, MINIMUM, STARTER, PRO)',
  `is_recommended` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '추천 플랜 여부 (인기 뱃지 표시)',
  `name_ko` VARCHAR(30) NOT NULL COMMENT '플랜 이름 (한국어)',
  `name_en` VARCHAR(30) NOT NULL COMMENT '플랜 이름 (영어)',
  `name_ja` VARCHAR(30) NOT NULL COMMENT '플랜 이름 (일본어)',
  `description_ko` VARCHAR(100) NOT NULL COMMENT '플랜 설명 (한국어)',
  `description_en` VARCHAR(100) NOT NULL COMMENT '플랜 설명 (영어)',
  `description_ja` VARCHAR(100) NOT NULL COMMENT '플랜 설명 (일본어)',
  `sort_num` TINYINT UNSIGNED NOT NULL COMMENT '정렬 순서',
  `price_ko` DECIMAL(12,2) UNSIGNED NOT NULL COMMENT '가격 (KRW)',
  `price_en` DECIMAL(12,2) UNSIGNED NOT NULL COMMENT '가격 (USD)',
  `price_ja` DECIMAL(12,2) UNSIGNED NOT NULL COMMENT '가격 (JPY)',
  `status` ENUM('ACTIVATED', 'SUSPENDED') NOT NULL DEFAULT 'ACTIVATED' COMMENT '플랜 상태',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '생성 시간',
  `created_by` INT UNSIGNED NOT NULL COMMENT '생성자',
  `updated_at` DATETIME NULL ON UPDATE CURRENT_TIMESTAMP COMMENT '수정 시간',
  `updated_by` INT UNSIGNED NULL COMMENT '수정자',
  UNIQUE INDEX `UNQ_PLAN_01` (`plan_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='요금제 플랜 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_plan_properties
-- Description: 요금제 플랜 속성 테이블
-- Note: EAV 패턴으로 플랜별 기능/제한 관리
-- ============================================
CREATE TABLE `tb_plan_properties` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `plan_seq` INT UNSIGNED NOT NULL COMMENT '플랜 SEQ (tb_plans.seq)',
  `prop_code` ENUM('DM', 'TRIGGER', 'ANALYTICS', 'CTA', 'OVER_USAGE') NOT NULL COMMENT '속성 코드',
  `display_ko` VARCHAR(100) NOT NULL COMMENT '표시 텍스트 (한국어)',
  `display_en` VARCHAR(100) NOT NULL COMMENT '표시 텍스트 (영어)',
  `display_ja` VARCHAR(100) NOT NULL COMMENT '표시 텍스트 (일본어)',
  `value_ko` VARCHAR(45) NULL COMMENT '값 (한국어)',
  `value_en` VARCHAR(45) NULL COMMENT '값 (영어)',
  `value_ja` VARCHAR(45) NULL COMMENT '값 (일본어)',
  `numeric_value` DECIMAL(12,2) NULL COMMENT '숫자 값 (DM 한도, 초과 단가 등)',
  `is_support` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT '지원 여부 (0: 미지원, 1: 지원)',
  `sort_num` TINYINT UNSIGNED NOT NULL COMMENT '정렬 순서',
  CONSTRAINT `FK_PLANPROPERTIES_PLAN` FOREIGN KEY (`plan_seq`) REFERENCES `tb_plans` (`seq`) ON DELETE CASCADE,
  UNIQUE INDEX `UNQ_PLANPROPERTIES_01` (`plan_seq`, `prop_code`),
  INDEX `IDX_PLANPROPERTIES_01` (`plan_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='요금제 플랜별 속성 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_subscriptions
-- Description: 사용자별 구독 정보 테이블
-- Note: 사용자당 1개의 구독만 허용 (user_seq UNIQUE)
-- ============================================
CREATE TABLE `tb_subscriptions` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '구독 소유자 (tb_users.seq)',
  `plan_seq` INT UNSIGNED NOT NULL COMMENT '현재 플랜 (tb_plans.seq)',
  `pending_plan_seq` INT UNSIGNED NULL COMMENT '다음 결제일부터 적용될 플랜 (tb_plans.seq, 플랜 변경 예약)',
  `subscription_status` ENUM('pending', 'active', 'cancelled', 'suspended') NOT NULL DEFAULT 'pending' COMMENT 'pending: 결제 대기, active: 활성, cancelled: 해지, suspended: 일시정지',
  `billing_key` VARCHAR(100) NULL COMMENT '아임포트 빌링키 (정기결제용, Free 플랜은 NULL)',
  `card_name` VARCHAR(50) NULL COMMENT '결제 카드사명 (예: 신한카드)',
  `card_number` VARCHAR(20) NULL COMMENT '마스킹된 카드번호 (예: 1234-****-****-5678)',
  `next_billing_date` DATE NULL COMMENT '다음 결제 예정일 (Free 플랜은 NULL)',
  `cancel_at_period_end` TINYINT(1) NOT NULL DEFAULT 0 COMMENT '구독 해지 예약 여부',
  `last_billing_amount` INT UNSIGNED NULL COMMENT '마지막 결제 금액 (원)',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '구독 생성 시간',
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '구독 수정 시간',
  CONSTRAINT `FK_SUBSCRIPTIONS_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_SUBSCRIPTIONS_PLAN` FOREIGN KEY (`plan_seq`) REFERENCES `tb_plans` (`seq`),
  CONSTRAINT `FK_SUBSCRIPTIONS_PENDING_PLAN` FOREIGN KEY (`pending_plan_seq`) REFERENCES `tb_plans` (`seq`),
  UNIQUE INDEX `UNQ_SUBSCRIPTIONS_USER` (`user_seq`),
  INDEX `IDX_SUBSCRIPTIONS_BILLING_DATE` (`next_billing_date`, `subscription_status`),
  INDEX `IDX_SUBSCRIPTIONS_STATUS` (`subscription_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='사용자별 구독 정보를 저장하는 테이블';

-- ============================================
-- Table: tb_subscription_history
-- Description: 구독 변경 이력 테이블 (감사 추적)
-- ============================================
CREATE TABLE `tb_subscription_history` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `subscription_seq` INT UNSIGNED NOT NULL COMMENT '구독 정보 (tb_subscriptions.seq)',
  `user_seq` INT UNSIGNED NOT NULL COMMENT '사용자 (tb_users.seq)',
  `event_type` ENUM('created', 'plan_changed', 'cancelled', 'reactivated', 'suspended') NOT NULL COMMENT 'created: 구독 생성, plan_changed: 플랜 변경, cancelled: 해지, reactivated: 재활성화, suspended: 일시정지',
  `old_plan_seq` INT UNSIGNED NULL COMMENT '변경 전 플랜 (tb_plans.seq, plan_changed인 경우)',
  `new_plan_seq` INT UNSIGNED NULL COMMENT '변경 후 플랜 (tb_plans.seq, plan_changed인 경우)',
  `reason` VARCHAR(500) NULL COMMENT '변경 사유',
  `admin_user_seq` INT UNSIGNED NULL COMMENT '관리자 조작인 경우 관리자 seq (NULL: 사용자 또는 시스템)',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '이벤트 발생 시간',
  CONSTRAINT `FK_SUBHISTORY_SUBSCRIPTION` FOREIGN KEY (`subscription_seq`) REFERENCES `tb_subscriptions` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_SUBHISTORY_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_SUBHISTORY_OLD_PLAN` FOREIGN KEY (`old_plan_seq`) REFERENCES `tb_plans` (`seq`),
  CONSTRAINT `FK_SUBHISTORY_NEW_PLAN` FOREIGN KEY (`new_plan_seq`) REFERENCES `tb_plans` (`seq`),
  INDEX `IDX_SUBHISTORY_SUBSCRIPTION` (`subscription_seq`),
  INDEX `IDX_SUBHISTORY_USER` (`user_seq`),
  INDEX `IDX_SUBHISTORY_CREATED_AT` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='구독 변경 이력을 저장하는 테이블 (감사 추적)';

-- ============================================
-- Table: tb_payment_transactions
-- Description: 결제 거래 내역 테이블
-- Note: 성공/실패 모두 기록
-- ============================================
CREATE TABLE `tb_payment_transactions` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `subscription_seq` INT UNSIGNED NOT NULL COMMENT '구독 정보 (tb_subscriptions.seq)',
  `user_seq` INT UNSIGNED NOT NULL COMMENT '결제자 (tb_users.seq)',
  `merchant_uid` VARCHAR(100) NOT NULL COMMENT '가맹점 주문 고유번호 (중복 결제 방지)',
  `imp_uid` VARCHAR(100) NULL COMMENT '아임포트 거래 고유번호 (결제 성공 시)',
  `transaction_type` ENUM('subscription', 'overage', 'refund') NOT NULL DEFAULT 'subscription' COMMENT 'subscription: 정기구독료, overage: 초과요금, refund: 환불',
  `payment_status` ENUM('pending', 'paid', 'failed', 'cancelled') NOT NULL DEFAULT 'pending' COMMENT 'pending: 대기, paid: 완료, failed: 실패, cancelled: 취소',
  `amount` INT UNSIGNED NOT NULL COMMENT '결제 금액 (원)',
  `currency` CHAR(3) NOT NULL DEFAULT 'KRW' COMMENT '통화',
  `paid_at` DATETIME(6) NULL COMMENT '결제 완료 시간',
  `failure_reason` VARCHAR(500) NULL COMMENT '결제 실패 사유',
  `pg_provider` VARCHAR(20) NULL COMMENT 'PG사 (예: nice, kcp)',
  `pg_tid` VARCHAR(100) NULL COMMENT 'PG사 거래 고유번호',
  `receipt_url` VARCHAR(500) NULL COMMENT '영수증 URL',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '거래 생성 시간',
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '거래 수정 시간',
  CONSTRAINT `FK_TRANSACTIONS_SUBSCRIPTION` FOREIGN KEY (`subscription_seq`) REFERENCES `tb_subscriptions` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_TRANSACTIONS_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  UNIQUE INDEX `UNQ_TRANSACTIONS_MERCHANT_UID` (`merchant_uid`),
  INDEX `IDX_TRANSACTIONS_IMP_UID` (`imp_uid`),
  INDEX `IDX_TRANSACTIONS_SUBSCRIPTION` (`subscription_seq`),
  INDEX `IDX_TRANSACTIONS_USER` (`user_seq`),
  INDEX `IDX_TRANSACTIONS_PAID_AT` (`paid_at`),
  INDEX `IDX_TRANSACTIONS_STATUS` (`payment_status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='결제 거래 내역을 저장하는 테이블';

-- ============================================
-- Table: tb_monthly_usage
-- Description: 월별 DM 사용량 추적 테이블
-- Note: 사용자별 월별 단일 레코드 (user_seq + year_month UNIQUE)
-- ============================================
CREATE TABLE `tb_monthly_usage` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `user_seq` INT UNSIGNED NOT NULL COMMENT '사용자 (tb_users.seq)',
  `plan_seq` INT UNSIGNED NOT NULL COMMENT '해당 월의 플랜 (tb_plans.seq)',
  `year_month` CHAR(7) NOT NULL COMMENT '년월 (YYYY-MM)',
  `dm_quota` INT UNSIGNED NOT NULL COMMENT '플랜 기본 DM 한도',
  `dm_sent_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '실제 발송 건수',
  `overage_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 건수',
  `overage_charge` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 요금 (원)',
  `overage_unit_price` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '초과 단가 (플랜별)',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '레코드 생성 시간',
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '레코드 수정 시간',
  CONSTRAINT `FK_USAGE_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_USAGE_PLAN` FOREIGN KEY (`plan_seq`) REFERENCES `tb_plans` (`seq`),
  UNIQUE INDEX `UNQ_USAGE_USER_MONTH` (`user_seq`, `year_month`),
  INDEX `IDX_USAGE_YEAR_MONTH` (`year_month`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='월별 DM 사용량을 추적하는 테이블';

-- ============================================
-- Table: tb_payment_retry_schedule
-- Description: 결제 재시도 스케줄 테이블
-- ============================================
CREATE TABLE `tb_payment_retry_schedule` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT PRIMARY KEY,
  `subscription_seq` INT UNSIGNED NOT NULL COMMENT '구독 정보 (tb_subscriptions.seq)',
  `transaction_seq` INT UNSIGNED NULL COMMENT '실패한 거래 (tb_payment_transactions.seq)',
  `retry_count` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '재시도 횟수',
  `max_retries` TINYINT UNSIGNED NOT NULL DEFAULT 3 COMMENT '최대 재시도 횟수',
  `next_retry_at` DATETIME(6) NOT NULL COMMENT '다음 재시도 예정 시간',
  `status` ENUM('pending', 'completed', 'exhausted') NOT NULL DEFAULT 'pending' COMMENT 'pending: 대기, completed: 성공, exhausted: 재시도 소진',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '생성 시간',
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6) COMMENT '수정 시간',
  CONSTRAINT `FK_RETRY_SUBSCRIPTION` FOREIGN KEY (`subscription_seq`) REFERENCES `tb_subscriptions` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_RETRY_TRANSACTION` FOREIGN KEY (`transaction_seq`) REFERENCES `tb_payment_transactions` (`seq`) ON DELETE SET NULL,
  INDEX `IDX_RETRY_NEXT_AT` (`next_retry_at`, `status`),
  INDEX `IDX_RETRY_SUBSCRIPTION` (`subscription_seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
COMMENT='결제 재시도 스케줄을 저장하는 테이블';

-- ============================================
-- End of Schema Definition
-- ============================================
