-- ============================================
-- SNS Automation Database Migration
-- Version: 1.5.0
-- Feature: Multi-Instagram Accounts Support
-- Description: 1유저 1계정 → 1유저 5계정 연동 지원
-- Last Updated: 2026-01-26
-- ============================================

USE `sns_automation`;

-- ============================================
-- Step 1: tb_instagram_posts에 oauth_seq 컬럼 추가 (NULL 허용)
-- ============================================
ALTER TABLE `tb_instagram_posts`
  ADD COLUMN `oauth_seq` INT UNSIGNED NULL AFTER `user_seq`
    COMMENT '포스트 소유 계정 (tb_user_oauth.seq)';

-- ============================================
-- Step 2: 기존 포스트를 첫 번째 계정에 매핑
-- ============================================
UPDATE tb_instagram_posts p
INNER JOIN (
  SELECT user_seq, MIN(seq) as oauth_seq
  FROM tb_user_oauth
  WHERE platform_type = 'INSTAGRAM'
  GROUP BY user_seq
) o ON p.user_seq = o.user_seq
SET p.oauth_seq = o.oauth_seq;

-- ============================================
-- Step 3: oauth_seq를 NOT NULL로 변경 및 제약조건 추가
-- ============================================
ALTER TABLE `tb_instagram_posts`
  MODIFY COLUMN `oauth_seq` INT UNSIGNED NOT NULL,
  ADD CONSTRAINT `FK_INSTAPOSTS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_INSTAPOSTS_03` (`oauth_seq`, `created_at`);

-- ============================================
-- Step 4: UNIQUE 제약 변경
-- ============================================
ALTER TABLE `tb_instagram_posts`
  DROP INDEX `UNQ_INSTAPOSTS_01`,
  ADD UNIQUE INDEX `UNQ_INSTAPOSTS_01` (`oauth_seq`, `media_id`);

-- ============================================
-- Step 5: tb_post_triggers에 oauth_seq 컬럼 추가
-- ============================================
ALTER TABLE `tb_post_triggers`
  ADD COLUMN `oauth_seq` INT UNSIGNED NULL AFTER `user_seq`
    COMMENT '트리거 소유 계정 (tb_user_oauth.seq, Instagram 트리거인 경우)';

-- ============================================
-- Step 6: 기존 Instagram 트리거를 포스트의 계정에 매핑
-- ============================================
UPDATE tb_post_triggers t
INNER JOIN tb_instagram_posts p ON t.post_seq = p.seq
SET t.oauth_seq = p.oauth_seq
WHERE t.post_seq IS NOT NULL;

-- ============================================
-- Step 7: oauth_seq 제약조건 및 인덱스 추가
-- ============================================
ALTER TABLE `tb_post_triggers`
  ADD CONSTRAINT `FK_POSTTRIGGERS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_POSTTRIGGERS_03` (`oauth_seq`, `status`);

-- ============================================
-- Step 8: tb_user_oauth UNIQUE 제약 변경
-- ============================================
ALTER TABLE `tb_user_oauth`
  DROP INDEX `UNQ_USEROAUTH_01`,
  ADD UNIQUE INDEX `UNQ_USEROAUTH_01` (`user_seq`, `platform_type`, `oauth_id`),
  ADD INDEX `IDX_USEROAUTH_02` (`user_seq`, `platform_type`);

-- ============================================
-- Step 9: tb_monthly_usage에 oauth_seq 컬럼 추가
-- ============================================
ALTER TABLE `tb_monthly_usage`
  ADD COLUMN `oauth_seq` INT UNSIGNED NULL AFTER `user_seq`
    COMMENT '계정별 사용량 추적 (NULL = 기존 통합 데이터)';

-- ============================================
-- Step 10: 기존 사용량 데이터를 첫 번째 계정에 매핑
-- ============================================
UPDATE tb_monthly_usage m
INNER JOIN (
  SELECT user_seq, MIN(seq) as oauth_seq
  FROM tb_user_oauth
  WHERE platform_type = 'INSTAGRAM'
  GROUP BY user_seq
) o ON m.user_seq = o.user_seq
SET m.oauth_seq = o.oauth_seq
WHERE m.oauth_seq IS NULL;

-- ============================================
-- Step 11: tb_monthly_usage 외래 키 및 인덱스 추가
-- ============================================
ALTER TABLE `tb_monthly_usage`
  ADD CONSTRAINT `FK_MONTHLYUSAGE_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_MONTHLYUSAGE_02` (`oauth_seq`, `usage_month`);

-- ============================================
-- Step 12: tb_monthly_usage UNIQUE 제약 재설정
-- ============================================
ALTER TABLE `tb_monthly_usage`
  DROP INDEX `UNQ_USAGE_USER_MONTH`,
  ADD UNIQUE INDEX `UNQ_USAGE_USER_MONTH` (`user_seq`, `oauth_seq`, `usage_month`);

-- ============================================
-- Step 13: tb_account_rate_limit 테이블 생성 (계정별 Rate Limit 관리)
-- ============================================
CREATE TABLE `tb_account_rate_limit` (
  `seq` INT UNSIGNED NOT NULL AUTO_INCREMENT,
  `oauth_seq` INT UNSIGNED NOT NULL COMMENT '계정 식별자',
  `api_type` VARCHAR(50) NOT NULL COMMENT 'API 유형 (DM_SEND, POST_FETCH, COMMENT_READ 등)',
  `window_start` DATETIME NOT NULL COMMENT 'Rate Limit 윈도우 시작 시간',
  `request_count` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT '현재 윈도우 내 요청 수',
  `limit_max` INT UNSIGNED NOT NULL DEFAULT 200 COMMENT '최대 허용 요청 수',
  `is_limited` TINYINT(1) NOT NULL DEFAULT 0 COMMENT 'Rate Limit 도달 여부',
  `limited_until` DATETIME NULL COMMENT 'Rate Limit 해제 예정 시간',
  `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`seq`),
  UNIQUE INDEX `UNQ_RATELIMIT_01` (`oauth_seq`, `api_type`),
  INDEX `IDX_RATELIMIT_02` (`is_limited`, `limited_until`),
  CONSTRAINT `FK_RATELIMIT_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='계정별 Instagram API Rate Limit 관리';

-- ============================================
-- Step 14: 기존 계정에 대해 Rate Limit 초기 레코드 생성
-- ============================================
INSERT INTO tb_account_rate_limit (oauth_seq, api_type, window_start, request_count, limit_max)
SELECT seq, 'DM_SEND', NOW(), 0, 200
FROM tb_user_oauth
WHERE platform_type = 'INSTAGRAM';

INSERT INTO tb_account_rate_limit (oauth_seq, api_type, window_start, request_count, limit_max)
SELECT seq, 'POST_FETCH', NOW(), 0, 200
FROM tb_user_oauth
WHERE platform_type = 'INSTAGRAM';

-- ============================================
-- 마이그레이션 완료 확인 쿼리
-- ============================================
-- 1. 포스트의 oauth_seq가 모두 설정되었는지 확인
SELECT COUNT(*) as orphan_posts
FROM tb_instagram_posts
WHERE oauth_seq IS NULL;
-- 결과: 0이어야 함

-- 2. 트리거의 oauth_seq가 설정되었는지 확인 (Instagram만)
SELECT COUNT(*) as orphan_triggers
FROM tb_post_triggers
WHERE oauth_seq IS NULL;
-- 결과: 0이어야 함

-- 3. 사용자별 계정 수 확인
SELECT user_seq, COUNT(*) as account_count
FROM tb_user_oauth
WHERE platform_type = 'INSTAGRAM'
GROUP BY user_seq
HAVING COUNT(*) > 5;
-- 결과: 0 rows (5개 초과 계정 없음)

-- 4. 사용량 데이터의 oauth_seq가 설정되었는지 확인
SELECT COUNT(*) as orphan_usage
FROM tb_monthly_usage
WHERE oauth_seq IS NULL;
-- 결과: 0이어야 함 (Instagram 사용자의 경우)

-- 5. Rate Limit 테이블 생성 확인
SELECT COUNT(*) as rate_limit_records
FROM tb_account_rate_limit;
-- 결과: (Instagram 계정 수) × 2 이상이어야 함

-- 6. 모든 계정에 DM_SEND Rate Limit 레코드가 있는지 확인
SELECT o.seq as oauth_seq, o.username
FROM tb_user_oauth o
LEFT JOIN tb_account_rate_limit r ON o.seq = r.oauth_seq AND r.api_type = 'DM_SEND'
WHERE o.platform_type = 'INSTAGRAM' AND r.seq IS NULL;
-- 결과: 0 rows (모든 계정에 레코드 존재)

-- ============================================
-- Migration Complete
-- ============================================
