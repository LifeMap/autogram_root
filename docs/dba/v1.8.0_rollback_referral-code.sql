-- ============================================
-- SNS Automation Database Rollback
-- Version: 1.8.0
-- Feature: Referral Code System
-- Description: 추천인 코드 시스템 롤백
-- Last Updated: 2026-02-09
-- Warning: tb_referral_coupons 데이터 및 user_code 데이터가 삭제됩니다
-- ============================================

USE `sns_automation`;

-- ============================================
-- Step 1: tb_monthly_usage에서 bonus_dm_count 컬럼 제거
-- ============================================
ALTER TABLE `tb_monthly_usage`
  DROP COLUMN `bonus_dm_count`;

-- ============================================
-- Step 2: tb_referral_coupons 테이블 삭제
-- ============================================
DROP TABLE IF EXISTS `tb_referral_coupons`;

-- ============================================
-- Step 3: tb_users에서 referrer_user_seq, user_code 컬럼 제거
-- ============================================
ALTER TABLE `tb_users`
  DROP FOREIGN KEY `FK_USERS_REFERRER`,
  DROP INDEX `IDX_USERS_REFERRER`,
  DROP COLUMN `referrer_user_seq`,
  DROP INDEX `UNQ_USERS_USER_CODE`,
  DROP COLUMN `user_code`;

-- ============================================
-- Rollback Complete
-- ============================================
