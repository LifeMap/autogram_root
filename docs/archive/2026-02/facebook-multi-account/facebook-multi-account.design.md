# Facebook 다중 연동 계정 지원 - 상세 설계

> **PRD**: [docs/prd-facebook-multi-account.md](../../prd-facebook-multi-account.md)
> **Plan**: [docs/01-plan/features/facebook-multi-account.plan.md](../../01-plan/features/facebook-multi-account.plan.md)
> **버전**: 1.0
> **작성일**: 2026-02-01
> **PDCA Phase**: Design

---

## 1. 현재 코드 분석

### 1.1 현재 Facebook 구조 (변경 전)

```
authController.handleFacebookCallback()
  → exchangeFacebookCode() → exchangeForLongLivedToken() → getUserPages()
  → 프론트엔드로 리다이렉트 (token + pages JSON)
  ❌ saveFacebookOAuth() 호출 없음 → tb_user_oauth에 FACEBOOK 레코드 없음

saveFacebookPage(userSeq, pageData)
  → FacebookPage.findOne({ page_id }) → create/update
  ❌ oauth_seq 없음 → 연동 계정 추적 불가

syncFacebookPosts(pageSeq, limit)
  → FacebookPost.findOrCreate({ user_seq, post_id })
  ❌ oauth_seq 없음 → 연동 계정별 포스트 구분 불가

PostTrigger (FACEBOOK)
  ❌ oauth_seq = NULL → CASCADE 삭제 미작동
```

### 1.2 현재 Instagram 구조 (참조 패턴)

```
accountService.addAccount(userSeq, oauthData)
  → validateAccountLimit() (5개 제한)
  → UserOAuth.create({ platform_type: 'INSTAGRAM', oauth_id, ... })
  → AccountRateLimit.bulkCreate([DM_SEND, POST_FETCH])

accountService.deleteAccount(userSeq, oauthSeq)
  → checkAccountOwnership()
  → 최소 1개 제한 검증 ❌ (PRD에서 제거 결정됨)
  → UserOAuth.destroy() → CASCADE

accountRoutes:
  GET    /api/accounts/instagram
  DELETE /api/accounts/instagram/:oauthSeq
  GET    /api/accounts/instagram/:oauthSeq/rate-limit
```

### 1.3 누락된 Association (models/index.js)

현재 `UserOAuth`와 `FacebookPage`/`FacebookPost` 사이에 association이 없음:
- `User.hasMany(FacebookPage)` ✅ 있음
- `UserOAuth.hasMany(FacebookPage)` ❌ 없음
- `UserOAuth.hasMany(FacebookPost)` ❌ 없음

---

## 2. DB 마이그레이션 설계

### 2.1 마이그레이션 SQL

파일: `docs/dba/v1.6.0_facebook-multi-account.sql` (PRD 섹션 4.1과 동일)

```sql
-- Step 1: tb_facebook_pages에 oauth_seq 추가
ALTER TABLE `tb_facebook_pages`
  ADD COLUMN `oauth_seq` INT UNSIGNED NOT NULL AFTER `user_seq`,
  ADD CONSTRAINT `FK_FBPAGES_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_FBPAGES_02` (`oauth_seq`);

-- Step 2: tb_facebook_posts에 oauth_seq 추가
ALTER TABLE `tb_facebook_posts`
  ADD COLUMN `oauth_seq` INT UNSIGNED NOT NULL AFTER `user_seq`,
  ADD CONSTRAINT `FK_FBPOSTS_OAUTH`
    FOREIGN KEY (`oauth_seq`) REFERENCES `tb_user_oauth` (`seq`) ON DELETE CASCADE,
  ADD INDEX `IDX_FBPOSTS_02` (`oauth_seq`, `created_time`);

-- Step 3: UNIQUE 제약 변경
ALTER TABLE `tb_facebook_posts`
  DROP INDEX `uk_post_id`,
  ADD UNIQUE INDEX `UNQ_FBPOSTS_01` (`oauth_seq`, `post_id`);
```

기존 데이터 0건이므로 데이터 마이그레이션 불필요.

### 2.2 롤백 SQL

PRD 섹션 11.2 참조.

---

## 3. 백엔드 상세 설계

### 3.1 Sequelize 모델 변경

#### FacebookPage 모델 변경

**파일**: `api/src/models/FacebookPage.js`

추가할 컬럼:
```javascript
oauth_seq: {
  type: DataTypes.INTEGER.UNSIGNED,
  allowNull: false,
  references: { model: 'tb_user_oauth', key: 'seq' },
  comment: '페이지 소유 연동 계정',
}
```

#### FacebookPost 모델 변경

**파일**: `api/src/models/FacebookPost.js`

추가할 컬럼:
```javascript
oauth_seq: {
  type: DataTypes.INTEGER.UNSIGNED,
  allowNull: false,
  references: { model: 'tb_user_oauth', key: 'seq' },
  comment: '포스트 소유 연동 계정',
}
```

#### models/index.js Association 추가

```javascript
// UserOAuth has many FacebookPage
UserOAuth.hasMany(FacebookPage, { foreignKey: 'oauth_seq', as: 'facebookPages' });
FacebookPage.belongsTo(UserOAuth, { foreignKey: 'oauth_seq', as: 'oauth' });

// UserOAuth has many FacebookPost
UserOAuth.hasMany(FacebookPost, { foreignKey: 'oauth_seq', as: 'facebookPosts' });
FacebookPost.belongsTo(UserOAuth, { foreignKey: 'oauth_seq', as: 'oauth' });
```

---

### 3.2 서비스 레이어 변경

#### 3.2.1 facebookService.saveFacebookOAuth() 수정

**파일**: `api/src/services/facebookService.js:832-864`

**현재 문제**: `findOrCreate` 조건이 `user_seq + platform_type`으로만 검색하여 다중 연동 계정 불가.

**변경 내용**:
```javascript
// 변경 전 (line 838-841)
where: {
  user_seq: userSeq,
  platform_type: 'FACEBOOK',
}

// 변경 후
where: {
  user_seq: userSeq,
  platform_type: 'FACEBOOK',
  oauth_id: userId,   // UNQ_USEROAUTH_01 매칭
}
```

추가: 호출 전 5개 제한 검증
```javascript
// saveFacebookOAuth 상단에 추가
const count = await UserOAuth.count({
  where: { user_seq: userSeq, platform_type: 'FACEBOOK' }
});
const maxAccounts = parseInt(process.env.MAX_FACEBOOK_ACCOUNTS || '5');
if (count >= maxAccounts && !existingOAuth) {
  throw new Error('MAX_ACCOUNTS');
}
```

#### 3.2.2 authController.handleFacebookCallback() 수정

**파일**: `api/src/controllers/authController.js:434-483`

**현재**: OAuth 후 token + pages를 프론트로 리다이렉트만 수행.

**변경 흐름**:
```
1. exchangeFacebookCode(code) → access_token
2. exchangeForLongLivedToken(access_token) → long_lived_token
3. Facebook /me API로 userId 조회 (NEW)
4. saveFacebookOAuth(userSeq, { userId, accessToken, expiresIn }) (NEW)
5. getUserPages(long_lived_token) → pages
6. 리다이렉트: /callback/facebook?status=success&oauthSeq={seq}&pages={json}
```

**에러 리다이렉트**:
- `MAX_ACCOUNTS` → `?error=MAX_ACCOUNTS&message=...`
- `DUPLICATE_ACCOUNT` → `?error=DUPLICATE_ACCOUNT&message=...`

**주의**: `handleFacebookCallback`은 JWT 인증 없이 호출됨 (OAuth callback). `userSeq`를 세션 또는 state 파라미터로 전달해야 함. 현재 `req.session`을 사용하므로 세션에 `userSeq` 저장 후 callback에서 복원.

#### 3.2.3 facebookService.saveFacebookPage() 수정

**파일**: `api/src/services/facebookService.js:343-379`

**변경**: `oauthSeq` 파라미터 추가

```javascript
// 변경 전
export const saveFacebookPage = async (userSeq, pageData) => {

// 변경 후
export const saveFacebookPage = async (userSeq, oauthSeq, pageData) => {
```

`FacebookPage.create()` 및 `existingPage.update()`에 `oauth_seq: oauthSeq` 추가.

#### 3.2.4 facebookService.syncFacebookPosts() 수정

**파일**: `api/src/services/facebookService.js:486-579`

**변경**: `findOrCreate` 조건에 `oauth_seq` 사용

```javascript
// 변경 전 (line 521-525)
const [facebookPost, created] = await FacebookPost.findOrCreate({
  where: {
    user_seq: page.user_seq,
    post_id: post.id,
  },

// 변경 후
const [facebookPost, created] = await FacebookPost.findOrCreate({
  where: {
    oauth_seq: page.oauth_seq,  // 페이지의 oauth_seq 사용
    post_id: post.id,
  },
```

`defaults`에도 `oauth_seq: page.oauth_seq` 추가.

#### 3.2.5 accountService 확장 - FacebookAccountService

**새 파일**: `api/src/services/facebookAccountService.js`

Instagram의 `accountService.js` 패턴을 미러링하되 Facebook 특화:

```javascript
class FacebookAccountService {
  // 연동 계정 목록 조회 (페이지 포함)
  async getAccountsByUser(userSeq, sort = 'connected_at_desc') {
    // UserOAuth WHERE platform_type='FACEBOOK'
    // include: FacebookPage (count), PostTrigger (count, where platform='FACEBOOK')
  }

  // 연동 계정 해제 (최소 제한 없음)
  async deleteAccount(userSeq, oauthSeq) {
    // 1. checkAccountOwnership (platform_type='FACEBOOK')
    // 2. COUNT 쿼리: 삭제될 페이지/포스트/트리거 수
    // 3. UserOAuth.destroy() → CASCADE
    // 4. 삭제 수 반환
  }

  // 소유권 검증
  async checkAccountOwnership(userSeq, oauthSeq) {
    // UserOAuth WHERE seq=oauthSeq, user_seq=userSeq, platform_type='FACEBOOK'
  }

  // 5개 제한 검증
  async validateAccountLimit(userSeq) {
    // COUNT WHERE user_seq, platform_type='FACEBOOK'
    // MAX_FACEBOOK_ACCOUNTS env (기본 5)
  }
}
```

**deleteAccount 상세 (PRD 요구: COUNT 후 CASCADE)**:
```javascript
async deleteAccount(userSeq, oauthSeq) {
  await this.checkAccountOwnership(userSeq, oauthSeq);

  // COUNT 조회 (삭제 전 수량 확인용)
  const [pageCount, postCount, triggerCount] = await Promise.all([
    FacebookPage.count({ where: { oauth_seq: oauthSeq } }),
    FacebookPost.count({ where: { oauth_seq: oauthSeq } }),
    PostTrigger.count({ where: { oauth_seq: oauthSeq, platform: 'FACEBOOK' } }),
  ]);

  // CASCADE 삭제
  await UserOAuth.destroy({ where: { seq: oauthSeq, user_seq: userSeq } });

  return { deletedPages: pageCount, deletedPosts: postCount, deletedTriggers: triggerCount };
}
```

#### 3.2.6 트리거 생성 시 oauth_seq 설정

Facebook 트리거 생성 시 포스트의 `oauth_seq`를 자동 전파:

```javascript
// triggerService 또는 트리거 생성 로직에서
const facebookPost = await FacebookPost.findByPk(facebookPostSeq);
const triggerData = {
  ...otherData,
  oauth_seq: facebookPost.oauth_seq,  // 포스트의 oauth_seq 전파
  platform: 'FACEBOOK',
};
```

---

### 3.3 라우트 및 컨트롤러

#### accountRoutes.js 추가

```javascript
// Facebook 연동 계정 관리
router.get('/facebook', authenticate, accountController.getFacebookAccounts);
router.delete('/facebook/:oauthSeq', authenticate, accountController.deleteFacebookAccount);
router.get('/facebook/:oauthSeq/pages', authenticate, accountController.getFacebookAccountPages);
```

#### accountController.js 추가 메서드

```javascript
// getFacebookAccounts: facebookAccountService.getAccountsByUser() 호출
// deleteFacebookAccount: facebookAccountService.deleteAccount() 호출 → { deletedPages, deletedPosts, deletedTriggers } 반환
// getFacebookAccountPages: facebookAccountService.getPagesByAccount() 호출
```

#### authRoutes에서 이동할 라우트

기존 `authRoutes`의 Facebook 관련 라우트 중 페이지 관리 라우트는 유지하되, 연동 계정 관리는 `accountRoutes`에서 처리:

- `GET /api/auth/facebook/login` → **유지** (OAuth 시작)
- `GET /api/auth/facebook/callback` → **유지** (OAuth callback)
- `GET /api/auth/facebook/pages` → **유지** (현재 사용자 전체 페이지, 하위 호환)
- `POST /api/auth/link-facebook` → **수정** (oauthSeq 파라미터 추가)
- `DELETE /api/auth/unlink-facebook/:pageSeq` → **유지** (개별 페이지 해제)

---

### 3.4 기존 accountService.deleteAccount() 수정

**파일**: `api/src/services/accountService.js:178-203`

**현재 문제** (line 189-192):
```javascript
if (accountCount <= 1) {
  throw new Error('최소 1개 계정은 유지해야 합니다.');
}
```

**변경**: PRD 결정에 따라 최소 제한 제거. Instagram도 동일하게 적용.

```javascript
// 삭제: 최소 1개 유지 검증 블록 전체 제거
// line 182-192 제거
```

---

## 4. 프론트엔드 상세 설계

### 4.1 새 Hooks

#### useFacebookAccounts.ts

**파일**: `web/hooks/useFacebookAccounts.ts`

```typescript
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { accountsApi } from '@/lib/api';

// 연동 계정 목록
export function useFacebookAccounts(sort: string = 'connected_at_desc') {
  return useQuery({
    queryKey: ['accounts', 'facebook', sort],
    queryFn: () => accountsApi.getFacebookAccounts(sort),
    staleTime: 1000 * 60 * 5,
  });
}

// 연동 계정 해제
export function useDeleteFacebookAccount() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (oauthSeq: number) => accountsApi.deleteFacebookAccount(oauthSeq),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['accounts', 'facebook'] });
      queryClient.invalidateQueries({ queryKey: ['facebook', 'pages'] });
      queryClient.invalidateQueries({ queryKey: ['triggers'] });
    },
  });
}

// 연동 계정별 페이지 목록
export function useFacebookAccountPages(oauthSeq: number) {
  return useQuery({
    queryKey: ['accounts', 'facebook', oauthSeq, 'pages'],
    queryFn: () => accountsApi.getFacebookAccountPages(oauthSeq),
    enabled: !!oauthSeq,
  });
}
```

### 4.2 API 클라이언트 확장

**파일**: `web/lib/api.ts` (또는 `web/lib/api/accounts.ts`)

```typescript
// accountsApi에 추가
getFacebookAccounts: (sort?: string) =>
  api.get('/accounts/facebook', { params: { sort } }),

deleteFacebookAccount: (oauthSeq: number) =>
  api.delete(`/accounts/facebook/${oauthSeq}`),

getFacebookAccountPages: (oauthSeq: number) =>
  api.get(`/accounts/facebook/${oauthSeq}/pages`),
```

### 4.3 페이지/컴포넌트 변경

#### 화면 1: Facebook 연동 계정 설정 페이지

**파일**: `web/app/dashboard/settings/facebook/page.tsx`

현재: `FacebookPageManagement` 컴포넌트로 페이지 목록만 표시
변경: 연동 계정 카드 목록 → 확장 시 페이지 목록

**컴포넌트 구조**:
```
FacebookSettingsPage
  ├── FacebookAccountList (NEW)
  │     ├── FacebookAccountCard (NEW, 반복)
  │     │     ├── 프로필 이미지 + 사용자명
  │     │     ├── 페이지 수 / 트리거 수 뱃지
  │     │     ├── "연동 해제" 버튼
  │     │     └── Accordion: FacebookPageList (기존 패턴 재사용)
  │     └── "Facebook 연동 계정 추가" 버튼 (< 5개일 때)
  └── DeleteAccountDialog (NEW)
        ├── 삭제될 데이터 수 표시
        └── 확인/취소 버튼
```

#### 화면 2: 포스트 선택 다이얼로그

**변경**: 연동 계정 → 페이지 → 포스트 3단계 선택

```
FacebookPostSelectDialog
  ├── Select: 연동 계정 (NEW)
  ├── Select: 페이지 (연동 계정 선택 후 활성화)
  ├── PostGrid (기존)
  └── SyncButton (기존)
```

#### 화면 3: 대시보드 필터

**새 컴포넌트**: `DashboardAccountFilter`

```
DashboardAccountFilter
  ├── Select/Combobox
  │     ├── "전체" (기본값)
  │     ├── Instagram 그룹 (useAccounts)
  │     └── Facebook 그룹 (useFacebookAccounts)
  └── localStorage 연동 (key: 'dashboard_account_filter')
```

localStorage 폴백 로직:
```typescript
const savedFilter = localStorage.getItem('dashboard_account_filter');
if (savedFilter) {
  const parsed = JSON.parse(savedFilter);
  // 저장된 연동 계정이 현재 목록에 있는지 검증
  const exists = allAccounts.some(a => a.seq === parsed.oauthSeq);
  if (!exists) {
    localStorage.removeItem('dashboard_account_filter');
    setFilter('all'); // "전체"로 폴백
  }
}
```

### 4.4 OAuth Callback 처리

**파일**: `web/app/callback/facebook/page.tsx` (또는 해당 경로)

현재: token + pages 파라미터로 페이지 선택 UI 표시
변경: `status=success&oauthSeq=123` 시 설정 페이지로 리다이렉트 + 성공 토스트

에러 처리:
- `error=MAX_ACCOUNTS` → 토스트 "Facebook 연동 계정은 최대 5개까지만 추가 가능합니다"
- `error=DUPLICATE_ACCOUNT` → 토스트 "이미 연동된 Facebook 계정입니다"

---

## 5. 타입 정의

**파일**: `web/types/index.ts` (또는 `web/types/facebook.ts`)

```typescript
type FacebookAccount = {
  seq: number;
  oauthId: string;
  username: string;
  connectedAt: string;
  totalPages: number;
  totalPosts: number;
  activeTriggerCount: number;
  pages: FacebookPageSummary[];
};

type FacebookPageSummary = {
  seq: number;
  pageId: string;
  pageName: string;
  profilePictureUrl: string | null;
  totalPosts: number;
  activeTriggerCount: number;
  lastSyncedAt: string | null;
};

type DeleteAccountResult = {
  deletedPages: number;
  deletedPosts: number;
  deletedTriggers: number;
};

type DashboardFilterValue = {
  type: 'all' | 'instagram' | 'facebook';
  oauthSeq?: number;
  label: string;
};
```

---

## 6. 구현 순서 체크리스트

### Phase 1: DB 마이그레이션
- [ ] `docs/dba/v1.6.0_facebook-multi-account.sql` 생성
- [ ] 로컬 DB에서 마이그레이션 실행 및 검증
- [ ] 롤백 스크립트 검증

### Phase 2: Sequelize 모델 + Association
- [ ] `FacebookPage` 모델에 `oauth_seq` 추가
- [ ] `FacebookPost` 모델에 `oauth_seq` 추가
- [ ] `models/index.js`에 `UserOAuth ↔ FacebookPage/FacebookPost` association 추가

### Phase 3: OAuth 연동 계정 저장
- [ ] `saveFacebookOAuth()` findOrCreate 조건에 `oauth_id` 추가
- [ ] `saveFacebookOAuth()`에 5개 제한 검증 추가
- [ ] `handleFacebookCallback()`에서 `/me` API로 userId 조회 추가
- [ ] `handleFacebookCallback()`에서 `saveFacebookOAuth()` 호출 추가
- [ ] 세션에 `userSeq` 저장/복원 로직 추가
- [ ] 리다이렉트 URL에 `status`/`error`/`oauthSeq` 파라미터 추가

### Phase 4: 연동 계정 관리 API
- [ ] `facebookAccountService.js` 생성 (getAccountsByUser, deleteAccount, checkAccountOwnership, validateAccountLimit)
- [ ] `accountController.js`에 getFacebookAccounts, deleteFacebookAccount, getFacebookAccountPages 추가
- [ ] `accountRoutes.js`에 Facebook 라우트 추가
- [ ] `accountService.deleteAccount()` 최소 1개 제한 제거

### Phase 5: 포스트/트리거 oauth_seq 연결
- [ ] `saveFacebookPage()` 시그니처에 `oauthSeq` 추가 및 저장 로직 수정
- [ ] `syncFacebookPosts()` findOrCreate 조건을 `oauth_seq + post_id`로 변경
- [ ] 트리거 생성 시 포스트의 `oauth_seq` 자동 전파
- [ ] `link-facebook` API에서 `oauthSeq` 전달하도록 수정

### Phase 6: FE - 연동 계정 설정 페이지
- [ ] `web/types/` Facebook 타입 정의
- [ ] `web/lib/api`에 Facebook accounts API 추가
- [ ] `useFacebookAccounts` 훅 생성
- [ ] `useDeleteFacebookAccount` 훅 생성
- [ ] `FacebookAccountCard` 컴포넌트 생성
- [ ] `FacebookAccountList` 컴포넌트 생성
- [ ] `DeleteAccountDialog` 컴포넌트 생성
- [ ] `facebook/page.tsx` 리팩토링
- [ ] OAuth callback 페이지 수정 (status/error 처리)

### Phase 7: FE - 포스트 선택 다이얼로그 개편
- [ ] `useFacebookAccountPages` 훅 생성
- [ ] 포스트 선택 다이얼로그에 연동 계정 드롭다운 추가
- [ ] 연동 계정 → 페이지 연쇄 필터링 구현

### Phase 8: FE - 대시보드 필터
- [ ] `DashboardAccountFilter` 컴포넌트 생성
- [ ] localStorage 저장/폴백 로직 구현
- [ ] 대시보드 통계 API에 `oauthSeq` 필터 전달

---

## 7. 변경 파일 목록

| 파일 | 변경 유형 | Phase |
|------|----------|-------|
| `docs/dba/v1.6.0_facebook-multi-account.sql` | 신규 | 1 |
| `api/src/models/FacebookPage.js` | 수정 | 2 |
| `api/src/models/FacebookPost.js` | 수정 | 2 |
| `api/src/models/index.js` | 수정 | 2 |
| `api/src/services/facebookService.js` | 수정 | 3, 5 |
| `api/src/controllers/authController.js` | 수정 | 3 |
| `api/src/services/facebookAccountService.js` | 신규 | 4 |
| `api/src/services/accountService.js` | 수정 | 4 |
| `api/src/controllers/accountController.js` | 수정 | 4 |
| `api/src/routes/accountRoutes.js` | 수정 | 4 |
| `web/types/index.ts` (또는 `facebook.ts`) | 수정 | 6 |
| `web/lib/api.ts` | 수정 | 6 |
| `web/hooks/useFacebookAccounts.ts` | 신규 | 6 |
| `web/components/settings/FacebookAccountCard.tsx` | 신규 | 6 |
| `web/components/settings/FacebookAccountList.tsx` | 신규 | 6 |
| `web/components/settings/DeleteFacebookAccountDialog.tsx` | 신규 | 6 |
| `web/app/dashboard/settings/facebook/page.tsx` | 수정 | 6 |
| `web/app/callback/facebook/page.tsx` | 수정 | 6 |
| `web/components/dashboard/DashboardAccountFilter.tsx` | 신규 | 8 |

---

## 8. 테스트 시나리오

### 백엔드
1. Facebook OAuth → `tb_user_oauth`에 FACEBOOK 레코드 생성 확인
2. 동일 Facebook 계정 중복 연동 시 에러 확인
3. 6번째 연동 시도 시 MAX_ACCOUNTS 에러 확인
4. 연동 계정 해제 시 페이지/포스트/트리거 CASCADE 삭제 확인
5. 모든 연동 계정 해제 후 정상 동작 확인 (최소 제한 없음)
6. 포스트 동기화 시 `oauth_seq` 정상 설정 확인
7. 트리거 생성 시 `oauth_seq` 자동 전파 확인

### 프론트엔드
1. 연동 계정 추가 버튼 → OAuth → 리다이렉트 → 설정 페이지 갱신
2. 연동 계정 카드 확장 → 페이지 목록 표시
3. 연동 해제 → 확인 다이얼로그 → 삭제 수 표시 → 성공 토스트
4. 포스트 선택 시 연동 계정 → 페이지 → 포스트 3단계 동작
5. 대시보드 필터 선택 → localStorage 저장 → 새로고침 후 유지
6. 해제된 연동 계정 필터 → "전체"로 폴백
