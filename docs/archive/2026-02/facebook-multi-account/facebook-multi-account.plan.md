# Facebook 다중 연동 계정 지원 - 구현 계획

> **PRD**: [docs/prd-facebook-multi-account.md](../../prd-facebook-multi-account.md)
> **버전**: 1.0
> **작성일**: 2026-02-01
> **PDCA Phase**: Plan

---

## 1. 목표

Instagram과 동일하게 Facebook 연동 계정을 최대 5개까지 지원하고, 연동 계정 → 페이지 → 포스트 → 트리거의 계층적 관리 및 CASCADE 삭제를 구현한다.

## 2. 구현 범위 요약

| 영역 | 변경 내용 |
|------|----------|
| DB | `tb_facebook_pages`, `tb_facebook_posts`에 `oauth_seq` 추가 + FK/인덱스 |
| 백엔드 | OAuth callback에 `saveFacebookOAuth()` 연결, 연동 계정 CRUD API, Sequelize association |
| 프론트엔드 | 연동 계정 설정 페이지, 포스트 선택 다이얼로그 개편, 대시보드 필터 |

## 3. 구현 순서 (Phase)

### Phase 1: DB 마이그레이션 (의존성: 없음)

**작업 목록:**
1. `v1.6.0_facebook-multi-account.sql` 마이그레이션 파일 생성
   - `tb_facebook_pages`에 `oauth_seq` NOT NULL + FK(CASCADE) + 인덱스
   - `tb_facebook_posts`에 `oauth_seq` NOT NULL + FK(CASCADE) + 인덱스
   - `tb_facebook_posts`의 `uk_post_id` → `UNQ_FBPOSTS_01 (oauth_seq, post_id)`로 변경
2. 롤백 스크립트 작성
3. 로컬 환경 테스트

**관련 PRD**: 섹션 4 (데이터베이스 스키마 변경사항)
**산출물**: `docs/dba/v1.6.0_facebook-multi-account.sql`

---

### Phase 2: Sequelize 모델 및 Association 수정 (의존성: Phase 1)

**작업 목록:**
1. `FacebookPage` 모델에 `oauth_seq` 컬럼 추가
2. `FacebookPost` 모델에 `oauth_seq` 컬럼 추가
3. `models/index.js`에 association 추가:
   - `UserOAuth.hasMany(FacebookPage, { foreignKey: 'oauth_seq' })`
   - `UserOAuth.hasMany(FacebookPost, { foreignKey: 'oauth_seq' })`
   - `FacebookPage.belongsTo(UserOAuth, { foreignKey: 'oauth_seq' })`
   - `FacebookPost.belongsTo(UserOAuth, { foreignKey: 'oauth_seq' })`

**관련 파일:**
- `api/src/models/FacebookPage.js` (또는 해당 모델 파일)
- `api/src/models/FacebookPost.js`
- `api/src/models/index.js`

---

### Phase 3: 백엔드 - OAuth 연동 계정 저장 (의존성: Phase 2)

**작업 목록:**
1. `facebookService.saveFacebookOAuth()` 수정
   - `findOrCreate` 조건에 `oauth_id` 추가 (기존: `user_seq + platform_type` → 변경: `user_seq + platform_type + oauth_id`)
   - 5개 제한 검증 로직 추가
2. `authController.handleFacebookCallback`에서 `saveFacebookOAuth()` 호출 추가
3. 프론트엔드 리다이렉트 시 `status=success` / `error=MAX_ACCOUNTS` / `error=DUPLICATE_ACCOUNT` 파라미터 포함

**관련 PRD**: US-001, API 1
**관련 파일:**
- `api/src/services/facebookService.js` (line 832-864 참고)
- `api/src/controllers/authController.js` (`handleFacebookCallback`)

---

### Phase 4: 백엔드 - 연동 계정 관리 API (의존성: Phase 3)

**작업 목록:**
1. `accountRoutes`에 Facebook 라우트 추가 (기존 `authRoutes`에서 이동)
   - `GET /api/accounts/facebook` - 연동 계정 목록 조회
   - `DELETE /api/accounts/facebook/:oauthSeq` - 연동 계정 해제
   - `GET /api/accounts/facebook/:oauthSeq/pages` - 연동 계정별 페이지 목록
2. `accountService` (또는 `facebookAccountService`) 구현
   - 목록 조회: 연동 계정 + 페이지 수 + 트리거 수 집계
   - 해제: COUNT 조회 후 CASCADE 삭제, 트랜잭션 처리
3. `accountService.deleteAccount()` 수정: 최소 연동 계정 카운트 제한 제거

**관련 PRD**: US-002, US-003, API 2~4
**관련 파일:**
- `api/src/routes/accountRoutes.js`
- `api/src/services/accountService.js`
- `api/src/controllers/accountController.js`

---

### Phase 5: 백엔드 - 포스트/트리거 oauth_seq 연결 (의존성: Phase 3)

**작업 목록:**
1. `facebookService.syncFacebookPosts()` 수정
   - `findOrCreate` 조건: `user_seq + post_id` → `oauth_seq + post_id`
   - 포스트 저장 시 `oauth_seq` 포함
2. 트리거 생성 시 `oauth_seq` 자동 설정
   - 포스트의 `oauth_seq`를 트리거에 자동 전파
3. 페이지 저장 시 `oauth_seq` 포함

**관련 PRD**: US-006, 기능 3~4
**관련 파일:**
- `api/src/services/facebookService.js` (`syncFacebookPosts`, 페이지 저장 관련)
- `api/src/services/triggerService.js` (트리거 생성 시 `oauth_seq` 설정)

---

### Phase 6: 프론트엔드 - 연동 계정 설정 페이지 (의존성: Phase 4)

**작업 목록:**
1. `/dashboard/settings/facebook` 페이지 구현
   - 연동 계정 목록 카드 UI (shadcn/ui Card + Accordion)
   - "Facebook 연동 계정 추가" 버튼 (5개 미만일 때만 활성)
   - 연동 해제 확인 다이얼로그 (삭제될 데이터 수 표시)
2. OAuth callback 처리 (URL 파라미터 `status` / `error` 읽기)
3. TanStack Query hooks:
   - `useFacebookAccounts()` - 연동 계정 목록
   - `useDeleteFacebookAccount()` - 연동 계정 해제

**관련 PRD**: US-001~003, 화면 1

---

### Phase 7: 프론트엔드 - 포스트 선택 다이얼로그 개편 (의존성: Phase 5, 6)

**작업 목록:**
1. 트리거 생성 모달에 "연동 계정 선택" 드롭다운 추가
2. 연동 계정 → 페이지 → 포스트 3단계 선택 UI
3. 기존 Facebook 포스트 선택 로직을 연동 계정 기반으로 변경

**관련 PRD**: US-004, 화면 2

---

### Phase 8: 프론트엔드 - 대시보드 연동 계정 필터 (의존성: Phase 6)

**작업 목록:**
1. 대시보드 상단에 "연동 계정 필터" 드롭다운 추가
   - "전체" / Instagram 그룹 / Facebook 그룹
2. `localStorage` 기반 필터 상태 유지 + 해제된 연동 계정 폴백
3. 대시보드 통계 API에 `oauthSeq` 필터 파라미터 추가

**관련 PRD**: US-005, 화면 3

---

## 4. 의존성 다이어그램

```
Phase 1 (DB)
  └→ Phase 2 (Model/Association)
       └→ Phase 3 (OAuth 저장)
            ├→ Phase 4 (연동 계정 API)
            │    └→ Phase 6 (설정 페이지 FE)
            │         ├→ Phase 7 (포스트 선택 FE)
            │         └→ Phase 8 (대시보드 필터 FE)
            └→ Phase 5 (포스트/트리거 연결)
                 └→ Phase 7 (포스트 선택 FE)
```

## 5. 제외 범위 (향후)

- 연동 계정별 Rate Limit 관리 (v1.6.x)
- 연동 계정별 월별 사용량 추적 (v1.7.x)
- 일괄 트리거 설정 (v1.8.x)
- Facebook Access Token 자동 갱신
- Access Token 암호화 저장

## 6. 위험 요소

| 위험 | 완화 방안 |
|------|----------|
| DB 마이그레이션 실패 | 기존 Facebook 데이터 0건이므로 위험 낮음. 롤백 스크립트 준비 |
| `saveFacebookOAuth()` findOrCreate 조건 변경 | 기존 Facebook OAuth 레코드 0건이므로 하위 호환 문제 없음 |
| 기존 authRoutes → accountRoutes 이동 | 프론트엔드 API 경로도 함께 변경 필요 |

## 7. 완료 조건

- [ ] 모든 Phase(1~8) 구현 완료
- [ ] Facebook 연동 계정 추가/조회/해제 E2E 플로우 동작
- [ ] 연동 계정 해제 시 CASCADE 삭제 정상 동작
- [ ] 대시보드 필터 localStorage 유지 + 폴백 동작
- [ ] `npm run build` 성공 (프론트엔드)
- [ ] `npm test` 통과 (백엔드)
