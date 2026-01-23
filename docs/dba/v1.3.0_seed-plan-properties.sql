-- ============================================
-- v1.3.0 Seed Data for tb_plans and tb_plan_properties
-- Version: 1.3.0
-- Date: 2026-01-17
-- Description: 요금제 플랜 및 속성 초기 데이터 삽입
-- ============================================

USE `sns_automation`;

-- ============================================
-- 1. tb_plans 데이터 삽입
-- ============================================

INSERT INTO `tb_plans` (
  `plan_code`,
  `is_recommended`,
  `name_ko`,
  `name_en`,
  `name_ja`,
  `description_ko`,
  `description_en`,
  `description_ja`,
  `sort_num`,
  `price_ko`,
  `price_en`,
  `price_ja`,
  `status`,
  `created_by`,
  `created_at`
) VALUES
-- FREE 플랜
(
  'FREE',
  0,
  '무료',
  'Free',
  '無料',
  '서비스 테스트 및 소규모 개인 계정용',
  'For service testing and small personal accounts',
  'サービステストと小規模個人アカウント用',
  1,
  0.00,
  0.00,
  0.00,
  'ACTIVATED',
  1,
  NOW()
),
-- MINIMUM 플랜
(
  'MINIMUM',
  0,
  '미니멈',
  'Minimum',
  'ミニマム',
  '1인 크리에이터 및 소규모 인플루언서용',
  'For solo creators and small influencers',
  '1人クリエイターと小規模インフルエンサー用',
  2,
  10000.00,
  8.50,
  1200.00,
  'ACTIVATED',
  1,
  NOW()
),
-- STARTER 플랜
(
  'STARTER',
  1,
  '스타터',
  'Starter',
  'スターター',
  '소규모 비즈니스 및 활발한 크리에이터용',
  'For small businesses and active creators',
  '小規模ビジネスとアクティブなクリエイター用',
  3,
  15000.00,
  13.00,
  1800.00,
  'ACTIVATED',
  1,
  NOW()
),
-- PRO 플랜
(
  'PRO',
  0,
  '프로',
  'Pro',
  'プロ',
  '에이전시, 브랜드, 대규모 마케팅 운영용',
  'For agencies, brands, and large marketing operations',
  'エージェンシー、ブランド、大規模マーケティング運用用',
  4,
  50000.00,
  42.00,
  6000.00,
  'ACTIVATED',
  1,
  NOW()
);

-- ============================================
-- 2. tb_plan_properties 데이터 삽입
-- ============================================

-- --------------------------------------------
-- FREE 플랜 속성 (plan_seq = 1)
-- --------------------------------------------

INSERT INTO `tb_plan_properties` (
  `plan_seq`,
  `prop_code`,
  `display_ko`,
  `display_en`,
  `display_ja`,
  `value_ko`,
  `value_en`,
  `value_ja`,
  `numeric_value`,
  `is_support`,
  `sort_num`
) VALUES
-- DM 발송 한도
(
  1,
  'DM',
  '월간 DM 발송',
  'Monthly DM Sends',
  '月間DM送信',
  '50건',
  '50 sends',
  '50件',
  50.00,
  1,
  1
),
-- 활성 트리거
(
  1,
  'TRIGGER',
  '활성 트리거',
  'Active Triggers',
  'アクティブトリガー',
  '무제한',
  'Unlimited',
  '無制限',
  NULL,
  1,
  2
),
-- 통계 보관 기간
(
  1,
  'ANALYTICS',
  '통계 보관 기간',
  'Analytics Retention',
  '統計保管期間',
  '1일',
  '1 day',
  '1日',
  1.00,
  1,
  3
),
-- CTA 버튼
(
  1,
  'CTA',
  'CTA 버튼',
  'CTA Button',
  'CTAボタン',
  NULL,
  NULL,
  NULL,
  NULL,
  0,
  4
),
-- 초과 사용 정책
(
  1,
  'OVER_USAGE',
  '초과 사용 정책',
  'Overage Policy',
  '超過使用ポリシー',
  '발송 중단',
  'Sending stopped',
  '送信停止',
  0.00,
  1,
  5
);

-- --------------------------------------------
-- MINIMUM 플랜 속성 (plan_seq = 2)
-- --------------------------------------------

INSERT INTO `tb_plan_properties` (
  `plan_seq`,
  `prop_code`,
  `display_ko`,
  `display_en`,
  `display_ja`,
  `value_ko`,
  `value_en`,
  `value_ja`,
  `numeric_value`,
  `is_support`,
  `sort_num`
) VALUES
-- DM 발송 한도
(
  2,
  'DM',
  '월간 DM 발송',
  'Monthly DM Sends',
  '月間DM送信',
  '500건',
  '500 sends',
  '500件',
  500.00,
  1,
  1
),
-- 활성 트리거
(
  2,
  'TRIGGER',
  '활성 트리거',
  'Active Triggers',
  'アクティブトリガー',
  '무제한',
  'Unlimited',
  '無制限',
  NULL,
  1,
  2
),
-- 통계 보관 기간
(
  2,
  'ANALYTICS',
  '통계 보관 기간',
  'Analytics Retention',
  '統計保管期間',
  '30일',
  '30 days',
  '30日',
  30.00,
  1,
  3
),
-- CTA 버튼
(
  2,
  'CTA',
  'CTA 버튼',
  'CTA Button',
  'CTAボタン',
  NULL,
  NULL,
  NULL,
  NULL,
  1,
  4
),
-- 초과 사용 정책
(
  2,
  'OVER_USAGE',
  '초과 사용 정책',
  'Overage Policy',
  '超過使用ポリシー',
  '건당 ₩50 과금',
  '₩50 per send',
  '1件あたり₩50課金',
  50.00,
  1,
  5
);

-- --------------------------------------------
-- STARTER 플랜 속성 (plan_seq = 3)
-- --------------------------------------------

INSERT INTO `tb_plan_properties` (
  `plan_seq`,
  `prop_code`,
  `display_ko`,
  `display_en`,
  `display_ja`,
  `value_ko`,
  `value_en`,
  `value_ja`,
  `numeric_value`,
  `is_support`,
  `sort_num`
) VALUES
-- DM 발송 한도
(
  3,
  'DM',
  '월간 DM 발송',
  'Monthly DM Sends',
  '月間DM送信',
  '1,500건',
  '1,500 sends',
  '1,500件',
  1500.00,
  1,
  1
),
-- 활성 트리거
(
  3,
  'TRIGGER',
  '활성 트리거',
  'Active Triggers',
  'アクティブトリガー',
  '무제한',
  'Unlimited',
  '無制限',
  NULL,
  1,
  2
),
-- 통계 보관 기간
(
  3,
  'ANALYTICS',
  '통계 보관 기간',
  'Analytics Retention',
  '統計保管期間',
  '30일',
  '30 days',
  '30日',
  30.00,
  1,
  3
),
-- CTA 버튼
(
  3,
  'CTA',
  'CTA 버튼',
  'CTA Button',
  'CTAボタン',
  NULL,
  NULL,
  NULL,
  NULL,
  1,
  4
),
-- 초과 사용 정책
(
  3,
  'OVER_USAGE',
  '초과 사용 정책',
  'Overage Policy',
  '超過使用ポリシー',
  '건당 ₩30 과금',
  '₩30 per send',
  '1件あたり₩30課金',
  30.00,
  1,
  5
);

-- --------------------------------------------
-- PRO 플랜 속성 (plan_seq = 4)
-- --------------------------------------------

INSERT INTO `tb_plan_properties` (
  `plan_seq`,
  `prop_code`,
  `display_ko`,
  `display_en`,
  `display_ja`,
  `value_ko`,
  `value_en`,
  `value_ja`,
  `numeric_value`,
  `is_support`,
  `sort_num`
) VALUES
-- DM 발송 한도
(
  4,
  'DM',
  '월간 DM 발송',
  'Monthly DM Sends',
  '月間DM送信',
  '10,000건',
  '10,000 sends',
  '10,000件',
  10000.00,
  1,
  1
),
-- 활성 트리거
(
  4,
  'TRIGGER',
  '활성 트리거',
  'Active Triggers',
  'アクティブトリガー',
  '무제한',
  'Unlimited',
  '無制限',
  NULL,
  1,
  2
),
-- 통계 보관 기간
(
  4,
  'ANALYTICS',
  '통계 보관 기간',
  'Analytics Retention',
  '統計保管期間',
  '90일',
  '90 days',
  '90日',
  90.00,
  1,
  3
),
-- CTA 버튼
(
  4,
  'CTA',
  'CTA 버튼',
  'CTA Button',
  'CTAボタン',
  NULL,
  NULL,
  NULL,
  NULL,
  1,
  4
),
-- 초과 사용 정책
(
  4,
  'OVER_USAGE',
  '초과 사용 정책',
  'Overage Policy',
  '超過使用ポリシー',
  '건당 ₩10 과금',
  '₩10 per send',
  '1件あたり₩10課金',
  10.00,
  1,
  5
);

-- ============================================
-- 3. 검증 쿼리
-- ============================================

-- 플랜 데이터 확인
SELECT
  seq,
  plan_code,
  is_recommended,
  name_ko,
  description_ko,
  price_ko,
  status
FROM tb_plans
ORDER BY sort_num;

-- 속성 데이터 확인 (plan_code와 함께)
SELECT
  p.plan_code,
  pp.prop_code,
  pp.display_ko,
  pp.value_ko,
  pp.numeric_value,
  pp.is_support,
  pp.sort_num
FROM tb_plan_properties pp
JOIN tb_plans p ON pp.plan_seq = p.seq
ORDER BY p.sort_num, pp.sort_num;

-- ============================================
-- End of Seed Data
-- ============================================
