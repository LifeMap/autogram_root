-- ============================================
-- v1.6.0 Rollback: Restore Multi-language Price Columns
-- Version: 1.6.0
-- Date: 2026-01-27
-- Description: 다국어 가격 컬럼 복구 (롤백용)
-- ============================================

USE `sns_automation`;

-- ============================================
-- 1. 다국어 가격 컬럼 복구
-- ============================================

ALTER TABLE `tb_plans`
  ADD COLUMN `fixed_price_en` DECIMAL(12,2) UNSIGNED NULL COMMENT '정가 (달러)' AFTER `price_ko`,
  ADD COLUMN `price_en` DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '판매가 (달러)' AFTER `fixed_price_en`,
  ADD COLUMN `fixed_price_ja` DECIMAL(12,2) UNSIGNED NULL COMMENT '정가 (엔)' AFTER `price_en`,
  ADD COLUMN `price_ja` DECIMAL(12,2) UNSIGNED NOT NULL DEFAULT 0.00 COMMENT '판매가 (엔)' AFTER `fixed_price_ja`;

-- ============================================
-- 2. 기존 데이터 환율 적용하여 복구
-- ============================================

-- 현재 환율 조회 (최신 환율 사용)
SET @usd_rate = (SELECT rate FROM tb_exchange_rates WHERE target_currency = 'USD' ORDER BY seq DESC LIMIT 1);
SET @jpy_rate = (SELECT rate FROM tb_exchange_rates WHERE target_currency = 'JPY' ORDER BY seq DESC LIMIT 1);

-- 기본 환율 설정 (환율 테이블이 비어있는 경우)
SET @usd_rate = IFNULL(@usd_rate, 0.000686);
SET @jpy_rate = IFNULL(@jpy_rate, 0.1077);

-- KRW 가격을 기준으로 USD, JPY 가격 계산 및 업데이트
UPDATE `tb_plans`
SET
  price_en = ROUND(price_ko * @usd_rate, 2),
  fixed_price_en = IF(fixed_price_ko IS NOT NULL, ROUND(fixed_price_ko * @usd_rate, 2), NULL),
  price_ja = ROUND(price_ko * @jpy_rate, 0),
  fixed_price_ja = IF(fixed_price_ko IS NOT NULL, ROUND(fixed_price_ko * @jpy_rate, 0), NULL);

-- ============================================
-- 3. 변경사항 확인
-- ============================================

SELECT
  'tb_plans 테이블 다국어 가격 컬럼 복구 완료' AS status,
  CONCAT('USD 환율: ', @usd_rate) AS usd_rate,
  CONCAT('JPY 환율: ', @jpy_rate) AS jpy_rate;

-- 복구된 데이터 확인
SELECT
  plan_code,
  price_ko,
  price_en,
  price_ja,
  fixed_price_ko,
  fixed_price_en,
  fixed_price_ja
FROM `tb_plans`
WHERE status = 'ACTIVATED'
ORDER BY sort_num;
