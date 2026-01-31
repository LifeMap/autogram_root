# Autogram - SNS 자동화 플랫폼

## 프로젝트 개요
Instagram/Facebook 댓글 기반 자동 DM 발송 시스템. 사용자가 특정 키워드를 댓글로 입력하면 자동으로 DM을 발송합니다.

## 기술 스택

### 백엔드 (`/api`)
- **런타임**: Node.js (ES Modules)
- **프레임워크**: Express.js
- **ORM**: Sequelize (MySQL)
- **인증**: JWT + Google/Instagram/Facebook OAuth
- **결제**: LemonSqueezy, Iamport
- **스토리지**: AWS S3 + CloudFront
- **이메일**: AWS SES + EJS 템플릿

### 프론트엔드 (`/web`)
- **프레임워크**: Next.js (App Router) + TypeScript
- **UI**: shadcn/ui + Radix UI + Tailwind CSS
- **서버 상태**: TanStack Query (React Query)
- **HTTP 클라이언트**: Axios
- **다국어**: next-intl (`i18n/`, `messages/`)

## 프로젝트 구조

```
api/
  src/
    controllers/    # 요청 처리, 유효성 검증
    services/       # 비즈니스 로직
    models/         # Sequelize 모델
    routes/         # Express 라우트 정의
    middleware/     # 인증, 에러 핸들링
    config/        # DB, 환경변수 설정
    constants/     # Enum, 상수값
    jobs/          # 스케줄링 작업
    utils/         # 공용 유틸리티
    templates/     # EJS 이메일 템플릿
  migrations/      # Sequelize 마이그레이션 파일

web/
  app/             # Next.js App Router 페이지
    (auth)/        # 인증 관련 페이지
    dashboard/     # 메인 앱 페이지
  components/      # React 컴포넌트
    ui/            # shadcn/ui 컴포넌트
  hooks/           # 커스텀 React Hooks
  lib/             # 유틸리티, API 클라이언트
  store/           # 클라이언트 상태 관리
  types/           # TypeScript 타입 정의
  i18n/            # 다국어 설정
  messages/        # 다국어 번역 파일

docs/
  dba/             # DB 마이그레이션 문서 및 SQL
```

## 개발 명령어

```bash
# API
cd api && npm run dev          # 개발 서버 시작 (포트 3000)
cd api && npm test             # Jest 테스트 실행

# Web
cd web && npm run dev          # 개발 서버 시작 (포트 3001)
cd web && npm run build        # 프로덕션 빌드
cd web && npm run lint         # ESLint 실행
```

## 코딩 컨벤션

### 백엔드 (JavaScript ES Modules)
- `import/export` 구문 사용 (`require` 사용 금지)
- Service 레이어에 비즈니스 로직, Controller는 HTTP 처리만
- Sequelize 모델 컬럼명은 `snake_case`
- API 응답 형식: `{ success: boolean, data?: any, message?: string }`
- 에러 핸들링은 중앙 미들웨어에서 처리

### 프론트엔드 (TypeScript)
- `interface`보다 `type` 선호
- 조건부 className은 `cn()` 사용 (shadcn 패턴)
- API 호출은 중앙 Axios 인스턴스를 통해 수행
- 서버 상태는 TanStack Query로 관리
- shadcn/ui 컴포넌트는 `components/ui/`에 위치

## 데이터베이스
- MySQL + Sequelize ORM
- 마이그레이션 파일: `api/migrations/` (Sequelize CLI) 또는 `docs/dba/` (수동 SQL)
- 테이블 접두사: `tb_`
- 기본키: `seq` (auto increment)
- 타임스탬프: `created_at`, `updated_at`
- 소프트 삭제: `deleted_at`

## 핵심 비즈니스 규칙
- OAuth 계정은 `tb_user_oauth`에 `platform_type` ENUM으로 저장
- Instagram/Facebook: 사용자당 플랫폼별 최대 5개 계정 연동
- 트리거: 포스트 댓글 키워드 기반 자동 DM 발송 규칙
- `tb_post_triggers.oauth_seq` FK → CASCADE 삭제

## 금지 사항
- `git push --force` 사용 금지
- `.env` 파일 직접 수정 금지
- 프로덕션 DB에 직접 SQL 실행 금지
- TypeScript에서 `any` 타입 사용 금지 (`unknown` 사용)
- `node_modules/`, `.env`, 인증 정보 파일 커밋 금지
- API 응답 형식은 항상 `{ success, data, message }` 유지
