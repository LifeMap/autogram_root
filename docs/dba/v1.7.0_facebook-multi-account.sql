-- ============================================
-- SNS Automation Database Migration
-- Version: 1.7.0
-- Feature: Facebook Multi-Account Support
-- Description: Facebook 연동 계정 단위 관리 (다중 연동 계정 지원)
-- Last Updated: 2026-02-01
-- Note: tb_facebook_pages, tb_facebook_posts, tb_user_oauth(FACEBOOK) 모두 0건이므로
--       기존 데이터 마이그레이션 불필요. 스키마 변경만 수행.
-- ============================================

USE `sns_automation`;

-- ============================================
-- Step 1: tb_facebook_pages에 oauth_seq 컬럼 추가 (NOT NULL, CASCADE)
-- ============================================
ALTER TABLE `tb_facebook_pages`
  ADD COLUMN `oauth_seq` INT UNSIGNED NOT NULL AFTER `user_seq`
    COMMENT '페이지 소유 연동 계정 (tb_user_oauth.seq)',
  ADD CONSTRAINT `FK_FBPAGES_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_FBPAGES_02` (`oauth_seq`);

-- ============================================
-- Step 2: tb_facebook_posts에 oauth_seq 컬럼 추가 (NOT NULL, CASCADE)
-- ============================================
ALTER TABLE `tb_facebook_posts`
  ADD COLUMN `oauth_seq` INT UNSIGNED NOT NULL AFTER `user_seq`
    COMMENT '포스트 소유 연동 계정 (tb_user_oauth.seq)',
  ADD CONSTRAINT `FK_FBPOSTS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_FBPOSTS_02` (`oauth_seq`, `created_time`);

-- ============================================
-- Step 3: UNIQUE 제약 변경 (user_seq+post_id → oauth_seq+post_id)
-- 기존 uk_post_id: (user_seq, post_id)
-- ============================================
ALTER TABLE `tb_facebook_posts`
  DROP INDEX `uk_post_id`,
  ADD UNIQUE INDEX `UNQ_FBPOSTS_01` (`oauth_seq`, `post_id`);

-- ============================================
-- Migration Complete
-- ============================================
