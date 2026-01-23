# Autogram 유저 매뉴얼

> Instagram 댓글 트리거 기반 자동 DM 발송 시스템

**버전:** 1.0.0
**최종 업데이트:** 2026-01-24

---

## 목차

1. [프로젝트 개요](#1-프로젝트-개요)
2. [시작하기](#2-시작하기)
3. [설치 및 설정](#3-설치-및-설정)
4. [주요 기능 사용 방법](#4-주요-기능-사용-방법)
5. [설정 옵션](#5-설정-옵션)
6. [문제 해결 가이드 (FAQ)](#6-문제-해결-가이드-faq)
7. [API 레퍼런스](#7-api-레퍼런스)

---

## 1. 프로젝트 개요

### 1.1 Autogram이란?

**Autogram**은 Instagram 비즈니스 계정의 게시물에 특정 키워드가 포함된 댓글이 달릴 때 자동으로 DM(Direct Message)을 발송하는 마케팅 자동화 플랫폼입니다.

### 1.2 주요 목적

- **마케팅 자동화**: 댓글을 통한 고객 문의에 즉각적인 자동 응답
- **리드 수집**: 특정 키워드로 관심을 표현한 잠재고객 자동 수집
- **시간 절약**: 수동 DM 발송 업무를 자동화하여 운영 효율성 증대
- **전환율 향상**: 빠른 응답으로 고객 참여도 및 전환율 상승

### 1.3 핵심 플로우

```
사용자 로그인
    ↓
Instagram 비즈니스 계정 연동
    ↓
게시물 선택 및 트리거 생성 (키워드 + DM 메시지)
    ↓
Instagram Webhook → 실시간 댓글 감지
    ↓
키워드 매칭 시 자동 DM 발송
    ↓
대시보드에서 통계 및 발송 이력 확인
```

### 1.4 지원 플랫폼

- **Instagram 비즈니스 계정** (필수)
- **Facebook 페이지** (Instagram 연동용)
- **웹 대시보드** (PC, 태블릿, 모바일 브라우저)

---

## 2. 시작하기

### 2.1 사전 요구사항

#### 필수 사항
1. **Instagram 비즈니스 계정** 또는 **크리에이터 계정**
2. **Facebook 페이지** (Instagram 계정과 연동되어 있어야 함)
3. **이메일 주소** (회원가입용)
4. **최신 웹 브라우저** (Chrome, Safari, Edge, Firefox)

#### 선택 사항
- Google 계정 (Google OAuth 로그인 사용 시)

### 2.2 회원가입

#### 방법 1: 이메일 회원가입

1. [https://autogram.yourdomain.com](https://autogram.yourdomain.com) 접속
2. **회원가입** 버튼 클릭
3. 이메일, 비밀번호, 이름 입력
4. **회원가입 완료** 버튼 클릭
5. 이메일 인증 링크 클릭 (선택사항)

#### 방법 2: Google 로그인

1. 랜딩 페이지에서 **Google로 시작하기** 클릭
2. Google 계정 선택 및 권한 승인
3. 자동 로그인 완료

### 2.3 Instagram 계정 연동

> ⚠️ **중요**: Autogram 사용을 위해서는 Instagram 비즈니스 계정 연동이 필수입니다.

1. 로그인 후 **설정** 페이지 이동
2. **Instagram 계정 연동** 섹션에서 **연동하기** 버튼 클릭
3. Instagram/Facebook 로그인 팝업에서 권한 승인
4. 연동 완료 후 Instagram 사용자명 표시 확인

**연동 시 필요한 권한:**
- `instagram_basic`: 기본 프로필 정보
- `instagram_manage_messages`: DM 발송 권한
- `instagram_manage_comments`: 댓글 읽기 권한
- `pages_manage_metadata`: 페이지 정보 접근

---

## 3. 설치 및 설정

### 3.1 시스템 요구사항

#### 백엔드 (API 서버)
- **Node.js**: 22.x 이상
- **MySQL**: 8.0 이상
- **운영체제**: Linux, macOS, Windows
- **메모리**: 최소 512MB RAM
- **디스크**: 최소 1GB 여유 공간

#### 프론트엔드 (웹 대시보드)
- **Node.js**: 22.x 이상
- **브라우저**: Chrome 90+, Safari 14+, Edge 90+, Firefox 88+

### 3.2 로컬 개발 환경 설정

#### Step 1: 프로젝트 클론

```bash
git clone https://github.com/yourorg/sns_automation.git
cd sns_automation
```

#### Step 2: 데이터베이스 설정

```bash
# MySQL 접속
mysql -u root -p

# 데이터베이스 생성
CREATE DATABASE sns_automation CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

# 초기 스키마 적용 (마이그레이션 파일 실행)
mysql -u root -p sns_automation < api/migrations/init.sql
```

#### Step 3: 백엔드 설정

```bash
cd api

# 의존성 설치
npm install

# 환경 변수 파일 생성
cp .env.example .env

# .env 파일 수정 (아래 섹션 참조)
nano .env
```

**필수 환경 변수 (.env):**

```bash
# 서버 설정
NODE_ENV=development
PORT=3000
FRONTEND_URL=http://localhost:3001

# 데이터베이스
DB_HOST=localhost
DB_PORT=3306
DB_NAME=sns_automation
DB_USER=root
DB_PASSWORD=your_password

# JWT 토큰
JWT_SECRET=your-super-secret-key-min-32-characters
JWT_ACCESS_TOKEN_EXPIRES_IN=15m
JWT_REFRESH_TOKEN_EXPIRES_IN=7d

# Instagram API
INSTAGRAM_APP_ID=your_instagram_app_id
INSTAGRAM_APP_SECRET=your_instagram_app_secret
INSTAGRAM_REDIRECT_URI=http://localhost:3000/api/auth/instagram/callback
INSTAGRAM_WEBHOOK_VERIFY_TOKEN=your_random_verify_token

# Google OAuth
GOOGLE_CLIENT_ID=your_google_client_id
GOOGLE_CLIENT_SECRET=your_google_client_secret
GOOGLE_REDIRECT_URI=http://localhost:3000/api/auth/google/callback

# AWS S3 (썸네일 저장용)
AWS_S3_BUCKET=your-bucket-name
AWS_S3_PREFIX=autogram
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
```

**개발 서버 실행:**

```bash
# 개발 모드 (nodemon 사용)
npm run dev

# 프로덕션 모드
npm start
```

서버가 `http://localhost:3000`에서 실행됩니다.

#### Step 4: 프론트엔드 설정

```bash
cd ../web

# 의존성 설치
npm install

# 환경 변수 파일 생성
cp .env.example .env.local

# .env.local 파일 수정
nano .env.local
```

**프론트엔드 환경 변수 (.env.local):**

```bash
NEXT_PUBLIC_API_URL=http://localhost:3000/api
NEXT_PUBLIC_APP_URL=http://localhost:3001
```

**개발 서버 실행:**

```bash
npm run dev
```

웹 대시보드가 `http://localhost:3001`에서 실행됩니다.

### 3.3 Instagram App 설정

#### 3.3.1 Meta for Developers 앱 생성

1. [Meta for Developers](https://developers.facebook.com/) 접속
2. **My Apps** → **Create App** 클릭
3. 앱 유형: **Business** 선택
4. 앱 이름 및 연락처 이메일 입력
5. 앱 생성 완료

#### 3.3.2 Instagram Graph API 추가

1. 앱 대시보드 → **Add Products**
2. **Instagram** 제품 추가
3. **Settings** → **Basic** 에서 **App ID**와 **App Secret** 확인
4. `.env` 파일에 복사

#### 3.3.3 Webhook 설정

1. 앱 대시보드 → **Instagram** → **Webhooks**
2. **Subscribe to Webhook** 버튼 클릭
3. **Callback URL**: `https://yourdomain.com/api/webhooks/instagram`
4. **Verify Token**: `.env`의 `INSTAGRAM_WEBHOOK_VERIFY_TOKEN` 값 입력
5. **Subscribe to**: `comments` 선택
6. 저장

#### 3.3.4 OAuth Redirect URI 등록

1. 앱 대시보드 → **Instagram** → **Basic Settings**
2. **Valid OAuth Redirect URIs** 추가:
   - `http://localhost:3000/api/auth/instagram/callback` (개발용)
   - `https://yourdomain.com/api/auth/instagram/callback` (프로덕션용)
3. 저장

### 3.4 프로덕션 배포

#### 백엔드 배포 (예: AWS EC2)

```bash
# PM2 설치 (프로세스 관리자)
npm install -g pm2

# 프로젝트 빌드 및 실행
cd api
npm install --production
pm2 start src/server.js --name autogram-api

# 부팅 시 자동 시작 설정
pm2 startup
pm2 save
```

#### 프론트엔드 배포 (예: Vercel)

```bash
cd web
npm run build

# Vercel CLI로 배포
npx vercel --prod
```

---

## 4. 주요 기능 사용 방법

### 4.1 대시보드

#### 4.1.1 통계 개요

대시보드 홈 화면에서 다음 정보를 확인할 수 있습니다:

- **오늘 발송**: 금일 자동 발송된 DM 개수
- **활성 트리거**: 현재 활성화된 트리거 개수
- **도달률**: 성공적으로 발송된 DM 비율
- **총 발송**: 누적 DM 발송 개수

#### 4.1.2 시간별 발송 현황

- 최근 24시간 동안의 시간대별 DM 발송 현황을 차트로 표시
- 성공/실패 건수를 색상으로 구분

#### 4.1.3 상위 트리거

- 가장 많이 실행된 트리거 TOP 5
- 각 트리거의 성공률 및 발송 건수 표시

#### 4.1.4 최근 활동 내역

- 최근 10건의 DM 발송 이력
- 수신자, 댓글 내용, 발송 상태 확인

### 4.2 트리거 관리

#### 4.2.1 트리거 생성

**Step 1: 트리거 페이지 이동**
- 좌측 메뉴에서 **트리거** 클릭
- 우측 상단 **+ 트리거 생성** 버튼 클릭

**Step 2: 게시물 선택**
- Instagram에서 불러온 게시물 목록이 표시됨
- 트리거를 적용할 게시물 선택

> 💡 **팁**: 게시물이 보이지 않는다면 **새로고침** 버튼을 클릭하거나 Instagram 연동 상태를 확인하세요.

**Step 3: 트리거 키워드 입력**
- 댓글에서 감지할 키워드 입력
- 여러 키워드는 쉼표로 구분 (예: `정보,신청,문의`)
- 키워드는 대소문자 구분 없음

**Step 4: DM 메시지 작성**
- 자동 발송될 DM 내용 입력
- 최대 1,000자
- 이모지 사용 가능

**Step 5: 옵션 설정**
- **팔로워에게만 발송**: 체크 시 팔로워가 아닌 사용자에게는 DM 미발송
- **댓글 자동 답글**: (향후 지원 예정)

**Step 6: 저장**
- **트리거 생성** 버튼 클릭
- 생성 완료 시 트리거 목록으로 자동 이동

#### 4.2.2 트리거 수정

1. 트리거 목록에서 수정할 트리거 카드 클릭
2. 우측 상단 **수정** 버튼 클릭
3. 키워드, DM 메시지, 옵션 변경
4. **저장** 버튼 클릭

#### 4.2.3 트리거 활성화/비활성화

- 트리거 카드 우측 상단의 **토글 스위치** 클릭
- 비활성화된 트리거는 댓글이 달려도 DM을 발송하지 않음

#### 4.2.4 트리거 삭제

1. 트리거 상세 페이지 이동
2. 우측 상단 **삭제** 버튼 클릭
3. 확인 대화상자에서 **확인** 클릭

> ⚠️ **주의**: 삭제된 트리거는 복구할 수 없으며, 연관된 발송 이력은 유지됩니다.

### 4.3 발송 이력 조회

#### 4.3.1 이력 페이지

좌측 메뉴에서 **발송 이력** 클릭 시 다음 정보를 확인할 수 있습니다:

- **발송 일시**: DM 발송 시간
- **수신자**: Instagram 사용자명
- **댓글 내용**: 트리거를 발생시킨 댓글
- **발송 상태**:
  - `성공` (SENT): 정상 발송
  - `대기` (PENDING): 발송 대기 중
  - `실패` (FAIL): 발송 실패
  - `중복` (DUPLICATED): 이미 발송된 사용자

#### 4.3.2 필터링

- **상태별 필터**: 드롭다운에서 원하는 상태 선택
- **트리거별 필터**: 특정 트리거의 이력만 조회
- **날짜 필터**: 시작일/종료일 지정

#### 4.3.3 페이지네이션

- 페이지당 20건씩 표시
- 하단 페이지네이션 컨트롤로 이동

### 4.4 설정

#### 4.4.1 계정 설정

**설정** 페이지에서 다음 항목을 관리할 수 있습니다:

- **프로필 정보**: 이름, 이메일 확인
- **Instagram 연동 상태**: 연동된 Instagram 계정 확인
- **연동 해제**: Instagram 계정 연동 해제 (재연동 필요)

#### 4.4.2 비밀번호 변경

1. **설정** → **비밀번호 변경** 섹션
2. 현재 비밀번호 입력
3. 새 비밀번호 입력 (8자 이상)
4. **변경** 버튼 클릭

#### 4.4.3 계정 연동 관리

- **Google 계정 연동**: Google 로그인으로도 접속 가능
- **Facebook 페이지 연동**: 추가 페이지 연동 (향후 지원)

---

## 5. 설정 옵션

### 5.1 트리거 옵션

| 옵션 | 설명 | 기본값 |
|------|------|--------|
| **트리거 키워드** | 댓글에서 감지할 단어 (쉼표로 구분) | 없음 (필수) |
| **DM 메시지** | 자동 발송될 메시지 내용 | 없음 (필수) |
| **팔로워에게만 발송** | 팔로워가 아닌 사용자 제외 | false |
| **댓글 자동 답글** | 댓글에 자동 답글 추가 (미구현) | false |
| **상태** | 활성화/비활성화 | ACTIVATED |

### 5.2 환경 변수 설정

#### 백엔드 (API) 환경 변수

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `NODE_ENV` | 실행 환경 | `development`, `production` |
| `PORT` | API 서버 포트 | `3000` |
| `DB_HOST` | MySQL 호스트 | `localhost` |
| `DB_NAME` | 데이터베이스 이름 | `sns_automation` |
| `JWT_SECRET` | JWT 서명 키 (32자 이상 권장) | `your-secret-key` |
| `INSTAGRAM_APP_ID` | Instagram App ID | `123456789` |
| `INSTAGRAM_APP_SECRET` | Instagram App Secret | `abc123...` |

#### 프론트엔드 (Web) 환경 변수

| 변수명 | 설명 | 예시 |
|--------|------|------|
| `NEXT_PUBLIC_API_URL` | 백엔드 API URL | `http://localhost:3000/api` |
| `NEXT_PUBLIC_APP_URL` | 프론트엔드 URL | `http://localhost:3001` |

### 5.3 데이터베이스 테이블 구조

주요 테이블 설명:

- **tb_users**: 사용자 계정 정보
- **tb_user_passwords**: 비밀번호 해시 (이메일 로그인용)
- **tb_user_oauth**: OAuth 토큰 저장 (Google, Instagram)
- **tb_instagram_posts**: 연동된 Instagram 게시물
- **tb_post_triggers**: 게시물별 트리거 설정
- **tb_trigger_execute_history**: DM 발송 이력
- **tb_subscriptions**: 구독 정보 (프리미엄 플랜용)
- **tb_plans**: 요금제 정보

---

## 6. 문제 해결 가이드 (FAQ)

### 6.1 로그인 및 계정 문제

#### Q1. "Instagram 계정을 연동할 수 없습니다" 오류

**원인:**
- Instagram 계정이 비즈니스 또는 크리에이터 계정이 아님
- Facebook 페이지와 연동되어 있지 않음
- 권한 승인을 거부함

**해결 방법:**
1. Instagram 앱에서 계정을 비즈니스 계정으로 전환
2. Facebook 페이지를 생성하고 Instagram 계정과 연결
3. 연동 시 모든 권한 승인

#### Q2. "토큰이 만료되었습니다" 메시지

**원인:**
- Access Token이 15분 후 만료됨

**해결 방법:**
- 페이지를 새로고침하면 자동으로 Refresh Token으로 갱신됨
- 갱신 실패 시 다시 로그인

#### Q3. Google 로그인이 작동하지 않음

**원인:**
- Google OAuth 설정 오류
- Redirect URI 불일치

**해결 방법:**
1. Google Cloud Console → OAuth 동의 화면 확인
2. 승인된 리디렉션 URI에 `http://localhost:3000/api/auth/google/callback` 추가
3. `.env` 파일의 `GOOGLE_REDIRECT_URI` 확인

### 6.2 트리거 관련 문제

#### Q4. 게시물 목록이 비어있음

**원인:**
- Instagram 계정에 게시물이 없음
- Instagram API 토큰 만료
- 권한 부족

**해결 방법:**
1. Instagram 앱에서 게시물 최소 1개 이상 업로드
2. **설정** → **Instagram 계정 연동 해제** 후 재연동
3. 연동 시 `instagram_basic` 권한 승인 확인

#### Q5. 트리거를 생성했는데 DM이 발송되지 않음

**원인:**
- 트리거가 비활성화 상태
- 키워드가 정확히 일치하지 않음
- Webhook이 설정되지 않음
- 팔로워 필터링 옵션 활성화 (비팔로워 댓글)

**해결 방법:**
1. 트리거 목록에서 활성화 상태 확인 (토글 ON)
2. 키워드는 대소문자 구분 없지만 정확히 일치해야 함
3. Meta for Developers에서 Webhook 설정 확인
4. 테스트 댓글 작성자가 팔로워인지 확인

#### Q6. "중복 발송" 상태로 표시됨

**원인:**
- 동일한 사용자가 이미 해당 트리거로 DM을 받았음

**설명:**
- Autogram은 스팸 방지를 위해 **동일 사용자 + 동일 트리거**에 대해 중복 발송을 차단합니다.
- 사용자가 다른 게시물에 댓글을 달면 새로운 DM 발송 가능

### 6.3 대시보드 및 통계 문제

#### Q7. 통계가 실시간으로 업데이트되지 않음

**원인:**
- 폴링 주기 (5초마다 갱신)

**해결 방법:**
- 페이지를 수동으로 새로고침 (F5)
- 브라우저 캐시 삭제

#### Q8. 발송 이력이 표시되지 않음

**원인:**
- 필터 설정으로 인해 데이터가 필터링됨
- 실제로 발송된 DM이 없음

**해결 방법:**
1. 필터 초기화 (전체 보기)
2. 날짜 범위 확장
3. 트리거가 활성화되어 있고 댓글이 달렸는지 확인

### 6.4 기술적 문제

#### Q9. 백엔드 서버가 시작되지 않음

**원인:**
- 포트 3000이 이미 사용 중
- 데이터베이스 연결 실패
- 환경 변수 설정 오류

**해결 방법:**

```bash
# 포트 사용 확인 및 종료 (macOS/Linux)
lsof -ti:3000 | xargs kill -9

# 데이터베이스 연결 테스트
mysql -u root -p -e "USE sns_automation; SHOW TABLES;"

# .env 파일 검증
cat api/.env | grep -E "(DB_|JWT_|INSTAGRAM_)"
```

#### Q10. 프론트엔드 빌드 오류

**원인:**
- Node.js 버전 불일치
- 의존성 설치 오류

**해결 방법:**

```bash
# Node.js 버전 확인
node -v  # 22.x 이상이어야 함

# 의존성 재설치
cd web
rm -rf node_modules package-lock.json
npm install

# 빌드 재시도
npm run build
```

#### Q11. Webhook이 작동하지 않음

**원인:**
- Meta Webhook 설정 오류
- HTTPS 필요 (프로덕션 환경)
- Verify Token 불일치

**해결 방법:**

1. **개발 환경**: ngrok으로 로컬 서버 터널링
   ```bash
   # ngrok 설치
   brew install ngrok  # macOS

   # 터널 생성
   ngrok http 3000

   # ngrok URL을 Meta Webhook Callback URL에 등록
   # 예: https://abc123.ngrok.io/api/webhooks/instagram
   ```

2. **프로덕션 환경**:
   - HTTPS 인증서 필수 (Let's Encrypt 권장)
   - Nginx 리버스 프록시 설정

3. **Verify Token 확인**:
   ```bash
   # .env 파일의 토큰 확인
   grep INSTAGRAM_WEBHOOK_VERIFY_TOKEN api/.env

   # Meta Webhook 설정의 Verify Token과 일치해야 함
   ```

### 6.5 성능 및 제한사항

#### Q12. Instagram API 호출 제한

**Instagram API 제한:**
- **Rate Limit**: 시간당 200 API 호출
- **DM 발송 제한**: 하루 최대 1,000건 (플랫폼 정책)

**해결 방법:**
- 트리거를 적절히 분산 배치
- 중요도가 낮은 트리거는 비활성화
- 프리미엄 플랜 고려 (향후 지원)

#### Q13. 데이터베이스 성능 저하

**원인:**
- 대량의 발송 이력 누적

**해결 방법:**

```sql
-- 오래된 이력 정리 (30일 이전 데이터)
DELETE FROM tb_trigger_execute_history
WHERE created_at < DATE_SUB(NOW(), INTERVAL 30 DAY)
AND status = 'SENT';
```

---

## 7. API 레퍼런스

### 7.1 기본 정보

**Base URL:** `http://localhost:3000/api` (개발)
**프로덕션 URL:** `https://api.yourdomain.com/api`

**인증 방식:** Bearer Token (JWT)

**공통 응답 형식:**

```json
{
  "result": true,
  "data": {},
  "errors": [],
  "meta": {
    "filter": [],
    "sort": [],
    "paging": {},
    "executed_time": "2026-01-24T10:30:00.000+09:00"
  }
}
```

### 7.2 인증 API

#### 7.2.1 이메일 로그인

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123"
}
```

**응답:**
```json
{
  "result": true,
  "data": {
    "user": {
      "user_seq": 1,
      "email": "user@example.com",
      "name": "홍길동",
      "user_type": "GENERAL"
    },
    "tokens": {
      "accessToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "refreshToken": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
      "expiresIn": 900
    }
  }
}
```

#### 7.2.2 회원가입

```http
POST /api/auth/register
Content-Type: application/json

{
  "email": "newuser@example.com",
  "password": "password123",
  "name": "김철수"
}
```

#### 7.2.3 Instagram OAuth 로그인

```http
GET /api/auth/instagram/login
```

**응답:** Instagram 로그인 URL 리다이렉트

#### 7.2.4 토큰 갱신

```http
POST /api/auth/refresh
Content-Type: application/json

{
  "refresh_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
}
```

### 7.3 트리거 API

#### 7.3.1 트리거 목록 조회

```http
GET /api/triggers?page=1&limit=20
Authorization: Bearer {access_token}
```

**응답:**
```json
{
  "result": true,
  "data": [
    {
      "trigger_seq": 1,
      "post_seq": 10,
      "trigger_word": "정보,신청",
      "dm_message": "안녕하세요! 문의 주셔서 감사합니다.",
      "trigger_follow": true,
      "status": "ACTIVATED",
      "post": {
        "media_url": "https://...",
        "caption": "게시물 캡션"
      }
    }
  ],
  "meta": {
    "paging": {
      "page": 1,
      "limit": 20,
      "total": 5
    }
  }
}
```

#### 7.3.2 트리거 생성

```http
POST /api/triggers
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "post_seq": 10,
  "trigger_word": "정보",
  "dm_message": "관심 가져주셔서 감사합니다!",
  "trigger_follow": true
}
```

#### 7.3.3 트리거 수정

```http
PATCH /api/triggers/{trigger_seq}
Authorization: Bearer {access_token}
Content-Type: application/json

{
  "trigger_word": "정보,신청",
  "dm_message": "수정된 메시지",
  "status": "ACTIVATED"
}
```

#### 7.3.4 트리거 삭제

```http
DELETE /api/triggers/{trigger_seq}
Authorization: Bearer {access_token}
```

### 7.4 통계 API

#### 7.4.1 대시보드 통계

```http
GET /api/stats/dashboard
Authorization: Bearer {access_token}
```

**응답:**
```json
{
  "result": true,
  "data": {
    "overview": {
      "todaySent": 42,
      "activeTriggers": 5,
      "deliveryRate": 95,
      "totalSent": 1523
    },
    "hourlyData": [
      {
        "hour": "00:00",
        "sent": 5,
        "success": 5,
        "failure": 0
      }
    ],
    "topTriggers": [
      {
        "triggerId": 1,
        "postUrl": "https://instagram.com/p/...",
        "keywords": ["정보"],
        "sentCount": 150,
        "successRate": 98
      }
    ]
  }
}
```

### 7.5 발송 이력 API

#### 7.5.1 발송 이력 조회

```http
GET /api/history?page=1&limit=20&status=SENT
Authorization: Bearer {access_token}
```

**쿼리 파라미터:**
- `page`: 페이지 번호 (기본: 1)
- `limit`: 페이지당 개수 (기본: 20, 최대: 100)
- `status`: 상태 필터 (PENDING, SENT, FAIL, DUPLICATED)
- `trigger_seq`: 트리거 ID 필터
- `start_date`: 시작 날짜 (ISO-8601)
- `end_date`: 종료 날짜 (ISO-8601)

**응답:**
```json
{
  "result": true,
  "data": [
    {
      "seq": 1,
      "trigger_seq": 1,
      "instagram_user_name": "user123",
      "comment_text": "정보 주세요",
      "status": "SENT",
      "created_at": "2026-01-24T10:30:00Z"
    }
  ],
  "meta": {
    "paging": {
      "page": 1,
      "limit": 20,
      "total": 150
    }
  }
}
```

### 7.6 에러 코드

| HTTP 상태 | 에러 코드 | 설명 |
|-----------|-----------|------|
| 400 | VALIDATION_ERROR | 입력 데이터 검증 실패 |
| 401 | UNAUTHORIZED | 인증 토큰 없음 또는 만료 |
| 403 | FORBIDDEN | 권한 없음 |
| 404 | NOT_FOUND | 리소스를 찾을 수 없음 |
| 409 | CONFLICT | 중복된 데이터 (예: 이미 존재하는 이메일) |
| 429 | RATE_LIMIT_EXCEEDED | API 호출 제한 초과 |
| 500 | INTERNAL_SERVER_ERROR | 서버 내부 오류 |

**에러 응답 예시:**
```json
{
  "result": false,
  "data": [],
  "errors": [
    {
      "internal_error_code": "VALIDATION_ERROR",
      "error_message": "Invalid email format"
    }
  ]
}
```

---

## 부록

### A. 용어 사전

- **트리거 (Trigger)**: 특정 키워드가 포함된 댓글을 감지하여 자동 DM을 발송하는 규칙
- **DM (Direct Message)**: Instagram 다이렉트 메시지
- **Webhook**: Instagram에서 댓글 이벤트를 실시간으로 전달하는 HTTP 콜백
- **JWT (JSON Web Token)**: 사용자 인증을 위한 토큰 기반 인증 방식
- **OAuth**: 제3자 인증 프로토콜 (Google, Instagram 로그인)
- **비즈니스 계정**: Instagram의 기업용 계정 (API 접근 가능)

### B. 지원 연락처

- **이메일**: support@yourdomain.com
- **문서**: https://docs.yourdomain.com
- **GitHub Issues**: https://github.com/yourorg/sns_automation/issues

### C. 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다.

---

**문서 버전**: 1.0.0
**최종 수정일**: 2026-01-24
**작성자**: Autogram 개발팀
