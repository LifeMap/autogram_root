# Multi-Platform Expansion Analysis

> **Document Purpose**: Facebook, Threads, X(Twitter)로의 확장 가능성 분석
> **Last Updated**: 2025-01-09
> **Current Status**: Instagram 전용 구현 완료

---

## 1. Executive Summary

### 현재 상태
Autogram은 현재 **Instagram 전용**으로 구현되어 있으며, 코드베이스가 Instagram API에 강하게 종속되어 있습니다.

### 확장 가능성 평가

| 플랫폼 | 기술적 가능성 | 구현 난이도 | 예상 기간 | 권장 우선순위 |
|--------|-------------|------------|----------|--------------|
| **Facebook Reels** | ✅ 가능 | 중간 | 2-3주 | 1순위 |
| **Threads** | ⚠️ 제한적 | 높음 | 3-4주 | 3순위 |
| **X (Twitter)** | ⚠️ 제한적 | 높음 | 3-4주 | 2순위 |

---

## 2. Current Architecture Analysis

### 2.1 Database Layer

#### 현재 구조 (Instagram 전용)
```
tb_users
  └── tb_user_oauth (platform_type: INSTAGRAM, TIKTOK)
        └── tb_instagram_posts (Instagram 전용 테이블)
              └── tb_post_triggers
                    └── tb_trigger_execute_histories
                          └── tb_trigger_clicks
```

#### 문제점
| 컴포넌트 | 현재 상태 | 확장 시 필요 조치 |
|---------|----------|------------------|
| `tb_instagram_posts` | 테이블명이 Instagram 전용 | 범용 테이블로 리팩토링 필요 |
| `tb_post_triggers` | Instagram 테이블 FK 참조 | FK 수정 필요 |
| `tb_user_oauth` | ✅ platform_type ENUM 존재 | Facebook, Threads, X 추가만 하면 됨 |
| `tb_trigger_execute_histories` | platform 필드 없음 | platform 필드 추가 필요 |

### 2.2 Service Layer

#### 현재 구조
```
api/src/services/
├── instagramService.js    ← Instagram API 하드코딩 (583 lines)
├── webhookService.js      ← Instagram 웹훅만 처리 (419 lines)
├── authService.js         ← Instagram OAuth 하드코딩 (1,351 lines)
├── triggerService.js      ← 트리거 관리 (재사용 가능)
└── ...
```

#### 문제점
- **추상화 레이어 부재**: 플랫폼별 서비스 팩토리 패턴 없음
- **하드코딩된 API 엔드포인트**: Instagram Graph API URL 직접 참조
- **웹훅 라우팅 고정**: `/webhooks/instagram` 단일 라우트

### 2.3 Reusable Components

| 컴포넌트 | 재사용 가능 여부 | 비고 |
|---------|----------------|------|
| JWT 인증 | ✅ 완전 재사용 | 플랫폼 무관 |
| 트리거 로직 | ✅ 대부분 재사용 | 플랫폼별 미세 조정 필요 |
| 클릭 추적 | ✅ 완전 재사용 | 플랫폼 무관 |
| 에러 핸들링 | ✅ 완전 재사용 | 공통 유틸리티 |
| 이메일 서비스 | ✅ 완전 재사용 | 알림용 |
| UserOAuth 모델 | ✅ 구조 재사용 | ENUM 확장만 필요 |

---

## 3. Platform-Specific Analysis

### 3.1 Facebook Reels

#### API 개요
- **API**: Facebook Graph API (Instagram과 동일 기반)
- **인증**: OAuth 2.0 (Meta Business Suite)
- **웹훅**: Page Webhooks 지원

#### 기능 지원 현황

| 기능 | 지원 여부 | API Endpoint |
|-----|----------|--------------|
| 게시물 조회 | ✅ 지원 | `GET /{page-id}/feed` |
| Reels 조회 | ✅ 지원 | `GET /{page-id}/video_reels` |
| 댓글 웹훅 | ✅ 지원 | Webhooks: `feed` subscription |
| 댓글 조회 | ✅ 지원 | `GET /{object-id}/comments` |
| DM 전송 | ⚠️ 제한적 | Messenger Platform API 필요 |
| Private Reply | ⚠️ 제한적 | Page Conversations API |

#### 주요 차이점 (Instagram vs Facebook)

```javascript
// Instagram Private Reply
POST /{ig-user-id}/messages
{
  recipient: { comment_id: "..." },
  message: { text: "..." }
}

// Facebook Page Reply (다른 구조)
POST /{page-id}/messages
{
  recipient: { id: "user-psid" },  // Page-Scoped ID 필요
  message: { text: "..." }
}
```

#### Facebook 확장 시 필요 작업

1. **Facebook App 설정**
   - Messenger Platform 권한 추가
   - Page Webhooks 구독 설정

2. **코드 수정**
   - `facebookService.js` 신규 생성
   - Page-Scoped User ID 매핑 로직
   - Messenger Send API 연동

3. **제한사항**
   - 24시간 메시징 윈도우 (Instagram과 동일)
   - 비즈니스 페이지만 지원
   - Messenger 정책 준수 필요

#### 예상 구현 난이도: **중간** (2-3주)

---

### 3.2 Threads

#### API 개요
- **API**: Threads API (2024년 6월 출시, 2025년 7월 대규모 업데이트)
- **인증**: Meta OAuth 2.0
- **현재 상태**: 빠르게 발전 중 (MAU 3.2억+)

#### 기능 지원 현황 (2025년 7월 업데이트 기준)

| 기능 | 지원 여부 | 비고 |
|-----|----------|------|
| 게시물 조회 | ✅ 지원 | 공개 프로필 접근 가능 |
| 게시물 작성 | ✅ 지원 | `auto_publish_text` 파라미터 |
| 답글 작성 | ✅ 지원 | 공개 게시물/답글에 답글 가능 |
| 리포스트 | ✅ 지원 | |
| 멘션 웹훅 | ✅ 지원 | 실시간 알림 |
| 키워드 검색 | ✅ 지원 | |
| **DM 전송** | ❌ 미지원 | 2025년 7월 DM 출시, API 미제공 |

#### 핵심 제한사항

```
⚠️ Threads API는 DM 기능을 지원하지 않습니다.

현재 가능한 것:
- 댓글에 공개 답글 달기
- 게시물 리포스트/인용

불가능한 것:
- 비공개 DM 전송 ← Autogram 핵심 기능 불가
```

#### Threads 확장 가능성

| 시나리오 | 가능 여부 | 설명 |
|---------|----------|------|
| 댓글 → DM | ❌ 불가 | DM API 미제공 |
| 댓글 → 공개 답글 | ✅ 가능 | 하지만 비공개 콘텐츠 전달 불가 |
| 멘션 모니터링 | ✅ 가능 | 웹훅으로 실시간 감지 |

#### 권장 사항
현재 Threads는 **DM API 미지원**으로 Autogram의 핵심 기능(댓글 → 비공개 DM) 구현이 **불가능**합니다. Meta가 DM API를 공개할 때까지 대기 권장.

#### 예상 구현 난이도: **불가능** (DM API 부재)

---

### 3.3 X (Twitter)

#### API 개요
- **API**: X API v2
- **인증**: OAuth 2.0 / OAuth 1.0a
- **가격**: Free(제한적), Basic($200/월), Pro($5,000/월)

#### 기능 지원 현황

| 기능 | 지원 여부 | 티어 요구사항 |
|-----|----------|-------------|
| 트윗 조회 | ✅ 지원 | Free (제한적) |
| 트윗 작성 | ✅ 지원 | Basic+ |
| 답글 작성 | ✅ 지원 | Basic+ |
| DM 전송 | ✅ 지원 | Basic+ |
| DM 웹훅 | ✅ 지원 | Pro (Account Activity API) |
| 멘션 웹훅 | ✅ 지원 | Pro |

#### X API 가격 정책 (2025년)

| 티어 | 월 비용 | 포스트 제한 | DM 기능 |
|-----|--------|-----------|---------|
| Free | $0 | 500/월 | ❌ |
| Basic | $200 | 3,000/월 | ✅ |
| Pro | $5,000 | 300,000/월 | ✅ + Webhooks |

#### 자동화 정책 제한

```
⚠️ X의 엄격한 자동화 정책

금지 사항:
- 키워드 검색 기반 자동 답글 (명시적 금지)
- 무분별한 대량 DM 발송
- 허가 없는 자동 응답 캠페인

허용 조건:
- 사용자가 계정을 @멘션해야 함
- 팔로우만으로는 동의로 인정 안 됨
- 광고/브랜드는 X 승인 필요
```

#### X 확장 시 고려사항

1. **비용 문제**
   - 웹훅 사용 시 Pro 티어 필요 ($5,000/월)
   - 폴링 방식 사용 시 Basic 가능 ($200/월)

2. **정책 준수**
   - 댓글 트리거 방식 제한적
   - 사용자가 반드시 @멘션해야 함
   - 자동화 캠페인 사전 승인 필요

3. **구현 방식 차이**
```javascript
// X DM 전송 (v1.1 API 사용 필요)
POST /1.1/direct_messages/events/new.json
{
  "event": {
    "type": "message_create",
    "message_create": {
      "target": { "recipient_id": "..." },
      "message_data": { "text": "..." }
    }
  }
}
```

#### 예상 구현 난이도: **높음** (정책 제한 + 비용)

---

## 4. Recommended Architecture for Multi-Platform

### 4.1 Database Schema Changes

#### Option A: 통합 테이블 (권장)
```sql
-- 기존 tb_instagram_posts → tb_social_posts로 마이그레이션
CREATE TABLE tb_social_posts (
  seq INT PRIMARY KEY AUTO_INCREMENT,
  user_seq INT NOT NULL,
  platform_type ENUM('INSTAGRAM', 'FACEBOOK', 'THREADS', 'X', 'TIKTOK'),
  platform_post_id VARCHAR(100),  -- 플랫폼별 고유 ID
  media_type VARCHAR(50),
  caption TEXT,
  permalink VARCHAR(500),
  thumbnail_url VARCHAR(500),
  post_timestamp DATETIME,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

-- UserOAuth ENUM 확장
ALTER TABLE tb_user_oauth
MODIFY platform_type ENUM('INSTAGRAM', 'FACEBOOK', 'THREADS', 'X', 'TIKTOK');

-- TriggerExecuteHistory에 platform 추가
ALTER TABLE tb_trigger_execute_histories
ADD COLUMN platform_type ENUM('INSTAGRAM', 'FACEBOOK', 'THREADS', 'X', 'TIKTOK');
```

#### Option B: 플랫폼별 테이블 분리
```sql
tb_instagram_posts  (기존 유지)
tb_facebook_posts   (신규)
tb_threads_posts    (신규)
tb_x_posts          (신규)
```

**권장**: Option A (유지보수 용이)

### 4.2 Service Layer Refactoring

#### 추상화 패턴 적용
```
api/src/services/
├── platform/
│   ├── PlatformServiceFactory.js   ← 팩토리 패턴
│   ├── BasePlatformService.js      ← 추상 클래스
│   ├── InstagramService.js         ← Instagram 구현
│   ├── FacebookService.js          ← Facebook 구현
│   └── XService.js                 ← X 구현
├── webhooks/
│   ├── WebhookDispatcher.js        ← 웹훅 라우터
│   ├── InstagramWebhookHandler.js
│   ├── FacebookWebhookHandler.js
│   └── XWebhookHandler.js
└── ...
```

#### 팩토리 패턴 예시
```javascript
// PlatformServiceFactory.js
export const getPlatformService = (platformType) => {
  switch (platformType) {
    case 'INSTAGRAM':
      return new InstagramService();
    case 'FACEBOOK':
      return new FacebookService();
    case 'X':
      return new XService();
    default:
      throw new Error(`Unsupported platform: ${platformType}`);
  }
};

// BasePlatformService.js (추상 인터페이스)
export class BasePlatformService {
  async getPosts(userSeq) { throw new Error('Not implemented'); }
  async sendDM(userSeq, targetId, message, options) { throw new Error('Not implemented'); }
  async replyToComment(userSeq, commentId, text) { throw new Error('Not implemented'); }
  async subscribeWebhook(userSeq) { throw new Error('Not implemented'); }
}
```

### 4.3 Webhook Architecture

#### 현재 (단일 플랫폼)
```
POST /api/webhooks/instagram → webhookController → webhookService
```

#### 제안 (멀티 플랫폼)
```
POST /api/webhooks/:platform → webhookDispatcher → platformHandler
```

```javascript
// webhookDispatcher.js
export const dispatchWebhook = async (platform, payload) => {
  const handler = getWebhookHandler(platform);
  return handler.process(payload);
};

// routes/webhookRoutes.js
router.post('/:platform', (req, res) => {
  const { platform } = req.params;
  webhookDispatcher.dispatchWebhook(platform, req.body);
  res.status(200).send('EVENT_RECEIVED');
});
```

---

## 5. Implementation Roadmap

### Phase 1: Foundation (1-2주)
- [ ] 추상화 레이어 설계 및 구현
- [ ] `tb_social_posts` 테이블 마이그레이션
- [ ] 기존 Instagram 코드를 새 구조로 리팩토링
- [ ] 웹훅 디스패처 구현

### Phase 2: Facebook Integration (2-3주)
- [ ] Facebook App 설정 (Messenger Platform)
- [ ] `FacebookService.js` 구현
- [ ] Facebook OAuth 플로우 추가
- [ ] Page Webhooks 연동
- [ ] Messenger Send API 연동
- [ ] 테스트 및 디버깅

### Phase 3: X Integration (3-4주) - Optional
- [ ] X Developer Account 설정 (Basic/Pro 티어)
- [ ] `XService.js` 구현
- [ ] X OAuth 2.0 플로우 추가
- [ ] Account Activity API 연동 (Pro 필요)
- [ ] DM API 연동
- [ ] 자동화 정책 준수 검증

### Phase 4: Threads Integration (대기)
- Meta DM API 공개 후 검토
- 현재는 공개 답글 기능만 가능

---

## 6. Risk Assessment

### 기술적 리스크

| 리스크 | 영향도 | 발생 확률 | 대응 방안 |
|-------|-------|----------|----------|
| API 변경/중단 | 높음 | 중간 | 버전 관리, 추상화 레이어 |
| Rate Limit 초과 | 중간 | 높음 | 큐 시스템, 재시도 로직 |
| 인증 토큰 만료 | 중간 | 높음 | 자동 갱신 로직 |

### 비즈니스 리스크

| 리스크 | 영향도 | 발생 확률 | 대응 방안 |
|-------|-------|----------|----------|
| X API 비용 | 높음 | 확정 | 티어 선택 신중히 |
| 정책 위반 계정 정지 | 높음 | 중간 | 정책 준수, 사용량 제한 |
| 숨겨진 요청 문제 | 중간 | 높음 | 사용자 안내 강화 |

---

## 7. Conclusion & Recommendations

### 단기 권장사항 (1-3개월)
1. **Instagram 안정화**: 현재 기능 완성도 향상
2. **추상화 레이어 구축**: 향후 확장을 위한 기반 마련
3. **Facebook Reels 검토**: 동일 Meta 생태계로 확장 용이

### 중기 권장사항 (3-6개월)
1. **Facebook Reels 구현**: Meta API 경험 활용
2. **X 비용 대비 효과 분석**: $200/월 이상 지출 가치 검토

### 장기 권장사항 (6개월+)
1. **Threads DM API 모니터링**: Meta 발표 주시
2. **TikTok 검토**: 현재 OAuth는 준비됨, DM API 확인 필요

---

## References

### Facebook/Meta
- [Meta Webhook Integration Guide](https://www.adarshyadav.dev/blog/webhook-integration-meta-apis)
- [Facebook Reels API Specifications](https://vistasocial.com/insights/facebook-reels-api-and-specifications/)
- [Instagram Graph API Guide 2025](https://elfsight.com/blog/instagram-graph-api-complete-developer-guide-for-2025/)

### Threads
- [Threads API Launch (TechCrunch)](https://techcrunch.com/2024/06/18/threads-finally-launches-its-api-for-developers/)
- [Meta Threads API Expansion 2025](https://martech360.com/social-media-technology/social-media-platforms/meta-expands-threads-api-with-advanced-features-to-empower-developers-and-boost-engagement/)
- [Threads API Documentation (Postman)](https://www.postman.com/meta/threads/documentation/dht3nzz/threads-api)

### X (Twitter)
- [X API Products](https://developer.twitter.com/en/products/twitter-api)
- [X Automation Rules](https://help.x.com/en/rules-and-policies/x-automation)
- [X API Key Guide 2025](https://elfsight.com/blog/how-to-get-x-twitter-api-key-in-2025/)
- [X Direct Message API](https://developer.x.com/en/docs/x-api/v1/direct-messages/api-features)

---

*Document generated for AI handoff and technical planning purposes.*
