# Autogram - SNS 자동화 플랫폼 포트폴리오

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [기술 스택](#2-기술-스택)
3. [시스템 아키텍처](#3-시스템-아키텍처)
4. [주요 기능](#4-주요-기능)
5. [데이터베이스 구조](#5-데이터베이스-구조)
6. [API 구조](#6-api-구조)
7. [프론트엔드 구조](#7-프론트엔드-구조)
8. [보안 및 인증 체계](#8-보안-및-인증-체계)
9. [배포 및 인프라](#9-배포-및-인프라)
10. [프로젝트 성과 및 특장점](#10-프로젝트-성과-및-특장점)

---

## 1. 프로젝트 개요

### 서비스 소개

**Autogram**은 Instagram 및 Facebook 비즈니스 계정을 위한 SNS 자동화 플랫폼입니다. 핵심 기능은 **댓글 트리거 기반 자동 DM (Direct Message) 발송**입니다. 사용자가 특정 키워드를 댓글로 입력하면, 시스템이 이를 실시간으로 감지하여 미리 설정된 DM 메시지를 자동으로 발송합니다.

### 해결하는 문제

인플루언서, 소상공인, 마케터들이 SNS에서 제품·서비스에 관심을 가진 잠재 고객에게 일일이 DM을 보내는 작업은 매우 반복적이고 시간 소모적입니다. Autogram은 이 과정을 완전히 자동화하여:

- **마케팅 효율 극대화**: 수동 DM 발송 불필요, 24시간 자동 대응
- **참여율 향상**: 댓글 작성 직후 즉각 응답으로 전환율 증가
- **다계정 관리**: Instagram/Facebook 다중 계정을 하나의 대시보드로 통합 관리
- **데이터 기반 마케팅**: 트리거별 성과 측정 및 CTA 버튼 클릭 추적

### 핵심 플로우

```
사용자 로그인
    ↓
Instagram / Facebook 비즈니스 계정 연동 (OAuth)
    ↓
게시물 선택 → 트리거 생성 (키워드 + DM 메시지 설정)
    ↓
Meta Webhook → 실시간 댓글 수신
    ↓
키워드 매칭 → 중복 확인 → 쿼터 확인
    ↓
자동 DM 발송 → 발송 이력 저장
    ↓
대시보드 통계 확인
```

### 비즈니스 모델

프리미엄 SaaS (Software as a Service) 구독 모델:

| 플랜     | 설명                        |
|----------|-----------------------------|
| Free     | 무료 플랜, 월 DM 발송 한도 제공 |
| Minimum  | 소규모 비즈니스용 입문 플랜    |
| Starter  | 성장 단계 비즈니스 추천 플랜  |
| Pro      | 대규모 운영 전문가 플랜        |

---

## 2. 기술 스택

### 백엔드 (`/api`)

| 분류             | 기술                                                    |
|------------------|---------------------------------------------------------|
| 런타임           | Node.js (ES Modules, `import`/`export` 구문)            |
| 웹 프레임워크    | Express.js 4.x                                          |
| 데이터베이스 ORM | Sequelize 6.x (MySQL)                                   |
| 인증             | JWT (Access Token 15분 / Refresh Token 7일)             |
| OAuth            | Google OAuth 2.0 / Instagram OAuth / Facebook OAuth     |
| 결제             | LemonSqueezy (해외 구독 결제) + Iamport (국내 정기결제) |
| 스토리지         | AWS S3 + CloudFront CDN (미디어 파일 영구 보관)         |
| 이메일           | AWS SES + EJS 템플릿                                    |
| 알림             | Slack Webhook (신규 가입, 결제, 에러 알림)              |
| 스케줄러         | node-cron (정기 배치 작업)                              |
| 유효성 검증      | Joi (요청 스키마 검증)                                  |
| 보안             | Helmet.js, express-rate-limit, bcrypt                   |
| 로깅             | Winston                                                 |
| 테스트           | Jest                                                    |

### 프론트엔드 (`/web`)

| 분류             | 기술                                                         |
|------------------|--------------------------------------------------------------|
| 프레임워크       | Next.js 14 (App Router) + TypeScript                        |
| UI 컴포넌트      | shadcn/ui + Radix UI                                         |
| 스타일링         | Tailwind CSS                                                 |
| 서버 상태 관리   | TanStack Query (React Query) v5                              |
| 클라이언트 상태  | Zustand (인증 상태)                                          |
| HTTP 클라이언트  | Axios (중앙 인스턴스 패턴)                                   |
| 폼 유효성        | React Hook Form + Zod                                        |
| 다국어 (i18n)    | next-intl (한국어/영어/일본어)                               |
| 차트             | Recharts                                                     |
| 날짜 처리        | date-fns                                                     |
| 분석             | Mixpanel (사용자 행동 추적)                                  |
| SEO              | JSON-LD 구조화 데이터, OpenGraph, Twitter Card               |

### 인프라 및 DevOps

| 분류         | 기술                                     |
|--------------|------------------------------------------|
| 클라우드     | Amazon Web Services (AWS)                |
| 스토리지     | AWS S3 + CloudFront CDN                  |
| 이메일       | AWS SES                                  |
| 버전 관리    | Git / GitHub                             |
| 데이터베이스 | MySQL (AWS RDS)                          |
| 역방향 프록시 | Nginx (리버스 프록시, SSL 종료)         |

---

## 3. 시스템 아키텍처

### 전체 아키텍처 다이어그램

```
┌─────────────────────────────────────────────────────────────────┐
│                        클라이언트 레이어                          │
│                                                                   │
│    ┌────────────────────────────────────────────────┐            │
│    │        Next.js 14 (App Router) - Port 3001      │            │
│    │  Landing / Dashboard / Auth / Pricing Pages     │            │
│    └───────────────────────┬────────────────────────┘            │
└───────────────────────────┬┴────────────────────────────────────┘
                            │ HTTPS / REST API
┌───────────────────────────▼────────────────────────────────────┐
│                       API 서버 레이어                            │
│                                                                  │
│    ┌────────────────────────────────────────────────┐           │
│    │         Express.js API Server - Port 3000       │           │
│    │                                                 │           │
│    │  ┌──────────┐  ┌──────────┐  ┌──────────────┐  │           │
│    │  │ Routes   │→ │Controllers│→ │   Services   │  │           │
│    │  └──────────┘  └──────────┘  └──────┬───────┘  │           │
│    │                                      │           │           │
│    │  ┌───────────────────────────────────▼────────┐  │           │
│    │  │              Sequelize ORM                  │  │           │
│    │  └───────────────────────────────────┬────────┘  │           │
│    └──────────────────────────────────────┼───────────┘           │
└──────────────────────────────────────────┬┴──────────────────────┘
                                           │
┌──────────────────────────────────────────▼──────────────────────┐
│                      데이터 레이어                               │
│                                                                  │
│    ┌────────────┐    ┌──────────────┐    ┌───────────────────┐  │
│    │  MySQL DB   │    │   AWS S3     │    │   AWS SES         │  │
│    │  (AWS RDS)  │    │ + CloudFront │    │  (이메일 발송)    │  │
│    └────────────┘    └──────────────┘    └───────────────────┘  │
└──────────────────────────────────────────────────────────────────┘
                                           ↑
┌──────────────────────────────────────────┴──────────────────────┐
│                    외부 서비스 레이어                            │
│                                                                  │
│  ┌──────────────────┐  ┌──────────────────┐  ┌───────────────┐  │
│  │  Meta Graph API   │  │  LemonSqueezy    │  │  Slack        │  │
│  │  (Instagram,      │  │  (해외 결제)     │  │  (알림)       │  │
│  │   Facebook)       │  └──────────────────┘  └───────────────┘  │
│  │  Webhook 수신     │  ┌──────────────────┐  ┌───────────────┐  │
│  └──────────────────┘  │  Google OAuth     │  │  Iamport      │  │
│                        │  (소셜 로그인)    │  │  (국내 결제)  │  │
│                        └──────────────────┘  └───────────────┘  │
└──────────────────────────────────────────────────────────────────┘
```

### 레이어별 역할

**라우터 (Routes)**
- URL 경로와 HTTP 메서드를 컨트롤러에 매핑
- Joi 기반 요청 스키마 검증 미들웨어 적용
- JWT 인증 미들웨어 적용

**컨트롤러 (Controllers)**
- HTTP 요청/응답 처리 전담
- 파라미터 추출 및 서비스 호출
- 에러 처리는 중앙 미들웨어로 위임

**서비스 (Services)**
- 모든 비즈니스 로직 구현
- 외부 API 연동 (Instagram, Facebook, LemonSqueezy 등)
- 트랜잭션 관리

**모델 (Models)**
- Sequelize ORM 기반 MySQL 스키마 정의
- 테이블 관계(Association) 정의
- 인덱스 및 유효성 검증 규칙

### 웹훅 처리 아키텍처

Meta (Instagram/Facebook) 플랫폼에서 댓글 이벤트가 발생하면:

```
Meta Platform
    │
    │  POST /api/webhooks/instagram (또는 /facebook)
    │  (HMAC-SHA256 서명 검증)
    ▼
WebhookController
    │
    ▼
WebhookService.processInstagramWebhook()
    │
    ├── 각 댓글 이벤트 비동기 병렬 처리
    │
    ▼
processCommentEvent()
    │
    ├── 1. 해당 게시물의 활성 트리거 조회
    ├── 2. 키워드 매칭 (포함 매칭 / 정확 매칭)
    ├── 3. 중복 발송 방지 확인 (TriggerExecuteHistory)
    ├── 4. DM 쿼터 확인 (quotaService)
    ├── 5. 팔로워 필터링 처리 (선택적)
    ├── 6. Instagram DM API 호출
    ├── 7. 댓글 답글 발송 (선택적)
    └── 8. 발송 이력 저장
```

### 스케줄러 구조

서버 시작 시 4개의 cron 스케줄러가 자동 실행됩니다:

| 스케줄러                  | 주기                    | 역할                                     |
|---------------------------|-------------------------|------------------------------------------|
| billingScheduler          | 매일 오전 9시 (KST)     | Free 플랜 구독 갱신 및 월간 사용량 리셋  |
| usageResetScheduler       | 매월 1일 자정            | 유료 플랜 월간 DM 사용량 리셋            |
| statsCleanupScheduler     | 주기적 실행              | 오래된 통계 데이터 정리                   |
| couponExpiryScheduler     | 매일 실행               | 만료된 추천 쿠폰 상태 업데이트           |

---

## 4. 주요 기능

### 4.1 인증 및 계정 관리

**다중 로그인 방식 지원**
- 이메일/비밀번호 로그인 (6자리 이메일 인증 코드)
- Google OAuth 소셜 로그인
- Instagram OAuth를 통한 직접 가입

**Instagram/Facebook 비즈니스 계정 연동**
- 사용자당 최대 5개의 Instagram/Facebook 계정 연동 가능
- OAuth 2.0을 통한 안전한 토큰 발급 및 관리
- 액세스 토큰 만료 시 자동 감지 및 재연동 안내

**계정 보안**
- 로그인 실패 횟수 추적 (5회 초과 시 잠금)
- JWT Access Token (15분) + Refresh Token (7일) 이중 토큰 체계
- 관리자 User Impersonation 기능 (고객 지원용)

### 4.2 트리거 관리 (핵심 기능)

**트리거 생성 및 설정**
- Instagram 또는 Facebook 게시물 선택
- 트리거 키워드 설정 (복수 키워드 콤마 구분: "정보,신청,문의")
- DM 메시지 작성 (최대 1,000자)
- CTA (Call-to-Action) 버튼 추가 (버튼 텍스트 + URL)
- 활성/비활성 상태 즉시 전환

**고급 키워드 매칭**
- **포함 매칭 (기본)**: 댓글에 키워드가 포함되면 반응 (예: "정보" → "정보 주세요" 매칭)
- **정확 매칭**: `=` 접두사 사용 시 댓글 전체가 키워드와 정확히 일치해야 매칭 (예: `=신청` → "신청" 만 매칭)

**팔로워 필터링 옵션**
- 팔로워에게만 DM 발송 옵션
- 비팔로워 대상 팔로우 유도 메시지 발송
- 단계적 팔로우 확인 메시지 설정 (확인 버튼, 재확인 메시지)

**댓글 답글 기능**
- DM 발송과 동시에 댓글에 공개 답글 작성
- 다수의 답글 템플릿 등록 후 랜덤 선택 발송 (스팸 감지 우회)

### 4.3 실시간 DM 자동 발송

**Webhook 기반 실시간 처리**
- Meta Webhook을 통해 댓글 이벤트 즉시 수신
- HMAC-SHA256 서명 검증으로 위변조 방지
- 비동기 병렬 처리로 대용량 댓글 이벤트 처리

**중복 발송 방지**
- 동일 사용자에게 동일 트리거로 발송 이력 확인
- 발송 상태 관리: `PENDING` → `SENT` / `FAIL` / `DUPLICATED`

**DM 쿼터 (Quota) 관리**
- 플랜별 월간 DM 발송 한도 관리
- 90% 도달 시 경고 이메일 자동 발송
- 100% 도달 시 DM 차단 및 안내 이메일 발송
- 추천인 쿠폰으로 추가 DM 할당량 획득 가능

**CTA 클릭 추적**
- 추적 URL 자동 생성 (`/redirect?url=...&t=...&h=...`)
- 버튼 클릭 시 TriggerClick 테이블에 이력 저장
- 트리거별 클릭 통계 확인 가능

### 4.4 게시물 관리

**게시물 동기화**
- Instagram/Facebook Graph API를 통해 게시물 자동 동기화
- 게시물 미디어(이미지/동영상)를 AWS S3에 영구 저장
- S3 저장 실패 시에도 원본 URL 폴백 처리

**게시물 목록 및 필터링**
- 연동된 계정별 게시물 목록 조회
- 트리거가 설정된 게시물 필터링
- 게시물별 댓글 조회

### 4.5 대시보드 및 통계

**실시간 대시보드**
- 오늘 DM 발송량 / 전일 대비 증감률
- 활성 트리거 수
- 이번 달 누적 발송량 / 플랜 한도 대비 사용률 (Progress Bar)
- 배달 성공률 (SENT / 전체 이력)

**시각화 차트**
- 7일간 시간별/일별 DM 발송 추이 막대 차트 (Recharts)
- 플랫폼별 필터링 (Instagram / Facebook / 전체)
- 계정별 필터링

**발송 이력**
- 전체 발송 이력 조회 (페이지네이션)
- 상태별 필터링 (성공/실패/중복)
- 트리거별 이력 조회

### 4.6 구독 및 결제

**구독 관리**
- 플랜 업그레이드/다운그레이드 (다음 결제일부터 적용)
- 구독 해지 (기간 종료 후 Free 전환)
- 구독 이력 조회

**결제 시스템**
- LemonSqueezy: 해외 카드 및 글로벌 구독 결제
- Iamport: 국내 카드 정기 결제 (빌링키 방식)
- 결제 실패 시 재시도 스케줄링

**추천인 시스템**
- 고유 8자리 추천 코드 발급 (`[A-Z0-9]{8}`)
- 추천인/신규 가입자 양방향 쿠폰 지급 (추가 DM 할당량)
- 쿠폰 유효기간 관리 및 자동 만료 처리

### 4.7 다국어 지원

- 한국어 (ko), 영어 (en), 일본어 (ja) 지원
- next-intl 기반 서버/클라이언트 컴포넌트 모두 지원
- 플랜 이름, 오류 메시지, UI 전체 다국어화

### 4.8 관리자 기능

- 사용자 구독 목록 조회 및 관리
- User Impersonation (관리자가 특정 사용자로 로그인하여 지원)
- Slack 알림 (신규 가입, 결제 완료, 시스템 오류)

---

## 5. 데이터베이스 구조

### 테이블 명명 규칙
- 접두사: `tb_`
- 기본키: `seq` (UNSIGNED INT, AUTO INCREMENT)
- 타임스탬프: `created_at`, `updated_at`
- 소프트 삭제: `suspended_at` (일부 테이블)

### 핵심 테이블 ERD (개요)

```
tb_users (사용자)
    │
    ├──< tb_user_oauth (SNS 계정, 최대 5개)
    │       │
    │       ├──< tb_instagram_posts (인스타 게시물)
    │       │       └──< tb_post_triggers (트리거)
    │       │                   └──< tb_trigger_execute_history (발송 이력)
    │       │                   └──< tb_trigger_clicks (CTA 클릭)
    │       │
    │       └──< tb_facebook_pages (Facebook 페이지)
    │               └──< tb_facebook_posts (FB 게시물)
    │                       └──< tb_post_triggers (트리거)
    │
    ├──< tb_user_password (비밀번호)
    │
    ├── tb_subscriptions (구독, 1:1)
    │       ├── tb_plans (요금제 플랜)
    │       │       └──< tb_plan_properties (플랜 속성)
    │       ├──< tb_payment_transactions (결제 내역)
    │       └──< tb_subscription_histories (구독 이력)
    │
    ├──< tb_monthly_usage (월별 DM 사용량)
    │
    └──< tb_referral_coupons (추천 쿠폰)
```

### 주요 테이블 상세

#### tb_users (사용자 마스터)

| 컬럼명                | 타입                                                      | 설명                                    |
|-----------------------|-----------------------------------------------------------|-----------------------------------------|
| seq                   | INT UNSIGNED PK                                           | 사용자 고유 ID                          |
| email                 | VARCHAR(255)                                              | 이메일 (로그인 식별자)                  |
| auth_type             | ENUM('EMAIL','GOOGLE','APPLE','KAKAO','INSTAGRAM','TIKTOK') | 가입 방식                              |
| name                  | VARCHAR(100)                                              | 사용자 이름                             |
| status                | ENUM('VERIFYING','ACTIVATED','SUSPENDED')                 | 계정 상태                               |
| role                  | ENUM('USER','ADMIN')                                      | 권한                                    |
| google_oauth_id       | VARCHAR(300)                                              | Google OAuth ID                         |
| refresh_token         | VARCHAR(500)                                              | JWT Refresh Token                       |
| login_failed_count    | TINYINT                                                   | 로그인 실패 횟수                        |
| locked_until          | DATETIME                                                  | 계정 잠금 해제 시간                     |
| user_code             | VARCHAR(8)                                                | 추천용 고유 코드                        |
| referrer_user_seq     | INT UNSIGNED (FK → tb_users.seq)                         | 추천인 (자기참조)                       |
| is_beta_tester        | BOOLEAN                                                   | 베타 테스터 여부                        |

#### tb_user_oauth (SNS 계정)

| 컬럼명               | 타입                                  | 설명                         |
|----------------------|---------------------------------------|------------------------------|
| seq                  | INT UNSIGNED PK                       | 계정 고유 ID                  |
| user_seq             | INT UNSIGNED (FK → tb_users.seq)     | 소유자                        |
| platform_type        | ENUM('INSTAGRAM','TIKTOK','FACEBOOK') | 플랫폼                        |
| oauth_id             | VARCHAR(300)                          | 플랫폼 사용자 ID              |
| username             | VARCHAR(100)                          | @username                    |
| api_access_token     | TEXT                                  | 액세스 토큰                  |
| api_refresh_token    | TEXT                                  | 리프레시 토큰                |
| api_token_expired_at | DATETIME                              | 토큰 만료일시                |

- **인덱스**: `(user_seq, platform_type, oauth_id)` UNIQUE

#### tb_post_triggers (트리거 - 핵심 테이블)

| 컬럼명               | 타입                              | 설명                                 |
|----------------------|-----------------------------------|--------------------------------------|
| seq                  | INT UNSIGNED PK                   | 트리거 고유 ID                       |
| platform             | ENUM('INSTAGRAM','FACEBOOK')      | 플랫폼                               |
| post_seq             | INT UNSIGNED (FK → instagram)     | Instagram 게시물                     |
| facebook_post_seq    | INT UNSIGNED (FK → facebook)      | Facebook 게시물                      |
| user_seq             | INT UNSIGNED (FK → tb_users.seq)  | 소유자                               |
| oauth_seq            | INT UNSIGNED (FK → tb_user_oauth) | 연동 계정                            |
| trigger_word         | VARCHAR(200)                      | 트리거 키워드 (콤마 구분 다중 지원)  |
| dm_message           | VARCHAR(1000)                     | 자동 발송 DM 메시지                  |
| trigger_follow       | TINYINT                           | 팔로워만 발송 여부                   |
| follow_check_message | VARCHAR(500)                      | 팔로우 확인 메시지                   |
| reply_comment        | TINYINT                           | 댓글 답글 여부                       |
| reply_comment_text   | TEXT                              | 답글 내용 (JSON 배열, 랜덤 선택)     |
| button_title         | VARCHAR(20)                       | CTA 버튼 텍스트                      |
| button_url           | VARCHAR(500)                      | CTA 버튼 URL                         |
| status               | ENUM('ACTIVATED','SUSPENDED')     | 트리거 상태                          |

- **유효성 검증**: INSTAGRAM 트리거는 반드시 `post_seq` 필요, FACEBOOK 트리거는 반드시 `facebook_post_seq` 필요 (Model-level validation)

#### tb_trigger_execute_history (발송 이력)

| 컬럼명        | 타입                                    | 설명                           |
|---------------|-----------------------------------------|--------------------------------|
| seq           | INT UNSIGNED PK                         | 이력 고유 ID                   |
| trigger_seq   | INT UNSIGNED (FK → tb_post_triggers)   | 트리거                         |
| commenter_id  | VARCHAR(300)                            | 댓글 작성자 SNS ID             |
| status        | ENUM('PENDING','SENT','FAIL','DUPLICATED') | 발송 상태                  |
| error_message | TEXT                                    | 실패 사유                      |
| comment_text  | TEXT                                    | 트리거된 댓글 내용             |
| matched_keyword | VARCHAR(200)                          | 매칭된 키워드                  |
| dm_sent_at    | DATETIME                                | DM 발송 시간                   |

#### tb_subscriptions (구독)

| 컬럼명                        | 타입                                          | 설명                          |
|-------------------------------|-----------------------------------------------|-------------------------------|
| seq                           | INT UNSIGNED PK                               | 구독 고유 ID                  |
| user_seq                      | INT UNSIGNED UNIQUE (FK → tb_users.seq)       | 소유자 (1:1)                  |
| plan_seq                      | INT UNSIGNED (FK → tb_plans.seq)             | 현재 플랜                     |
| pending_plan_seq              | INT UNSIGNED                                  | 다음 주기에 적용될 플랜       |
| subscription_status           | ENUM('pending','active','cancelled','suspended') | 구독 상태                  |
| billing_key                   | VARCHAR(100)                                  | Iamport 빌링키                |
| lemon_squeezy_subscription_id | VARCHAR(100)                                  | LemonSqueezy 구독 ID          |
| next_billing_date             | DATE                                          | 다음 결제 예정일              |
| cancel_at_period_end          | BOOLEAN                                       | 기간 종료 후 해지 예약        |

#### tb_monthly_usage (월별 DM 사용량)

| 컬럼명                    | 타입              | 설명                           |
|---------------------------|-------------------|--------------------------------|
| seq                       | INT UNSIGNED PK   | 레코드 ID                      |
| user_seq                  | INT UNSIGNED      | 사용자                         |
| oauth_seq                 | INT UNSIGNED      | 계정별 사용량 추적             |
| plan_seq                  | INT UNSIGNED      | 해당 월의 플랜                 |
| usage_month               | CHAR(7)           | 년월 (YYYY-MM)                 |
| dm_sent_count             | INT UNSIGNED      | 실제 발송 건수                 |
| bonus_dm_count            | INT UNSIGNED      | 쿠폰 보너스 DM 발송량          |
| warning_email_sent        | TINYINT           | 90% 경고 이메일 발송 여부      |
| quota_reached_email_sent  | TINYINT           | 100% 차단 이메일 발송 여부     |

- **인덱스**: `(user_seq, oauth_seq, usage_month)` UNIQUE

#### tb_referral_coupons (추천 쿠폰)

| 컬럼명           | 타입                              | 설명                    |
|------------------|-----------------------------------|-------------------------|
| seq              | INT UNSIGNED PK                   | 쿠폰 ID                 |
| user_seq         | INT UNSIGNED (FK)                 | 쿠폰 소유자             |
| referrer_user_seq | INT UNSIGNED (FK)                | 추천인                  |
| dm_amount        | INT UNSIGNED                      | 추가 DM 발송량 (기본 100) |
| status           | ENUM('AVAILABLE','USED','EXPIRED') | 쿠폰 상태              |
| expires_at       | DATETIME                          | 만료일시                |
| applied_month    | CHAR(7)                           | 적용된 월 (YYYY-MM)     |

---

## 6. API 구조

### 기본 규칙

- **Base URL**: `/api`
- **응답 형식**: `{ success: boolean, data?: any, message?: string }`
- **인증**: `Authorization: Bearer <access_token>` 헤더
- **에러 처리**: 중앙 에러 미들웨어에서 일관된 형식으로 응답

### 라우트 그룹

| 라우트 접두사      | 설명                             |
|--------------------|----------------------------------|
| `GET /api/health`  | 서버 상태 확인                   |
| `/api/auth`        | 인증 (로그인, 회원가입, OAuth)   |
| `/api/posts`       | 게시물 조회 및 동기화            |
| `/api/triggers`    | 트리거 CRUD                      |
| `/api/history`     | 발송 이력                        |
| `/api/webhooks`    | Meta Webhook 수신                |
| `/api/stats`       | 통계 조회                        |
| `/api/plans`       | 요금제 플랜 조회                 |
| `/api/subscriptions` | 구독 관리                      |
| `/api/payments`    | 결제 처리                        |
| `/api/usage`       | DM 사용량 조회                   |
| `/api/accounts`    | 계정 관리 (연동/해제)            |
| `/api/referrals`   | 추천인 코드 및 쿠폰              |
| `/api/feedback`    | 피드백 및 고객 문의              |
| `/api/admin`       | 관리자 전용 API                  |

### 주요 API 엔드포인트

#### 인증 API (`/api/auth`)

```
GET  /instagram/login          Instagram OAuth URL 요청
GET  /instagram/callback       Instagram OAuth 콜백
POST /instagram/deauthorize    Instagram 앱 연결 해제 콜백 (GDPR)
POST /instagram/data-deletion  Instagram 데이터 삭제 요청 (GDPR)
GET  /google/login             Google OAuth URL 요청
GET  /google/callback          Google OAuth 콜백
POST /link-google              Google 계정 연동
GET  /facebook/login           Facebook OAuth URL 요청
GET  /facebook/callback        Facebook OAuth 콜백
GET  /facebook/pages           연동된 Facebook 페이지 목록
POST /link-facebook            Facebook 페이지 연동
DELETE /unlink-facebook/:pageSeq  Facebook 페이지 연동 해제
POST /register                 이메일 회원가입
POST /verify-email             이메일 인증 코드 확인
POST /resend-code              인증 코드 재발송
POST /login                    이메일 로그인
POST /forgot-password          비밀번호 재설정 요청
POST /reset-password           비밀번호 재설정 완료
PATCH /password                비밀번호 변경 (인증 필요)
POST /link-instagram           Instagram 계정 추가 연동
POST /refresh                  Access Token 갱신
GET  /me                       현재 사용자 정보 조회
POST /logout                   로그아웃
DELETE /account                회원 탈퇴
```

#### 트리거 API (`/api/triggers`)

```
GET    /              트리거 목록 조회 (페이지네이션, 플랫폼/계정 필터)
POST   /              트리거 생성
GET    /stats         플랫폼별 트리거 통계
GET    /:id           트리거 상세 조회
PATCH  /:id           트리거 수정
DELETE /:id           트리거 삭제
PATCH  /:id/toggle    트리거 활성/비활성 전환
GET    /:id/clicks    트리거 CTA 클릭 통계
```

#### 게시물 API (`/api/posts`)

```
GET  /                      저장된 Instagram 게시물 목록 (DB)
POST /sync                  Instagram 게시물 동기화
GET  /instagram             Instagram API 직접 게시물 조회
GET  /media-status          게시물 미디어 저장 상태 (폴링용)
GET  /facebook              Facebook 게시물 목록 (DB)
POST /facebook/sync         Facebook 게시물 동기화
GET  /facebook/:postSeq     Facebook 게시물 상세
GET  /facebook/:postSeq/triggers  Facebook 게시물 트리거 목록
GET  /facebook/:postId/comments   Facebook 게시물 댓글
GET  /:postSeq              Instagram 게시물 상세
GET  /:postSeq/triggers     Instagram 게시물 트리거 목록
GET  /:postId/comments      Instagram 게시물 댓글
```

#### 웹훅 API (`/api/webhooks`)

```
GET  /instagram     Instagram Webhook 검증 (Subscribe)
POST /instagram     Instagram Webhook 이벤트 수신
GET  /facebook      Facebook Webhook 검증 (Subscribe)
POST /facebook      Facebook Webhook 이벤트 수신
```

---

## 7. 프론트엔드 구조

### 디렉토리 구조

```
web/
├── app/                          # Next.js App Router
│   ├── (auth)/                   # 인증 레이아웃 그룹
│   │   ├── login/                # 로그인 페이지
│   │   ├── register/             # 회원가입 페이지
│   │   ├── forgot-password/      # 비밀번호 찾기
│   │   └── reset-password/       # 비밀번호 재설정
│   ├── dashboard/                # 메인 앱 (인증 필요)
│   │   ├── page.tsx              # 대시보드 메인 (통계)
│   │   ├── triggers/             # 트리거 관리
│   │   │   ├── page.tsx          # 트리거 목록
│   │   │   ├── new/              # 트리거 생성
│   │   │   └── [id]/             # 트리거 상세/편집
│   │   ├── posts/                # 게시물 관리
│   │   ├── history/              # 발송 이력
│   │   ├── subscription/         # 구독 관리
│   │   ├── pricing/              # 요금제
│   │   ├── settings/             # 계정 설정
│   │   └── admin/                # 관리자 페이지
│   ├── about/                    # 서비스 소개
│   ├── pricing/                  # 랜딩 요금제
│   ├── privacy/                  # 개인정보처리방침
│   └── terms/                    # 이용약관
│
├── components/                   # React 컴포넌트
│   ├── ui/                       # shadcn/ui 기본 컴포넌트 (30개+)
│   ├── layout/                   # 레이아웃 컴포넌트
│   │   ├── DashboardLayout.tsx   # 대시보드 사이드바+헤더
│   │   ├── LandingHeader.tsx     # 랜딩 헤더
│   │   └── LandingFooter.tsx     # 랜딩 푸터
│   ├── auth/                     # 인증 관련 컴포넌트
│   ├── triggers/                 # 트리거 폼 컴포넌트
│   │   ├── TriggerForm.tsx       # 트리거 생성/편집 폼 (Zod 검증)
│   │   ├── PostSelector.tsx      # Instagram 게시물 선택
│   │   ├── FacebookPostSelector.tsx # Facebook 게시물 선택
│   │   └── KeywordInput.tsx      # 키워드 태그 입력
│   ├── dashboard/                # 대시보드 컴포넌트
│   ├── settings/                 # 설정 컴포넌트
│   │   ├── AccountManagement.tsx # Instagram 계정 관리
│   │   └── FacebookAccountManagement.tsx
│   ├── analytics/                # 분석 컴포넌트 (Mixpanel)
│   ├── pricing/                  # 요금제 컴포넌트
│   ├── subscription/             # 구독 컴포넌트
│   └── common/                   # 공통 컴포넌트 (Loading, EmptyState 등)
│
├── hooks/                        # 커스텀 React Hooks
│   ├── useAuth.ts                # 인증 (로그인/회원가입/탈퇴)
│   ├── useTriggers.ts            # 트리거 CRUD
│   ├── usePosts.ts               # 게시물 조회
│   ├── useStats.ts               # 통계 조회
│   ├── useSubscription.ts        # 구독 정보
│   ├── useUsage.ts               # DM 사용량
│   ├── useAccounts.ts            # SNS 계정 관리
│   ├── useFacebookAccounts.ts    # Facebook 계정 관리
│   ├── useReferral.ts            # 추천인 시스템
│   ├── useHistory.ts             # 발송 이력
│   └── usePlans.ts               # 요금제 목록
│
├── lib/
│   ├── api/                      # API 클라이언트 모듈
│   │   ├── index.ts              # Axios 인스턴스 (인터셉터)
│   │   ├── auth.ts               # 인증 API
│   │   ├── triggers.ts           # 트리거 API
│   │   ├── posts.ts              # 게시물 API
│   │   └── ...
│   ├── validations/              # Zod 스키마
│   └── utils.ts                  # cn() 등 유틸리티
│
├── store/
│   └── authStore.ts              # Zustand 인증 상태 관리
│
├── types/                        # TypeScript 타입 정의
│
├── messages/                     # 다국어 번역 파일
│   ├── ko.json                   # 한국어
│   ├── en.json                   # 영어
│   └── ja.json                   # 일본어
│
└── i18n/                         # next-intl 설정
```

### 상태 관리 전략

**서버 상태 (TanStack Query)**
- API 데이터는 모두 TanStack Query로 관리
- 캐시 무효화(Invalidation)로 낙관적 업데이트 구현
- 에러 상태 및 로딩 상태 일관 처리

**클라이언트 상태 (Zustand)**
- 인증 상태 (로그인 여부, 사용자 정보, 토큰) 전용
- localStorage 연동으로 새로고침 후에도 유지

**URL 상태**
- 필터, 페이지 번호 등은 URL 쿼리 파라미터에 저장
- Next.js `useSearchParams`/`useRouter`로 관리

### Axios 인터셉터 패턴

```typescript
// 요청 인터셉터: Authorization 헤더 자동 삽입
// 응답 인터셉터:
//   401 응답 시 → Refresh Token으로 자동 갱신
//   갱신 성공 시 → 원래 요청 재시도
//   갱신 실패 시 → 로그인 페이지로 리다이렉트
```

### Feature Flag 패턴

환경 변수를 이용한 기능 플래그로 점진적 배포 지원:

```typescript
const isFacebookEnabled = process.env.NEXT_PUBLIC_ENABLE_FACEBOOK === 'true';
const isInstagramFollowEnabled = process.env.NEXT_PUBLIC_ENABLE_INSTAGRAM_FOLLOW === 'true';
const isReferralEnabled = process.env.NEXT_PUBLIC_ENABLE_REFERRAL === 'true';
```

---

## 8. 보안 및 인증 체계

### JWT 토큰 이중 체계

```
로그인 성공
    ↓
Access Token (15분 만료) + Refresh Token (7일 만료) 발급
    ↓
API 요청 시 Access Token 사용 (Authorization: Bearer)
    ↓
Access Token 만료 시 → Refresh Token으로 자동 갱신
    ↓
로그아웃 시 → 서버의 Refresh Token 무효화
```

### OAuth 연동 보안

- Instagram/Facebook OAuth: HMAC-SHA256 서명 검증
- Google OAuth: state 파라미터로 CSRF 방지
- Instagram 앱 연결 해제 / 데이터 삭제 Webhook 처리 (GDPR 준수)

### API 보안

| 보안 항목           | 구현 내용                                                         |
|---------------------|-------------------------------------------------------------------|
| 보안 헤더           | Helmet.js (X-Frame-Options, CSP, HSTS 등 자동 설정)              |
| Rate Limiting       | express-rate-limit (API별 요청 횟수 제한)                         |
| 요청 검증           | Joi 스키마 기반 전수 검증                                         |
| SQL Injection 방지  | Sequelize ORM의 Parameterized Query                               |
| 비밀번호 보안       | bcrypt (Salt Round 10)                                            |
| Webhook 검증        | HMAC-SHA256 서명 검증 (rawBody 보존)                              |
| CORS 설정           | 허용 Origin 명시적 제한                                           |
| Admin 권한 분리     | `requireAdmin` 미들웨어로 관리자 API 보호                        |

### 계정 잠금 정책

- 로그인 5회 연속 실패 시 계정 임시 잠금
- `locked_until` 시간 이후 자동 해제
- 잠금 상태에서 추가 시도 시 남은 잠금 시간 안내

### 관리자 Impersonation

- ADMIN 권한 사용자만 `X-Impersonate-User-Seq` 헤더 사용 가능
- Impersonation 상태에서는 민감한 액션 차단 (`blockDuringImpersonation`)
- 모든 Impersonation 행위 로그 기록

---

## 9. 배포 및 인프라

### 인프라 구성

```
인터넷
    ↓
DNS (도메인)
    ↓
AWS / 서버 (Nginx 리버스 프록시 + SSL/TLS)
    ├── Next.js 앱 (Port 3001)
    └── Express.js API (Port 3000)
         ↓
    AWS RDS MySQL
         ↓
    AWS S3 + CloudFront CDN (미디어 파일)
         ↓
    AWS SES (이메일)
```

### AWS 서비스 활용

| 서비스       | 용도                                               |
|--------------|----------------------------------------------------|
| AWS EC2/서버 | Node.js API 서버 / Next.js 서버 호스팅             |
| AWS RDS      | MySQL 데이터베이스 (고가용성, 자동 백업)           |
| AWS S3       | Instagram/Facebook 미디어 파일 영구 저장           |
| CloudFront   | S3 미디어 파일 CDN 배포 (전세계 빠른 로딩)        |
| AWS SES      | 트랜잭셔널 이메일 발송 (인증, 알림, 한도 경고)    |

### 이메일 시스템

AWS SES + EJS 템플릿 기반 다양한 이메일 자동 발송:

| 이메일 종류           | 발송 시점                                  |
|-----------------------|--------------------------------------------|
| 이메일 인증           | 회원가입 시 6자리 인증 코드 발송           |
| 비밀번호 재설정       | 비밀번호 찾기 요청 시 재설정 링크 발송     |
| DM 90% 경고           | 월간 DM 한도 90% 도달 시 자동 발송         |
| DM 100% 차단 안내     | 월간 DM 한도 초과 시 차단 안내 발송        |
| 구독 갱신 알림        | 정기 구독 갱신 완료 시 발송               |
| 구독 해지 확인        | 구독 해지 요청 시 확인 이메일 발송         |

### Slack 모니터링

실시간 Slack 알림을 통한 운영 모니터링:

- 신규 사용자 가입 알림 (가입 방식, 이메일 포함)
- 결제 성공/실패 알림
- 시스템 에러 알림

### SEO 최적화

- JSON-LD 구조화 데이터 (SoftwareApplication 스키마)
- OpenGraph / Twitter Card 메타태그
- 다국어 `hreflang` 태그
- `sitemap.xml` 자동 생성
- `robots.ts` 설정

---

## 10. 프로젝트 성과 및 특장점

### 기술적 특장점

**1. 확장 가능한 멀티 플랫폼 아키텍처**

초기 Instagram 전용으로 설계된 시스템을 Facebook까지 확장한 경험. `tb_post_triggers` 테이블의 `platform` ENUM과 `post_seq`/`facebook_post_seq` 선택적 FK 설계로 플랫폼 추가 시 스키마 변경 최소화.

**2. 지능형 키워드 매칭 알고리즘**

단순 포함 매칭을 넘어, `=` 접두사를 통한 정확 매칭 지원. 콤마 구분 다중 키워드로 하나의 트리거에 여러 조건 설정 가능. 대소문자 무관 매칭(case-insensitive).

**3. 이중 결제 시스템 통합**

국내 사용자(Iamport 빌링키 방식)와 해외 사용자(LemonSqueezy 구독)를 동일한 구독 모델(`tb_subscriptions`)로 통합 관리. 각 결제 수단의 Webhook을 통한 실시간 구독 상태 동기화.

**4. 쿼터 기반 DM 제한 시스템**

초과 과금 없이 한도 도달 시 차단하는 예측 가능한 과금 정책. 플랜 속성을 `tb_plan_properties`에 동적으로 관리하여 코드 변경 없이 플랜 한도 조정 가능.

**5. 랜덤 댓글 답글 로테이션**

JSON 배열로 저장된 다수의 답글 템플릿 중 랜덤 선택 발송. Meta 플랫폼의 스팸 감지 알고리즘 우회 및 자연스러운 응대 경험 제공.

**6. 미디어 영구 보관 전략**

Instagram/Facebook 미디어 URL은 만료 기한이 있어, Webhook 수신 시 S3에 자동 복사 저장. 만료 후에도 대시보드에서 게시물 이미지 확인 가능. S3 장애 시 원본 URL 폴백 처리.

**7. 추천인 양방향 쿠폰 시스템**

추천인과 신규 가입자 모두에게 쿠폰 발급 (양방향 인센티브). `(user_seq, referrer_user_seq)` UNIQUE 제약으로 중복 쿠폰 방지. 쿠폰은 보너스 DM 할당량으로 적용되어 기존 쿼터에 추가.

**8. Feature Flag 기반 점진적 배포**

환경 변수 기반 Feature Flag 패턴으로 미완성 기능을 코드베이스에 포함하면서 특정 환경에서만 노출. Facebook 기능, 팔로워 필터 기능 등 단계적으로 활성화.

**9. 다국어 지원 (한국어/영어/일본어)**

next-intl을 통한 서버 컴포넌트/클라이언트 컴포넌트 양방향 다국어 지원. 플랜 이름(`name_ko`, `name_en`, `name_ja`)도 DB에서 다국어로 관리.

**10. 관리자 Impersonation**

고객 지원 시 해당 사용자의 시점에서 문제를 직접 확인할 수 있는 Impersonation 기능. 모든 행위 로그 기록 및 민감한 액션 자동 차단으로 안전한 운영 지원.

### 코드 품질

- **레이어드 아키텍처**: Routes → Controllers → Services → Models의 명확한 레이어 분리
- **중앙 에러 핸들링**: 커스텀 에러 클래스 계층 구조 (`NotFoundError`, `UnauthorizedError`, `ForbiddenError` 등)
- **일관된 API 응답**: 모든 엔드포인트에서 `{ success, data, message }` 형식 유지
- **TypeScript 엄격 모드**: 프론트엔드 전체 TypeScript, `unknown` 타입 사용 원칙
- **유효성 검증 이중화**: 서버(Joi) + 클라이언트(Zod) 양측 검증

### 운영 편의성

- **Graceful Shutdown**: SIGTERM/SIGINT 신호 수신 시 진행 중인 요청 완료 후 안전 종료
- **구조화된 로깅**: Winston 기반 레벨별 로그 관리
- **Slack 알림**: 주요 비즈니스 이벤트 및 에러 실시간 알림
- **관리자 대시보드**: 구독 현황 조회 및 사용자 지원 기능 내장

---

*최종 업데이트: 2026년 2월 26일*
