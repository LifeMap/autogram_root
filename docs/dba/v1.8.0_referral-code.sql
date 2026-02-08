-- ============================================
-- SNS Automation Database Migration
-- Version: 1.8.0
-- Feature: Referral Code System
-- Description: 추천인 코드 시스템 (유저코드, 추천인 등록, 보너스 쿠폰)
-- Last Updated: 2026-02-09
-- ============================================

USE `sns_automation`;

-- ============================================
-- Step 1: tb_users에 user_code, referrer_user_seq 컬럼 추가
-- ============================================
ALTER TABLE `tb_users`
  ADD COLUMN `user_code` VARCHAR(8) NULL AFTER `is_beta_tester`
    COMMENT '추천 코드 [A-Z0-9]{8}',
  ADD COLUMN `referrer_user_seq` INT UNSIGNED NULL AFTER `user_code`
    COMMENT '추천인 user seq',
  ADD UNIQUE INDEX `UNQ_USERS_USER_CODE` (`user_code`),
  ADD INDEX `IDX_USERS_REFERRER` (`referrer_user_seq`),
  ADD CONSTRAINT `FK_USERS_REFERRER`
    FOREIGN KEY (`referrer_user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE SET NULL;

-- ============================================
-- Step 2: 기존 회원 유저코드 일괄 생성
-- Note: 애플리케이션 마이그레이션 스크립트에서 처리 (crypto.randomBytes)
--       또는 아래 프로시저로 수동 실행
-- ============================================
-- 기존 회원이 있는 경우 아래 프로시저 실행:
DELIMITER //
CREATE PROCEDURE generate_user_codes()
BEGIN
  DECLARE done INT DEFAULT FALSE;
  DECLARE v_seq INT;
  DECLARE v_code VARCHAR(8);
  DECLARE v_exists INT;
  DECLARE cur CURSOR FOR SELECT seq FROM tb_users WHERE user_code IS NULL;
  DECLARE CONTINUE HANDLER FOR NOT FOUND SET done = TRUE;

  OPEN cur;
  read_loop: LOOP
    FETCH cur INTO v_seq;
    IF done THEN LEAVE read_loop; END IF;

    SET v_exists = 1;
    WHILE v_exists > 0 DO
      SET v_code = UPPER(SUBSTRING(MD5(RAND()), 1, 8));
      SELECT COUNT(*) INTO v_exists FROM tb_users WHERE user_code = v_code;
    END WHILE;

    UPDATE tb_users SET user_code = v_code WHERE seq = v_seq;
  END LOOP;
  CLOSE cur;
END //
DELIMITER ;

CALL generate_user_codes();
DROP PROCEDURE IF EXISTS generate_user_codes;

-- ============================================
-- Step 3: tb_referral_coupons 테이블 생성
-- ============================================
CREATE TABLE `tb_referral_coupons` (
  `seq` INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '쿠폰 ID',
  `user_seq` INT UNSIGNED NOT NULL COMMENT '쿠폰 소유자 (피추천인)',
  `referrer_user_seq` INT UNSIGNED NOT NULL COMMENT '추천인 user seq',
  `dm_amount` INT UNSIGNED NOT NULL DEFAULT 100 COMMENT '추가 DM 발송량',
  `status` ENUM('AVAILABLE', 'USED', 'EXPIRED') NOT NULL DEFAULT 'AVAILABLE' COMMENT '쿠폰 상태',
  `issued_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '발급일',
  `expires_at` DATETIME(6) NOT NULL COMMENT '만료일',
  `used_at` DATETIME(6) NULL COMMENT '사용일',
  `applied_month` CHAR(7) NULL COMMENT '적용된 월 (YYYY-MM)',
  `created_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `updated_at` DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),

  INDEX `IDX_COUPON_USER` (`user_seq`),
  INDEX `IDX_COUPON_STATUS` (`user_seq`, `status`),
  INDEX `IDX_COUPON_EXPIRES` (`status`, `expires_at`),
  UNIQUE INDEX `UNQ_COUPON_PAIR` (`user_seq`, `referrer_user_seq`),

  CONSTRAINT `FK_COUPON_USER` FOREIGN KEY (`user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE,
  CONSTRAINT `FK_COUPON_REFERRER` FOREIGN KEY (`referrer_user_seq`) REFERENCES `tb_users` (`seq`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='추천 보너스 쿠폰';

-- ============================================
-- Step 4: tb_monthly_usage에 bonus_dm_count 컬럼 추가
-- ============================================
ALTER TABLE `tb_monthly_usage`
  ADD COLUMN `bonus_dm_count` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `dm_sent_count`
    COMMENT '쿠폰 보너스 DM 발송량';

-- ============================================
-- Migration Complete
-- ============================================
