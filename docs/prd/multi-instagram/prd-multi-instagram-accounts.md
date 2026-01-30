# 멀티 인스타그램 계정 연동 PRD

## 1. 개요

### 1.1 목적
현재 1유저 1인스타그램 계정 연동 체계를 1유저 5인스타그램 계정 연동으로 확장하여 경쟁업체와의 차별화를 달성합니다.

**비즈니스 가치:**
- 다중 계정 운영 사용자(에이전시, 인플루언서, 비즈니스 계정 관리자) 유치
- 사용자당 가치(ARPU) 증대
- 경쟁 서비스 대비 기능적 우위 확보

### 1.2 범위

**포함 범위 (MVP):**
- 1유저당 최대 5개 인스타그램 계정 연동
- 트리거 생성 시 계정 선택 기능
- 계정별 독립적인 대시보드
- 계정별 DM 사용량 추적 (과금 정확성)
- 계정별 Instagram API Rate Limit 관리
- 계정 목록 정렬 (계정명 기준)
- 기존 1개 계정 사용자 자동 마이그레이션
- 계정 추가/삭제 기능

**제외 범위:**
- 팀/조직 기능 (여러 사용자가 동일 계정 관리)
- 계정 간 콘텐츠 복사/이동
- 프리미엄 플랜에서의 5개 초과 연동 (향후 고려)

### 1.3 이해관계자
- **제품 책임자**: 기획 담당
- **개발 팀**: 백엔드, 프론트엔드 개발자
- **사용자**: 다중 인스타그램 계정 운영자 (에이전시, 인플루언서, 비즈니스)

---

## 2. 사용자 스토리

### 주요 사용자 페르소나

**페르소나 1: 소셜미디어 에이전시 운영자**
- 역할: 여러 클라이언트의 인스타그램 계정을 관리
- 목표: 클라이언트별 계정을 하나의 대시보드에서 통합 관리
- 불만 사항: 계정마다 로그인/로그아웃을 반복해야 함

**페르소나 2: 멀티 브랜드 인플루언서**
- 역할: 개인 계정 + 브랜드 계정 운영
- 목표: 각 계정별로 독립적인 트리거 설정 및 분석
- 불만 사항: 계정별로 다른 서비스를 사용해야 함

---

### 에픽 1: 멀티 계정 연동 관리

**US-001: 인스타그램 계정 추가**

**사용자 스토리:**
- 기존 사용자로서
- 추가 인스타그램 계정을 연동하고 싶습니다
- 그래서 여러 계정을 하나의 플랫폼에서 관리할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 "인스타그램 계정 추가" 버튼이 제공된다
- [ ] 최대 5개까지 계정을 연동할 수 있다
- [ ] 5개 제한 도달 시 명확한 안내 메시지가 표시된다
- [ ] 각 계정은 고유한 식별자(oauth_id)로 구분된다
- [ ] 계정 추가 시 OAuth 인증 플로우가 정상 작동한다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** 없음

---

**US-002: 연동된 계정 목록 조회**

**사용자 스토리:**
- 사용자로서
- 연동된 모든 인스타그램 계정 목록을 보고 싶습니다
- 그래서 어떤 계정이 연동되어 있는지 확인하고 관리할 수 있습니다

**수락 기준:**
- [ ] 설정 페이지에서 연동된 계정 목록이 카드 형태로 표시된다
- [ ] 각 계정 카드에 프로필 사진, 사용자명(@username), 연동 날짜가 표시된다
- [ ] 계정별 활성 트리거 개수가 표시된다
- [ ] 최대 5개 계정이 그리드 레이아웃으로 표시된다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-001

---

**US-003: 인스타그램 계정 삭제**

**사용자 스토리:**
- 사용자로서
- 연동된 인스타그램 계정을 삭제하고 싶습니다
- 그래서 더 이상 사용하지 않는 계정을 제거할 수 있습니다

**수락 기준:**
- [ ] 각 계정 카드에 "연동 해제" 버튼이 제공된다
- [ ] 삭제 시 확인 다이얼로그가 표시된다
- [ ] 해당 계정에 연결된 포스트, 트리거도 함께 삭제됨을 경고한다
- [ ] 삭제 후 해당 계정의 모든 데이터가 제거된다 (CASCADE)
- [ ] 최소 1개 계정은 유지되어야 한다 (마지막 계정 삭제 불가)

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-002

---

### 에픽 2: 트리거 생성 시 계정 선택

**US-004: 트리거 생성 시 계정 선택**

**사용자 스토리:**
- 사용자로서
- 트리거 생성 시 어떤 인스타그램 계정의 포스트를 사용할지 선택하고 싶습니다
- 그래서 계정별로 독립적인 트리거를 설정할 수 있습니다

**수락 기준:**
- [ ] 트리거 생성 폼 최상단에 "계정 선택" 드롭다운이 표시된다
- [ ] 드롭다운에 연동된 모든 계정이 @username 형태로 표시된다
- [ ] 계정 선택 시 해당 계정의 포스트만 포스트 선택 다이얼로그에 표시된다
- [ ] 계정을 선택하지 않으면 포스트 선택이 비활성화된다
- [ ] 선택한 계정 정보가 트리거 데이터에 저장된다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-001

---

**US-005: 포스트 목록 필터링**

**사용자 스토리:**
- 사용자로서
- 선택한 계정의 포스트만 보고 싶습니다
- 그래서 혼동 없이 올바른 포스트를 선택할 수 있습니다

**수락 기준:**
- [ ] 포스트 선택 다이얼로그에서 선택한 계정의 포스트만 표시된다
- [ ] 계정 전환 시 포스트 목록이 자동으로 갱신된다
- [ ] 각 포스트에 소속 계정 정보가 명확히 표시된다 (선택사항)
- [ ] 포스트 동기화 시 선택한 계정의 포스트만 동기화된다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-004

---

### 에픽 3: 계정별 대시보드

**US-006: 계정별 통계 조회**

**사용자 스토리:**
- 사용자로서
- 각 인스타그램 계정의 성과를 개별적으로 확인하고 싶습니다
- 그래서 계정별 전략을 수립할 수 있습니다

**수락 기준:**
- [ ] 대시보드 상단에 계정 선택 드롭다운이 제공된다
- [ ] "모든 계정" 옵션으로 통합 대시보드를 볼 수 있다
- [ ] 특정 계정 선택 시 해당 계정의 통계만 표시된다
- [ ] 계정별로 활성 트리거, DM 발송, 도달율이 독립적으로 집계된다
- [ ] URL 파라미터로 계정 필터 상태가 유지된다 (예: /dashboard?account_id=123)

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-001

---

**US-007: 통합 대시보드 (모든 계정)**

**사용자 스토리:**
- 사용자로서
- 모든 계정의 통합 성과를 한눈에 보고 싶습니다
- 그래서 전체적인 운영 현황을 파악할 수 있습니다

**수락 기준:**
- [ ] "모든 계정" 선택 시 모든 계정의 데이터가 합산되어 표시된다
- [ ] 상위 트리거 목록에서 계정별 구분이 가능하다 (계정명 표시)
- [ ] 시간별 차트에서 모든 계정의 데이터가 합산된다
- [ ] 최근 활동에서 어떤 계정의 활동인지 명시된다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** US-006

---

### 에픽 4: 데이터 마이그레이션

**US-008: 기존 사용자 데이터 마이그레이션**

**사용자 스토리:**
- 기존 사용자로서
- 시스템 업그레이드 후에도 기존 연동 계정과 데이터가 유지되길 원합니다
- 그래서 서비스 중단 없이 계속 사용할 수 있습니다

**수락 기준:**
- [ ] 기존 `tb_user_oauth` 데이터가 새 스키마로 자동 마이그레이션된다
- [ ] 기존 포스트와 트리거는 첫 번째 계정에 자동 매핑된다
- [ ] 마이그레이션 중 데이터 손실이 없다
- [ ] 마이그레이션 후 기존 기능이 정상 작동한다
- [ ] 롤백 계획이 수립되어 있다

**우선순위:** 필수
**예상 공수:** [개발자와 함께 결정 예정]
**종속성:** 없음

---

## 3. 기능 명세

### 3.1 데이터베이스 스키마 변경

#### 변경사항 1: `tb_user_oauth` 테이블

**현재 구조 (1:1):**
```
- UNIQUE INDEX: (platform_type, oauth_id)
- 1 user_seq → 1 platform_type (INSTAGRAM)
```

**변경 후 구조 (1:N):**
```sql
-- UNIQUE 제약 변경
-- 기존: UNIQUE(platform_type, oauth_id)
-- 변경: UNIQUE(user_seq, platform_type, oauth_id)

ALTER TABLE `tb_user_oauth`
  DROP INDEX `UNQ_USEROAUTH_01`,
  ADD UNIQUE INDEX `UNQ_USEROAUTH_01` (`user_seq`, `platform_type`, `oauth_id`),
  ADD INDEX `IDX_USEROAUTH_02` (`user_seq`, `platform_type`);
```

**비즈니스 규칙:**
1. 1명의 사용자는 동일 플랫폼(INSTAGRAM)에 최대 5개 계정 연동 가능
2. 동일한 oauth_id는 다른 사용자가 재사용 불가 (보안)
3. 계정 삭제 시 관련 포스트, 트리거는 CASCADE로 자동 삭제

**제약 조건 추가:**
```sql
-- 애플리케이션 레벨에서 검증
-- 1. SELECT COUNT(*) FROM tb_user_oauth
--    WHERE user_seq = ? AND platform_type = 'INSTAGRAM'
--    HAVING COUNT(*) < 5
```

---

#### 변경사항 2: `tb_instagram_posts` 테이블

**현재 구조:**
```
- user_seq만 저장 (어떤 계정의 포스트인지 불명확)
```

**변경 후 구조:**
```sql
ALTER TABLE `tb_instagram_posts`
  ADD COLUMN `oauth_seq` INT UNSIGNED NOT NULL AFTER `user_seq`
    COMMENT '포스트 소유 계정 (tb_user_oauth.seq)',
  ADD CONSTRAINT `FK_INSTAPOSTS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_INSTAPOSTS_03` (`oauth_seq`, `created_at`);

-- 기존 UNIQUE 제약 변경
ALTER TABLE `tb_instagram_posts`
  DROP INDEX `UNQ_INSTAPOSTS_01`,
  ADD UNIQUE INDEX `UNQ_INSTAPOSTS_01` (`oauth_seq`, `media_id`);
```

**마이그레이션 로직:**
```sql
-- 기존 포스트를 첫 번째 계정에 매핑
UPDATE tb_instagram_posts p
INNER JOIN (
  SELECT user_seq, MIN(seq) as oauth_seq
  FROM tb_user_oauth
  WHERE platform_type = 'INSTAGRAM'
  GROUP BY user_seq
) o ON p.user_seq = o.user_seq
SET p.oauth_seq = o.oauth_seq;
```

---

#### 변경사항 3: `tb_post_triggers` 테이블

**현재 구조:**
```
- post_seq (tb_instagram_posts.seq)
- user_seq만으로 소유권 확인
```

**변경 후 구조:**
```sql
ALTER TABLE `tb_post_triggers`
  ADD COLUMN `oauth_seq` INT UNSIGNED NULL AFTER `user_seq`
    COMMENT '트리거 소유 계정 (tb_user_oauth.seq, Instagram 트리거인 경우)',
  ADD CONSTRAINT `FK_POSTTRIGGERS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_POSTTRIGGERS_03` (`oauth_seq`, `status`);
```

**비즈니스 규칙:**
1. Instagram 트리거: `oauth_seq` 필수, `post_seq` 필수
2. Facebook 트리거: `oauth_seq` NULL (기존 로직 유지)

**마이그레이션 로직:**
```sql
-- 기존 트리거를 해당 포스트의 계정에 매핑
UPDATE tb_post_triggers t
INNER JOIN tb_instagram_posts p ON t.post_seq = p.seq
SET t.oauth_seq = p.oauth_seq
WHERE t.platform = 'INSTAGRAM';
```

---

#### 변경사항 4: `tb_monthly_usage` 테이블 (계정별 DM 사용량 추적)

**현재 구조:**
```
- user_seq 기준으로만 사용량 집계
- 계정별 사용량 구분 불가
```

**변경 후 구조:**
```sql
ALTER TABLE `tb_monthly_usage`
  ADD COLUMN `oauth_seq` INT UNSIGNED NULL AFTER `user_seq`
    COMMENT '계정별 사용량 추적 (NULL = 기존 통합 데이터)',
  ADD CONSTRAINT `FK_MONTHLYUSAGE_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_MONTHLYUSAGE_02` (`oauth_seq`, `year_month`);

-- UNIQUE 제약 변경 (계정별 독립 집계)
ALTER TABLE `tb_monthly_usage`
  DROP INDEX `UNQ_MONTHLYUSAGE_01`,
  ADD UNIQUE INDEX `UNQ_MONTHLYUSAGE_01` (`user_seq`, `oauth_seq`, `year_month`);
```

**비즈니스 규칙:**
1. DM 발송 시 해당 계정의 `oauth_seq`로 사용량 집계
2. 통합 사용량 조회 시 user_seq 기준 SUM
3. 계정별 사용량 조회 시 oauth_seq 필터
4. 계정 삭제 시 해당 계정의 사용량 기록도 CASCADE 삭제

**마이그레이션 로직:**
```sql
-- 기존 사용량 데이터는 첫 번째 계정에 매핑
UPDATE tb_monthly_usage m
INNER JOIN (
  SELECT user_seq, MIN(seq) as oauth_seq
  FROM tb_user_oauth
  WHERE platform_type = 'INSTAGRAM'
  GROUP BY user_seq
) o ON m.user_seq = o.user_seq
SET m.oauth_seq = o.oauth_seq
WHERE m.oauth_seq IS NULL;
```

---

#### 변경사항 5: `tb_account_rate_limit` 테이블 (신규 - 계정별 Rate Limit 관리)

**목적:**
- Instagram API는 계정별로 Rate Limit 적용 (1시간당 200회 등)
- 계정별 독립적인 Rate Limit 추적 및 관리 필요
- Rate Limit 초과 시 해당 계정만 일시 정지, 다른 계정은 정상 작동

**신규 테이블:**
```sql
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
  CONSTRAINT `FK_RATELIMIT_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='계정별 Instagram API Rate Limit 관리';
```

**비즈니스 규칙:**
1. API 호출 전 Rate Limit 확인, 초과 시 요청 거부
2. Rate Limit 도달 시 해당 계정만 `is_limited = 1` 설정
3. `limited_until` 시간 경과 후 자동 해제
4. 계정 삭제 시 Rate Limit 기록도 CASCADE 삭제

**API 유형별 기본 제한:**
| api_type | limit_max | 윈도우 |
|----------|-----------|--------|
| DM_SEND | 200 | 1시간 |
| POST_FETCH | 200 | 1시간 |
| COMMENT_READ | 500 | 1시간 |
| MEDIA_INSIGHTS | 100 | 1시간 |

---

### 3.2 API 엔드포인트 변경

#### 신규 API

**1. 계정 목록 조회**
```
GET /api/accounts/instagram
요청 파라미터:
- sort (선택): username_asc (기본값), username_desc, connected_at_asc, connected_at_desc

응답:
{
  "success": true,
  "data": [
    {
      "seq": 1,
      "oauth_id": "17841234567890",
      "username": "@my_brand",
      "profile_picture_url": "https://...",
      "connected_at": "2025-01-01T00:00:00Z",
      "active_trigger_count": 5,
      "total_posts": 120,
      "rate_limit_status": {
        "is_limited": false,
        "dm_remaining": 180,
        "dm_reset_at": "2026-01-26T15:00:00Z"
      }
    }
  ],
  "meta": {
    "total": 3,
    "limit": 5,
    "sort": "username_asc"
  }
}

비즈니스 로직:
1. 기본 정렬: 계정명(username) 오름차순 (A-Z)
2. Rate Limit 상태 포함하여 반환
3. is_limited가 true인 계정은 UI에서 경고 표시
```

**2. 계정 추가 (OAuth 콜백 수정)**
```
POST /api/auth/instagram/callback
요청 Body:
{
  "code": "AQD...",
  "state": "..."
}

비즈니스 로직:
1. 현재 사용자의 Instagram 계정 수 확인
2. 5개 미만인 경우에만 추가 허용
3. oauth_id 중복 체크 (다른 사용자가 이미 연동한 계정인지)
4. tb_user_oauth에 INSERT
```

**3. 계정 삭제**
```
DELETE /api/accounts/instagram/:oauthSeq
응답:
{
  "success": true,
  "message": "Account disconnected successfully"
}

비즈니스 로직:
1. 소유권 확인 (user_seq 일치)
2. 최소 1개 계정 유지 검증
3. 삭제 확인 후 CASCADE로 포스트, 트리거 삭제
```

---

#### 수정 API

**4. 포스트 목록 조회 (수정)**
```
GET /api/posts?oauth_seq=123
요청 파라미터:
- oauth_seq (선택): 특정 계정의 포스트만 조회
- 미제공 시: 모든 연동 계정의 포스트 조회

응답:
{
  "success": true,
  "data": {
    "posts": [
      {
        "seq": 1,
        "oauth_seq": 123,
        "account_username": "@my_brand",
        "media_id": "...",
        "caption": "..."
      }
    ]
  }
}
```

**5. 포스트 동기화 (수정)**
```
POST /api/posts/sync
요청 Body:
{
  "oauth_seq": 123,  // 필수: 동기화할 계정
  "limit": 50
}

비즈니스 로직:
1. oauth_seq의 소유권 확인
2. 해당 계정의 액세스 토큰으로 Instagram API 호출
3. oauth_seq와 함께 포스트 저장
```

**6. 트리거 생성 (수정)**
```
POST /api/triggers
요청 Body:
{
  "platform": "INSTAGRAM",
  "oauth_seq": 123,     // 필수: 계정 선택
  "post_seq": 456,
  "trigger_word": "...",
  "dm_message": "..."
}

검증 로직:
1. oauth_seq의 소유권 확인
2. post_seq가 oauth_seq에 속하는지 확인
3. 트리거 생성 시 oauth_seq 저장
```

**7. 통계 조회 (수정)**
```
GET /api/stats?oauth_seq=123
요청 파라미터:
- oauth_seq (선택): 특정 계정의 통계만 조회
- 미제공 시: 모든 계정의 통합 통계

응답:
{
  "success": true,
  "data": {
    "account_filter": "@my_brand",  // oauth_seq 제공 시
    "overview": {
      "todaySent": 100,
      "activeTriggers": 5,
      ...
    }
  }
}
```

**8. 사용량 조회 (수정)**
```
GET /api/usage?oauth_seq=123&year_month=2026-01
요청 파라미터:
- oauth_seq (선택): 특정 계정의 사용량만 조회
- year_month (선택): 특정 월의 사용량 조회
- 미제공 시: 모든 계정의 통합 사용량

응답:
{
  "success": true,
  "data": {
    "total": {
      "dm_sent": 1500,
      "dm_limit": 5000,
      "usage_percent": 30
    },
    "by_account": [
      {
        "oauth_seq": 123,
        "username": "@my_brand",
        "dm_sent": 800,
        "usage_percent": 53.3
      },
      {
        "oauth_seq": 456,
        "username": "@my_shop",
        "dm_sent": 700,
        "usage_percent": 46.7
      }
    ]
  }
}

비즈니스 로직:
1. oauth_seq 제공 시: 해당 계정의 사용량만 반환
2. oauth_seq 미제공 시: 전체 통합 + 계정별 breakdown 반환
3. 과금 기준은 user_seq 기준 통합 사용량 유지
```

**9. Rate Limit 상태 조회**
```
GET /api/accounts/instagram/:oauthSeq/rate-limit
응답:
{
  "success": true,
  "data": {
    "oauth_seq": 123,
    "username": "@my_brand",
    "limits": [
      {
        "api_type": "DM_SEND",
        "request_count": 20,
        "limit_max": 200,
        "remaining": 180,
        "is_limited": false,
        "window_reset_at": "2026-01-26T15:00:00Z"
      },
      {
        "api_type": "POST_FETCH",
        "request_count": 50,
        "limit_max": 200,
        "remaining": 150,
        "is_limited": false,
        "window_reset_at": "2026-01-26T15:00:00Z"
      }
    ]
  }
}
```

**10. Rate Limit 수동 리셋 (관리자용)**
```
POST /api/admin/accounts/:oauthSeq/rate-limit/reset
요청 Body:
{
  "api_type": "DM_SEND"  // 선택, 미제공 시 모든 타입 리셋
}

응답:
{
  "success": true,
  "message": "Rate limit reset successfully"
}

비즈니스 로직:
1. 관리자 권한 필요
2. is_limited = 0, request_count = 0으로 초기화
3. window_start를 현재 시간으로 갱신
```

---

### 3.3 프론트엔드 UI/UX 변경

#### 1. 설정 페이지 (신규 섹션)

**위치:** `/dashboard/settings`

**구성요소:**
```tsx
<AccountManagement>
  <SectionHeader>
    <Title>연동된 인스타그램 계정</Title>
    <HeaderActions>
      <SortDropdown value={sortBy} onChange={setSortBy}>
        <option value="username_asc">계정명 (A-Z)</option>
        <option value="username_desc">계정명 (Z-A)</option>
        <option value="connected_at_asc">연동순 (오래된순)</option>
        <option value="connected_at_desc">연동순 (최신순)</option>
      </SortDropdown>
      <AddButton disabled={accounts.length >= 5}>
        계정 추가 ({accounts.length}/5)
      </AddButton>
    </HeaderActions>
  </SectionHeader>

  <AccountGrid>
    {accounts.map(account => (
      <AccountCard>
        <ProfileImage src={account.profile_picture_url} />
        <Username>@{account.username}</Username>

        {/* Rate Limit 상태 표시 */}
        {account.rate_limit_status.is_limited && (
          <RateLimitBadge variant="warning">
            API 제한 중 ({formatTime(account.rate_limit_status.dm_reset_at)}에 해제)
          </RateLimitBadge>
        )}

        <Stats>
          <div>활성 트리거: {account.active_trigger_count}개</div>
          <div>포스트: {account.total_posts}개</div>
          <div>DM 잔여: {account.rate_limit_status.dm_remaining}/200</div>
        </Stats>
        <DisconnectButton>연동 해제</DisconnectButton>
      </AccountCard>
    ))}
  </AccountGrid>
</AccountManagement>
```

**상호작용:**
- 정렬 드롭다운: 기본값 "계정명 (A-Z)", 선택 시 목록 재정렬
- Rate Limit 뱃지: 제한된 계정에 경고 표시, 클릭 시 상세 정보
- "계정 추가" 클릭 → Instagram OAuth 플로우 시작
- "연동 해제" 클릭 → 확인 다이얼로그 표시 → 삭제

---

#### 2. 트리거 생성 폼 (수정)

**위치:** `/dashboard/triggers/new`

**구성요소:**
```tsx
<TriggerForm>
  {/* 신규: 계정 선택 */}
  <FormField>
    <Label>계정 선택</Label>
    <AccountDropdown>
      {accounts.map(account => (
        <option value={account.seq}>
          @{account.username}
        </option>
      ))}
    </AccountDropdown>
  </FormField>

  {/* 기존: 포스트 선택 (필터링 적용) */}
  <FormField>
    <Label>포스트 선택</Label>
    <PostSelector
      oauthSeq={selectedAccount}
      disabled={!selectedAccount}
    />
  </FormField>

  {/* 기존 필드들... */}
</TriggerForm>
```

**상호작용:**
- 계정 선택 전: 포스트 선택 비활성화
- 계정 선택 후: 해당 계정의 포스트만 표시
- 계정 전환 시: 선택한 포스트 초기화

---

#### 3. 대시보드 (수정)

**위치:** `/dashboard`

**구성요소:**
```tsx
<Dashboard>
  {/* 신규: 계정 필터 */}
  <Header>
    <Title>대시보드</Title>
    <AccountFilter>
      <Select value={selectedAccount} onChange={handleAccountChange}>
        <option value="">모든 계정</option>
        {accounts.map(account => (
          <option value={account.seq}>@{account.username}</option>
        ))}
      </Select>
    </AccountFilter>
  </Header>

  {/* 기존 통계 카드들 (필터 적용) */}
  <StatsGrid>
    {/* 선택한 계정 또는 전체 계정의 통계 표시 */}
  </StatsGrid>
</Dashboard>
```

**상호작용:**
- "모든 계정" 선택: 통합 통계 표시
- 특정 계정 선택: 해당 계정의 통계만 표시
- URL 파라미터로 상태 유지 (`?oauth_seq=123`)

**사용량 표시 (계정별 DM 사용량):**
```tsx
<UsageCard>
  <Title>이번 달 DM 사용량</Title>
  {selectedAccount ? (
    // 특정 계정 선택 시
    <AccountUsage>
      <Progress value={accountUsage.usage_percent} />
      <Text>{accountUsage.dm_sent} / {totalLimit} DM</Text>
    </AccountUsage>
  ) : (
    // 모든 계정 선택 시: 통합 + 계정별 breakdown
    <TotalUsage>
      <Progress value={totalUsage.usage_percent} />
      <Text>{totalUsage.dm_sent} / {totalLimit} DM</Text>
      <AccountBreakdown>
        {usageByAccount.map(account => (
          <BreakdownItem>
            <Username>@{account.username}</Username>
            <Percent>{account.usage_percent}%</Percent>
          </BreakdownItem>
        ))}
      </AccountBreakdown>
    </TotalUsage>
  )}
</UsageCard>
```

---

#### 4. 포스트 선택 다이얼로그 (수정)

**구성요소:**
```tsx
<PostSelector oauthSeq={selectedAccount}>
  <DialogHeader>
    <Title>포스트 선택 - @{accountUsername}</Title>
    <SyncButton onClick={() => syncPosts(oauthSeq)}>
      동기화
    </SyncButton>
  </DialogHeader>

  <PostGrid>
    {/* 선택한 계정의 포스트만 표시 */}
    {posts.filter(p => p.oauth_seq === oauthSeq).map(post => (
      <PostCard post={post} />
    ))}
  </PostGrid>
</PostSelector>
```

---

### 3.4 엣지 케이스 및 오류 처리

#### 케이스 1: 5개 제한 도달 시 계정 추가 시도
**시나리오:** 사용자가 이미 5개 계정을 연동한 상태에서 추가 시도
**처리 방법:**
- 설정 페이지: "계정 추가" 버튼 비활성화 + 툴팁 표시 ("최대 5개까지 연동 가능")
- API: 400 Bad Request + 에러 메시지 ("계정 추가 한도 초과")

#### 케이스 2: 동일 계정 중복 연동 시도
**시나리오:** 사용자가 이미 연동한 계정을 다시 연동 시도
**처리 방법:**
- OAuth 콜백에서 oauth_id 중복 체크
- 409 Conflict + 에러 메시지 ("이미 연동된 계정입니다")

#### 케이스 3: 다른 사용자가 이미 연동한 계정 연동 시도
**시나리오:** 계정 A가 사용자 1에게 연동되어 있는데, 사용자 2가 연동 시도
**처리 방법:**
- OAuth 콜백에서 oauth_id가 다른 user_seq에 이미 존재하는지 체크
- 409 Conflict + 에러 메시지 ("이 계정은 다른 사용자에게 연동되어 있습니다")

#### 케이스 4: 마지막 계정 삭제 시도
**시나리오:** 사용자가 유일한 계정을 삭제 시도
**처리 방법:**
- 프론트엔드: accounts.length === 1일 때 "연동 해제" 버튼 비활성화
- 백엔드: 400 Bad Request + 에러 메시지 ("최소 1개 계정은 유지해야 합니다")

#### 케이스 5: 계정 삭제 시 트리거 존재
**시나리오:** 삭제하려는 계정에 활성 트리거가 존재
**처리 방법:**
- 확인 다이얼로그에 명확한 경고 표시
- "이 계정에 연결된 X개의 트리거와 Y개의 포스트가 모두 삭제됩니다. 계속하시겠습니까?"
- 사용자 확인 후 CASCADE 삭제

#### 케이스 6: OAuth 토큰 만료
**시나리오:** 특정 계정의 액세스 토큰이 만료됨
**처리 방법:**
- 해당 계정 사용 시 401 Unauthorized 반환
- 프론트엔드: 해당 계정 카드에 "재연동 필요" 뱃지 표시
- 재연동 버튼 클릭 → OAuth 플로우 재시작

#### 케이스 7: 포스트 동기화 중 계정 전환
**시나리오:** 계정 A 포스트 동기화 중 사용자가 계정 B로 전환
**처리 방법:**
- 동기화는 백그라운드에서 계속 진행
- 계정 B의 포스트 목록 즉시 표시
- 동기화 완료 시 토스트 알림 ("@account_a 포스트 동기화 완료")

#### 케이스 8: 계정별 Rate Limit 도달
**시나리오:** 특정 계정의 Instagram API Rate Limit 도달
**처리 방법:**
- 해당 계정만 `is_limited = 1` 설정, 다른 계정은 정상 작동
- 프론트엔드: 해당 계정 카드에 "API 제한 중" 경고 뱃지 표시
- 트리거 실행: 해당 계정의 트리거는 대기열에 보관, 해제 후 재시도
- 사용자 알림: "계정 @account_a의 API 사용량이 한도에 도달했습니다. X분 후 자동 해제됩니다."

#### 케이스 9: Rate Limit 해제 후 대기 작업 처리
**시나리오:** Rate Limit 해제 후 대기열에 있던 DM 발송
**처리 방법:**
- 백그라운드 워커가 `limited_until` 경과 확인
- `is_limited = 0`으로 변경, `request_count = 0`으로 리셋
- 대기열의 작업을 순차적으로 처리 (급격한 재요청 방지)
- 처리 완료 시 사용자에게 알림

#### 케이스 10: 여러 계정 동시 Rate Limit
**시나리오:** 사용자의 여러 계정이 동시에 Rate Limit 도달
**처리 방법:**
- 각 계정 독립적으로 Rate Limit 관리
- 대시보드에 전체 계정의 Rate Limit 상태 요약 표시
- "N개 계정이 API 제한 중입니다" 통합 알림

---

## 4. 비기능 요구사항

### 4.1 성능
- **포스트 조회 응답 시간**: 계정당 100개 포스트 기준 < 500ms
- **대시보드 로드 시간**: 모든 계정 통합 통계 < 1초
- **계정 추가 OAuth 플로우**: < 5초 (Instagram API 응답 시간 제외)

### 4.2 보안
- **계정 소유권 검증**: 모든 API 호출 시 user_seq와 oauth_seq 일치 확인
- **OAuth 토큰 관리**: 계정별 독립적인 토큰 저장 및 갱신
- **CASCADE 삭제**: 계정 삭제 시 관련 데이터 완전 제거 (GDPR 준수)

### 4.3 확장성
- **5개 제한 변경 가능성**: 환경 변수로 제한 값 설정 (`MAX_INSTAGRAM_ACCOUNTS=5`)
- **데이터베이스 인덱스**: oauth_seq 기반 조회 최적화
- **페이지네이션**: 계정별 포스트 목록 페이징 유지
- **Rate Limit 설정 가변성**: API 유형별 제한 값을 환경 변수 또는 DB 설정으로 관리
- **Rate Limit 윈도우**: 슬라이딩 윈도우 방식으로 확장 가능 (현재: 고정 윈도우)

### 4.4 호환성
- **브라우저**: Chrome, Firefox, Safari 최신 2개 버전
- **모바일 반응형**: 768px 이하에서 계정 카드 세로 스택

---

## 5. 데이터베이스 마이그레이션 계획

### 5.1 마이그레이션 스크립트

**파일명:** `v1.5.0_multi-instagram-accounts.sql`

```sql
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
WHERE t.platform = 'INSTAGRAM' AND t.post_seq IS NOT NULL;

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
-- Step 11: tb_monthly_usage 제약조건 및 인덱스 추가
-- ============================================
ALTER TABLE `tb_monthly_usage`
  ADD CONSTRAINT `FK_MONTHLYUSAGE_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_MONTHLYUSAGE_02` (`oauth_seq`, `year_month`),
  DROP INDEX `UNQ_MONTHLYUSAGE_01`,
  ADD UNIQUE INDEX `UNQ_MONTHLYUSAGE_01` (`user_seq`, `oauth_seq`, `year_month`);

-- ============================================
-- Step 12: tb_account_rate_limit 테이블 생성 (계정별 Rate Limit 관리)
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
-- Step 13: 기존 계정에 대해 Rate Limit 초기 레코드 생성
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
WHERE platform = 'INSTAGRAM' AND oauth_seq IS NULL;
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
```

### 5.2 롤백 계획

**파일명:** `v1.5.0_rollback_multi-instagram-accounts.sql`

```sql
-- ============================================
-- Step 1: tb_account_rate_limit 테이블 삭제
-- ============================================
DROP TABLE IF EXISTS `tb_account_rate_limit`;

-- ============================================
-- Step 2: tb_monthly_usage 롤백
-- ============================================
ALTER TABLE `tb_monthly_usage`
  DROP FOREIGN KEY `FK_MONTHLYUSAGE_OAUTH`,
  DROP INDEX `IDX_MONTHLYUSAGE_02`,
  DROP INDEX `UNQ_MONTHLYUSAGE_01`,
  ADD UNIQUE INDEX `UNQ_MONTHLYUSAGE_01` (`user_seq`, `year_month`),
  DROP COLUMN `oauth_seq`;

-- ============================================
-- Step 3: 제약조건 제거
-- ============================================
ALTER TABLE `tb_post_triggers`
  DROP FOREIGN KEY `FK_POSTTRIGGERS_OAUTH`,
  DROP INDEX `IDX_POSTTRIGGERS_03`,
  DROP COLUMN `oauth_seq`;

ALTER TABLE `tb_instagram_posts`
  DROP FOREIGN KEY `FK_INSTAPOSTS_OAUTH`,
  DROP INDEX `IDX_INSTAPOSTS_03`,
  DROP INDEX `UNQ_INSTAPOSTS_01`,
  ADD UNIQUE INDEX `UNQ_INSTAPOSTS_01` (`user_seq`, `media_id`),
  DROP COLUMN `oauth_seq`;

-- ============================================
-- Step 4: tb_user_oauth UNIQUE 제약 복원
-- ============================================
ALTER TABLE `tb_user_oauth`
  DROP INDEX `UNQ_USEROAUTH_01`,
  DROP INDEX `IDX_USEROAUTH_02`,
  ADD UNIQUE INDEX `UNQ_USEROAUTH_01` (`platform_type`, `oauth_id`);

-- ============================================
-- Step 5: 추가된 계정 삭제 (첫 번째 계정만 유지)
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
```

### 5.3 마이그레이션 체크리스트

- [ ] 프로덕션 데이터베이스 풀 백업
- [ ] 스테이징 환경에서 마이그레이션 테스트
- [ ] 마이그레이션 스크립트 실행 시간 측정 (예상: < 1분)
- [ ] 마이그레이션 완료 확인 쿼리 실행
- [ ] 애플리케이션 배포 (API + Frontend)
- [ ] 기존 기능 회귀 테스트
- [ ] 신규 기능 동작 확인
- [ ] 롤백 계획 준비 (필요시 즉시 실행 가능)

---

## 6. 일정 및 마일스톤

| 단계 | 기간 | 산출물 | 담당자 |
|-----|------|-------|-------|
| **1단계: 설계 및 검토** | 2일 | 기술 설계 문서, DB 스키마 최종안 | 백엔드 개발자, DBA |
| **2단계: 백엔드 개발** | 5일 | API 구현, 마이그레이션 스크립트 | 백엔드 개발자 |
| **3단계: 프론트엔드 개발** | 5일 | UI 컴포넌트, 계정 관리 페이지 | 프론트엔드 개발자 |
| **4단계: 통합 및 테스팅** | 3일 | 테스트 완료, 버그 수정 | QA, 전체 팀 |
| **5단계: 스테이징 배포** | 1일 | 스테이징 환경 검증 | DevOps, QA |
| **6단계: 프로덕션 배포** | 1일 | 프로덕션 배포, 모니터링 | DevOps, 전체 팀 |

**총 예상 기간:** 17일 (약 3.5주)

**주요 마일스톤:**
- **M1 (7일차)**: 백엔드 API 및 DB 마이그레이션 완료
- **M2 (12일차)**: 프론트엔드 UI 구현 완료
- **M3 (15일차)**: 통합 테스팅 완료
- **M4 (17일차)**: 프로덕션 배포 완료

---

## 7. 위험 및 이슈

| 위험 | 영향도 | 발생 가능성 | 완화 방안 |
|-----|-------|-----------|---------|
| **마이그레이션 중 데이터 손실** | 높음 | 낮음 | 풀 백업, 스테이징 테스트, 롤백 계획 |
| **기존 사용자 혼란** | 중간 | 중간 | 인앱 가이드, 이메일 공지, 헬프 센터 문서 |
| **Instagram API 제한** | 중간 | 중간 | Rate Limit 모니터링, 계정별 동기화 큐 |
| **5개 제한 비즈니스 정책 변경** | 낮음 | 중간 | 환경 변수로 설정 값 관리 |
| **포스트/트리거 CASCADE 삭제 오해** | 중간 | 높음 | 명확한 경고 메시지, 2단계 확인 |

**알려진 이슈:**
- **이슈 1**: Facebook 계정 연동 기능과의 혼동 가능성
  - **해결 계획**: 설정 페이지에서 Instagram/Facebook 섹션 명확히 구분

---

## 8. 성공 지표 (KPI)

| 지표 | 현재값 | 목표값 | 측정 방법 |
|-----|-------|-------|---------|
| **2개 이상 계정 연동 사용자 비율** | 0% | 30% | SELECT COUNT(DISTINCT user_seq) / total_users WHERE account_count >= 2 |
| **평균 연동 계정 수** | 1.0 | 1.8 | AVG(account_count) FROM user_oauth_count |
| **계정당 평균 트리거 수** | - | 2.5 | AVG(trigger_count) FROM account_trigger_stats |
| **계정 추가 성공률** | - | 95% | (성공 / 전체 시도) × 100 |
| **기능 사용 후 사용자 만족도** | - | 4.5/5.0 | 인앱 설문조사 |

**정성적 지표:**
- 사용자 피드백: "여러 계정 관리가 편리해졌다" 긍정 피드백 수집
- 고객 지원 문의: 계정 관리 관련 문의 감소

---

## 9. 대시보드 통합 vs 계정별 대시보드 의견

### 9.1 현재 대시보드 분석

**현재 대시보드 구조:**
- 월간 DM 사용량 (user_seq 기준 집계)
- 오늘 발송 건수
- 활성 트리거 수
- 도달율
- 시간별 발송 차트
- 상위 트리거 목록
- 최근 활동

**통합 대시보드로 적합한 이유:**
✅ 모든 통계가 이미 user_seq 기준으로 집계됨
✅ 계정 필터만 추가하면 쉽게 확장 가능
✅ 사용자가 "전체 성과"를 한눈에 볼 수 있음
✅ 추가 페이지 없이 드롭다운 하나로 해결

### 9.2 권장 구조

**통합 대시보드 + 계정 필터 방식 채택**

```tsx
<Dashboard>
  <Header>
    <Title>대시보드</Title>
    <AccountFilter>
      <Select>
        <option value="">모든 계정 통합</option>
        <option value="123">@account_1</option>
        <option value="456">@account_2</option>
      </Select>
    </AccountFilter>
  </Header>

  {/* 통계 카드, 차트 등 (필터 적용) */}
</Dashboard>
```

**장점:**
1. **사용자 경험**: 페이지 전환 없이 계정별/통합 뷰 즉시 전환
2. **개발 효율**: 기존 대시보드 로직 재사용, 필터 로직만 추가
3. **유지보수**: 단일 대시보드 컴포넌트 관리
4. **성능**: API 엔드포인트 하나로 모든 케이스 처리 (`/api/stats?oauth_seq=123`)

**제공 기능:**
- "모든 계정": 전체 통합 통계 (기본값)
- 특정 계정 선택: 해당 계정만의 독립 통계
- URL 파라미터로 상태 유지 (`/dashboard?oauth_seq=123`)

### 9.3 향후 고려사항

**선택사항 (2차 버전):**
- 계정별 비교 차트 (여러 계정을 한 차트에 표시)
- 계정별 목표 설정 및 달성률
- 계정별 성과 순위

---

## 10. 부록

### 10.1 용어집
- **oauth_seq**: `tb_user_oauth` 테이블의 시퀀스(PK), 연동된 계정의 고유 식별자
- **user_seq**: `tb_users` 테이블의 시퀀스(PK), 사용자 고유 식별자
- **멀티 계정**: 1명의 사용자가 여러 개의 인스타그램 계정을 연동한 상태
- **통합 대시보드**: 모든 연동 계정의 통계를 합산하여 표시하는 대시보드

### 10.2 참고 자료
- Instagram Graph API 문서: https://developers.facebook.com/docs/instagram-api
- 데이터베이스 스키마: `/docs/dba/init.sql`
- 기존 사용자 인증 플로우: `/api/src/controllers/authController.js`

### 10.3 변경 이력
| 날짜 | 버전 | 변경사항 | 작성자 |
|------|------|---------|-------|
| 2026-01-26 | 1.0 | 초안 작성 | Claude (PRD 분석가) |
| 2026-01-26 | 1.1 | 계정별 DM 사용량 추적 MVP 포함 (tb_monthly_usage 스키마 변경, 사용량 API 추가) | Claude |
| 2026-01-26 | 1.2 | 계정별 Rate Limit 관리 추가 (tb_account_rate_limit 테이블, Rate Limit API), 계정 목록 정렬 기능 추가 (기본값: 계정명 A-Z) | Claude |

---

## 11. 구현 참고사항 (개발자용)

### 11.1 백엔드 체크리스트

**데이터베이스:**
- [ ] 마이그레이션 스크립트 작성 및 테스트
- [ ] 롤백 스크립트 준비
- [ ] 인덱스 성능 테스트 (oauth_seq 기반 조회)

**API:**
- [ ] `GET /api/accounts/instagram` - 계정 목록 조회 (sort 파라미터, 기본값: username_asc)
- [ ] `DELETE /api/accounts/instagram/:oauthSeq` - 계정 삭제
- [ ] `POST /api/auth/instagram/callback` - OAuth 콜백 수정 (5개 제한 검증)
- [ ] `GET /api/posts?oauth_seq=123` - 포스트 목록 필터링
- [ ] `POST /api/posts/sync` - oauth_seq 파라미터 추가
- [ ] `POST /api/triggers` - oauth_seq 검증 및 저장
- [ ] `GET /api/stats?oauth_seq=123` - 통계 필터링
- [ ] `GET /api/usage?oauth_seq=123` - 계정별 사용량 조회
- [ ] `GET /api/accounts/instagram/:oauthSeq/rate-limit` - Rate Limit 상태 조회
- [ ] `POST /api/admin/accounts/:oauthSeq/rate-limit/reset` - Rate Limit 수동 리셋

**비즈니스 로직:**
- [ ] 계정 수 5개 제한 검증
- [ ] oauth_id 중복 체크 (동일 사용자 + 다른 사용자)
- [ ] 최소 1개 계정 유지 검증
- [ ] 소유권 검증 (user_seq + oauth_seq)
- [ ] CASCADE 삭제 확인
- [ ] Rate Limit 체크 (API 호출 전 is_limited 확인)
- [ ] Rate Limit 카운터 증가 (API 호출 후 request_count++)
- [ ] Rate Limit 윈도우 리셋 (1시간 경과 시 자동 리셋)
- [ ] Rate Limit 도달 시 대기열 처리

### 11.2 프론트엔드 체크리스트

**컴포넌트:**
- [ ] `AccountManagement.tsx` - 계정 목록 및 추가/삭제
- [ ] `AccountCard.tsx` - 계정 카드 UI
- [ ] `AccountDropdown.tsx` - 계정 선택 드롭다운
- [ ] `TriggerForm.tsx` 수정 - 계정 선택 필드 추가
- [ ] `PostSelector.tsx` 수정 - oauth_seq 필터링
- [ ] `Dashboard.tsx` 수정 - 계정 필터

**API 연동:**
- [ ] `useAccounts()` - 계정 목록 조회 훅 (sort 파라미터 지원)
- [ ] `useAddAccount()` - 계정 추가 훅
- [ ] `useDeleteAccount()` - 계정 삭제 훅
- [ ] `usePosts()` - oauth_seq 파라미터 추가
- [ ] `useStats()` - oauth_seq 파라미터 추가
- [ ] `useUsage()` - 계정별 사용량 조회 훅
- [ ] `useRateLimit()` - 계정별 Rate Limit 상태 조회 훅

**UI/UX:**
- [ ] 계정 카드 그리드 레이아웃 (반응형)
- [ ] 5개 제한 도달 시 버튼 비활성화 + 툴팁
- [ ] 계정 삭제 확인 다이얼로그
- [ ] 계정 전환 시 로딩 상태 표시
- [ ] 오류 메시지 다국어 지원
- [ ] 계정 목록 정렬 드롭다운 (기본값: 계정명 A-Z)
- [ ] Rate Limit 경고 뱃지 (is_limited 시 표시)
- [ ] Rate Limit 상세 정보 팝오버/모달
- [ ] DM 잔여 횟수 표시 (계정 카드)

### 11.3 테스팅 체크리스트

**단위 테스트:**
- [ ] 계정 수 제한 검증 로직
- [ ] oauth_id 중복 체크 로직
- [ ] 소유권 검증 로직
- [ ] 포스트 필터링 로직
- [ ] 통계 집계 로직 (계정별/통합)
- [ ] 사용량 집계 로직 (계정별/통합)
- [ ] Rate Limit 체크 로직 (is_limited 확인)
- [ ] Rate Limit 카운터 증가 로직
- [ ] Rate Limit 윈도우 리셋 로직
- [ ] 계정 목록 정렬 로직 (username_asc/desc)

**통합 테스트:**
- [ ] 계정 추가 → 포스트 동기화 → 트리거 생성 플로우
- [ ] 계정 삭제 → CASCADE 삭제 확인
- [ ] 계정 전환 → 대시보드/포스트 목록 갱신
- [ ] 마이그레이션 → 기존 데이터 정합성
- [ ] Rate Limit 도달 → 해당 계정만 제한 → 다른 계정 정상 작동
- [ ] Rate Limit 해제 → 대기열 작업 처리

**E2E 테스트:**
- [ ] 신규 사용자: 첫 계정 연동 → 추가 계정 연동 (5개까지)
- [ ] 기존 사용자: 마이그레이션 후 추가 계정 연동
- [ ] 계정 삭제 → 재연동
- [ ] 모든 브라우저에서 계정 관리 기능 동작 확인

---

**PRD 승인:**
- [ ] 제품 책임자
- [ ] 백엔드 개발 리드
- [ ] 프론트엔드 개발 리드
- [ ] DBA

**다음 단계:** 기술 설계 문서 작성 및 개발 시작
