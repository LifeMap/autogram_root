# Autogram 브랜드 아이덴티티 가이드

## 개요

이 문서는 Autogram 브랜드의 시각적 아이덴티티와 언어적 표현 방식을 정의합니다. 모든 마케팅 자료, UI 디자인, 커뮤니케이션에서 일관된 브랜드 경험을 제공하기 위한 가이드라인입니다.

---

## 1. 브랜드 정의

### 1.1 브랜드명

**Autogram** = **Auto** + Insta**gram**

- 발음: 오토그램
- 의미: Instagram 마케팅의 자동화를 상징
- 표기: 영문으로만 표기, 항상 첫 글자 대문자 (Autogram)

### 1.2 슬로건

**메인 슬로건**
```
"댓글이 고객이 되는 순간"
```

**서브 슬로건**
```
"키워드 트리거 하나로 시작되는 마케팅 자동화"
```

### 1.3 브랜드 에센스

- **카테고리**: Instagram 마케팅 자동화 도구
- **핵심 가치**: 즉시성, 간편함, 신뢰성
- **타겟 오디언스**: Instagram 비즈니스 계정 및 크리에이터 운영자
- **브랜드 약속**: 댓글 하나도 놓치지 않는 24/7 자동 응답 시스템

---

## 2. 로고 가이드라인

### 2.1 로고 파일

| 용도 | 파일 경로 | 형식 |
|------|----------|------|
| 웹 기본 | `/public/autogram.svg` | SVG |
| 파비콘 | `/public/favicon.ico` | ICO |

### 2.2 로고 사용 규칙

#### 최소 사이즈
- 웹: 40px x 40px
- 인쇄: 15mm x 15mm

#### 여백 규칙
- 로고 주변에 로고 높이의 50% 이상 여백 확보
- 다른 요소와 충분한 간격 유지

#### 금지 사항
- 로고 비율 변경 금지
- 로고 색상 임의 변경 금지
- 복잡한 배경 위에 로고 배치 금지
- 로고에 그림자, 외곽선 추가 금지

### 2.3 로고 적용 사이즈

| 위치 | 사이즈 | 클래스 |
|------|--------|--------|
| 헤더 | 40x40px | `h-10 w-auto` |
| 로그인/회원가입 | 64x64px | `h-16 w-16` |
| 랜딩 히어로 | 80x80px | `width={80} height={80}` |
| 파비콘 | 32x32px | - |

---

## 3. 색상 팔레트

### 3.1 Primary Colors

#### Instagram 그라데이션 (브랜드 시그니처)
```css
background: linear-gradient(135deg, #F58529, #DD2A7B, #8134AF);
```

| 색상명 | HEX 코드 | 용도 |
|--------|----------|------|
| Instagram Orange | `#F58529` | 그라데이션 시작 |
| Instagram Pink | `#DD2A7B` | 그라데이션 중간 |
| Instagram Purple | `#8134AF` | 그라데이션 끝 |

#### CTA 그라데이션 (Action Color)
CTA 버튼에는 Instagram 그라데이션을 사용합니다.
```css
background: linear-gradient(to right, #F58529, #DD2A7B, #8134AF);
```

| 상태 | 스타일 | 용도 |
|------|--------|------|
| 기본 | 그라데이션 배경 | CTA 버튼 |
| 호버 | `opacity: 0.9` | 버튼 호버 상태 |
| 아이콘 | `#DD2A7B` (핑크) | Feature 아이콘 강조 |

### 3.2 Semantic Colors

| 색상 | HEX 코드 | 용도 |
|------|----------|------|
| Success | `#16A34A` | 성공, 활성 상태 |
| Error | `#DC2626` | 오류, 삭제 |
| Warning | `#F59E0B` | 경고, 주의 |
| Info | `#0EA5E9` | 정보, 안내 |

### 3.3 Neutral Colors

#### Light Mode
| 용도 | 색상 값 |
|------|---------|
| 배경 | `oklch(1 0 0)` (순백) |
| 텍스트 | `oklch(0.145 0 0)` (거의 검정) |
| 보조 텍스트 | `oklch(0.556 0 0)` (회색) |
| 테두리 | `oklch(0.922 0 0)` (연회색) |

#### Dark Mode
| 용도 | 색상 값 |
|------|---------|
| 배경 | `oklch(0.145 0 0)` |
| 텍스트 | `oklch(0.985 0 0)` |
| 보조 텍스트 | `oklch(0.708 0 0)` |
| 테두리 | `oklch(1 0 0 / 10%)` |

### 3.4 색상 사용 가이드

#### 그라데이션 텍스트 적용
```tsx
<span className="bg-gradient-to-r from-[#F58529] via-[#DD2A7B] to-[#8134AF] bg-clip-text text-transparent">
  Autogram
</span>
```

#### CTA 버튼 적용
```tsx
<Button className="bg-gradient-to-r from-[#F58529] via-[#DD2A7B] to-[#8134AF] hover:opacity-90 text-white">
  무료로 시작하기
</Button>
```

#### 아이콘 강조
```tsx
<Zap className="h-5 w-5 text-[#DD2A7B]" />
```

---

## 4. 타이포그래피

### 4.1 폰트 패밀리

**Primary Font**: Geist Sans
```css
font-family: 'Geist Sans', -apple-system, BlinkMacSystemFont, 'Segoe UI',
             'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif;
```

**Monospace Font**: Geist Mono
```css
font-family: 'Geist Mono', 'SF Mono', 'Consolas', monospace;
```

### 4.2 타이포그래피 스케일

#### 헤딩
| 레벨 | 데스크톱 | 모바일 | 두께 |
|------|----------|--------|------|
| H1 (Hero) | 60px / 3.75rem | 36px / 2.25rem | Bold (700) |
| H2 (Section) | 30px / 1.875rem | 24px / 1.5rem | Bold (700) |
| H3 (Card) | 20px / 1.25rem | 18px / 1.125rem | Semibold (600) |
| H4 (Sub) | 16px / 1rem | 16px / 1rem | Semibold (600) |

#### 본문
| 종류 | 크기 | 두께 | Line Height |
|------|------|------|-------------|
| Body Large | 18px / 1.125rem | Regular (400) | 1.6 |
| Body | 16px / 1rem | Regular (400) | 1.6 |
| Body Small | 14px / 0.875rem | Regular (400) | 1.5 |
| Caption | 12px / 0.75rem | Medium (500) | 1.4 |

### 4.3 텍스트 스타일 적용

```tsx
// Hero 헤드라인
<h1 className="text-4xl font-bold tracking-tight sm:text-5xl md:text-6xl">

// 섹션 제목
<h2 className="text-3xl font-bold">

// 카드 제목
<h3 className="text-xl font-semibold">

// 본문 (보조)
<p className="text-muted-foreground">

// 작은 텍스트
<span className="text-sm text-muted-foreground">
```

---

## 5. 브랜드 보이스 & 톤

### 5.1 보이스 속성

| 속성 | 비율 | 설명 |
|------|------|------|
| 친근함 | 70% | 딱딱한 기술 용어 대신 일상 언어 사용 |
| 전문성 | 30% | 신뢰성 있는 표현으로 서비스 품질 전달 |
| 직접적 | 95% | 돌려 말하지 않고 핵심만 명확히 전달 |
| 솔루션 중심 | 80% | 문제보다 해결책에 집중 |

### 5.2 작성 원칙

#### Do (해야 할 것)
- 명확한 혜택 제시: "댓글을 자동으로 DM으로 보내드립니다"
- 구체적 수치 사용: "3분이면 설정이 끝나요"
- 진입 장벽 제거: "무료로 시작하세요"
- 짧은 문장 (15단어 이하)
- 능동태 사용: "Autogram이 발송합니다"

#### Don't (하지 말아야 할 것)
- 비즈니스 유행어: "레버리지", "시너지", "혁신적 솔루션"
- 불확실한 표현: "아마도", "~할 수도 있습니다"
- 기술 전문 용어: API, Webhook, Cron Job
- 과도한 느낌표 사용
- 수동태: "DM이 발송됩니다"

### 5.3 상황별 메시지 톤

#### 성공 메시지
```
트리거가 활성화되었습니다!
이제 댓글에 "[키워드]"가 포함되면 자동으로 DM이 발송됩니다.
```

#### 에러 메시지
```
앗, 트리거 저장에 실패했습니다.
Instagram 포스트 URL을 다시 확인해주세요.
```

#### 안내 메시지
```
첫 트리거 설정은 3분이면 충분합니다.
도움이 필요하면 언제든 문의해주세요!
```

---

## 6. UI 컴포넌트 가이드

### 6.1 CTA 버튼

#### Primary CTA
```tsx
<Button size="lg" className="bg-gradient-to-r from-[#F58529] via-[#DD2A7B] to-[#8134AF] hover:opacity-90 text-white">
  무료로 시작하기
</Button>
```
- 용도: 주요 액션 (회원가입, 트리거 생성)
- 색상: Instagram 그라데이션
- 사이즈: Large (h-11, px-8)

#### CTA 문구 가이드
| 위치 | 문구 | 의도 |
|------|------|------|
| 랜딩 히어로 | "무료로 시작하기" | 진입 장벽 제거 |
| 랜딩 하단 | "지금 바로 자동화하기" | 즉각 행동 유도 |
| 대시보드 | "트리거 만들기" | 구체적 행동 |
| 온보딩 | "첫 트리거 만들기" | 친근한 안내 |

### 6.2 카드

```tsx
<Card>
  <CardHeader>
    <Icon className="mb-2 h-8 w-8 text-[#DD2A7B]" />
    <CardTitle>제목</CardTitle>
    <CardDescription>설명</CardDescription>
  </CardHeader>
  <CardContent>
    <ul className="space-y-2">
      <li className="flex items-center gap-2">
        <CheckCircle className="h-4 w-4 text-green-500" />
        항목 내용
      </li>
    </ul>
  </CardContent>
</Card>
```

### 6.3 배지

| 상태 | 스타일 | 용도 |
|------|--------|------|
| 활성 | `bg-green-500 text-white` | 활성화된 트리거 |
| 비활성 | `bg-gray-500 text-white` | 비활성화된 트리거 |
| 성공 | `text-green-600` | 발송 성공 |
| 실패 | `text-red-600` | 발송 실패 |

---

## 7. 핵심 메시징 기둥

브랜드 커뮤니케이션의 3가지 핵심 기둥:

### 기둥 1: 즉시 반응하는 자동화
**헤드라인**: "댓글이 달리면, DM이 날아갑니다"

**지원 포인트**:
- 키워드 감지 즉시 자동 DM 발송
- 24/7 무중단 모니터링 시스템
- 수동 응답 대비 20배 빠른 반응

**아이콘**: Zap (번개)

### 기둥 2: 복잡하지 않은 간편함
**헤드라인**: "설정 3분, 효과는 평생"

**지원 포인트**:
- Instagram 포스트 URL 입력만으로 시작
- 키워드와 메시지만 입력하면 완료
- 코딩/기술 지식 불필요

**아이콘**: Settings (설정)

### 기둥 3: 데이터로 보는 성과
**헤드라인**: "감이 아닌, 숫자로 확인하세요"

**지원 포인트**:
- 실시간 발송 통계 대시보드
- 트리거별 성과 비교 분석
- 전송 성공/실패 이력 추적

**아이콘**: BarChart (차트)

---

## 8. 디자인 원칙

### 8.1 시각적 원칙

1. **에너지와 속도감**
   - Instagram 그라데이션으로 활기 표현
   - 번개 모티프로 즉각성 강조
   - 부드러운 애니메이션으로 역동성

2. **명확성과 신뢰**
   - 깔끔한 카드 기반 레이아웃
   - 명확한 시각적 계층 구조
   - 데이터 시각화로 투명성 제공

3. **접근성과 사용성**
   - 직관적인 인터페이스
   - 충분한 터치 타겟 (최소 44x44px)
   - 고대비 색상 사용

### 8.2 레이아웃 원칙

- **콘텐츠 최대 너비**: 1200px (container)
- **패딩**: 16px (모바일), 24px (태블릿), 32px (데스크톱)
- **그리드**: 모바일 1열, 태블릿 2열, 데스크톱 3-4열
- **카드 간격**: 32px (gap-8)
- **섹션 간격**: 80px (py-20)

---

## 9. 적용 체크리스트

### 랜딩 페이지
- [x] 히어로에 로고, 슬로건, 헤드라인 배치
- [x] "Auto + Instagram = Autogram" 그라데이션 적용
- [x] 3가지 핵심 메시징 기둥 반영
- [x] CTA 버튼 Instagram 그라데이션 적용
- [x] Feature 아이콘 핑크 색상 (#DD2A7B) 적용
- [x] 하단 CTA 문구 차별화 ("지금 바로 자동화하기")

### 인증 페이지
- [x] 로고 64x64 사이즈로 배치
- [x] 브랜드명 "Autogram" 표시
- [x] 일관된 폼 스타일 적용

### 대시보드
- [ ] 통계 카드에 아이콘 색상 통일
- [ ] 트리거 카드 상태 배지 적용
- [ ] 빈 상태 메시지 브랜드 톤 적용

---

## 10. 리소스

### 파일 위치
- 로고: `/web/public/autogram.svg`
- 글로벌 스타일: `/web/app/globals.css`
- 디자인 시스템: `/web/docs/DESIGN_SYSTEM.md`
- 브랜드 메시징: `/docs/brand/messaging/autogram-brand-messaging.md`

### 외부 리소스
- 폰트: [Geist](https://vercel.com/font)
- 아이콘: [Lucide Icons](https://lucide.dev/)
- 컴포넌트: [shadcn/ui](https://ui.shadcn.com/)

---

## 문서 정보

- **작성일**: 2026-01-02
- **버전**: 1.0
- **다음 검토일**: 2026-04-02 (3개월 후)
- **담당**: Autogram 브랜드팀
