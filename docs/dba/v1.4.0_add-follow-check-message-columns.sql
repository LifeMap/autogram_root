-- ============================================
-- Migration: v1.4.0
-- Description: 팔로우 확인 메시지 커스터마이징 컬럼 추가
-- Date: 2025-01-25
-- ============================================

-- tb_post_triggers 테이블에 팔로우 확인 메시지 커스터마이징 컬럼 추가
ALTER TABLE `tb_post_triggers`
  ADD COLUMN `follow_check_message` VARCHAR(500) NULL
    COMMENT '팔로우 확인 요청 메시지 (커스텀)'
    AFTER `trigger_follow`,
  ADD COLUMN `follow_check_button` VARCHAR(20) NULL
    COMMENT '팔로우 확인 버튼 텍스트 (최대 20자)'
    AFTER `follow_check_message`,
  ADD COLUMN `follow_retry_message` VARCHAR(500) NULL
    COMMENT '팔로우 재확인 메시지 (커스텀)'
    AFTER `follow_check_button`,
  ADD COLUMN `follow_retry_button` VARCHAR(20) NULL
    COMMENT '팔로우 재확인 버튼 텍스트 (최대 20자)'
    AFTER `follow_retry_message`;

-- 확인 쿼리
-- SELECT seq, trigger_word, follow_check_message, follow_check_button, follow_retry_message, follow_retry_button FROM tb_post_triggers LIMIT 10;
