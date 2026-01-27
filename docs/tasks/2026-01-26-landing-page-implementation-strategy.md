# Cockat 랜딩페이지 구현 전략

## 개요
- **목적**: Cockat 앱 다운로드 유도 및 핵심 가치 전달
- **타겟**: 홈바텐딩 입문자, 칵테일 애호가
- **범위**: 별도 웹 프로젝트 (Flutter 앱과 독립)
- **다국어**: 한국어(Primary), 영어(Secondary)
- **예상 소요 기간**: 2-3주 (기획 3일, 디자인 5일, 개발 10일)

## 현재 상태 분석

### 프로젝트 핵심 가치
1. **문제 해결**: 칵테일 입문 장벽 제거 - "집에 있는 재료로 무엇을 만들 수 있을까?"
2. **차별화 요소**:
   - 500+ 칵테일 레시피, 250+ 재료 데이터베이스
   - 상품(술병) 기반 직관적 재료 관리
   - 대체재 정보로 유연한 레시피 활용
   - 비회원도 핵심 기능 체험 가능 (자연스러운 전환 유도)
   - "재료 1개만 더 있으면" 추천으로 구매 유도

### 타겟 사용자 페르소나
- **입문자**: 칵테일을 만들고 싶지만 어디서부터 시작할지 모름
- **홈바텐더**: 집에 술은 있는데 어떤 칵테일을 만들 수 있는지 모름
- **효율 추구자**: 보유 재료를 최대한 활용하고 싶음
- **경험자**: 다양한 레시피를 탐색하고 싶음

### 기존 리소스
- Flutter 앱 (iOS/Android)
- Supabase 백엔드
- 500+ 칵테일 레시피 DB
- 250+ 재료 정보
- 제품 이미지 및 데이터

## 구현 전략

### 1. 기술 스택 추천

#### 추천: Next.js 14 (App Router) + TypeScript
**선정 이유**:
- **SEO 최적화**: React Server Components로 완벽한 SSR 지원
- **성능**: 자동 코드 분할, 이미지 최적화, 빠른 초기 로딩
- **다국어**: next-intl 또는 i18n 라우팅 기본 지원
- **배포**: Vercel 무료 호스팅, 자동 HTTPS, 글로벌 CDN
- **개발 경험**: TypeScript 완벽 지원, Fast Refresh, 강력한 생태계

#### 기술 스택 상세
```yaml
프레임워크: Next.js 14 (App Router)
언어: TypeScript
스타일링: Tailwind CSS + shadcn/ui
애니메이션: Framer Motion
이미지: next/image (자동 최적화)
다국어: next-intl
분석: Google Analytics 4 / Vercel Analytics
배포: Vercel (무료 티어)
```

#### 대안 검토
| 기술 | 장점 | 단점 | 적합도 |
|------|------|------|--------|
| **Astro** | 초경량, 매우 빠름, 간단함 | 인터랙션 제한적, 생태계 작음 | ⭐⭐⭐ |
| **Next.js** | SEO/성능/생태계 우수, 인터랙션 풍부 | 러닝커브, 번들 크기 | ⭐⭐⭐⭐⭐ |
| **Nuxt 3** | Vue 기반, 강력한 SSR | Vue 생태계 선호 시 | ⭐⭐⭐⭐ |
| **HTML+CSS** | 가장 빠름, 단순함 | 유지보수 어려움, 다국어 복잡 | ⭐⭐ |

### 2. 페이지 구성 및 섹션 설계

#### 페이지 구조
```
/ (홈페이지 - 단일 페이지)
├── Hero Section (히어로)
├── Problem-Solution Section (문제-해결)
├── Features Section (핵심 기능)
├── How It Works (사용 방법)
├── Social Proof (사용자 후기/통계)
├── Screenshots Gallery (앱 스크린샷)
├── CTA Section (다운로드 유도)
└── Footer (푸터)

/privacy (개인정보처리방침)
/terms (이용약관)
```

#### 섹션별 상세 설계

##### 1. Hero Section (히어로)
**목표**: 3초 안에 핵심 가치 전달 및 즉시 행동 유도

```
구성:
┌─────────────────────────────────────────────────┐
│  [로고] Cockat                    [언어 전환: 🇰🇷/🇺🇸] │
├─────────────────────────────────────────────────┤
│                                                 │
│              🍸 [앱 스크린샷 3D 모형]              │
│                                                 │
│        집에 있는 술로, 무엇을 만들 수 있을까?        │
│     보유한 재료로 만들 수 있는 칵테일을 찾아보세요    │
│                                                 │
│   [App Store 다운로드]  [Google Play 다운로드]     │
│   500+ 레시피 · 비회원도 사용 가능 · 완전 무료      │
│                                                 │
│                 ↓ 스크롤 유도                     │
└─────────────────────────────────────────────────┘
```

**카피**:
- 헤드라인(KR): "집에 있는 술로, 무엇을 만들 수 있을까?"
- 헤드라인(EN): "What Can You Make With What You Have?"
- 서브헤드(KR): "보유한 재료로 만들 수 있는 칵테일을 찾아보세요. 500+ 레시피, 로그인 없이 바로 시작."
- 서브헤드(EN): "Discover cocktails you can make with ingredients you already have. 500+ recipes, no sign-up required."

**디자인 요소**:
- 그라디언트 배경 (보라-핑크-오렌지, 칵테일 분위기)
- 3D 목업 앱 스크린샷 (회전 애니메이션)
- CTA 버튼 크고 명확하게

##### 2. Problem-Solution Section
**목표**: 사용자의 문제를 공감하고 해결책 제시

```
구성:
┌─────────────────────────────────────────────────┐
│              이런 고민 있으신가요?                 │
├─────────────────────────────────────────────────┤
│  😕 집에 술은 있는데        🤔 칵테일 레시피는       │
│     뭘 만들 수 있을까?          너무 복잡해          │
│                                                 │
│  🛒 재료를 사러 가기엔      📱 앱마다 회원가입       │
│     귀찮고 비용도...            해야 하고...          │
└─────────────────────────────────────────────────┘
         ↓ (전환 애니메이션)
┌─────────────────────────────────────────────────┐
│                Cockat이 해결합니다                │
├─────────────────────────────────────────────────┤
│  ✅ 보유 재료만 선택하면      ✅ 대체재 안내로       │
│     만들 수 있는 칵테일 표시     유연하게 활용        │
│                                                 │
│  ✅ 재료 1개만 더 있으면      ✅ 로그인 없이도       │
│     추천으로 구매 가이드          바로 사용 가능       │
└─────────────────────────────────────────────────┘
```

##### 3. Features Section (핵심 기능)
**목표**: 주요 기능을 시각적으로 명확히 전달

```
구성: 3-4개 핵심 기능 (아이콘 + 제목 + 설명 + 스크린샷)

Feature 1: 🍾 상품 기반 재료 관리
- 제목: "술병으로 바로 찾기"
- 설명: "바코드 스캔 또는 제품명 검색으로 간편하게 보유 재료 등록"
- 스크린샷: 상품 선택 화면

Feature 2: 🔍 스마트 매칭
- 제목: "만들 수 있는 칵테일 자동 매칭"
- 설명: "보유 재료로 만들 수 있는 칵테일과 재료 1개만 더 있으면 만들 수 있는 칵테일 추천"
- 스크린샷: 칵테일 목록 화면

Feature 3: 📝 상세한 레시피
- 제목: "초보자도 쉽게 따라할 수 있는 레시피"
- 설명: "재료, 도구, 만드는 법, 대체 가능한 재료까지 한눈에"
- 스크린샷: 레시피 상세 화면

Feature 4: 🔓 비회원도 OK
- 제목: "로그인 없이 바로 사용"
- 설명: "앱 설치하고 바로 시작. 나중에 로그인하면 데이터 동기화"
- 스크린샷: 비회원 체험 플로우
```

##### 4. How It Works (사용 방법)
**목표**: 3단계 간단한 사용법 제시

```
구성:
┌─────────────────────────────────────────────────┐
│                3단계로 시작하기                    │
├─────────────────────────────────────────────────┤
│  1️⃣ 보유 재료 선택      2️⃣ 칵테일 탐색      3️⃣ 레시피 따라하기  │
│  [이미지]             [이미지]            [이미지]       │
│  바코드 스캔 또는       만들 수 있는          상세 레시피로      │
│  제품명 검색           칵테일 확인           바로 제조         │
└─────────────────────────────────────────────────┘
```

##### 5. Social Proof (신뢰 구축)
**목표**: 사용자 통계 및 후기로 신뢰 구축

```
구성:
┌─────────────────────────────────────────────────┐
│              이미 많은 분들이 사용 중              │
├─────────────────────────────────────────────────┤
│   500+        250+         1,000+               │
│  칵테일 레시피   재료 정보      다운로드 (출시 후)      │
└─────────────────────────────────────────────────┘
│         (선택) 사용자 후기 캐러셀                  │
│  "집에서 칵테일 만들기가 이렇게 쉬울 줄 몰랐어요!"    │
│  - 사용자 A                                      │
└─────────────────────────────────────────────────┘
```

**초기 전략**: 출시 전이므로 사용자 후기는 제외하고 통계만 표시

##### 6. Screenshots Gallery (앱 미리보기)
**목표**: 실제 앱 화면으로 신뢰도 향상

```
구성: 캐러셀 또는 그리드
- 홈 화면
- 재료 선택 화면
- 칵테일 목록 화면
- 레시피 상세 화면
- 즐겨찾기 화면

(각 스크린샷에 짧은 설명 추가)
```

##### 7. CTA Section (최종 전환 유도)
**목표**: 마지막 다운로드 유도

```
구성:
┌─────────────────────────────────────────────────┐
│           지금 바로 시작해보세요                   │
│        완전 무료 · 로그인 없이 사용 가능            │
│                                                 │
│   [App Store 다운로드]  [Google Play 다운로드]     │
└─────────────────────────────────────────────────┘
```

##### 8. Footer
```
구성:
┌─────────────────────────────────────────────────┐
│  Cockat                                         │
│  집에 있는 재료로 칵테일 만들기                     │
│                                                 │
│  정보          법적 정보        SNS               │
│  About        개인정보처리방침   Instagram        │
│  FAQ          이용약관          Twitter          │
│  Contact                      Facebook         │
│                                                 │
│  © 2026 Cockat. All rights reserved.           │
└─────────────────────────────────────────────────┘
```

### 3. 핵심 메시지 및 카피라이팅 방향

#### 메시지 계층 구조
```yaml
핵심 메시지 (Primary):
  KR: "집에 있는 술로, 무엇을 만들 수 있을까?"
  EN: "What Can You Make With What You Have?"

보조 메시지 (Secondary):
  KR: "보유한 재료로 만들 수 있는 칵테일을 찾아보세요"
  EN: "Discover cocktails you can make with ingredients you already have"

지원 메시지 (Supporting):
  - "500+ 칵테일 레시피"
  - "비회원도 사용 가능"
  - "완전 무료"
  - "대체재 안내 포함"
```

#### 톤앤매너
- **친근함**: 전문 바텐더가 아닌 친구처럼
- **실용성**: 현실적인 문제 해결 강조
- **긍정적**: "할 수 있다", "쉽다"는 메시지
- **간결함**: 짧고 명확한 문장

#### 카피 원칙
1. **베네핏 중심**: 기능이 아닌 사용자 이득 강조
   - ❌ "500개 레시피 제공"
   - ✅ "500+ 레시피로 매일 새로운 칵테일 도전"

2. **행동 유도**: 명확한 CTA
   - "지금 다운로드"
   - "무료로 시작하기"
   - "바로 시작해보세요"

3. **신뢰 구축**: 구체적인 숫자 및 증거
   - "500+ 칵테일"
   - "250+ 재료"
   - "로그인 없이 사용 가능"

### 4. 디자인 컨셉 및 톤앤매너

#### 비주얼 아이덴티티
```yaml
컬러 팔레트:
  Primary:
    - Purple (#8B5CF6) - 우아함, 프리미엄
    - Pink (#EC4899) - 활력, 친근함
  Secondary:
    - Orange (#F59E0B) - 에너지, 창의성
    - Teal (#14B8A6) - 신선함, 신뢰
  Neutral:
    - Dark (#1F2937) - 텍스트
    - Gray (#6B7280) - 보조 텍스트
    - Light (#F9FAFB) - 배경

타이포그래피:
  헤드라인: Inter/Pretendard Bold (700)
  본문: Inter/Pretendard Regular (400)
  크기:
    - H1: 48px (모바일 32px)
    - H2: 36px (모바일 24px)
    - Body: 18px (모바일 16px)

아이콘:
  - Lucide Icons (일관된 선 굵기)
  - 커스텀 칵테일 아이콘

이미지 스타일:
  - 앱 스크린샷: 3D 목업, 그림자 효과
  - 배경: 그라디언트 블러, 글래스모피즘
  - 사진: 고품질 칵테일 이미지 (Unsplash)
```

#### 레이아웃 원칙
- **모바일 퍼스트**: 반응형 디자인
- **화이트스페이스**: 여백을 통한 가독성 확보
- **계층 구조**: 크기/색상/간격으로 중요도 표현
- **일관성**: 섹션별 동일한 패딩/마진

#### 인터랙션
```yaml
애니메이션:
  - 스크롤 트리거 페이드인 (Framer Motion)
  - 호버 효과 (버튼 확대, 그림자)
  - 스크린샷 캐러셀 (자동 재생 + 드래그)

마이크로인터랙션:
  - CTA 버튼 호버 시 화살표 애니메이션
  - 다운로드 버튼 클릭 시 체크마크 표시
  - 언어 전환 플립 애니메이션

성능:
  - 초기 로딩 < 3초
  - Lighthouse 점수 > 90점
```

### 5. SEO 및 마케팅 고려사항

#### SEO 전략
```yaml
메타 태그:
  title: "Cockat - 집에 있는 재료로 칵테일 만들기 | 홈바텐딩 레시피 앱"
  description: "보유한 재료로 만들 수 있는 칵테일을 찾아보세요. 500+ 레시피, 대체재 안내, 비회원도 무료 사용 가능. iOS/Android 다운로드."
  keywords: "칵테일, 홈바텐딩, 레시피, 칵테일 앱, 칵테일 만들기, 재료 기반 검색"

Open Graph (소셜 공유):
  og:title: "Cockat - 집에 있는 재료로 칵테일 만들기"
  og:description: "500+ 칵테일 레시피, 비회원도 사용 가능"
  og:image: "/og-image.png" (1200x630)
  og:type: "website"

Schema.org (구조화 데이터):
  - MobileApplication
  - SoftwareApplication
  - AggregateRating (출시 후 추가)
```

#### 기술적 SEO
```typescript
// next.config.js
export default {
  i18n: {
    locales: ['ko', 'en'],
    defaultLocale: 'ko',
  },
  images: {
    formats: ['image/webp', 'image/avif'],
    deviceSizes: [640, 750, 828, 1080, 1200],
  },
}

// robots.txt
User-agent: *
Allow: /
Sitemap: https://cockat.app/sitemap.xml

// sitemap.xml 자동 생성
```

#### 마케팅 채널
```yaml
초기 트래픽 소스:
  1. Product Hunt 런칭
  2. Reddit (/r/cocktails, /r/homebrewing)
  3. Facebook 칵테일 커뮤니티
  4. Instagram 해시태그 (#홈바텐딩, #칵테일레시피)
  5. 네이버 카페/블로그 (칵테일 관련)

콘텐츠 마케팅:
  - 블로그: "초보자를 위한 홈바텐딩 시작 가이드"
  - 유튜브: 앱 사용법 튜토리얼
  - 인스타그램: 레시피 짧은 영상

측정 지표:
  - 페이지 뷰
  - 다운로드 버튼 클릭률 (CTR)
  - App Store/Play Store 전환율
  - 체류 시간
  - 이탈률 (Bounce Rate)
```

#### 분석 도구
```typescript
// Google Analytics 4
// app/layout.tsx
import { GoogleAnalytics } from '@next/third-parties/google'

export default function RootLayout({ children }) {
  return (
    <html>
      <body>{children}</body>
      <GoogleAnalytics gaId="G-XXXXXXXXXX" />
    </html>
  )
}

// 이벤트 트래킹
const trackDownloadClick = (platform: 'ios' | 'android') => {
  gtag('event', 'download_click', {
    platform,
    location: 'hero_section',
  })
}
```

### 6. 개발 단계별 계획

#### Phase 1: 기획 및 준비 (3일)
```yaml
Day 1: 기획 확정
  - 와이어프레임 작성 (Figma)
  - 카피라이팅 초안
  - 기술 스택 최종 결정

Day 2: 디자인 시스템
  - 컬러 팔레트 확정
  - 타이포그래피 설정
  - 아이콘/이미지 리소스 수집

Day 3: 콘텐츠 준비
  - 최종 카피라이팅
  - 앱 스크린샷 캡처/편집
  - 이미지 최적화
```

#### Phase 2: 프로젝트 설정 (1일)
```bash
# Next.js 프로젝트 생성
npx create-next-app@latest cockat-landing --typescript --tailwind --app

# 패키지 설치
npm install framer-motion next-intl class-variance-authority clsx tailwind-merge
npm install -D @types/node

# shadcn/ui 초기화
npx shadcn-ui@latest init

# 폴더 구조
cockat-landing/
├── app/
│   ├── [locale]/
│   │   ├── layout.tsx
│   │   ├── page.tsx
│   │   └── sections/
│   │       ├── Hero.tsx
│   │       ├── ProblemSolution.tsx
│   │       ├── Features.tsx
│   │       ├── HowItWorks.tsx
│   │       ├── SocialProof.tsx
│   │       ├── Screenshots.tsx
│   │       ├── CTA.tsx
│   │       └── Footer.tsx
│   ├── privacy/page.tsx
│   ├── terms/page.tsx
│   └── api/
├── components/
│   ├── ui/ (shadcn)
│   ├── DownloadButton.tsx
│   ├── LanguageSwitch.tsx
│   └── AppMockup.tsx
├── lib/
│   └── utils.ts
├── messages/
│   ├── ko.json
│   └── en.json
├── public/
│   ├── screenshots/
│   ├── app-icon.png
│   └── og-image.png
└── styles/
    └── globals.css
```

#### Phase 3: 컴포넌트 개발 (5일)
```yaml
Day 4: 공통 컴포넌트
  - Layout, Header, Footer
  - DownloadButton (App Store/Play Store)
  - LanguageSwitch
  - SEO 컴포넌트

Day 5-6: 주요 섹션 (1-4)
  - Hero Section
  - Problem-Solution Section
  - Features Section
  - How It Works Section

Day 7-8: 나머지 섹션 및 페이지
  - Social Proof Section
  - Screenshots Gallery
  - CTA Section
  - Privacy Policy 페이지
  - Terms of Service 페이지

Day 9: 다국어 및 애니메이션
  - next-intl 설정
  - Framer Motion 애니메이션 추가
  - 반응형 디자인 점검
```

#### Phase 4: 최적화 및 테스트 (2일)
```yaml
Day 10: 성능 최적화
  - 이미지 최적화 (WebP/AVIF)
  - 번들 크기 최적화
  - Lighthouse 점수 확인 (>90점 목표)
  - Core Web Vitals 개선

Day 11: 크로스브라우저 테스트
  - Chrome, Safari, Firefox, Edge
  - 모바일 (iOS Safari, Chrome Android)
  - 접근성 검사 (WCAG AA)
  - 다국어 동작 확인
```

#### Phase 5: 배포 및 모니터링 (1일)
```yaml
Day 12: 배포
  - Vercel 프로젝트 생성
  - 환경 변수 설정
  - 커스텀 도메인 연결 (cockat.app)
  - SSL 인증서 확인

배포 후:
  - Google Search Console 등록
  - Google Analytics 설정
  - 소셜 미디어 공유 테스트
  - 다운로드 링크 동작 확인
```

#### Phase 6: 마케팅 및 개선 (진행 중)
```yaml
Week 2:
  - Product Hunt 런칭 준비
  - SNS 홍보 포스트 작성
  - 초기 사용자 피드백 수집

Week 3+:
  - A/B 테스트 (CTA 문구, 버튼 위치)
  - 전환율 분석 및 개선
  - SEO 순위 모니터링
  - 콘텐츠 업데이트 (블로그, 튜토리얼)
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 앱 출시 지연으로 랜딩페이지 먼저 공개 | 중간 | "사전 등록" 기능 추가, 이메일 수집 후 출시 알림 |
| 스크린샷 품질 부족 | 높음 | 디자이너 협업 또는 Figma 목업 제작 |
| 다국어 번역 품질 | 중간 | 전문 번역가 검토 또는 네이티브 피드백 |
| SEO 효과 지연 | 낮음 | 초기 유료 광고 병행 (Google Ads, SNS) |
| 모바일 성능 저하 | 중간 | 이미지 lazy loading, 번들 분할, CDN 활용 |
| 접근성 기준 미달 | 낮음 | axe DevTools로 사전 검사, semantic HTML 사용 |

## 테스트 전략

### 기능 테스트
```yaml
다운로드 버튼:
  - App Store 링크 정상 동작 (iOS)
  - Play Store 링크 정상 동작 (Android)
  - 플랫폼 자동 감지 (선택)

언어 전환:
  - 한국어 ↔ 영어 전환
  - URL 라우팅 (/ko, /en)
  - 로컬 스토리지 저장

폼 (Contact/Newsletter):
  - 이메일 유효성 검증
  - 제출 성공/실패 처리
  - reCAPTCHA (스팸 방지)
```

### 성능 테스트
```yaml
Lighthouse 목표:
  - Performance: >90
  - Accessibility: >95
  - Best Practices: >90
  - SEO: >95

Core Web Vitals:
  - LCP (Largest Contentful Paint): <2.5s
  - FID (First Input Delay): <100ms
  - CLS (Cumulative Layout Shift): <0.1

페이지 크기:
  - 초기 번들: <200KB (gzipped)
  - 총 페이지 크기: <1MB
```

### 크로스브라우저 테스트
```yaml
데스크톱:
  - Chrome (최신)
  - Safari (최신)
  - Firefox (최신)
  - Edge (최신)

모바일:
  - iOS Safari (14+)
  - Chrome Android (최신)
  - Samsung Internet (최신)

반응형:
  - 모바일: 375px - 767px
  - 태블릿: 768px - 1023px
  - 데스크톱: 1024px+
```

### 접근성 테스트
```yaml
도구:
  - axe DevTools
  - WAVE
  - Lighthouse Accessibility

기준:
  - WCAG 2.1 AA 준수
  - 키보드 네비게이션 지원
  - 스크린 리더 호환 (NVDA, VoiceOver)
  - 색상 대비 4.5:1 이상
```

## 성공 기준

### 기술적 기준
- [ ] Lighthouse 점수 모두 90점 이상
- [ ] Core Web Vitals 모두 Green 상태
- [ ] 모든 주요 브라우저에서 정상 작동
- [ ] WCAG 2.1 AA 접근성 준수
- [ ] 다국어 (한/영) 완벽 동작

### 비즈니스 기준
- [ ] 랜딩페이지 → 다운로드 전환율 >5% (첫 달)
- [ ] 페이지 평균 체류 시간 >1분
- [ ] 이탈률 <60%
- [ ] 모바일 트래픽 비율 >70%

### 콘텐츠 기준
- [ ] 핵심 가치가 3초 안에 전달
- [ ] 모든 CTA 버튼이 명확하게 보임
- [ ] 앱 스크린샷이 선명하고 매력적
- [ ] 카피가 간결하고 이해하기 쉬움

## 참고 자료

### 디자인 영감
- [Notion 랜딩페이지](https://notion.so)
- [Linear 랜딩페이지](https://linear.app)
- [Duolingo 랜딩페이지](https://duolingo.com)
- [Headspace 랜딩페이지](https://headspace.com)

### 기술 문서
- [Next.js Documentation](https://nextjs.org/docs)
- [Tailwind CSS](https://tailwindcss.com/docs)
- [Framer Motion](https://www.framer.com/motion/)
- [next-intl](https://next-intl-docs.vercel.app/)
- [shadcn/ui](https://ui.shadcn.com/)

### SEO 가이드
- [Google Search Essentials](https://developers.google.com/search/docs/essentials)
- [Vercel SEO Guide](https://nextjs.org/learn/seo/introduction-to-seo)

### 분석 도구
- [Google Analytics 4](https://analytics.google.com/)
- [Vercel Analytics](https://vercel.com/analytics)
- [Google Search Console](https://search.google.com/search-console)

## 다음 단계

1. **즉시 시작**: 와이어프레임 작성 (Figma/Excalidraw)
2. **우선순위**: 앱 스크린샷 준비 (고품질 필수)
3. **검토 필요**:
   - App Store/Play Store 링크 (출시 전 사전 등록 페이지?)
   - 도메인 확보 (cockat.app 또는 대안)
   - 브랜드 컬러 최종 확정
4. **의사결정**:
   - 사전 등록 기능 포함 여부
   - 뉴스레터/커뮤니티 기능 추가 여부
   - 초기 마케팅 예산 및 채널

---

**작성일**: 2026-01-26
**작성자**: Claude Code (Strategic Implementation Architect)
**상태**: 전략 수립 완료, 검토 대기
