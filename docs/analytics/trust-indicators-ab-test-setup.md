# Trust Indicators A/B 테스트 설정 가이드

## 📊 개요

랜딩 페이지의 새로운 Trust Indicators (옵션 A) 효과를 측정하기 위한 A/B 테스트 설정 가이드입니다.

### 변경 내용

**기존 (Control):**
- ✓ 무료로 시작
- ✓ 신용카드 불필요
- ✓ 5분 안에 설정 완료

**신규 (Variant A):**
- ✓ 무료 플랜 영구 제공
- ✓ 클릭 3번이면 설정 완료
- ✓ 24시간 자동 반응

---

## 1️⃣ Hotjar 설정

### 1.1 Hotjar 스크립트 설치

웹 앱에 Hotjar 추적 코드를 설치합니다.

#### **설치 위치:** `web/app/layout.tsx`

**방법: Next.js Script 컴포넌트 사용 (권장)**

```tsx
// web/app/layout.tsx
import Script from 'next/script';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  const hotjarId = process.env.NEXT_PUBLIC_HOTJAR_ID;

  return (
    <html lang={locale}>
      <head>
        {/* 기존 메타 태그들 */}
      </head>
      <body>
        {children}

        {/* Hotjar 추적 코드 */}
        {hotjarId && (
          <Script
            id="hotjar-tracking"
            strategy="afterInteractive"
          >
            {`
              (function(h,o,t,j,a,r){
                  h.hj=h.hj||function(){(h.hj.q=h.hj.q||[]).push(arguments)};
                  h._hjSettings={hjid:${hotjarId},hjsv:6};
                  a=o.getElementsByTagName('head')[0];
                  r=o.createElement('script');r.async=1;
                  r.src=t+h._hjSettings.hjid+j+h._hjSettings.hjsv;
                  a.appendChild(r);
              })(window,document,'https://static.hotjar.com/c/hotjar-','.js?sv=');
            `}
          </Script>
        )}
      </body>
    </html>
  );
}
```

#### **환경변수 설정:** `.env.local`

```bash
# Hotjar Site ID (Hotjar 대시보드에서 확인)
NEXT_PUBLIC_HOTJAR_ID=YOUR_HOTJAR_SITE_ID
```

### 1.2 Hotjar에서 측정할 항목

#### ✅ Heatmap 설정
1. Hotjar 대시보드 → **Heatmaps** → **New Heatmap**
2. URL 필터: `https://yourdomain.com/` (랜딩 페이지)
3. 측정 기간: 14일
4. 추적 항목:
   - Trust Indicators 영역 클릭률
   - CTA 버튼 클릭률
   - 스크롤 깊이

#### ✅ Recording 설정
1. Hotjar 대시보드 → **Recordings** → **Settings**
2. 페이지 필터: 랜딩 페이지만
3. 샘플링: 20% (트래픽에 따라 조정)
4. 관찰 포인트:
   - Trust Indicators 읽는 시간
   - CTA 버튼 클릭 전 행동

---

## 2️⃣ Mixpanel 설정

### 2.1 Mixpanel SDK 설치

```bash
cd web
npm install mixpanel-browser
```

### 2.2 Mixpanel 초기화

#### **파일 생성:** `web/lib/analytics/mixpanel.ts`

```typescript
// web/lib/analytics/mixpanel.ts
import mixpanel from 'mixpanel-browser';

const MIXPANEL_TOKEN = process.env.NEXT_PUBLIC_MIXPANEL_TOKEN;

export const initMixpanel = () => {
  if (MIXPANEL_TOKEN) {
    mixpanel.init(MIXPANEL_TOKEN, {
      debug: process.env.NODE_ENV === 'development',
      track_pageview: true,
      persistence: 'localStorage',
    });
  }
};

// Trust Indicators 이벤트 추적
export const trackTrustIndicatorView = (variant: 'control' | 'variant_a') => {
  mixpanel.track('Trust Indicators Viewed', {
    variant,
    timestamp: new Date().toISOString(),
  });
};

export const trackCTAClick = (variant: 'control' | 'variant_a', ctaText: string) => {
  mixpanel.track('CTA Button Clicked', {
    variant,
    cta_text: ctaText,
    timestamp: new Date().toISOString(),
  });
};

export const trackSignup = (variant: 'control' | 'variant_a') => {
  mixpanel.track('User Signed Up', {
    variant,
    timestamp: new Date().toISOString(),
  });

  // 사용자 속성 설정
  mixpanel.people.set({
    'Landing Page Variant': variant,
    'Signup Date': new Date().toISOString(),
  });
};

export default mixpanel;
```

#### **환경변수 설정:** `.env.local`

```bash
# Mixpanel Project Token (Mixpanel 대시보드에서 확인)
NEXT_PUBLIC_MIXPANEL_TOKEN=YOUR_MIXPANEL_TOKEN
```

### 2.3 Root Layout에서 Mixpanel 초기화

#### **파일 수정:** `web/app/layout.tsx`

```tsx
// web/app/layout.tsx
'use client';

import { useEffect } from 'react';
import { initMixpanel } from '@/lib/analytics/mixpanel';

export default function RootLayout({ children }: { children: React.ReactNode }) {
  useEffect(() => {
    initMixpanel();
  }, []);

  return (
    // ... 기존 코드
  );
}
```

### 2.4 랜딩 페이지에 이벤트 추가

#### **파일 수정:** `web/app/page.tsx`

```tsx
// web/app/page.tsx
'use client';

import { useEffect } from 'react';
import { trackTrustIndicatorView, trackCTAClick } from '@/lib/analytics/mixpanel';

export default function LandingPage() {
  // Trust Indicators 뷰 추적
  useEffect(() => {
    // 현재는 variant_a만 추적 (나중에 A/B 테스트 도구로 분기)
    trackTrustIndicatorView('variant_a');
  }, []);

  const handleCTAClick = () => {
    trackCTAClick('variant_a', '무료로 시작하기');
    // 기존 CTA 로직...
  };

  return (
    // ... 기존 코드
    <Button onClick={handleCTAClick}>
      무료로 시작하기
    </Button>
  );
}
```

### 2.5 회원가입 성공 시 추적

#### **파일 수정:** `web/app/(auth)/register/page.tsx`

```tsx
import { trackSignup } from '@/lib/analytics/mixpanel';

// 회원가입 성공 후
const handleSignupSuccess = () => {
  trackSignup('variant_a');
  // 기존 로직...
};
```

---

## 3️⃣ Google Analytics 4 (GA4) 이벤트 설정

GA4는 이미 설정되어 있으므로, 커스텀 이벤트만 추가합니다.

### 3.1 gtag.js 이벤트 추적 추가

#### **파일 생성:** `web/lib/analytics/gtag.ts`

```typescript
// web/lib/analytics/gtag.ts

declare global {
  interface Window {
    gtag: (...args: any[]) => void;
  }
}

export const trackTrustIndicatorView = (variant: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', 'trust_indicators_view', {
      variant,
      event_category: 'engagement',
      event_label: variant,
    });
  }
};

export const trackCTAClick = (variant: string, ctaText: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', 'cta_button_click', {
      variant,
      cta_text: ctaText,
      event_category: 'conversion',
      event_label: ctaText,
    });
  }
};

export const trackSignup = (variant: string) => {
  if (typeof window !== 'undefined' && window.gtag) {
    window.gtag('event', 'sign_up', {
      variant,
      event_category: 'conversion',
      event_label: variant,
    });
  }
};
```

### 3.2 랜딩 페이지에 GA4 이벤트 추가

```tsx
// web/app/page.tsx
import { trackTrustIndicatorView as trackGAView, trackCTAClick as trackGACTA } from '@/lib/analytics/gtag';
import { trackTrustIndicatorView as trackMixpanelView, trackCTAClick as trackMixpanelCTA } from '@/lib/analytics/mixpanel';

export default function LandingPage() {
  useEffect(() => {
    trackMixpanelView('variant_a');
    trackGAView('variant_a');
  }, []);

  const handleCTAClick = () => {
    trackMixpanelCTA('variant_a', '무료로 시작하기');
    trackGACTA('variant_a', '무료로 시작하기');
    // 기존 CTA 로직...
  };

  return (
    // ... 기존 코드
  );
}
```

---

## 4️⃣ A/B 테스트 실행 계획

### Phase 1: 기준 데이터 수집 (1주)

**목표:** 현재 Trust Indicators (Control) 성과 측정

**측정 지표:**
- 랜딩 페이지 방문자 수
- CTA 클릭률
- 회원가입 전환율
- 이탈률
- 평균 체류 시간

### Phase 2: Variant A 테스트 (2주)

**배포 방법:** 100% 트래픽에 Variant A 적용

**측정 지표:**
- 같은 지표 측정
- 주간 비교 분석

### Phase 3: 데이터 분석 및 결정 (1주)

**분석 항목:**
1. **전환율 변화**
   - CTA 클릭률: Control vs Variant A
   - 회원가입 전환율: Control vs Variant A

2. **사용자 행동 변화**
   - Hotjar Heatmap: Trust Indicators 영역 주목도
   - Recordings: 사용자 행동 패턴 변화

3. **통계적 유의성**
   - 최소 95% 신뢰 수준
   - 최소 2,000 방문자 샘플

---

## 5️⃣ Hotjar & Mixpanel 대시보드 설정

### Hotjar Dashboard

#### **필수 대시보드:**
1. **Trust Indicators Heatmap**
   - URL 필터: `/` (홈페이지)
   - 디바이스 분리: Mobile / Desktop
   - 측정 기간: 14일

2. **CTA Conversion Funnel**
   - Step 1: Trust Indicators 뷰
   - Step 2: CTA 버튼 클릭
   - Step 3: 회원가입 페이지 도달

### Mixpanel Dashboard

#### **Insights 생성:**

1. **Trust Indicators Funnel**
   ```
   Step 1: Trust Indicators Viewed
   Step 2: CTA Button Clicked
   Step 3: User Signed Up
   ```
   - Breakdown by: `variant`
   - Date Range: Last 30 days

2. **Conversion Rate by Variant**
   - Event: `User Signed Up`
   - Formula: `User Signed Up` / `Trust Indicators Viewed`
   - Breakdown by: `variant`

3. **Time to Conversion**
   - Event: `User Signed Up`
   - Show: Time between events
   - From: `Trust Indicators Viewed`
   - To: `User Signed Up`
   - Breakdown by: `variant`

---

## 6️⃣ 성공 기준 (Success Metrics)

### 주요 KPI

| 지표 | 기준 (Control) | 목표 (Variant A) | 측정 도구 |
|------|----------------|------------------|-----------|
| **CTA 클릭률** | TBD | +10% 이상 | Mixpanel, GA4 |
| **회원가입 전환율** | TBD | +15% 이상 | Mixpanel, GA4 |
| **이탈률** | TBD | -5% 이하 | GA4, Hotjar |
| **평균 체류 시간** | TBD | +20% 이상 | GA4 |

### 부가 지표

- **Trust Indicators 주목도** (Hotjar Heatmap)
- **스크롤 깊이** (GA4, Hotjar)
- **모바일 vs 데스크톱 전환율 차이** (Mixpanel)

---

## 7️⃣ 문제 해결 (Troubleshooting)

### Hotjar가 데이터를 수집하지 않는 경우

1. **스크립트 로딩 확인**
   - 브라우저 개발자 도구 → Network 탭
   - `hotjar-` 로 시작하는 요청 확인

2. **Site ID 확인**
   - `.env.local`의 `NEXT_PUBLIC_HOTJAR_ID` 값 확인
   - Hotjar 대시보드 → Settings → Site ID

3. **Ad Blocker 비활성화**
   - Hotjar는 ad blocker에 의해 차단될 수 있음

### Mixpanel 이벤트가 전송되지 않는 경우

1. **토큰 확인**
   - `.env.local`의 `NEXT_PUBLIC_MIXPANEL_TOKEN` 값 확인
   - Mixpanel 대시보드 → Settings → Project Token

2. **브라우저 콘솔 확인**
   ```javascript
   // 개발자 도구 콘솔에서 테스트
   mixpanel.track('Test Event', { test: true });
   ```

3. **Debug 모드 활성화**
   ```typescript
   mixpanel.init(MIXPANEL_TOKEN, {
     debug: true  // 콘솔에 로그 출력
   });
   ```

### GA4 이벤트가 보이지 않는 경우

1. **실시간 보고서 확인**
   - GA4 → Reports → Realtime
   - 30초 내에 이벤트 표시되어야 함

2. **gtag 로드 확인**
   ```javascript
   // 브라우저 콘솔에서 확인
   console.log(window.gtag);
   ```

---

## 8️⃣ 다음 단계

### ✅ 즉시 실행
1. **환경변수 설정** - `.env.local`에 Hotjar ID, Mixpanel Token 추가
2. **코드 배포** - Trust Indicators 변경 + 추적 코드 배포
3. **대시보드 설정** - Hotjar Heatmap, Mixpanel Insights 생성

### ⏳ 1주 후
4. **데이터 확인** - 충분한 샘플 수집 여부 확인
5. **초기 분석** - 주요 지표 트렌드 확인

### ⏳ 2주 후
6. **종합 분석** - Hotjar + Mixpanel + GA4 데이터 종합
7. **의사결정** - Variant A 유지 or 추가 최적화

---

## 📚 참고 자료

- [Hotjar 공식 문서](https://help.hotjar.com/)
- [Mixpanel 공식 문서](https://developer.mixpanel.com/)
- [Google Analytics 4 이벤트 가이드](https://developers.google.com/analytics/devguides/collection/ga4/events)
- [Next.js Script 컴포넌트](https://nextjs.org/docs/app/api-reference/components/script)

---

**작성일:** 2026-01-29
**버전:** 1.0
**담당자:** 마케팅 팀, 개발 팀
