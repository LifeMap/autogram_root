# 페이스북 다중 연동 계정 지원 PRD

## 1. 개요

### 1.1 목적
현재 시스템은 Instagram 플랫폼에 대해서는 Autogram 계정당 최대 5개의 Instagram 연동 계정을 지원하지만, Facebook은 연동 계정 단위의 관리 없이 페이지 단위로만 관리됩니다. 이 기능은 Instagram과 동일하게 Facebook 연동 계정을 최대 5개까지 추가하고, 각 연동 계정의 여러 페이지를 계층적으로 관리할 수 있도록 개선합니다.

**비즈니스 가치:**
- 사용자 경험 통일: Instagram과 Facebook의 연동 계정 관리 방식을 일관되게 제공
- 멀티 연동 계정 마케팅: 여러 브랜드/비즈니스를 운영하는 사용자를 위한 효율적인 관리 도구 제공
- 데이터 격리: 연동 계정별 사용량, Rate Limit, 트리거를 독립적으로 관리하여 안정성 향상

### 1.2 범위

**포함 범위:**
- Facebook 연동 계정 최대 5개 지원
- `tb_user_oauth` 테이블을 활용한 연동 계정 단위 관리 (`platform_type = 'FACEBOOK'`)
- `tb_facebook_pages` 테이블에 `oauth_seq` 컬럼 추가하여 연동 계정-페이지 관계 설정
- `tb_facebook_posts` 테이블에 `oauth_seq` 컬럼 추가하여 연동 계정별 포스트 관리
- `tb_post_triggers` 테이블의 Facebook 트리거에 `oauth_seq` 연결
- 연동 계정 해제 시 해당 연동 계정의 모든 페이지, 포스트, 트리거 삭제 (CASCADE)
- 프론트엔드: 연동 계정 선택 → 페이지 선택 2단계 UI 구현
- Facebook 트리거에 `oauth_seq` 연결하여 CASCADE 삭제 지원

**제외 범위:**
- 페이지별 개별 연동 해제 (연동 계정 단위로만 관리)
- 일괄 트리거 설정 기능 (각 페이지별 트리거는 개별 설정)
- 연동 계정별 Rate Limit 관리 (향후 버전에서 고려)
- 연동 계정별 사용량 추적 (향후 버전에서 고려)

**향후 계획:**
- v1.6.x: 연동 계정별 Facebook API Rate Limit 관리 (`tb_account_rate_limit`)
- v1.7.x: 연동 계정별 월별 사용량 추적 (`tb_monthly_usage`에 Facebook 지원)
- v1.8.x: 일괄 트리거 설정 (한 번에 여러 페이지/포스트에 동일 트리거 적용)

### 1.3 이해관계자

- **제품 책임자**: PRD 작성자
- **개발 팀**: 백엔드 개발자, 프론트엔드 개발자
- **데이터베이스**: DBA (마이그레이션 스크립트 검토)
- **사용자**: 멀티 브랜드 마케터, 에이전시, 개인 크리에이터

---

## 2. 사용자 스토리

### 주요 사용자 페르소나

**페르소나 1: 멀티 브랜드 마케터 (김마케)**
- 역할: 3개의 다른 브랜드를 운영하는 마케팅 담당자
- 목표: 각 브랜드의 Facebook 페이지를 별도의 연동 계정으로 관리하면서도 하나의 Autogram 계정에서 통합 관리
- 불만 사항: 현재는 모든 페이지가 섞여서 표시되어 어느 Facebook 연동 계정에서 관리하는 페이지인지 구분이 어려움

**페르소나 2: SNS 에이전시 운영자 (박에이전)**
- 역할: 클라이언트의 여러 Facebook 연동 계정을 대행 관리
- 목표: 클라이언트별로 연동 계정을 분리하여 데이터와 트리거를 독립적으로 관리
- 불만 사항: 연동 계정 해제 시 관련 트리거가 남아있어 혼란 발생

---

### 사용자 스토리 목록

**에픽 1: Facebook 다중 연동 계정**

#### **US-001: Facebook 연동 계정 추가**
- **역할**: 멀티 브랜드 마케터로서
- **기능**: 최대 5개의 Facebook 연동 계정을 추가하고 싶습니다
- **이유**: 각 브랜드별 Facebook 연동 계정을 분리하여 관리할 수 있도록

**수락 기준:**
- [ ] 사용자가 "Facebook 연동 계정 추가" 버튼을 클릭하면 Facebook OAuth 인증 페이지로 이동한다
- [ ] OAuth 인증 완료 후 `/me/accounts` API를 통해 사용자가 관리하는 모든 페이지 목록을 조회한다
- [ ] 사용자가 원하는 페이지들을 선택하면 해당 Facebook 사용자 정보가 `tb_user_oauth`에 저장된다 (`platform_type = 'FACEBOOK'`)
- [ ] 선택한 페이지들은 `tb_facebook_pages`에 저장되며 `oauth_seq`가 해당 연동 계정을 참조한다
- [ ] 이미 5개의 Facebook 연동 계정이 있는 상태에서 추가 시도 시 "Facebook 연동 계정은 최대 5개까지만 추가 가능합니다" 오류 메시지를 표시한다
- [ ] 동일한 Facebook 사용자 (`oauth_id`)를 중복 연동하려고 하면 "이미 연동된 Facebook 계정입니다" 오류 메시지를 표시한다

**우선순위:** 필수
**예상 공수:** 백엔드 3일, 프론트엔드 2일
**종속성:** 없음

---

#### **US-002: Facebook 연동 계정 목록 조회**
- **역할**: 사용자로서
- **기능**: 내가 추가한 모든 Facebook 연동 계정 목록을 연동 계정별로 구분하여 보고 싶습니다
- **이유**: 어느 연동 계정에 어떤 페이지들이 연결되어 있는지 한눈에 파악할 수 있도록

**수락 기준:**
- [ ] 설정 페이지에서 Facebook 연동 계정 목록을 카드 형태로 표시한다
- [ ] 각 연동 계정 카드에는 Facebook 사용자명(또는 이메일), 연동된 페이지 수, 활성 트리거 수가 표시된다
- [ ] 연동 계정 카드를 펼치면 해당 연동 계정에 속한 페이지 목록이 표시된다
- [ ] 페이지 목록에는 페이지명, 프로필 이미지, 포스트 수, 트리거 수가 표시된다
- [ ] 연동 계정별로 마지막 동기화 시간이 표시된다

**우선순위:** 필수
**예상 공수:** 프론트엔드 2일
**종속성:** US-001

---

#### **US-003: Facebook 연동 계정 해제**
- **역할**: 사용자로서
- **기능**: 추가한 Facebook 연동 계정을 해제하고 싶습니다
- **이유**: 더 이상 사용하지 않는 연동 계정을 정리하여 관리를 단순화하기 위해

**수락 기준:**
- [ ] 연동 계정 카드에 "연동 해제" 버튼이 표시된다
- [ ] 연동 해제 버튼 클릭 시 확인 다이얼로그가 표시되며, 삭제될 데이터 목록을 보여준다:
  - 해당 연동 계정의 페이지 N개
  - 해당 연동 계정의 포스트 M개
  - 해당 연동 계정의 트리거 K개
- [ ] 사용자가 확인하면 해당 연동 계정 (`tb_user_oauth`)이 삭제되고, CASCADE로 연결된 모든 데이터가 삭제된다
- [ ] 모든 연동 계정(Instagram + Facebook 포함)을 해제해도 정상적으로 진행된다 (최소 연동 계정 유지 제한 없음)
- [ ] 해제 완료 후 "연동 계정이 성공적으로 해제되었습니다" 성공 메시지를 표시한다
- [ ] 관련 캐시(연동 계정 목록, 포스트, 트리거)가 무효화된다

**우선순위:** 필수
**예상 공수:** 백엔드 2일, 프론트엔드 1일
**종속성:** US-001, US-002

---

**에픽 2: 연동 계정별 페이지 및 포스트 관리**

#### **US-004: 연동 계정별 페이지 선택 UI**
- **역할**: 사용자로서
- **기능**: 트리거를 생성할 때 연동 계정을 먼저 선택한 후 해당 연동 계정의 페이지를 선택하고 싶습니다
- **이유**: 많은 페이지 중에서 원하는 페이지를 빠르게 찾기 위해

**수락 기준:**
- [ ] Facebook 포스트 선택 다이얼로그에 "연동 계정 선택" 드롭다운이 추가된다
- [ ] 연동 계정 선택 시 해당 연동 계정에 속한 페이지만 필터링되어 표시된다
- [ ] 연동 계정을 변경하면 페이지 목록이 자동으로 업데이트된다
- [ ] 페이지 선택 후 해당 페이지의 포스트 목록이 표시된다
- [ ] 포스트 동기화 버튼을 클릭하면 선택한 페이지의 최신 포스트를 Facebook API에서 가져온다

**우선순위:** 필수
**예상 공수:** 프론트엔드 2일
**종속성:** US-001

---

#### **US-005: 대시보드 연동 계정 필터**
- **역할**: 사용자로서
- **기능**: 대시보드에서 특정 연동 계정의 데이터만 필터링하여 보고 싶습니다
- **이유**: 각 브랜드/클라이언트별 성과를 독립적으로 확인하기 위해

**수락 기준:**
- [ ] 대시보드 상단에 "연동 계정 필터" 드롭다운이 표시된다
- [ ] 드롭다운에는 "전체", "Instagram 연동 계정 목록", "Facebook 연동 계정 목록"이 그룹화되어 표시된다
- [ ] Facebook 연동 계정을 선택하면 해당 연동 계정의 페이지들의 포스트와 트리거만 표시된다
- [ ] 선택한 필터는 `localStorage`에 저장되어 브라우저 재시작 후에도 유지된다. 저장된 연동 계정이 해제된 경우 "전체"로 자동 폴백한다
- [ ] 통계(활성 트리거 수, DM 발송 수)도 선택한 연동 계정에 해당하는 데이터만 집계된다

**우선순위:** 중요
**예상 공수:** 백엔드 2일, 프론트엔드 2일
**종속성:** US-001, US-004

---

**에픽 3: 데이터 정합성 개선**

#### **US-006: Facebook 트리거 oauth_seq 연결**
- **역할**: 시스템 관리자로서
- **기능**: Facebook 트리거에 `oauth_seq`를 연결하여 연동 계정 해제 시 CASCADE로 자동 삭제되기를 원합니다
- **이유**: 현재 Facebook 트리거의 `oauth_seq`가 NULL이므로 `tb_user_oauth` 삭제 시 CASCADE가 작동하지 않아 고아 트리거(orphan trigger)가 발생함

**현황 분석:**
- Instagram: `tb_post_triggers.oauth_seq`가 정상 연결 → CASCADE 작동 ✅
- Facebook: `tb_post_triggers.oauth_seq`가 NULL → CASCADE 미작동 ❌
- 원인: `handleFacebookCallback`이 `saveFacebookOAuth()`를 호출하지 않아 `tb_user_oauth`에 연동 계정이 저장되지 않고, 트리거 생성 시 `oauth_seq`가 설정되지 않음

**수락 기준:**
- [ ] 마이그레이션에서 기존 Facebook 트리거의 `oauth_seq`를 해당 포스트의 `oauth_seq`로 업데이트한다
- [ ] 새로 생성되는 Facebook 트리거에 `oauth_seq`가 자동으로 설정된다
- [ ] 연동 계정 해제 시 해당 연동 계정의 모든 Facebook 트리거가 CASCADE로 삭제된다
- [ ] 삭제된 트리거 수가 로그에 기록된다

**우선순위:** 필수
**예상 공수:** 백엔드 1일, 테스트 1일
**종속성:** 없음 (독립적인 데이터 정합성 수정)

> **참고**: `facebookService.js:832-864`에 `saveFacebookOAuth()` 함수가 이미 구현되어 있으나, `authController.handleFacebookCallback`에서 호출되지 않고 있음. 이 함수의 `findOrCreate` 조건은 `user_seq + platform_type`으로만 검색하여 다중 연동 계정을 지원하지 못하므로, `oauth_id`를 조건에 추가해야 함.

---

## 3. 기능 명세

### 3.1 현재 Instagram 다중 연동 계정 구조 분석

Instagram은 v1.5.0 마이그레이션을 통해 다중 연동 계정을 지원합니다:

**핵심 테이블 구조:**
1. **`tb_user_oauth`**: 연동 계정 정보 저장
   - `platform_type = 'INSTAGRAM'`
   - `user_seq`와 `oauth_id` 조합으로 UNIQUE 제약
   - 플랫폼당 최대 5개 연동 계정 제한은 애플리케이션 레벨에서 검증

2. **`tb_instagram_posts`**: 포스트와 연동 계정 연결
   - `oauth_seq` 컬럼으로 어느 연동 계정의 포스트인지 식별
   - UNIQUE 제약: `(oauth_seq, media_id)`

3. **`tb_post_triggers`**: 트리거와 연동 계정 연결
   - `oauth_seq` 컬럼으로 어느 연동 계정의 트리거인지 식별
   - CASCADE 삭제로 연동 계정 해제 시 트리거 자동 삭제

4. **`tb_monthly_usage`**: 연동 계정별 사용량 추적
   - `oauth_seq` 컬럼으로 연동 계정별 DM 사용량 관리

5. **`tb_account_rate_limit`**: 연동 계정별 Rate Limit 관리
   - Instagram API 호출 제한을 연동 계정별로 추적

**장점:**
- 연동 계정별 독립적인 데이터 관리
- 연동 계정 해제 시 CASCADE로 안전한 정리
- 연동 계정별 사용량 및 Rate Limit 추적 가능

---

### 3.2 Facebook 다중 연동 계정 지원 상세 설계

#### **기능 1: Facebook OAuth 연동 계정 정보 저장**

**설명:**
Facebook OAuth 인증 후 연동 계정 정보를 `tb_user_oauth`에 저장합니다. Instagram과 동일하게 `platform_type = 'FACEBOOK'`으로 구분합니다.

**입력값:**
- 필수: `userSeq`, `oauthId` (Facebook User ID), `accessToken`, `expiresIn`
- 선택: `username` (Facebook 프로필명 또는 이메일)

**출력값:**
- 성공: `tb_user_oauth` 레코드 생성/업데이트, `oauth_seq` 반환
- 실패:
  - 5개 초과 시: "Facebook 연동 계정은 최대 5개까지만 추가 가능합니다"
  - 중복 연동 시: "이미 연동된 Facebook 계정입니다"

**비즈니스 규칙:**
1. Autogram 계정당 최대 5개의 Facebook 연동 계정을 추가할 수 있다
2. `user_seq`, `platform_type`, `oauth_id` 조합은 UNIQUE (`UNQ_USEROAUTH_01`)
3. `api_access_token`은 Long-Lived Token으로 저장한다 (60일)
4. `api_refresh_token`은 Facebook이 제공하지 않으므로 `access_token`과 동일하게 저장

**엣지 케이스:**
- **케이스 1**: 토큰 만료 → 사용자에게 재인증 요청 알림
- **케이스 2**: 이미 해제된 연동 계정 재연동 → 새로운 레코드로 생성
- **케이스 3**: Facebook API 오류 → 명확한 오류 메시지 반환 및 롤백

---

#### **기능 2: 페이지와 연동 계정 연결**

**설명:**
사용자가 선택한 Facebook 페이지들을 `tb_facebook_pages`에 저장하며, `oauth_seq`로 어느 연동 계정에서 연동했는지 추적합니다.

**입력값:**
- 필수: `oauthSeq`, `pageId`, `pageName`, `pageAccessToken`
- 선택: `profilePictureUrl`

**출력값:**
- 성공: `tb_facebook_pages` 레코드 생성, 페이지 정보 반환
- 실패: "페이지 저장에 실패했습니다"

**비즈니스 규칙:**
1. 하나의 페이지는 하나의 연동 계정(`oauth_seq`)에만 속한다
2. 동일한 `page_id`는 시스템 전체에서 UNIQUE하다 (여러 Autogram 계정이 같은 페이지를 연동할 수 없음)
3. Page Access Token은 Long-Lived Token으로 저장된다
4. Webhook 구독은 페이지 저장 후 자동으로 설정된다 (실패해도 페이지 저장은 유지)

**구현 참고:**
- `models/index.js`에 `UserOAuth → FacebookPage`, `UserOAuth → FacebookPost` Sequelize association 추가 필요 (현재 누락)

**엣지 케이스:**
- **케이스 1**: 이미 다른 Autogram 계정이 연동한 페이지 → "이미 다른 사용자가 연동한 페이지입니다" 오류
- **케이스 2**: 페이지 권한 부족 → "페이지 관리 권한이 없습니다" 오류
- **케이스 3**: Page Access Token 없음 → "페이지 토큰을 가져올 수 없습니다" 오류

---

#### **기능 3: 포스트와 연동 계정 연결**

**설명:**
Facebook 페이지의 포스트를 동기화할 때 `tb_facebook_posts`에 `oauth_seq`를 저장하여 어느 연동 계정의 포스트인지 식별합니다.

**입력값:**
- 필수: `pageSeq`, `postId`, `oauthSeq`
- 선택: `message`, `fullPicture`, `permalinkUrl`, `createdTime`

**출력값:**
- 성공: 동기화된 포스트 수, 신규 포스트 수, 업데이트된 포스트 수
- 실패: "포스트 동기화에 실패했습니다"

**비즈니스 규칙:**
1. `oauth_seq`와 `post_id` 조합은 UNIQUE해야 한다
2. 포스트의 `oauth_seq`는 해당 페이지의 `oauth_seq`와 동일해야 한다
3. S3가 설정된 경우 이미지를 S3에 저장하고 `stored_picture_url`에 CloudFront URL을 저장한다
4. 동기화 시 기존 포스트는 최신 정보로 업데이트된다

**구현 참고:**
- `facebookService.syncFacebookPosts()`의 `findOrCreate` 조건을 `user_seq + post_id`에서 `oauth_seq + post_id`로 변경해야 함 (UNIQUE 인덱스 변경에 맞춤)

**엣지 케이스:**
- **케이스 1**: 페이지 토큰 만료 → 페이지 상태를 `SUSPENDED`로 변경하고 재인증 요청
- **케이스 2**: Facebook API 오류 → 부분 동기화된 데이터는 유지하고 오류 로그 기록
- **케이스 3**: S3 저장 실패 → 원본 URL만 저장하고 동기화는 계속 진행

---

#### **기능 4: 트리거와 연동 계정 연결**

**설명:**
Facebook 포스트에 트리거를 생성할 때 `tb_post_triggers`의 `oauth_seq`를 해당 포스트의 연동 계정으로 설정합니다.

**입력값:**
- 필수: `userSeq`, `facebookPostSeq`, `triggerWord`, `dmMessage`
- 선택: `replyComment`, `buttonTitle`, `buttonUrl`

**출력값:**
- 성공: 생성된 트리거 정보
- 실패: "트리거 생성에 실패했습니다"

**비즈니스 규칙:**
1. 트리거의 `oauth_seq`는 해당 포스트의 `oauth_seq`와 동일해야 한다
2. `platform = 'FACEBOOK'`인 경우 `facebook_post_seq`는 필수, `post_seq`는 NULL
3. 동일한 `facebook_post_seq`, `trigger_word`, `status` 조합은 UNIQUE

**엣지 케이스:**
- **케이스 1**: 포스트가 삭제된 경우 → "포스트를 찾을 수 없습니다" 오류
- **케이스 2**: 중복 트리거 단어 → "이미 동일한 트리거가 존재합니다" 오류

---

#### **기능 5: Facebook 연동 계정 해제**

**설명:**
사용자가 Facebook 연동 계정을 해제하면 해당 연동 계정의 모든 페이지, 포스트, 트리거가 CASCADE로 삭제됩니다.

**입력값:**
- 필수: `userSeq`, `oauthSeq`

**출력값:**
- 성공: 삭제된 페이지 수, 포스트 수, 트리거 수 반환
- 실패:
  - 권한 없음: "연동 계정 해제 권한이 없습니다"

**비즈니스 규칙:**
1. 모든 연동 계정을 해제해도 정상적으로 진행된다 (최소 연동 계정 유지 제한 없음)
2. 삭제는 트랜잭션으로 처리되어 원자성(Atomicity)을 보장한다
3. 삭제 순서: 트리거 → 포스트 → 페이지 → 연동 계정 (OAuth)
4. 삭제 전 COUNT 쿼리로 삭제될 페이지/포스트/트리거 수를 조회한 후, CASCADE 삭제를 실행하여 삭제 수를 응답에 포함한다

**구현 참고:**
- `authService.withdrawAccount()`에 Facebook 데이터 삭제 로직 추가 필요: `tb_user_oauth WHERE platform_type='FACEBOOK'` 삭제 시 CASCADE로 페이지/포스트/트리거 자동 정리
- `accountService.deleteAccount()`의 최소 연동 계정 카운트 로직을 제거하여 모든 연동 계정 해제를 허용하도록 수정 필요

**엣지 케이스:**
- **케이스 1**: 해제 중 오류 발생 → 전체 롤백하고 오류 메시지 반환
- **케이스 2**: 이미 해제된 연동 계정 → "연동 계정을 찾을 수 없습니다" 404 오류
- **케이스 3**: 다른 Autogram 계정의 연동 계정 해제 시도 → "권한이 없습니다" 403 오류

---

### 3.3 화면/UI 요구사항

#### **화면 1: Facebook 연동 계정 설정 페이지**
- **위치**: `/dashboard/settings/facebook`
- **구성요소**:
  - Facebook 연동 계정 목록 (카드 레이아웃)
  - "Facebook 연동 계정 추가" 버튼 (연동 수가 5개 미만일 때만 활성화)
  - 각 연동 계정 카드:
    - Facebook 프로필 이미지 (없으면 기본 Facebook 아이콘)
    - Facebook 사용자명 (또는 이메일)
    - 연동된 페이지 수
    - 활성 트리거 수
    - "연동 해제" 버튼
  - 연동 계정 카드 확장 시:
    - 해당 연동 계정의 페이지 목록 (페이지명, 프로필 이미지, 포스트 수, 트리거 수)
- **상호작용**:
  - "Facebook 연동 계정 추가" 버튼 클릭 → Facebook OAuth 인증 페이지로 이동
  - "연동 해제" 버튼 클릭 → 확인 다이얼로그 표시 → 해제 실행
  - 연동 계정 카드 클릭 → 확장/축소
- **반응형**: 모바일/태블릿/데스크톱 모두 지원

---

#### **화면 2: Facebook 포스트 선택 다이얼로그**
- **위치**: 트리거 생성 페이지 내 모달
- **구성요소**:
  - "연동 계정 선택" 드롭다운 (새로 추가)
  - "페이지 선택" 드롭다운 (연동 계정 선택 후 활성화)
  - 포스트 그리드 (3열 레이아웃)
  - "동기화" 버튼
- **상호작용**:
  - 연동 계정 선택 → 해당 연동 계정의 페이지 목록 로드
  - 페이지 선택 → 해당 페이지의 포스트 목록 로드
  - 동기화 버튼 클릭 → 선택한 페이지의 최신 포스트 가져오기
  - 포스트 클릭 → 선택 상태 토글
- **반응형**: 모바일에서는 2열로 축소

---

#### **화면 3: 대시보드 연동 계정 필터**
- **위치**: 대시보드 상단
- **구성요소**:
  - "연동 계정 필터" 드롭다운
  - 드롭다운 내용:
    - "전체" (기본값)
    - Instagram 그룹:
      - @username1
      - @username2
    - Facebook 그룹:
      - Facebook 사용자명1
      - Facebook 사용자명2
- **상호작용**:
  - 연동 계정 선택 → 해당 연동 계정의 데이터만 필터링하여 표시
  - 선택 상태는 `localStorage`에 저장되어 브라우저 재시작 후에도 유지. 해제된 연동 계정 선택 시 "전체"로 자동 폴백
- **반응형**: 모바일에서는 전체 너비로 표시

---

### 3.4 API 요구사항

#### **API 1: Facebook OAuth 연동 계정 저장**

**엔드포인트**: 기존 `GET /api/auth/facebook/callback` 흐름 유지 (Instagram과 동일한 리다이렉트 패턴)

> 현재 `handleFacebookCallback`이 OAuth 인증 후 프론트엔드로 리다이렉트만 수행하고 `saveFacebookOAuth()`를 호출하지 않음. 기존 callback 흐름에 `saveFacebookOAuth()` 호출을 추가하고, `findOrCreate` 조건에 `oauth_id`를 추가(`UNQ_USEROAUTH_01`: `user_seq, platform_type, oauth_id`)하여 다중 연동 계정을 지원하도록 수정.

**기존 흐름 (수정)**:
1. `GET /api/auth/facebook/login` → Facebook OAuth 페이지로 리다이렉트
2. `GET /api/auth/facebook/callback` → `saveFacebookOAuth()` 호출 추가 → 프론트엔드로 리다이렉트
3. 프론트엔드 리다이렉트 URL에 `status=success` 또는 `error=MAX_ACCOUNTS` 파라미터 포함 (Instagram과 동일 패턴)

**리다이렉트 (성공)**:
```
{FRONTEND_URL}/dashboard/settings/facebook?status=success&oauthSeq=123
```

**리다이렉트 (실패)**:
```
{FRONTEND_URL}/dashboard/settings/facebook?error=MAX_ACCOUNTS&message=Facebook 연동 계정은 최대 5개까지만 추가 가능합니다
{FRONTEND_URL}/dashboard/settings/facebook?error=DUPLICATE_ACCOUNT&message=이미 연동된 Facebook 계정입니다
```

---

#### **API 2: Facebook 연동 계정 목록 조회**

> 기존 `authRoutes`에 있던 Facebook 페이지 관련 라우트(`/api/auth/facebook/pages`, `/api/auth/link-facebook`, `/api/auth/unlink-facebook/:pageSeq`)를 `accountRoutes`로 이동하여 Instagram과 패턴 통일.

**엔드포인트**: `GET /api/accounts/facebook`

**쿼리 파라미터**:
- `sort`: 정렬 방식 (기본값: `connected_at_desc`)

**응답 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "accounts": [
      {
        "seq": 123,
        "oauthId": "facebook_user_id",
        "username": "user@example.com",
        "connectedAt": "2026-01-15T10:30:00Z",
        "totalPages": 3,
        "totalPosts": 150,
        "activeTriggerCount": 5,
        "pages": [
          {
            "seq": 1,
            "pageId": "page_id_1",
            "pageName": "Brand Page 1",
            "profilePictureUrl": "https://...",
            "totalPosts": 50,
            "activeTriggerCount": 2
          }
        ]
      }
    ]
  },
  "meta": {
    "total": 2,
    "limit": 5
  }
}
```

---

#### **API 3: Facebook 연동 계정 해제**

**엔드포인트**: `DELETE /api/accounts/facebook/:oauthSeq`

**응답 (200 OK)**:
```json
{
  "success": true,
  "message": "연동 계정이 성공적으로 해제되었습니다",
  "data": {
    "deletedPages": 3,
    "deletedPosts": 150,
    "deletedTriggers": 5
  }
}
```

---

#### **API 4: 연동 계정별 페이지 목록 조회**

**엔드포인트**: `GET /api/accounts/facebook/:oauthSeq/pages`

**응답 (200 OK)**:
```json
{
  "success": true,
  "data": {
    "pages": [
      {
        "seq": 1,
        "pageId": "page_id_1",
        "pageName": "Brand Page 1",
        "profilePictureUrl": "https://...",
        "totalPosts": 50,
        "activeTriggerCount": 2,
        "lastSyncedAt": "2026-01-20T14:30:00Z"
      }
    ]
  }
}
```

---

#### **API 5: (삭제됨)**

> Instagram 연동 계정 해제 시 트리거 삭제는 이미 `tb_post_triggers.oauth_seq`의 CASCADE로 정상 작동함. 별도 API 수정 불필요.

---

## 4. 데이터베이스 스키마 변경사항

### 4.1 마이그레이션 파일: `v1.6.0_facebook-multi-account.sql`

```sql
-- ============================================
-- SNS Automation Database Migration
-- Version: 1.6.0
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
```

---

### 4.2 데이터 모델 다이어그램

```
tb_users (Autogram 계정)
    ↓ 1:N
tb_user_oauth (연동 계정)
    ├─ platform_type: ENUM('INSTAGRAM', 'FACEBOOK', 'TIKTOK')
    ├─ UNQ_USEROAUTH_01: UNIQUE (user_seq, platform_type, oauth_id)
    └─ 플랫폼당 최대 5개 연동 계정 (애플리케이션 레벨 검증)
    ↓ 1:N
tb_facebook_pages (페이지)
    ├─ oauth_seq (FK → tb_user_oauth.seq, CASCADE)
    ├─ page_id: UNIQUE
    └─ page_access_token
    ↓ 1:N
tb_facebook_posts (포스트)
    ├─ oauth_seq (FK → tb_user_oauth.seq, CASCADE)
    ├─ page_seq (FK → tb_facebook_pages.seq, CASCADE)
    └─ UNIQUE (oauth_seq, post_id)
    ↓ 1:N
tb_post_triggers (트리거)
    ├─ oauth_seq (FK → tb_user_oauth.seq, CASCADE)
    ├─ facebook_post_seq (FK → tb_facebook_posts.seq, CASCADE)
    ├─ platform: 'FACEBOOK'
    └─ UNIQUE (facebook_post_seq, trigger_word, status)
```

---

## 5. 비기능 요구사항

### 5.1 성능
- **페이지 로드**: 연동 계정 목록 페이지 < 2초
- **동시 사용자**: 1,000명 동시 사용자 지원
- **API 응답 시간**:
  - 연동 계정 목록 조회 < 500ms
  - 페이지 동기화 < 3초 (50개 포스트 기준)
- **데이터베이스 쿼리**: 모든 쿼리에 인덱스 활용, N+1 문제 방지

### 5.2 보안
- **인증**: JWT 토큰 기반 인증
- **권한 부여**:
  - 사용자는 본인의 연동 계정만 조회/해제 가능
  - 연동 계정 해제 시 `user_seq` 검증 필수
- **데이터 보호**:
  - Facebook Access Token은 암호화하여 저장 (향후 고려)
  - API 요청 시 HTTPS 필수
- **SQL Injection 방지**: Sequelize ORM 사용, Prepared Statement

### 5.3 접근성
- **WCAG 준수 수준**: AA
- **키보드 내비게이션**: 모든 버튼과 드롭다운 키보드 접근 가능
- **스크린 리더 지원**: ARIA 레이블 추가

### 5.4 호환성
- **브라우저**: Chrome, Firefox, Safari, Edge 최신 2개 버전
- **기기**: iOS 14+, Android 10+
- **화면 해상도**: 320px (모바일) ~ 2560px (데스크톱)

---

## 6. 기술 스택 권장사항

| 영역 | 기술 | 선정 근거 |
|-----|------|---------|
| **백엔드** | Node.js + Express.js | 기존 코드베이스와 일관성 유지 |
| **ORM** | Sequelize | 기존 사용 중, 마이그레이션 스크립트 지원 |
| **데이터베이스** | MySQL 8.0+ | 기존 사용 중, CASCADE 삭제 지원 |
| **프론트엔드** | Next.js 14 + TypeScript | 기존 사용 중, 타입 안정성 |
| **상태 관리** | TanStack Query (React Query) | 기존 사용 중, 서버 상태 관리 최적화 |
| **UI 라이브러리** | shadcn/ui | 기존 사용 중, 일관된 디자인 시스템 |

---

## 7. 일정 및 마일스톤

| 단계 | 기간 | 산출물 | 담당자 |
|-----|------|-------|-------|
| **1단계: 설계** | D+0 ~ D+2 | 기술 설계 문서, DB 마이그레이션 스크립트 | 백엔드 개발자, DBA |
| **2단계: 백엔드 개발** | D+3 ~ D+8 | API 구현 완료 (OAuth, 연동 계정 관리, 페이지 관리) | 백엔드 개발자 |
| **3단계: 프론트엔드 개발** | D+6 ~ D+11 | UI 컴포넌트 구현 (연동 계정 설정, 포스트 선택, 필터) | 프론트엔드 개발자 |
| **4단계: 통합 테스팅** | D+12 ~ D+14 | E2E 테스트, 버그 수정 | QA, 개발자 |
| **5단계: 배포** | D+15 | 프로덕션 배포, 모니터링 설정 | DevOps, 백엔드 개발자 |

**주요 마일스톤:**
- **M1**: D+2 - DB 마이그레이션 스크립트 승인
- **M2**: D+8 - 백엔드 API 개발 완료 및 Postman 테스트
- **M3**: D+11 - 프론트엔드 UI 개발 완료
- **M4**: D+14 - 통합 테스팅 완료
- **M5**: D+15 - 프로덕션 배포

**일정 제약사항:**
- DB 마이그레이션은 새벽 시간대(02:00-04:00)에 실행
- 배포는 트래픽이 적은 수요일 새벽에 진행
- 롤백 계획 수립 필수

---

## 8. 위험 및 이슈

| 위험 | 영향도 | 발생 가능성 | 완화 방안 |
|-----|-------|-----------|---------|
| **DB 마이그레이션 실패** | 높음 | 낮음 | 스테이징 환경에서 충분히 테스트, 롤백 스크립트 준비 |
| **기존 데이터 손실** | 높음 | 낮음 | 마이그레이션 전 전체 DB 백업, 단계별 검증 쿼리 실행 |
| **Facebook API 변경** | 중간 | 중간 | Graph API 버전 고정, 변경 사항 모니터링 |
| **성능 저하** | 중간 | 낮음 | 인덱스 최적화, 쿼리 프로파일링, 캐싱 적용 |
| **UI 혼란** | 낮음 | 중간 | 사용자 가이드 제공, 온보딩 툴팁 추가 |
| **Facebook oauth_seq 마이그레이션** | 중간 | 낮음 | 기존 Facebook 트리거 전체 검증 |

**알려진 이슈:**
- **이슈 1**: Facebook 트리거의 `oauth_seq`가 NULL → 이번 버전에서 마이그레이션으로 수정
- **이슈 2**: Facebook Page Access Token 갱신 로직 부재 → 향후 버전에서 자동 갱신 구현
- **이슈 3**: 5개 제한 검증이 프론트엔드만 있고 백엔드 없음 → 백엔드 검증 추가 필요

---

## 9. 성공 지표 (KPI)

| 지표 | 현재값 | 목표값 | 측정 방법 |
|-----|-------|-------|---------|
| **Facebook 연동 계정 추가율** | N/A | 30% | GA4: Facebook OAuth 완료 / 전체 Autogram 계정 |
| **연동 계정당 평균 페이지 수** | N/A | 2.5개 | DB: AVG(page_count per oauth_seq) |
| **연동 계정 해제 시 오류율** | 예상 10% | < 1% | Sentry: 해제 API 에러율 |
| **페이지 로드 시간** | N/A | < 2초 | New Relic: 연동 계정 목록 페이지 응답 시간 |
| **트리거 고아 레코드** | 예상 5% | 0% | DB: COUNT(triggers without valid post) |

**정성적 지표:**
- **사용자 만족도**: NPS 설문조사 (목표: 8점 이상/10점)
- **사용성**: 사용자 테스트 세션 5회 이상, 주요 태스크 완료율 > 90%

---

## 10. 엣지 케이스 및 비즈니스 룰

### 10.1 연동 계정 추가 엣지 케이스

| 시나리오 | 예상 동작 | 우선순위 |
|---------|----------|---------|
| **Facebook 연동 계정 5개 초과 추가 시도** | "Facebook 연동 계정은 최대 5개까지만 추가 가능합니다" 오류 표시, 추가 버튼 비활성화 | 필수 |
| **동일 Facebook 사용자 중복 연동** | "이미 연동된 Facebook 계정입니다" 오류 표시, 기존 연동 계정 정보 유지 | 필수 |
| **이미 다른 Autogram 계정이 연동한 페이지** | "이미 다른 사용자가 연동한 페이지입니다" 오류, 페이지 선택 불가 | 필수 |
| **OAuth 인증 중 취소** | 사용자를 설정 페이지로 리다이렉트, 아무것도 저장하지 않음 | 중요 |
| **페이지 권한 부족** | "페이지 관리 권한이 없습니다" 오류, 해당 페이지 필터링 | 중요 |
| **Facebook API 타임아웃** | "일시적인 오류입니다. 다시 시도해주세요" 오류, 재시도 버튼 제공 | 중요 |
| **Page Access Token 없음** | "페이지 토큰을 가져올 수 없습니다" 오류, 해당 페이지 건너뛰기 | 선택 |

### 10.2 연동 계정 해제 엣지 케이스

| 시나리오 | 예상 동작 | 우선순위 |
|---------|----------|---------|
| **마지막 연동 계정 해제** | 정상적으로 해제 진행. 모든 연동 계정 해제 후에도 Autogram 서비스 이용 가능 (연동 계정 없는 상태) | 필수 |
| **해제 중 DB 오류** | 전체 트랜잭션 롤백, "연동 계정 해제에 실패했습니다" 오류 | 필수 |
| **다른 Autogram 계정의 연동 계정 해제 시도** | 403 Forbidden 오류, "권한이 없습니다" 메시지 | 필수 |
| **이미 해제된 연동 계정 재해제** | 404 Not Found 오류, "연동 계정을 찾을 수 없습니다" 메시지 | 중요 |
| **해제 중 네트워크 끊김** | 클라이언트 재시도 로직, 서버 트랜잭션 타임아웃 설정 | 중요 |

### 10.3 데이터 동기화 엣지 케이스

| 시나리오 | 예상 동작 | 우선순위 |
|---------|----------|---------|
| **토큰 만료 중 동기화** | 페이지 상태를 `SUSPENDED`로 변경, 재인증 요청 알림 | 필수 |
| **S3 저장 실패** | 원본 URL만 저장하고 동기화 계속 진행, 에러 로그 기록 | 중요 |
| **Facebook API 일일 제한 초과** | "Facebook API 제한에 도달했습니다" 오류, 다음 날 재시도 안내 | 중요 |
| **포스트가 삭제된 경우** | DB에서도 삭제하거나 `deleted` 플래그 추가 (향후 고려) | 선택 |

### 10.4 비즈니스 룰

1. **최대 연동 계정 수 제한**: Autogram 계정당 Instagram 최대 5개 + Facebook 최대 5개 (플랫폼별 독립 카운트)
2. **연동 계정 전체 해제 허용**: 사용자는 모든 연동 계정을 해제할 수 있으며, 연동 계정 0개 상태에서도 Autogram 서비스 이용 가능
3. **페이지 소유권**: 한 페이지는 시스템 전체에서 하나의 Autogram 계정만 연동 가능 (`page_id` UNIQUE)
4. **트리거 정리**: 연동 계정/페이지/포스트 삭제 시 관련 트리거 자동 삭제 (CASCADE)
5. **토큰 갱신**: Page Access Token 만료 60일 전 재인증 알림 (향후 구현)
6. **데이터 격리**: 각 연동 계정의 데이터는 독립적으로 관리되며, 연동 계정 간 데이터 공유 불가

---

## 11. 마이그레이션 전략

### 11.1 기존 데이터 처리

`tb_facebook_pages`, `tb_facebook_posts`, `tb_user_oauth(FACEBOOK)` 모두 0건이므로 기존 데이터 마이그레이션이 불필요합니다. 스키마 변경(컬럼 추가 + FK + 인덱스)만 수행합니다.

### 11.2 롤백 계획

**롤백 트리거**:
- 마이그레이션 검증 쿼리에서 orphan 데이터 발견 시
- 프로덕션 배포 후 30분 이내 심각한 버그 발견 시

**롤백 스크립트**:
```sql
-- oauth_seq 컬럼 제거
ALTER TABLE `tb_facebook_pages` DROP FOREIGN KEY `FK_FBPAGES_OAUTH`;
ALTER TABLE `tb_facebook_pages` DROP INDEX `IDX_FBPAGES_02`;
ALTER TABLE `tb_facebook_pages` DROP COLUMN `oauth_seq`;

ALTER TABLE `tb_facebook_posts` DROP FOREIGN KEY `FK_FBPOSTS_OAUTH`;
ALTER TABLE `tb_facebook_posts` DROP INDEX `IDX_FBPOSTS_02`;
ALTER TABLE `tb_facebook_posts` DROP INDEX `UNQ_FBPOSTS_01`;
ALTER TABLE `tb_facebook_posts` DROP COLUMN `oauth_seq`;
ALTER TABLE `tb_facebook_posts` ADD UNIQUE INDEX `uk_post_id` (`user_seq`, `post_id`);
```

### 11.3 테스트 전략

**단계별 테스트**:
1. **로컬 환경**: 개발자 로컬 DB에서 마이그레이션 스크립트 실행 및 검증
2. **스테이징 환경**: 프로덕션 DB 스냅샷으로 스테이징 DB 복원 후 마이그레이션 실행
3. **검증 쿼리 실행**: 모든 검증 쿼리가 0 rows 반환하는지 확인
4. **기능 테스트**: 연동 계정 추가, 페이지 동기화, 트리거 생성/삭제 전체 플로우 테스트
5. **프로덕션 배포**: 새벽 시간대 배포, 30분간 모니터링

---

## 12. 부록

### 12.1 용어집

- **Autogram 계정**: Autogram 서비스의 사용자 계정 (`tb_users`). 이메일/소셜 로그인으로 가입한 서비스 계정
- **연동 계정**: Autogram 계정에 OAuth로 연결한 외부 SNS 플랫폼 계정 (`tb_user_oauth`). Instagram 또는 Facebook의 개인 계정을 의미하며, Autogram 계정당 플랫폼별 최대 5개까지 추가 가능
- **페이지 (Page)**: Facebook 비즈니스 페이지 (`tb_facebook_pages`). 하나의 Facebook 연동 계정이 여러 페이지를 관리할 수 있음
- **포스트 (Post)**: Facebook 페이지에 게시된 글/사진/비디오 (`tb_facebook_posts`)
- **트리거 (Trigger)**: 특정 키워드 댓글 시 자동 DM을 발송하는 규칙 (`tb_post_triggers`)
- **CASCADE 삭제**: 상위 레코드 삭제 시 관련 하위 레코드도 자동 삭제되는 DB 제약
- **Long-Lived Token**: 60일간 유효한 Facebook Access Token
- **Page Access Token**: Facebook 페이지를 관리할 수 있는 권한 토큰

### 12.2 참고 자료

- [Facebook Graph API Documentation](https://developers.facebook.com/docs/graph-api)
- [Instagram 다중 연동 계정 마이그레이션 (v1.5.0)](/docs/dba/v1.5.0_multi-instagram-accounts.sql)
- [Sequelize Migrations Guide](https://sequelize.org/docs/v6/other-topics/migrations/)
- [React Query Best Practices](https://tanstack.com/query/latest/docs/react/guides/important-defaults)

### 12.3 변경 이력

| 날짜 | 버전 | 변경사항 | 작성자 |
|------|------|---------|-------|
| 2026-02-01 | 1.0 | 초안 작성 | product-requirements-analyst |
| 2026-02-01 | 1.1 | 명확화 질문 답변 반영, 상세 명세 작성 | product-requirements-analyst |
| 2026-02-01 | 1.2 | US-006 재정의, saveFacebookOAuth 현황 반영, Legacy 마이그레이션 제거 (기존 데이터 0건), 리뷰 항목 3~8 A안 반영 | code-reviewer |
| 2026-02-01 | 1.3 | 최소 연동 계정 유지 제한 삭제, OAuth callback을 리다이렉트 패턴으로 수정, UNIQUE 제약 명시(UNQ_USEROAUTH_01, uk_post_id), CASCADE 삭제 전 COUNT 조회 방식, localStorage + 유효성 검증 폴백, 토큰 암호화·로드맵 향후 검토로 이관 | PRD 리뷰 반영 |
| 2026-02-01 | 1.4 | 용어 정리: "계정" → Autogram 계정(tb_users), "연동 계정" → SNS OAuth 연동 계정(tb_user_oauth)으로 문서 전체 통일 | 용어 표준화 |

---

## 13. 승인 및 검토

**검토자:**
- [ ] 백엔드 시니어 개발자: 기술적 실현 가능성 검토
- [ ] 프론트엔드 시니어 개발자: UI/UX 요구사항 검토
- [ ] DBA: 마이그레이션 스크립트 검토
- [ ] QA 리드: 테스트 전략 검토

**승인자:**
- [ ] 프로덕트 오너: 비즈니스 요구사항 승인
- [ ] CTO: 기술 아키텍처 승인

**승인 날짜**: TBD

---

**문서 끝**
