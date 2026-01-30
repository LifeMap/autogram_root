-- ============================================
-- SNS Automation Database Rollback Script
-- Version: 1.5.0
-- Feature: Multi-Instagram Accounts Support Rollback
-- Description: v1.5.0 마이그레이션을 v1.3.0으로 롤백
-- Last Updated: 2026-01-26
-- ============================================

USE `sns_automation`;

-- ============================================
-- Step 1: tb_account_rate_limit 테이블 삭제
-- ============================================
DROP TABLE IF EXISTS `tb_account_rate_limit`;

-- ============================================
-- Step 2: tb_monthly_usage UNIQUE 제약 롤백
-- ============================================
ALTER TABLE `tb_monthly_usage`
  DROP INDEX `UNQ_USAGE_USER_MONTH`,
  ADD UNIQUE INDEX `UNQ_USAGE_USER_MONTH` (`user_seq`, `usage_month`);

-- ============================================
-- Step 3: tb_monthly_usage 외래 키 및 컬럼 삭제
-- ============================================
ALTER TABLE `tb_monthly_usage`
  DROP FOREIGN KEY `FK_MONTHLYUSAGE_OAUTH`,
  DROP INDEX `IDX_MONTHLYUSAGE_02`,
  DROP COLUMN `oauth_seq`;

-- ============================================
-- Step 4: tb_post_triggers 롤백
-- ============================================
ALTER TABLE `tb_post_triggers`
  DROP FOREIGN KEY `FK_POSTTRIGGERS_OAUTH`,
  DROP INDEX `IDX_POSTTRIGGERS_03`,
  DROP COLUMN `oauth_seq`;

-- ============================================
-- Step 5: tb_instagram_posts 롤백
-- ============================================
ALTER TABLE `tb_instagram_posts`
  DROP FOREIGN KEY `FK_INSTAPOSTS_OAUTH`,
  DROP INDEX `IDX_INSTAPOSTS_03`,
  DROP INDEX `UNQ_INSTAPOSTS_01`,
  ADD UNIQUE INDEX `UNQ_INSTAPOSTS_01` (`user_seq`, `media_id`),
  DROP COLUMN `oauth_seq`;

-- ============================================
-- Step 6: tb_user_oauth UNIQUE 제약 복원
-- ============================================
ALTER TABLE `tb_user_oauth`
  DROP INDEX `UNQ_USEROAUTH_01`,
  DROP INDEX `IDX_USEROAUTH_02`,
  ADD UNIQUE INDEX `UNQ_USEROAUTH_01` (`platform_type`, `oauth_id`);

-- ============================================
-- Step 7: 추가된 계정 삭제 (첫 번째 계정만 유지)
-- ============================================
DELETE o1 FROM tb_user_oauth o1
INNER JOIN (
  SELECT user_seq, MIN(seq) as keep_seq
  FROM tb_user_oauth
  WHERE platform_type = 'INSTAGRAM'
  GROUP BY user_seq
) o2 ON o1.user_seq = o2.user_seq
WHERE o1.platform_type = 'INSTAGRAM'
  AND o1.seq != o2.keep_seq;

-- ============================================
-- Rollback 완료 확인 쿼리
-- ============================================
-- 1. tb_account_rate_limit 테이블 삭제 확인
SHOW TABLES LIKE 'tb_account_rate_limit';
-- 결과: Empty set (테이블이 삭제되어야 함)

-- 2. tb_instagram_posts의 oauth_seq 컬럼 삭제 확인
SHOW COLUMNS FROM tb_instagram_posts LIKE 'oauth_seq';
-- 결과: Empty set (컬럼이 삭제되어야 함)

-- 3. tb_post_triggers의 oauth_seq 컬럼 삭제 확인
SHOW COLUMNS FROM tb_post_triggers LIKE 'oauth_seq';
-- 결과: Empty set (컬럼이 삭제되어야 함)

-- 4. tb_monthly_usage의 oauth_seq 컬럼 삭제 확인
SHOW COLUMNS FROM tb_monthly_usage LIKE 'oauth_seq';
-- 결과: Empty set (컬럼이 삭제되어야 함)

-- 5. 사용자별 Instagram 계정이 1개씩만 남았는지 확인
SELECT user_seq, COUNT(*) as account_count
FROM tb_user_oauth
WHERE platform_type = 'INSTAGRAM'
GROUP BY user_seq
HAVING COUNT(*) > 1;
-- 결과: 0 rows (모든 사용자가 1개씩만 가져야 함)

-- 6. tb_user_oauth UNIQUE 제약 복원 확인
SHOW INDEX FROM tb_user_oauth WHERE Key_name = 'UNQ_USEROAUTH_01';
-- 결과: Column_name이 'platform_type', 'oauth_id'만 포함되어야 함

-- ============================================
-- Rollback Complete
-- ============================================
