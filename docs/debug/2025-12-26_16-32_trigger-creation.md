# 디버그 로그: 트리거 생성 API 연동

**날짜:** 2025-12-26 16:32
**파일:**
- web/lib/api/triggers.ts
- web/types/trigger.ts
**심각도:** High

## 1. 문제 설명

### 오류 메시지
```json
{
    "result": false,
    "data": [],
    "errors": [
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"platform\" is required"},
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"post_id\" is required"},
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"post_type\" is required"},
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"post_url\" is required"},
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"trigger_word\" is required"},
        {"internal_error_code": "VALIDATION_ERROR", "error_message": "\"dm_message\" is required"}
    ]
}
```

### 재현 단계
1. 로그인 후 트리거 만들기 페이지 이동 (`/dashboard/triggers/new`)
2. Instagram 포스트 URL 입력
3. 트리거 키워드 입력
4. 자동 DM 메시지 입력
5. 저장 버튼 클릭
6. VALIDATION_ERROR 발생

## 2. 근본 원인 분석

### 원인
WEB 프론트엔드와 API 백엔드 간 데이터 형식 불일치

**WEB에서 보내는 데이터 (camelCase):**
- `postUrl`
- `keywords` (배열)
- `dmMessage`
- `followerOnly`

**API가 기대하는 데이터 (snake_case):**
- `platform` (필수, WEB에서 미전송)
- `post_id` (필수, WEB에서 미전송)
- `post_type` (필수, WEB에서 미전송)
- `post_url`
- `trigger_word` (단일 문자열)
- `dm_message`
- `trigger_follow`

## 3. 시도한 솔루션

### 솔루션 1: API 클라이언트에 데이터 변환 로직 추가 ✅ 성공
`web/lib/api/triggers.ts`에 변환 함수 추가:

```typescript
// Instagram URL에서 post_id 추출
const extractPostId = (url: string): string => {
  const match = url.match(/instagram\.com\/(?:p|reel|reels)\/([A-Za-z0-9_-]+)/);
  return match ? match[1] : '';
};

// URL에서 post_type 결정
const getPostType = (url: string): 'POST' | 'REELS' => {
  if (url.includes('/reel/') || url.includes('/reels/')) {
    return 'REELS';
  }
  return 'POST';
};

// WEB form data를 API format으로 변환
const transformToApiFormat = (dto: CreateTriggerDto) => {
  return {
    platform: 'INSTAGRAM',
    post_id: extractPostId(dto.postUrl),
    post_type: getPostType(dto.postUrl),
    post_url: dto.postUrl,
    trigger_follow: dto.followerOnly ?? false,
    trigger_word: dto.keywords.join(','),
    dm_message: dto.dmMessage,
  };
};
```

## 4. 최종 솔루션

### 수정된 파일
1. `web/lib/api/triggers.ts`
   - `extractPostId()` 함수 추가 - Instagram URL에서 post_id 추출
   - `getPostType()` 함수 추가 - URL에서 POST/REELS 구분
   - `transformToApiFormat()` 함수 추가 - camelCase → snake_case 변환
   - `createTrigger()` 함수 수정 - 변환 로직 적용
   - `updateTrigger()` 함수 수정 - 변환 로직 적용

### 검증 결과
- 빌드 성공 확인 (`npm run build`)
- 실제 트리거 생성 테스트 필요 (사용자 확인 필요)

## 5. 추가 참고 사항

### API 스키마 (api/src/utils/validators.js)
```javascript
export const createTriggerSchema = Joi.object({
  platform: Joi.string().valid('INSTAGRAM', 'TIKTOK').required(),
  post_id: Joi.string().max(500).required(),
  post_type: Joi.string().valid('POST', 'REELS').required(),
  post_url: Joi.string().uri().required(),
  trigger_follow: Joi.boolean().default(false),
  trigger_word: Joi.string().max(30).required(),
  dm_message: Joi.string().max(1000).required(),
});
```

### 주의사항
- `trigger_word`는 최대 30자 제한이 있으므로, 여러 키워드를 쉼표로 연결할 때 주의 필요
- WEB에서는 여러 키워드를 배열로 관리하지만 API는 단일 문자열로 처리

---

## 추가 이슈: 트리거 목록 조회 오류 (2025-12-26 17:00)

### 문제
트리거 생성 후 목록 페이지에서 트리거가 표시되지 않음

### 원인
API 응답(snake_case)과 WEB 기대 형식(camelCase) 불일치

**API 응답 필드:**
- `seq` → WEB: `id`
- `post_url` → WEB: `postUrl`
- `trigger_word` (문자열) → WEB: `keywords` (배열)
- `status` ('ACTIVATED') → WEB: `isActive` (boolean)
- `trigger_follow` (0/1) → WEB: `followerOnly` (boolean)

### 솔루션
`transformFromApiFormat()` 함수 추가하여 API 응답을 WEB 형식으로 변환:

```typescript
const transformFromApiFormat = (apiTrigger: any): Trigger => {
  return {
    id: apiTrigger.seq,
    userId: apiTrigger.user_seq,
    postId: apiTrigger.post_id,
    postUrl: apiTrigger.post_url,
    keywords: apiTrigger.trigger_word ? apiTrigger.trigger_word.split(',') : [],
    dmMessage: apiTrigger.dm_message,
    followerOnly: apiTrigger.trigger_follow === 1 || apiTrigger.trigger_follow === true,
    isActive: apiTrigger.status === 'ACTIVATED',
    createdAt: apiTrigger.created_at,
    updatedAt: apiTrigger.last_updated_at,
    // ...
  };
};
```

### 수정된 함수
- `getTriggers()` - 목록 조회
- `getTrigger()` - 단일 조회
- `createTrigger()` - 생성
- `updateTrigger()` - 수정
- `toggleTrigger()` - 상태 토글

### 검증
빌드 성공 확인
