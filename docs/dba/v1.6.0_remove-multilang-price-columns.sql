-- ============================================
-- v1.6.0 Remove Multi-language Price Columns
-- Version: 1.6.0
-- Date: 2026-01-27
-- Description: 환율 기반 실시간 가격 계산으로 전환, 다국어 가격 컬럼 제거
-- ============================================

USE `sns_automation`;

-- ============================================
-- 1. tb_plans 테이블에서 다국어 가격 컬럼 제거
-- ============================================

ALTER TABLE `tb_plans`
  DROP COLUMN IF EXISTS `fixed_price_en`,
  DROP COLUMN IF EXISTS `price_en`,
  DROP COLUMN IF EXISTS `fixed_price_ja`,
  DROP COLUMN IF EXISTS `price_ja`;

-- ============================================
-- 2. 변경사항 확인
-- ============================================

SELECT
  'tb_plans 테이블 구조 변경 완료' AS status,
  'price_ko 기준 환율 실시간 계산 방식으로 전환' AS description;

-- 현재 테이블 구조 확인
DESCRIBE `tb_plans`;
