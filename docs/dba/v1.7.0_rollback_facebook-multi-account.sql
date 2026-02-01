-- ============================================
-- SNS Automation Database Rollback
-- Version: 1.7.0
-- Feature: Facebook Multi-Account Support
-- ============================================

USE `sns_automation`;

-- Step 1: tb_facebook_pages - oauth_seq 제거
ALTER TABLE `tb_facebook_pages` DROP FOREIGN KEY `FK_FBPAGES_OAUTH`;
ALTER TABLE `tb_facebook_pages` DROP INDEX `IDX_FBPAGES_02`;
ALTER TABLE `tb_facebook_pages` DROP COLUMN `oauth_seq`;

-- Step 2: tb_facebook_posts - oauth_seq 제거 및 UNIQUE 복원
ALTER TABLE `tb_facebook_posts` DROP FOREIGN KEY `FK_FBPOSTS_OAUTH`;
ALTER TABLE `tb_facebook_posts` DROP INDEX `IDX_FBPOSTS_02`;
ALTER TABLE `tb_facebook_posts` DROP INDEX `UNQ_FBPOSTS_01`;
ALTER TABLE `tb_facebook_posts` DROP COLUMN `oauth_seq`;
ALTER TABLE `tb_facebook_posts` ADD UNIQUE INDEX `uk_post_id` (`user_seq`, `post_id`);

-- Rollback Complete
