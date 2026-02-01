# Gap 분석: facebook-multi-account

> **요약**: Facebook 다중 연동 계정 지원 기능의 설계 대비 구현 Gap 분석
>
> **작성자**: Claude (gap-detector)
> **작성일**: 2026-02-01
> **설계 문서**: docs/02-design/features/facebook-multi-account.design.md
> **PRD 문서**: docs/prd-facebook-multi-account.md

---

## 요약

| 카테고리 | 점수 | 상태 |
|----------|:----:|:----:|
| Phase 1: DB 마이그레이션 | 95% | ✅ |
| Phase 2: Sequelize 모델 + Association | 100% | ✅ |
| Phase 3: OAuth 연동 계정 저장 | 95% | ✅ |
| Phase 4: 연동 계정 관리 API | 90% | ✅ |
| Phase 5: 포스트/트리거 oauth_seq 연결 | 95% | ✅ |
| Phase 6: FE 연동 계정 설정 페이지 | 88% | ⚠️ |
| Phase 7: FE 포스트 선택 다이얼로그 | 95% | ✅ |
| Phase 8: FE 대시보드 필터 | 92% | ✅ |
| **전체 (가중 평균)** | **93%** | **✅** |

---

## Phase별 분석

### Phase 1: DB 마이그레이션 (95%)

- **구현 파일**: `docs/dba/v1.7.0_facebook-multi-account.sql`

**✅ 구현 완료:**
- `tb_facebook_pages`에 `oauth_seq` INT UNSIGNED NOT NULL, FK CASCADE, IDX_FBPAGES_02
- `tb_facebook_posts`에 `oauth_seq` INT UNSIGNED NOT NULL, FK CASCADE, IDX_FBPOSTS_02(oauth_seq, created_time)
- `uk_post_id` DROP 후 `UNQ_FBPOSTS_01(oauth_seq, post_id)` 추가
- 롤백 스크립트 작성 완료

**⚠️ 차이점:**
- 파일명 버전: 설계 `v1.6.0` → 구현 `v1.7.0` (기존 파일과 충돌 방지)

---

### Phase 2: Sequelize 모델 + Association (100%)

- **구현 파일**: `api/src/models/FacebookPage.js`, `FacebookPost.js`, `index.js`

**✅ 구현 완료:**
- FacebookPage/Post: `oauth_seq` 컬럼 정의 (INTEGER.UNSIGNED, NOT NULL, FK)
- FacebookPost UNIQUE 인덱스: `(oauth_seq, post_id)` - `UNQ_FBPOSTS_01`
- Association 4개 모두 추가 (UserOAuth ↔ FacebookPage, UserOAuth ↔ FacebookPost)

---

### Phase 3: OAuth 연동 계정 저장 (95%)

- **구현 파일**: `api/src/services/facebookService.js`, `api/src/controllers/authController.js`

**✅ 구현 완료:**
- `saveFacebookOAuth()`: `oauth_id` 포함 findOne, 5개 제한 검증, MAX_ACCOUNTS 에러 코드
- `handleFacebookCallback()`: 세션 기반 userSeq 복원, `getFacebookUserInfo()` 호출, `saveFacebookOAuth()` 호출
- 리다이렉트 파라미터: status/oauthSeq/error/message

**⚠️ 차이점:**
- 리다이렉트: 설계는 settings 직접, 구현은 `/callback/facebook` 경유 (기능 동일)

---

### Phase 4: 연동 계정 관리 API (90%)

- **구현 파일**: `api/src/services/facebookAccountService.js`, `accountController.js`, `accountRoutes.js`

**✅ 구현 완료:**
- `facebookAccountService`: `getAccountsByUser`, `deleteAccount`, `checkAccountOwnership`, `getPagesByAccount`
- `deleteAccount`: COUNT → CASCADE 삭제, `{ deletedPages, deletedPosts, deletedTriggers }` 반환
- 라우트 3개: GET `/facebook`, DELETE `/facebook/:oauthSeq`, GET `/facebook/:oauthSeq/pages`
- `accountService.deleteAccount()`: 최소 1개 제한 제거 완료

**⚠️ 차이점:**
- `validateAccountLimit` 별도 메서드 없음 (saveFacebookOAuth에서 처리, 기능 영향 없음)

---

### Phase 5: 포스트/트리거 oauth_seq 연결 (95%)

- **구현 파일**: `facebookService.js`, `triggerService.js`, `authController.js`

**✅ 구현 완료:**
- `saveFacebookPage(userSeq, oauthSeq, pageData)`: 시그니처 변경, oauth_seq 포함
- `syncFacebookPosts()`: findOrCreate 조건 `oauth_seq + post_id`
- 트리거 생성: `triggerData.oauth_seq = facebookPost.oauth_seq` 전파
- `linkFacebookPage`: `oauth_seq` 필수 파라미터, 소유권 검증

---

### Phase 6: FE 연동 계정 설정 페이지 (88%)

- **구현 파일**: `web/types/account.ts`, `web/lib/api/accounts.ts`, `web/hooks/useFacebookAccounts.ts`, `web/components/settings/FacebookAccountManagement.tsx`, `facebook/page.tsx`

**✅ 구현 완료:**
- 타입: `FacebookAccount`, `FacebookPageSummary`, `DeleteFacebookAccountResult` 등
- API: `getFacebookAccounts`, `deleteFacebookAccount`, `getFacebookAccountPages`
- Hooks: `useFacebookAccounts`, `useDeleteFacebookAccount`, `useFacebookAccountPages`
- UI: Accordion 기반 계정 카드, 페이지 목록, 삭제 확인 다이얼로그, 빈 상태
- OAuth 콜백 처리: status/error/MAX_ACCOUNTS

**⚠️ 차이점:**
- 컴포넌트 분리: 설계 3개 분리 → 구현 1개 통합 (`FacebookAccountManagement`)

**❌ 누락:**
- `DUPLICATE_ACCOUNT` 에러 전용 토스트 미구현
- 페이지별 통계 데이터(`totalPosts`, `activeTriggerCount`)가 API 응답에 포함되는지 확인 필요

---

### Phase 7: FE 포스트 선택 다이얼로그 (95%)

- **구현 파일**: `web/components/triggers/FacebookPostSelector.tsx`

**✅ 구현 완료:**
- 3단계 연쇄 선택: 연동 계정 → 페이지 → 포스트
- 연동 계정/페이지 Select 드롭다운
- 포스트 3열 그리드, 동기화 버튼
- 빈 상태 UI (계정/페이지/포스트 없음)
- 첫 번째 계정 자동 선택

**⚠️ 차이점:**
- 설계는 `useFacebookAccountPages` 훅 사용, 구현은 직접 API 호출 (기능 동일)

---

### Phase 8: FE 대시보드 필터 (92%)

- **구현 파일**: `web/components/dashboard/AccountFilter.tsx`, `dashboard/page.tsx`

**✅ 구현 완료:**
- Facebook 그룹: 연동 계정 표시 (페이지 → 연동 계정으로 변경)
- localStorage 저장/로드 (`autogram:dashboard:accountFilter`)
- 해제된 계정 → "전체" 폴백 검증
- 대시보드 API: `oauthSeq` 필터 전달

**⚠️ 차이점:**
- 컴포넌트명: 설계 `DashboardAccountFilter` → 구현 `AccountFilter`
- localStorage 키: 설계 `dashboard_account_filter` → 구현 `autogram:dashboard:accountFilter`
- 필터 값 형식: 설계 JSON 객체 → 구현 문자열 `'platform:seq'` (더 간결)

**✅ 추가 구현:**
- URL searchParams 동기화 (설계에는 localStorage만 명시)

---

## 전체 Match Rate: 93%

---

## 권장 조치

### 🔴 즉시 조치 (High)

1. **페이지별 통계 데이터 확인**
   - `api/src/services/facebookAccountService.js`의 `getAccountsByUser()` pages 매핑에서 `totalPosts`, `activeTriggerCount` 포함 여부 확인
   - 누락 시 프론트엔드 페이지 카드에 "포스트 0개 / 트리거 0개" 표시됨

2. **DUPLICATE_ACCOUNT 에러 처리**
   - `web/app/dashboard/settings/facebook/page.tsx`에 `error === 'DUPLICATE_ACCOUNT'` 분기 추가
   - "이미 연동된 Facebook 계정입니다" 전용 토스트 표시

### 🟡 문서 업데이트 (Medium)

3. 설계 문서 마이그레이션 파일명 `v1.6.0` → `v1.7.0` 반영
4. `accountService.js` JSDoc "최소 1개 계정 유지" 잔존 문구 제거

### 🟢 개선 사항 (Low)

5. `FacebookPostSelector`에서 `useFacebookAccountPages` 훅 사용으로 통일
6. `FacebookIcon` 컴포넌트 3곳 중복 → 공통 컴포넌트 추출
