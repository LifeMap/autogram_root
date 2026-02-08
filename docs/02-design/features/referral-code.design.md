# Design: 추천인 코드 시스템 (referral-code)

> **Phase**: Design
> **Created**: 2026-02-08
> **Plan Reference**: `docs/01-plan/features/referral-code.plan.md`
> **PRD Reference**: `docs/prd-referral-system.md`
> **Status**: Phase 1~2 구현 완료, Phase 3 확정

---

## 1. 설계 범위

이 문서는 Plan 문서의 **확정된 항목 (Phase 1~2)** 만 상세 설계한다.

| Phase | 범위 | 상태 |
|-------|------|------|
| Phase 1 | DB 스키마 + 유저코드 생성 | **구현 완료** |
| Phase 2 | 추천인 코드 입력 API + 프론트엔드 | **구현 완료** |
| Phase 3 | 쿠폰 발급/적용 (DM 발송량 보너스) | **확정 - 이 문서에서 설계** |

---

## 2. DB 스키마 변경

### 2.1 `tb_users` ALTER - 컬럼 추가

```sql
ALTER TABLE tb_users
  ADD COLUMN user_code VARCHAR(8) NULL COMMENT '추천용 유저코드 [A-Z0-9]{8}' AFTER is_beta_tester,
  ADD COLUMN referrer_user_seq INT UNSIGNED NULL COMMENT '추천인 user seq (self-reference)' AFTER user_code,
  ADD UNIQUE INDEX UNQ_USERS_USER_CODE (user_code),
  ADD INDEX IDX_USERS_REFERRER (referrer_user_seq),
  ADD CONSTRAINT FK_USERS_REFERRER FOREIGN KEY (referrer_user_seq) REFERENCES tb_users(seq) ON DELETE SET NULL;
```

**설계 근거**:
- `user_code`: NULL 허용 - 기존 회원은 마이그레이션 전까지 NULL, 마이그레이션 후 UNIQUE 보장
- `referrer_user_seq`: NULL 허용 - 추천인 없는 회원 허용. `ON DELETE SET NULL` - 추천인 탈퇴 시 관계만 해제
- FK를 self-reference로 설정하여 참조 무결성 보장
- `user_code`에 UNIQUE 인덱스로 중복 방지의 최종 보장

### 2.2 Sequelize 모델 업데이트 (`api/src/models/User.js`)

```javascript
// 추가할 컬럼 정의
user_code: {
  type: DataTypes.STRING(8),
  allowNull: true,
  comment: '추천용 유저코드 [A-Z0-9]{8}',
},
referrer_user_seq: {
  type: DataTypes.INTEGER.UNSIGNED,
  allowNull: true,
  references: {
    model: 'tb_users',
    key: 'seq',
  },
  comment: '추천인 user seq',
},
```

인덱스 추가:
```javascript
indexes: [
  // ... 기존 인덱스 유지
  {
    unique: true,
    fields: ['user_code'],
    name: 'UNQ_USERS_USER_CODE',
  },
  {
    fields: ['referrer_user_seq'],
    name: 'IDX_USERS_REFERRER',
  },
],
```

### 2.3 모델 관계 추가 (`api/src/models/index.js`)

```javascript
// User self-referential relationship (추천인)
User.belongsTo(User, { as: 'referrer', foreignKey: 'referrer_user_seq' });
User.hasMany(User, { as: 'referrals', foreignKey: 'referrer_user_seq' });
```

### 2.4 마이그레이션 파일

파일명: `api/migrations/20260208000000-add-referral-columns.js`

```javascript
export default {
  async up(queryInterface, Sequelize) {
    // 1. 컬럼 추가
    await queryInterface.addColumn('tb_users', 'user_code', {
      type: Sequelize.STRING(8),
      allowNull: true,
      after: 'is_beta_tester',
    });
    await queryInterface.addColumn('tb_users', 'referrer_user_seq', {
      type: Sequelize.INTEGER.UNSIGNED,
      allowNull: true,
      after: 'user_code',
      references: { model: 'tb_users', key: 'seq' },
      onDelete: 'SET NULL',
    });

    // 2. 기존 회원 유저코드 일괄 생성
    const [users] = await queryInterface.sequelize.query(
      'SELECT seq FROM tb_users WHERE user_code IS NULL'
    );
    for (const user of users) {
      let code;
      let attempts = 0;
      while (attempts < 10) {
        code = generateUserCode();
        const [existing] = await queryInterface.sequelize.query(
          'SELECT seq FROM tb_users WHERE user_code = ?',
          { replacements: [code] }
        );
        if (existing.length === 0) break;
        attempts++;
      }
      await queryInterface.sequelize.query(
        'UPDATE tb_users SET user_code = ? WHERE seq = ?',
        { replacements: [code, user.seq] }
      );
    }

    // 3. UNIQUE 인덱스 추가 (마이그레이션 완료 후)
    await queryInterface.addIndex('tb_users', ['user_code'], {
      unique: true,
      name: 'UNQ_USERS_USER_CODE',
    });
    await queryInterface.addIndex('tb_users', ['referrer_user_seq'], {
      name: 'IDX_USERS_REFERRER',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeIndex('tb_users', 'IDX_USERS_REFERRER');
    await queryInterface.removeIndex('tb_users', 'UNQ_USERS_USER_CODE');
    await queryInterface.removeColumn('tb_users', 'referrer_user_seq');
    await queryInterface.removeColumn('tb_users', 'user_code');
  },
};

function generateUserCode() {
  const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  let code = '';
  for (let i = 0; i < 8; i++) {
    code += chars.charAt(Math.floor(Math.random() * chars.length));
  }
  return code;
}
```

---

## 3. 유저코드 생성 유틸리티

### 3.1 파일: `api/src/utils/userCode.js`

```javascript
import crypto from 'crypto';

const CHARSET = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
const CODE_LENGTH = 8;
const MAX_RETRIES = 10;

/**
 * 랜덤 유저코드 생성
 * @returns {string} [A-Z0-9]{8}
 */
export function generateUserCode() {
  const bytes = crypto.randomBytes(CODE_LENGTH);
  let code = '';
  for (let i = 0; i < CODE_LENGTH; i++) {
    code += CHARSET[bytes[i] % CHARSET.length];
  }
  return code;
}

/**
 * 유저코드 형식 검증
 * @param {string} code
 * @returns {boolean}
 */
export function isValidUserCode(code) {
  return /^[A-Z0-9]{8}$/.test(code);
}

export { MAX_RETRIES };
```

**설계 근거**:
- `crypto.randomBytes` 사용 - `Math.random()`보다 안전한 난수 생성
- 36^8 = 약 28억 조합 - 현재 규모(수천 유저)에서 충돌 확률 극히 낮음
- 최대 10회 재시도 + DB UNIQUE 인덱스로 이중 보장

### 3.2 회원가입 서비스 통합

유저코드 생성 로직을 회원가입 플로우에 통합해야 하는 3개 지점:

| 가입 경로 | 파일 | 함수 | 통합 지점 |
|-----------|------|------|----------|
| 이메일 | `authService.js` | `registerWithEmail()` | `User.create()` 호출 시 `user_code` 포함 |
| Google OAuth | `authService.js` | `loginWithGoogle()` | `User.create()` 호출 시 `user_code` 포함 |
| Instagram OAuth | `authService.js` | `loginWithInstagram()` | `User.create()` 호출 시 `user_code` 포함 |

**통합 패턴** (모든 가입 경로 동일):

```javascript
import { generateUserCode, MAX_RETRIES } from '../utils/userCode.js';
import { User } from '../models/index.js';

async function createUserWithCode(userData) {
  let userCode;
  let retries = 0;

  while (retries < MAX_RETRIES) {
    userCode = generateUserCode();
    const existing = await User.findOne({ where: { user_code: userCode } });
    if (!existing) break;
    retries++;
    if (retries >= MAX_RETRIES) {
      throw new Error('Failed to generate unique user code');
    }
  }

  return await User.create({
    ...userData,
    user_code: userCode,
  });
}
```

**주의**: 각 가입 함수(`registerWithEmail`, `loginWithGoogle`, `loginWithInstagram`)에서 `User.create()` 호출 부분을 이 패턴으로 교체한다. 트랜잭션 컨텍스트가 있는 경우 트랜잭션 내에서 실행해야 한다.

---

## 4. API 설계

### 4.1 추천인 코드 입력 API

```
POST /api/referrals/set-referrer
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "referrerCode": "ABC12345"
}

Response (200):
{
  "success": true,
  "data": {
    "referrerCode": "ABC12345",
    "referrerName": "김**"  // 마스킹된 이름
  },
  "message": "추천인이 등록되었습니다."
}

Error Responses:
- 400: INVALID_REFERRAL_CODE - 유효하지 않은 코드 형식
- 404: REFERRER_NOT_FOUND - 해당 코드의 사용자가 없음
- 409: REFERRER_ALREADY_SET - 이미 추천인이 등록됨
- 409: SELF_REFERRAL_NOT_ALLOWED - 본인 코드 입력 불가
```

### 4.2 내 유저코드 조회 API

기존 `GET /api/auth/me` 응답에 `userCode` 필드 추가.

```
GET /api/auth/me
Authorization: Bearer {accessToken}

Response (200) - 추가 필드:
{
  "success": true,
  "data": {
    // ... 기존 필드들
    "userCode": "XYZ98765",
    "referrerCode": "ABC12345",  // null if no referrer
    "hasReferrer": true
  }
}
```

**설계 근거**: 별도 API 대신 기존 `/auth/me`에 추가 - 프론트엔드에서 이미 이 API로 사용자 정보를 조회하므로 추가 네트워크 요청 불필요.

### 4.3 라우트 구조

새 파일: `api/src/routes/referralRoutes.js`

```javascript
import express from 'express';
import { authenticate } from '../middleware/auth.js';
import * as referralController from '../controllers/referralController.js';

const router = express.Router();

// 추천인 코드 입력
router.post('/set-referrer', authenticate, referralController.setReferrer);

export default router;
```

`api/src/routes/index.js` 에 추가:
```javascript
import referralRoutes from './referralRoutes.js';
// ...
router.use('/referrals', referralRoutes);
```

---

## 5. 서비스 레이어 설계

### 5.1 새 파일: `api/src/services/referralService.js`

```javascript
/**
 * 추천인 코드 관련 비즈니스 로직
 */

/**
 * 추천인 등록
 * @param {number} userSeq - 현재 사용자 seq
 * @param {string} referrerCode - 추천인 유저코드
 * @returns {Promise<object>} - 등록 결과
 *
 * 검증 순서:
 * 1. 코드 형식 검증 (isValidUserCode)
 * 2. 본인 코드 입력 차단 (user.user_code !== referrerCode)
 * 3. 이미 추천인 등록 여부 (user.referrer_user_seq === null)
 * 4. 추천인 존재 여부 (User.findOne({ user_code: referrerCode }))
 * 5. 추천인이 ACTIVATED 상태인지 확인
 * 6. referrer_user_seq 업데이트
 */
export async function setReferrer(userSeq, referrerCode) { ... }
```

### 5.2 컨트롤러: `api/src/controllers/referralController.js`

```javascript
/**
 * POST /api/referrals/set-referrer
 * - req.body.referrerCode 추출
 * - referralService.setReferrer(req.user.seq, referrerCode) 호출
 * - 표준 응답 형식 반환: { success, data, message }
 */
export async function setReferrer(req, res, next) { ... }
```

---

## 6. 기존 코드 수정 범위

### 6.1 `authService.js` 수정 (3개소)

| 함수 | 수정 내용 |
|------|----------|
| `registerWithEmail()` (L637) | `User.create()`에 `user_code` 추가 |
| `loginWithGoogle()` (L463) | `User.create()`에 `user_code` 추가 |
| `loginWithInstagram()` (L147) | `User.create()`에 `user_code` 추가 |

공통 로직은 헬퍼 함수 `generateUniqueUserCode()`로 추출:

```javascript
// authService.js 상단에 추가
import { generateUserCode, MAX_RETRIES } from '../utils/userCode.js';

async function generateUniqueUserCode() {
  for (let i = 0; i < MAX_RETRIES; i++) {
    const code = generateUserCode();
    const existing = await User.findOne({ where: { user_code: code } });
    if (!existing) return code;
  }
  throw new Error('Failed to generate unique user code after max retries');
}
```

### 6.2 `authService.js` - `getCurrentUser()` 수정

```javascript
// 기존 attributes 배열에 추가
attributes: ['seq', 'email', 'name', 'auth_type', /* 기존 */ 'user_code', 'referrer_user_seq'],

// 반환 객체에 추가
return {
  // ... 기존 필드
  userCode: user.user_code,
  hasReferrer: !!user.referrer_user_seq,
};
```

### 6.3 `models/index.js` 수정

User self-reference 관계 추가:
```javascript
User.belongsTo(User, { as: 'referrer', foreignKey: 'referrer_user_seq' });
User.hasMany(User, { as: 'referrals', foreignKey: 'referrer_user_seq' });
```

### 6.4 `routes/index.js` 수정

```javascript
import referralRoutes from './referralRoutes.js';
router.use('/referrals', referralRoutes);
```

---

## 7. 프론트엔드 설계

### 7.1 내 유저코드 표시 + 복사 (설정 페이지)

**위치**: `web/app/dashboard/settings/page.tsx`

```
┌─────────────────────────────────────┐
│ 내 추천 코드                         │
│ ┌─────────────┐ ┌──────┐           │
│ │  XYZ98765   │ │ 복사  │           │
│ └─────────────┘ └──────┘           │
│ 친구에게 이 코드를 공유하세요         │
└─────────────────────────────────────┘
```

- 기존 `/auth/me` API 응답의 `userCode` 필드 사용
- 복사 버튼: `navigator.clipboard.writeText()`
- 복사 성공 시 toast 알림: "추천 코드가 복사되었습니다"

### 7.2 추천인 코드 입력 (설정 페이지)

**위치**: `web/app/dashboard/settings/page.tsx` (유저코드 아래)

```
┌─────────────────────────────────────┐
│ 추천인 코드 입력                      │
│ ┌───────────────────────┐ ┌──────┐ │
│ │  추천인 코드 입력       │ │ 등록  │ │
│ └───────────────────────┘ └──────┘ │
│ * 한 번 등록하면 변경할 수 없습니다   │
└─────────────────────────────────────┘

(등록 완료 후)
┌─────────────────────────────────────┐
│ 추천인                               │
│ 김** 님의 추천으로 가입              │
└─────────────────────────────────────┘
```

- `hasReferrer === true` → 입력 폼 숨기고 추천인 정보 표시
- `hasReferrer === false` → 입력 폼 노출
- 입력 폼: 8자 영대문자+숫자만 허용 (`toUpperCase()` 자동 변환)
- 등록 전 확인 다이얼로그: "추천인 코드는 한 번 등록하면 변경할 수 없습니다. 등록하시겠습니까?"

### 7.3 OAuth 가입 모달에 추천인 코드 입력 (선택)

**시점**: Google/Instagram 최초 가입 직후 (isNewUser === true)
**위치**: 기존 OAuth 콜백 처리 흐름

```
┌───────────────────────────────┐
│       가입을 환영합니다! 🎉     │
│                               │
│  추천인 코드가 있으신가요?      │
│  ┌─────────────────────────┐  │
│  │ 추천인 코드 (선택)       │  │
│  └─────────────────────────┘  │
│                               │
│  [건너뛰기]     [등록하기]     │
└───────────────────────────────┘
```

- 선택 사항 (건너뛰기 가능)
- 설정 페이지에서도 나중에 입력 가능하므로 강제하지 않음
- 등록 성공 시 설정 페이지로 이동

### 7.4 다국어 메시지 (`web/messages/`)

```json
// ko.json
{
  "referral": {
    "myCode": "내 추천 코드",
    "copyCode": "복사",
    "codeCopied": "추천 코드가 복사되었습니다",
    "shareMessage": "친구에게 이 코드를 공유하세요",
    "inputTitle": "추천인 코드 입력",
    "inputPlaceholder": "추천인 코드 입력",
    "register": "등록",
    "confirmMessage": "추천인 코드는 한 번 등록하면 변경할 수 없습니다. 등록하시겠습니까?",
    "registeredTitle": "추천인",
    "registeredMessage": "{name} 님의 추천으로 가입",
    "immutableNotice": "한 번 등록하면 변경할 수 없습니다",
    "welcomeTitle": "가입을 환영합니다!",
    "welcomeQuestion": "추천인 코드가 있으신가요?",
    "skip": "건너뛰기",
    "errors": {
      "invalidFormat": "추천 코드는 영문 대문자와 숫자 8자리입니다",
      "notFound": "존재하지 않는 추천 코드입니다",
      "alreadySet": "이미 추천인이 등록되어 있습니다",
      "selfReferral": "본인의 추천 코드는 사용할 수 없습니다"
    }
  }
}
```

```json
// en.json
{
  "referral": {
    "myCode": "My Referral Code",
    "copyCode": "Copy",
    "codeCopied": "Referral code copied",
    "shareMessage": "Share this code with your friends",
    "inputTitle": "Enter Referral Code",
    "inputPlaceholder": "Enter referral code",
    "register": "Register",
    "confirmMessage": "The referral code cannot be changed once registered. Do you want to register?",
    "registeredTitle": "Referred by",
    "registeredMessage": "Joined with {name}'s referral",
    "immutableNotice": "Cannot be changed once registered",
    "welcomeTitle": "Welcome!",
    "welcomeQuestion": "Do you have a referral code?",
    "skip": "Skip",
    "errors": {
      "invalidFormat": "Referral code must be 8 uppercase letters and numbers",
      "notFound": "Referral code not found",
      "alreadySet": "Referral code is already registered",
      "selfReferral": "Cannot use your own referral code"
    }
  }
}
```

---

## 8. 에러 코드 정의

`api/src/utils/errors.js` 에 추가할 에러 코드:

| 코드 | HTTP | 설명 |
|------|------|------|
| `INVALID_REFERRAL_CODE` | 400 | 유저코드 형식 불일치 |
| `REFERRER_NOT_FOUND` | 404 | 해당 코드의 활성 사용자 없음 |
| `REFERRER_ALREADY_SET` | 409 | 이미 추천인 등록됨 (변경 불가) |
| `SELF_REFERRAL_NOT_ALLOWED` | 409 | 본인 코드 입력 시도 |

---

## 9. 보안 고려사항

| 항목 | 대응 |
|------|------|
| 유저코드 무차별 대입 | Rate limiting (기존 Express rate limiter 적용) |
| 추천인 정보 노출 | 이름 마스킹 (김** 형태) |
| 중복 등록 | DB 레벨 - `referrer_user_seq`가 이미 NOT NULL이면 서비스 레벨에서 거부 |
| 코드 예측 | crypto.randomBytes 기반 생성, 36^8 조합 |
| SQL Injection | Sequelize ORM parameterized query 사용 |

---

## 10. 구현 체크리스트

### Phase 1: DB + 유저코드 (2일)

- [ ] `api/src/utils/userCode.js` 생성 (generateUserCode, isValidUserCode)
- [ ] `api/src/models/User.js` - user_code, referrer_user_seq 컬럼 추가
- [ ] `api/src/models/index.js` - User self-reference 관계 추가
- [ ] `api/migrations/20260208000000-add-referral-columns.js` 생성
- [ ] `api/src/services/authService.js` - registerWithEmail()에 user_code 생성 추가
- [ ] `api/src/services/authService.js` - loginWithGoogle()에 user_code 생성 추가
- [ ] `api/src/services/authService.js` - loginWithInstagram()에 user_code 생성 추가
- [ ] `api/src/services/authService.js` - getCurrentUser()에 userCode, hasReferrer 추가
- [ ] 마이그레이션 실행 테스트

### Phase 2: 추천인 코드 입력 + 프론트엔드 (1일)

- [ ] `api/src/services/referralService.js` 생성 (setReferrer)
- [ ] `api/src/controllers/referralController.js` 생성
- [ ] `api/src/routes/referralRoutes.js` 생성
- [ ] `api/src/routes/index.js` - referralRoutes 등록
- [ ] `api/src/utils/errors.js` - 추천 관련 에러 코드 추가
- [ ] `web/messages/ko.json` - referral 메시지 추가
- [ ] `web/messages/en.json` - referral 메시지 추가
- [ ] `web/app/dashboard/settings/page.tsx` - 유저코드 표시 + 복사 UI
- [ ] `web/app/dashboard/settings/page.tsx` - 추천인 코드 입력 UI
- [ ] OAuth 가입 완료 모달 - 추천인 코드 입력 (선택)

### Phase 3: 쿠폰 (TBD)

> 보상 디테일 확정 후 별도 Design 문서로 작성

---

## 11. 영향 받는 파일 목록

### 새로 생성하는 파일
| 파일 | 설명 |
|------|------|
| `api/src/utils/userCode.js` | 유저코드 생성/검증 유틸리티 |
| `api/src/services/referralService.js` | 추천 비즈니스 로직 |
| `api/src/controllers/referralController.js` | 추천 HTTP 컨트롤러 |
| `api/src/routes/referralRoutes.js` | 추천 라우트 |
| `api/migrations/20260208000000-add-referral-columns.js` | DB 마이그레이션 |

### 수정하는 파일
| 파일 | 수정 내용 |
|------|----------|
| `api/src/models/User.js` | user_code, referrer_user_seq 컬럼 추가 |
| `api/src/models/index.js` | User self-reference 관계 추가 |
| `api/src/services/authService.js` | 3개 가입함수 + getCurrentUser 수정 |
| `api/src/routes/index.js` | referralRoutes 등록 |
| `api/src/utils/errors.js` | 추천 관련 에러 코드 추가 |
| `web/messages/ko.json` | 추천 관련 다국어 메시지 |
| `web/messages/en.json` | 추천 관련 다국어 메시지 |
| `web/app/dashboard/settings/page.tsx` | 유저코드 + 추천인 입력 UI |

---

## 12. Phase 3: 쿠폰 발급/적용 시스템

### 12.1 환경변수 설정

```env
# 추천 쿠폰 설정
REFERRAL_COUPON_DM_AMOUNT=100       # 쿠폰당 추가 DM 발송량
REFERRAL_COUPON_EXPIRY_DAYS=30      # 쿠폰 유효기간 (일)
```

---

### 12.2 DB 스키마: `tb_referral_coupons`

```sql
CREATE TABLE tb_referral_coupons (
  seq INT UNSIGNED AUTO_INCREMENT PRIMARY KEY COMMENT '쿠폰 ID',
  user_seq INT UNSIGNED NOT NULL COMMENT '쿠폰 소유자 (피추천인)',
  referrer_user_seq INT UNSIGNED NOT NULL COMMENT '추천인 user seq',
  dm_amount INT UNSIGNED NOT NULL DEFAULT 100 COMMENT '추가 DM 발송량',
  status ENUM('AVAILABLE', 'USED', 'EXPIRED') NOT NULL DEFAULT 'AVAILABLE' COMMENT '쿠폰 상태',
  issued_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) COMMENT '발급일',
  expires_at DATETIME(6) NOT NULL COMMENT '만료일',
  used_at DATETIME(6) NULL COMMENT '사용일',
  applied_month CHAR(7) NULL COMMENT '적용된 월 (YYYY-MM)',
  created_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  updated_at DATETIME(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6) ON UPDATE CURRENT_TIMESTAMP(6),

  INDEX IDX_COUPON_USER (user_seq),
  INDEX IDX_COUPON_STATUS (user_seq, status),
  INDEX IDX_COUPON_EXPIRES (status, expires_at),
  UNIQUE INDEX UNQ_COUPON_PAIR (user_seq, referrer_user_seq),

  CONSTRAINT FK_COUPON_USER FOREIGN KEY (user_seq) REFERENCES tb_users(seq) ON DELETE CASCADE,
  CONSTRAINT FK_COUPON_REFERRER FOREIGN KEY (referrer_user_seq) REFERENCES tb_users(seq) ON DELETE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='추천 보너스 쿠폰';
```

**설계 근거**:
- `UNQ_COUPON_PAIR`: 동일 추천인-피추천인 쌍으로 중복 발급 방지 (웹훅 재시도 안전)
- `user_seq + referrer_user_seq`: 피추천인이 여러 명을 추천받아도 각각 1회씩만 발급
- `status` ENUM: 상태 전이 — `AVAILABLE` → `USED` (사용자 적용) 또는 `EXPIRED` (스케줄러)
- `applied_month`: 어느 월에 적용했는지 추적 (NULL이면 미사용)
- `ON DELETE CASCADE`: 유저 탈퇴 시 쿠폰도 삭제

### 12.3 기존 테이블 수정: `tb_monthly_usage`

```sql
ALTER TABLE tb_monthly_usage
  ADD COLUMN bonus_dm_count INT UNSIGNED NOT NULL DEFAULT 0
    COMMENT '쿠폰 보너스 DM 발송량' AFTER dm_sent_count;
```

**설계 근거**:
- 기존 `dm_sent_count`(실제 발송량)와 분리하여 쿠폰 보너스를 별도 관리
- 쿼터 체크 시 `plan_quota + bonus_dm_count`로 합산
- 월별 리셋 시 `bonus_dm_count`도 0으로 리셋 (쿠폰은 적용한 월에만 유효)

---

### 12.4 Sequelize 모델: `api/src/models/ReferralCoupon.js`

```javascript
import { DataTypes } from 'sequelize';
import sequelize from '../config/database.js';

const ReferralCoupon = sequelize.define(
  'tb_referral_coupons',
  {
    seq: {
      type: DataTypes.INTEGER.UNSIGNED,
      primaryKey: true,
      autoIncrement: true,
    },
    user_seq: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      references: { model: 'tb_users', key: 'seq' },
    },
    referrer_user_seq: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      references: { model: 'tb_users', key: 'seq' },
    },
    dm_amount: {
      type: DataTypes.INTEGER.UNSIGNED,
      allowNull: false,
      defaultValue: 100,
      comment: '추가 DM 발송량',
    },
    status: {
      type: DataTypes.ENUM('AVAILABLE', 'USED', 'EXPIRED'),
      allowNull: false,
      defaultValue: 'AVAILABLE',
    },
    issued_at: {
      type: DataTypes.DATE(6),
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    expires_at: {
      type: DataTypes.DATE(6),
      allowNull: false,
    },
    used_at: {
      type: DataTypes.DATE(6),
      allowNull: true,
    },
    applied_month: {
      type: DataTypes.CHAR(7),
      allowNull: true,
      comment: '적용된 월 (YYYY-MM)',
    },
    created_at: {
      type: DataTypes.DATE(6),
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
    updated_at: {
      type: DataTypes.DATE(6),
      allowNull: false,
      defaultValue: DataTypes.NOW,
    },
  },
  {
    tableName: 'tb_referral_coupons',
    timestamps: true,
    createdAt: 'created_at',
    updatedAt: 'updated_at',
    indexes: [
      { fields: ['user_seq'], name: 'IDX_COUPON_USER' },
      { fields: ['user_seq', 'status'], name: 'IDX_COUPON_STATUS' },
      { fields: ['status', 'expires_at'], name: 'IDX_COUPON_EXPIRES' },
      { unique: true, fields: ['user_seq', 'referrer_user_seq'], name: 'UNQ_COUPON_PAIR' },
    ],
  }
);

export default ReferralCoupon;
```

### 12.5 모델 관계 추가: `api/src/models/index.js`

```javascript
// 추천 쿠폰 관계
User.hasMany(ReferralCoupon, { as: 'receivedCoupons', foreignKey: 'user_seq' });
User.hasMany(ReferralCoupon, { as: 'givenCoupons', foreignKey: 'referrer_user_seq' });
ReferralCoupon.belongsTo(User, { as: 'owner', foreignKey: 'user_seq' });
ReferralCoupon.belongsTo(User, { as: 'referrer', foreignKey: 'referrer_user_seq' });
```

### 12.6 마이그레이션: `api/migrations/20260208100000-add-referral-coupons.js`

```javascript
export default {
  async up(queryInterface, Sequelize) {
    // 1. tb_referral_coupons 테이블 생성
    await queryInterface.createTable('tb_referral_coupons', {
      seq: { type: Sequelize.INTEGER.UNSIGNED, primaryKey: true, autoIncrement: true },
      user_seq: {
        type: Sequelize.INTEGER.UNSIGNED, allowNull: false,
        references: { model: 'tb_users', key: 'seq' }, onDelete: 'CASCADE',
      },
      referrer_user_seq: {
        type: Sequelize.INTEGER.UNSIGNED, allowNull: false,
        references: { model: 'tb_users', key: 'seq' }, onDelete: 'CASCADE',
      },
      dm_amount: { type: Sequelize.INTEGER.UNSIGNED, allowNull: false, defaultValue: 100 },
      status: {
        type: Sequelize.ENUM('AVAILABLE', 'USED', 'EXPIRED'),
        allowNull: false, defaultValue: 'AVAILABLE',
      },
      issued_at: { type: Sequelize.DATE(6), allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP(6)') },
      expires_at: { type: Sequelize.DATE(6), allowNull: false },
      used_at: { type: Sequelize.DATE(6), allowNull: true },
      applied_month: { type: Sequelize.CHAR(7), allowNull: true },
      created_at: { type: Sequelize.DATE(6), allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP(6)') },
      updated_at: { type: Sequelize.DATE(6), allowNull: false, defaultValue: Sequelize.literal('CURRENT_TIMESTAMP(6)') },
    });

    // 2. 인덱스 추가
    await queryInterface.addIndex('tb_referral_coupons', ['user_seq'], { name: 'IDX_COUPON_USER' });
    await queryInterface.addIndex('tb_referral_coupons', ['user_seq', 'status'], { name: 'IDX_COUPON_STATUS' });
    await queryInterface.addIndex('tb_referral_coupons', ['status', 'expires_at'], { name: 'IDX_COUPON_EXPIRES' });
    await queryInterface.addIndex('tb_referral_coupons', ['user_seq', 'referrer_user_seq'], {
      unique: true, name: 'UNQ_COUPON_PAIR',
    });

    // 3. tb_monthly_usage에 bonus_dm_count 컬럼 추가
    await queryInterface.addColumn('tb_monthly_usage', 'bonus_dm_count', {
      type: Sequelize.INTEGER.UNSIGNED,
      allowNull: false,
      defaultValue: 0,
      after: 'dm_sent_count',
      comment: '쿠폰 보너스 DM 발송량',
    });
  },

  async down(queryInterface) {
    await queryInterface.removeColumn('tb_monthly_usage', 'bonus_dm_count');
    await queryInterface.dropTable('tb_referral_coupons');
  },
};
```

---

### 12.7 서비스 레이어: `api/src/services/couponService.js`

```javascript
/**
 * 추천 쿠폰 서비스
 */

const DM_AMOUNT = parseInt(process.env.REFERRAL_COUPON_DM_AMOUNT || '100', 10);
const EXPIRY_DAYS = parseInt(process.env.REFERRAL_COUPON_EXPIRY_DAYS || '30', 10);

/**
 * 쿠폰 발급 (피추천인에게)
 * @param {number} refereeUserSeq - 피추천인 user seq
 * @returns {Promise<object|null>} 발급된 쿠폰 또는 null (추천인 없음/이미 발급)
 *
 * 로직:
 * 1. 피추천인의 referrer_user_seq 조회
 * 2. referrer가 없으면 null 반환 (추천인 미등록)
 * 3. 이미 동일 쌍으로 발급된 쿠폰 확인 (UNQ_COUPON_PAIR)
 * 4. 이미 있으면 null 반환 (중복 방지 - 웹훅 재시도 안전)
 * 5. 쿠폰 생성: dm_amount=env, expires_at=now+env일
 */
export async function issueCoupon(refereeUserSeq) { ... }

/**
 * 쿠폰 사용 (사용자가 "사용 시작" 클릭)
 * @param {number} userSeq - 사용자 seq
 * @param {number[]} couponSeqs - 적용할 쿠폰 seq 배열
 * @returns {Promise<object>} { appliedCount, totalBonusDm }
 *
 * 로직 (트랜잭션):
 * 1. couponSeqs에 해당하는 AVAILABLE 쿠폰 조회 (FOR UPDATE)
 * 2. user_seq 소유 확인 + 만료일 확인
 * 3. 현재 월의 MonthlyUsage.bonus_dm_count에 dm_amount 합산
 * 4. 쿠폰 상태 USED로 변경, used_at 기록, applied_month 기록
 */
export async function applyCoupons(userSeq, couponSeqs) { ... }

/**
 * 사용자 쿠폰 목록 조회
 * @param {number} userSeq
 * @returns {Promise<object[]>} 쿠폰 목록 (AVAILABLE만)
 */
export async function getUserCoupons(userSeq) { ... }

/**
 * 만료 쿠폰 일괄 처리 (스케줄러에서 호출)
 * @returns {Promise<number>} 만료 처리된 쿠폰 수
 *
 * WHERE status = 'AVAILABLE' AND expires_at < NOW()
 * UPDATE status = 'EXPIRED'
 */
export async function expireExpiredCoupons() { ... }
```

**설계 근거**:
- `issueCoupon`: 웹훅 재시도에 안전 (UNQ_COUPON_PAIR + 중복 체크)
- `applyCoupons`: 복수 쿠폰 동시 적용 지원, 트랜잭션으로 원자성 보장
- `expireExpiredCoupons`: 별도 스케줄러에서 일 1회 실행 (또는 조회 시 Lazy expire)

### 12.8 컨트롤러: `api/src/controllers/couponController.js`

```javascript
/**
 * GET /api/referrals/coupons
 * - couponService.getUserCoupons(req.user.seq) 호출
 * - 응답: { success, data: { coupons: [...] } }
 */
export async function getCoupons(req, res, next) { ... }

/**
 * POST /api/referrals/coupons/apply
 * - req.body.couponSeqs: number[] (적용할 쿠폰 seq 배열)
 * - couponService.applyCoupons(req.user.seq, couponSeqs) 호출
 * - 응답: { success, data: { appliedCount, totalBonusDm }, message }
 */
export async function applyCoupons(req, res, next) { ... }
```

### 12.9 라우트 수정: `api/src/routes/referralRoutes.js`

```javascript
// 기존
router.post('/set-referrer', authenticate, referralController.setReferrer);

// 추가
router.get('/coupons', authenticate, couponController.getCoupons);
router.post('/coupons/apply', authenticate, couponController.applyCoupons);
```

---

### 12.10 기존 서비스 수정

#### 12.10.1 `lemonSqueezyWebhookService.js` - 쿠폰 자동 발급

`handleSubscriptionPaymentSuccess()` 내 `isFirstPayment === true` 분기 직후에 추가:

```javascript
// 기존 코드 (L400-412)
const isFirstPayment = minutesSinceCreation < 5;

await SubscriptionHistory.create({ ... }, { transaction });

await transaction.commit();

// === 추가 코드 (commit 후, 비동기) ===
if (isFirstPayment) {
  setImmediate(async () => {
    try {
      const coupon = await couponService.issueCoupon(subscription.user_seq);
      if (coupon) {
        logger.info(`Referral coupon issued for user ${subscription.user_seq}: ${coupon.dm_amount} DMs`);
      }
    } catch (err) {
      logger.error(`Failed to issue referral coupon for user ${subscription.user_seq}:`, err);
    }
  });
}
```

**설계 근거**:
- `transaction.commit()` 후 비동기(`setImmediate`) 실행 — 쿠폰 발급 실패가 결제 처리를 롤백시키지 않음
- `issueCoupon` 내부에서 중복 체크하므로 웹훅 재시도에 안전

#### 12.10.2 `quotaService.js` - 쿼터에 보너스 합산

`checkQuota()` 함수 수정:

```javascript
// 기존: const quota = await getPlanQuota(subscription.plan_seq);
// 변경:
const planQuota = await getPlanQuota(subscription.plan_seq);
const usage = await getOrCreateMonthlyUsage(userSeq, subscription.plan_seq, usageMonth);
const quota = planQuota + (usage.bonus_dm_count || 0);  // 보너스 합산
```

`incrementDmCount()` 함수도 동일하게 수정:

```javascript
const planQuota = await getPlanQuota(subscription.plan_seq);
const quota = planQuota + (usage.bonus_dm_count || 0);
```

#### 12.10.3 `usageService.js` - 응답에 보너스 포함

`getCurrentUsage()` 반환값에 `bonusDmCount` 추가:

```javascript
return {
  // 기존 필드들
  dmQuota: plan.dmQuota,
  bonusDmCount: usage.bonus_dm_count || 0,  // 추가
  effectiveQuota: plan.dmQuota + (usage.bonus_dm_count || 0),  // 추가
  dmSentCount: dmSentCount,
  // ...
};
```

#### 12.10.4 `MonthlyUsage.js` - 모델 컬럼 추가

```javascript
bonus_dm_count: {
  type: DataTypes.INTEGER.UNSIGNED,
  allowNull: false,
  defaultValue: 0,
  comment: '쿠폰 보너스 DM 발송량',
},
```

---

### 12.11 스케줄러: 만료 쿠폰 처리

`api/src/jobs/couponExpiryScheduler.js`

```javascript
/**
 * 만료 쿠폰 처리 스케줄러
 * @cron 0 1 * * * (매일 01:00)
 *
 * AVAILABLE 상태이면서 expires_at이 지난 쿠폰을 EXPIRED로 변경
 */
import cron from 'node-cron';
import * as couponService from '../services/couponService.js';

export function startCouponExpiryScheduler() {
  cron.schedule('0 1 * * *', async () => {
    const count = await couponService.expireExpiredCoupons();
    logger.info(`Expired ${count} referral coupons`);
  });
}
```

---

### 12.12 API 설계 상세

#### GET /api/referrals/coupons

```
Authorization: Bearer {accessToken}

Response (200):
{
  "success": true,
  "data": {
    "coupons": [
      {
        "seq": 1,
        "dmAmount": 100,
        "status": "AVAILABLE",
        "issuedAt": "2026-02-08T12:00:00.000Z",
        "expiresAt": "2026-03-10T12:00:00.000Z",
        "daysLeft": 22
      }
    ]
  }
}
```

#### POST /api/referrals/coupons/apply

```
Authorization: Bearer {accessToken}
Content-Type: application/json

Request Body:
{
  "couponSeqs": [1, 2]
}

Response (200):
{
  "success": true,
  "data": {
    "appliedCount": 2,
    "totalBonusDm": 200,
    "appliedMonth": "2026-02"
  },
  "message": "쿠폰이 적용되었습니다. 이번 달 DM 한도가 200건 추가되었습니다."
}

Error Responses:
- 400: COUPON_INVALID_REQUEST - couponSeqs 배열 비어있음
- 404: COUPON_NOT_FOUND - 해당 쿠폰이 없거나 소유자 불일치
- 409: COUPON_ALREADY_USED - 이미 사용된 쿠폰
- 409: COUPON_EXPIRED - 만료된 쿠폰
```

---

### 12.13 에러 코드 추가

`api/src/constants/errorMessages.js` 에 추가:

| 코드 | HTTP | 설명 |
|------|------|------|
| `COUPON_INVALID_REQUEST` | 400 | 요청 형식 오류 |
| `COUPON_NOT_FOUND` | 404 | 쿠폰 미존재 또는 소유자 불일치 |
| `COUPON_ALREADY_USED` | 409 | 이미 사용된 쿠폰 |
| `COUPON_EXPIRED` | 409 | 만료된 쿠폰 |

---

### 12.14 프론트엔드 설계

#### 12.14.1 API 클라이언트: `web/lib/api/referrals.ts` 추가

```typescript
export interface Coupon {
  seq: number;
  dmAmount: number;
  status: 'AVAILABLE' | 'USED' | 'EXPIRED';
  issuedAt: string;
  expiresAt: string;
  daysLeft: number;
}

export interface CouponsResponse {
  coupons: Coupon[];
}

export interface ApplyCouponsRequest {
  couponSeqs: number[];
}

export interface ApplyCouponsResponse {
  appliedCount: number;
  totalBonusDm: number;
  appliedMonth: string;
}

// referralApi에 추가
getCoupons: async (): Promise<CouponsResponse> => { ... },
applyCoupons: async (data: ApplyCouponsRequest): Promise<ApplyCouponsResponse> => { ... },
```

#### 12.14.2 훅: `web/hooks/useReferral.ts` 추가

```typescript
export function useCoupons() {
  return useQuery({
    queryKey: ['referral', 'coupons'],
    queryFn: () => referralApi.getCoupons(),
  });
}

export function useApplyCoupons() {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (data: ApplyCouponsRequest) => referralApi.applyCoupons(data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['referral', 'coupons'] });
      queryClient.invalidateQueries({ queryKey: ['user', 'current'] });
    },
  });
}
```

#### 12.14.3 UI: 설정 페이지 추천 섹션 내 쿠폰 영역

기존 추천 코드 섹션 `<CardContent>` 내부, 추천인 등록 영역 아래에 추가:

```
┌─────────────────────────────────────────┐
│ 보너스 쿠폰 (2개 보유)                    │
│                                         │
│ ┌─────────────────────────────────────┐ │
│ │ 🎁 DM +100건                       │ │
│ │ 만료까지 22일 (2026-03-10)          │ │
│ │ [사용 시작]                         │ │
│ └─────────────────────────────────────┘ │
│ ┌─────────────────────────────────────┐ │
│ │ 🎁 DM +100건                       │ │
│ │ 만료까지 15일 (2026-03-03)          │ │
│ │ [사용 시작]                         │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ * 사용 시 이번 달 DM 한도에 즉시 추가됩니다│
└─────────────────────────────────────────┘
```

- 쿠폰이 없으면 이 섹션 전체 숨김
- "사용 시작" 클릭 시 확인 다이얼로그 표시
- 적용 성공 시 toast + 쿠폰 목록 갱신

#### 12.14.4 다국어 메시지 추가: `web/messages/`

```json
// ko.json - referral 섹션에 추가
{
  "referral": {
    // ... 기존 키 유지
    "coupon": {
      "title": "보너스 쿠폰",
      "count": "{count}개 보유",
      "dmAmount": "DM +{amount}건",
      "expiresIn": "만료까지 {days}일",
      "expiresAt": "만료: {date}",
      "apply": "사용 시작",
      "applyConfirmTitle": "쿠폰 사용",
      "applyConfirmMessage": "이 쿠폰을 사용하면 이번 달 DM 한도에 {amount}건이 추가됩니다. 사용하시겠습니까?",
      "applySuccess": "쿠폰이 적용되었습니다. DM 한도가 {amount}건 추가되었습니다.",
      "notice": "사용 시 이번 달 DM 한도에 즉시 추가됩니다",
      "empty": "보유 중인 쿠폰이 없습니다",
      "errors": {
        "notFound": "쿠폰을 찾을 수 없습니다",
        "alreadyUsed": "이미 사용된 쿠폰입니다",
        "expired": "만료된 쿠폰입니다"
      }
    }
  }
}
```

```json
// en.json
{
  "referral": {
    "coupon": {
      "title": "Bonus Coupons",
      "count": "{count} available",
      "dmAmount": "DM +{amount}",
      "expiresIn": "{days} days left",
      "expiresAt": "Expires: {date}",
      "apply": "Use Now",
      "applyConfirmTitle": "Use Coupon",
      "applyConfirmMessage": "Using this coupon will add {amount} DMs to this month's limit. Continue?",
      "applySuccess": "Coupon applied. {amount} DMs added to this month's limit.",
      "notice": "Applied immediately to this month's DM limit",
      "empty": "No coupons available",
      "errors": {
        "notFound": "Coupon not found",
        "alreadyUsed": "Coupon already used",
        "expired": "Coupon has expired"
      }
    }
  }
}
```

```json
// ja.json
{
  "referral": {
    "coupon": {
      "title": "ボーナスクーポン",
      "count": "{count}枚保有",
      "dmAmount": "DM +{amount}件",
      "expiresIn": "残り{days}日",
      "expiresAt": "期限: {date}",
      "apply": "使用開始",
      "applyConfirmTitle": "クーポン使用",
      "applyConfirmMessage": "このクーポンを使用すると、今月のDM上限に{amount}件が追加されます。使用しますか？",
      "applySuccess": "クーポンが適用されました。DM上限が{amount}件追加されました。",
      "notice": "使用すると今月のDM上限に即時追加されます",
      "empty": "保有中のクーポンはありません",
      "errors": {
        "notFound": "クーポンが見つかりません",
        "alreadyUsed": "すでに使用されたクーポンです",
        "expired": "期限切れのクーポンです"
      }
    }
  }
}
```

---

### 12.15 구현 체크리스트 (Phase 3)

- [ ] `api/src/models/ReferralCoupon.js` 생성
- [ ] `api/src/models/MonthlyUsage.js` - bonus_dm_count 컬럼 추가
- [ ] `api/src/models/index.js` - ReferralCoupon 관계 추가
- [ ] `api/migrations/20260208100000-add-referral-coupons.js` 생성
- [ ] `api/src/services/couponService.js` 생성 (issueCoupon, applyCoupons, getUserCoupons, expireExpiredCoupons)
- [ ] `api/src/controllers/couponController.js` 생성
- [ ] `api/src/routes/referralRoutes.js` - GET /coupons, POST /coupons/apply 추가
- [ ] `api/src/constants/errorMessages.js` - 쿠폰 에러 코드 4개 추가
- [ ] `api/src/services/lemonSqueezyWebhookService.js` - isFirstPayment 분기에 쿠폰 발급 추가
- [ ] `api/src/services/quotaService.js` - checkQuota, incrementDmCount에 bonus 합산
- [ ] `api/src/services/usageService.js` - getCurrentUsage에 bonusDmCount 추가
- [ ] `api/src/jobs/couponExpiryScheduler.js` 생성
- [ ] `web/lib/api/referrals.ts` - getCoupons, applyCoupons 추가
- [ ] `web/hooks/useReferral.ts` - useCoupons, useApplyCoupons 추가
- [ ] `web/app/dashboard/settings/page.tsx` - 쿠폰 목록 + 사용 UI 추가
- [ ] `web/messages/ko.json` - coupon 메시지 추가
- [ ] `web/messages/en.json` - coupon 메시지 추가
- [ ] `web/messages/ja.json` - coupon 메시지 추가

---

### 12.16 영향 받는 파일 목록 (Phase 3)

#### 새로 생성하는 파일
| 파일 | 설명 |
|------|------|
| `api/src/models/ReferralCoupon.js` | 쿠폰 Sequelize 모델 |
| `api/src/services/couponService.js` | 쿠폰 비즈니스 로직 |
| `api/src/controllers/couponController.js` | 쿠폰 HTTP 컨트롤러 |
| `api/src/jobs/couponExpiryScheduler.js` | 만료 쿠폰 스케줄러 |
| `api/migrations/20260208100000-add-referral-coupons.js` | DB 마이그레이션 |

#### 수정하는 파일
| 파일 | 수정 내용 |
|------|----------|
| `api/src/models/MonthlyUsage.js` | bonus_dm_count 컬럼 추가 |
| `api/src/models/index.js` | ReferralCoupon import + 관계 추가 |
| `api/src/routes/referralRoutes.js` | GET /coupons, POST /coupons/apply 추가 |
| `api/src/constants/errorMessages.js` | 쿠폰 에러 코드 4개 추가 |
| `api/src/services/lemonSqueezyWebhookService.js` | isFirstPayment에 쿠폰 발급 호출 |
| `api/src/services/quotaService.js` | checkQuota, incrementDmCount 보너스 합산 |
| `api/src/services/usageService.js` | getCurrentUsage 보너스 포함 |
| `web/lib/api/referrals.ts` | getCoupons, applyCoupons API 추가 |
| `web/hooks/useReferral.ts` | useCoupons, useApplyCoupons 훅 추가 |
| `web/app/dashboard/settings/page.tsx` | 쿠폰 섹션 UI 추가 |
| `web/messages/ko.json` | coupon 다국어 메시지 |
| `web/messages/en.json` | coupon 다국어 메시지 |
| `web/messages/ja.json` | coupon 다국어 메시지 |

---

> **Next Step**: `/pdca do referral-code` (Phase 3 구현 시작)
