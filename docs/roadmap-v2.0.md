# Cockat v2.0 Roadmap

Cockat 앱의 차기 버전(v2.0) 기능 개발 로드맵입니다.

## Overview

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                           COCKAT v2.0 FEATURES                               │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                              │
│  [P1] Multiple My Bar        [P2] Custom Cocktails      [P3] Data Quality   │
│  ┌─────────────────────┐     ┌─────────────────────┐    ┌─────────────────┐ │
│  │ 여러 장소의 술 관리  │     │ 나만의 칵테일 레시피 │    │ 데이터 정밀도   │ │
│  │ - 집, 직장, 바 등    │     │ - 레시피 생성/편집   │    │ - 이미지 보완   │ │
│  │ - 장소별 재고 관리   │     │ - 공유 기능         │    │ - 데이터 검증   │ │
│  └─────────────────────┘     └─────────────────────┘    └─────────────────┘ │
│                                                                              │
│  [P4] Base Substitution      [P5] Glass Visualization   [P6] Product Data   │
│  ┌─────────────────────┐     ┌─────────────────────┐    ┌─────────────────┐ │
│  │ 베이스 변경 기능     │     │ 칵테일 잔 시각화    │    │ 상품 데이터 확충│ │
│  │ - 대체 주류 추천     │     │ - Mock 잔 이미지    │    │ - 크롤링/수집   │ │
│  │ - 변형 레시피 생성   │     │ - 레이어드 조합     │    │ - 외부 API 연동 │ │
│  └─────────────────────┘     └─────────────────────┘    └─────────────────┘ │
│                                                                              │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Priority 1: Multiple My Bar (다중 바 관리)

### 개요
일하는 곳이 여러 곳이거나, 소유한 술의 종류가 다른 장소들이 여럿 있는 경우를 위한 기능입니다.

### 사용 시나리오
- 집과 직장에서 각각 다른 술을 보유한 경우
- 바텐더가 여러 매장에서 근무하는 경우
- 친구 집에서 파티할 때 해당 장소의 재고로 칵테일 추천받고 싶은 경우

### 데이터베이스 변경

#### 신규 테이블: `user_bars`
```sql
CREATE TABLE user_bars (
  id TEXT PRIMARY KEY,                    -- UUID or slug
  user_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,                     -- "집", "회사", "친구네" 등
  description TEXT,
  icon TEXT,                              -- emoji or icon name
  is_default BOOLEAN DEFAULT false,       -- 기본 바 설정
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 변경 테이블: `user_products`
```sql
ALTER TABLE user_products
  ADD COLUMN bar_id TEXT REFERENCES user_bars(id);
```

#### 변경 테이블: `user_misc_items`
```sql
ALTER TABLE user_misc_items
  ADD COLUMN bar_id TEXT REFERENCES user_bars(id);
```

### UI/UX 설계

#### 바 선택 UI
```
┌─────────────────────────────────────┐
│  My Bar                    [+] ▼   │
│  ┌─────┐ ┌─────┐ ┌─────┐          │
│  │ 🏠  │ │ 🏢  │ │ 🍸  │          │
│  │ 집  │ │ 회사 │ │ Bar │          │
│  └─────┘ └─────┘ └─────┘          │
│    ●       ○       ○              │
└─────────────────────────────────────┘
```

#### 기능 요구사항
- [ ] 바 생성/수정/삭제
- [ ] 바 간 재료 복사/이동
- [ ] 바 별 칵테일 추천 필터링
- [ ] 기본 바 설정 (앱 시작 시 자동 선택)
- [ ] 바 병합 기능 (모든 바의 재료를 합쳐서 추천)

### 마이그레이션 전략
1. 기존 사용자의 데이터는 "기본 바"로 자동 마이그레이션
2. 바 관련 RLS 정책 추가
3. 하위 호환성 유지 (bar_id가 NULL이면 기본 바로 처리)

---

## Priority 2: Custom Cocktails (나만의 칵테일)

### 개요
사용자가 직접 칵테일 레시피를 생성하고 관리할 수 있는 기능입니다.

### 사용 시나리오
- 자신만의 시그니처 칵테일 레시피 저장
- 기존 칵테일을 변형한 레시피 저장
- 친구에게 레시피 공유

### 데이터베이스 변경

#### 신규 테이블: `user_cocktails`
```sql
CREATE TABLE user_cocktails (
  id TEXT PRIMARY KEY,
  user_id UUID NOT NULL REFERENCES auth.users(id),
  name TEXT NOT NULL,
  name_ko TEXT,
  description TEXT,
  description_ko TEXT,
  instructions TEXT NOT NULL,
  instructions_ko TEXT,
  garnish TEXT,
  garnish_ko TEXT,
  glass TEXT,
  method TEXT,                            -- Stir, Shake, Build 등
  abv NUMERIC,
  tags TEXT[] DEFAULT '{}',
  image_url TEXT,
  is_public BOOLEAN DEFAULT false,        -- 공개 여부
  based_on_cocktail_id TEXT REFERENCES cocktails(id),  -- 원본 칵테일 참조
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

#### 신규 테이블: `user_cocktail_ingredients`
```sql
CREATE TABLE user_cocktail_ingredients (
  id SERIAL PRIMARY KEY,
  user_cocktail_id TEXT NOT NULL REFERENCES user_cocktails(id) ON DELETE CASCADE,
  ingredient_id TEXT REFERENCES ingredients(id),  -- NULL이면 커스텀 재료
  custom_ingredient_name TEXT,                     -- ingredient_id가 NULL일 때 사용
  amount NUMERIC,
  units TEXT,
  sort_order INTEGER DEFAULT 0,
  is_optional BOOLEAN DEFAULT false,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

### UI/UX 설계

#### 레시피 생성 플로우
```
┌─────────────────────────────────────────────────┐
│  새 칵테일 만들기                               │
├─────────────────────────────────────────────────┤
│  칵테일 이름                                    │
│  ┌─────────────────────────────────────────┐   │
│  │ My Sunset Martini                       │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  재료 추가                          [+ 추가]   │
│  ┌─────────────────────────────────────────┐   │
│  │ 🍸 Gin               │ 60ml        [×]  │   │
│  │ 🍊 Orange Juice      │ 30ml        [×]  │   │
│  │ ✨ Custom: Honey Syrup│ 15ml        [×]  │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  만드는 방법                                    │
│  ┌─────────────────────────────────────────┐   │
│  │ Shake with ice and strain...            │   │
│  └─────────────────────────────────────────┘   │
│                                                 │
│  [📷 사진 추가]                                │
│                                                 │
│            [저장]  [공개하기]                   │
└─────────────────────────────────────────────────┘
```

### 기능 요구사항
- [ ] 칵테일 레시피 CRUD
- [ ] 기존 칵테일 기반 변형 생성 ("이 칵테일 변형하기")
- [ ] 커스텀 재료 입력 (DB에 없는 재료)
- [ ] 레시피 사진 업로드
- [ ] 공개/비공개 설정
- [ ] 공개 레시피 검색 및 저장 (Phase 2)

---

## Priority 3: Data Quality (데이터 정밀도 향상)

### 개요
현재 주류 데이터의 신빙성 검증 및 누락된 이미지 보완 작업입니다.

### 현재 상태 분석

#### 데이터 통계
| 테이블 | 총 행 | 이미지 있음 | 이미지 없음 | 비율 |
|--------|-------|------------|------------|------|
| cocktails | 613 | ? | ? | ?% |
| ingredients | 261 | ? | ? | ?% |
| products | 110 | ? | ? | ?% |

### 개선 작업

#### Phase 1: 데이터 감사
- [ ] 이미지 누락 항목 리스트업
- [ ] 데이터 출처별 신뢰도 평가
- [ ] 중복 데이터 탐지
- [ ] 잘못된 분류 확인 (category 검증)

#### Phase 2: 이미지 보완
- [ ] 누락 이미지 수집 (공개 API, 크롤링)
- [ ] 이미지 품질 표준화 (크기, 포맷, 배경)
- [ ] 썸네일 자동 생성 파이프라인

#### Phase 3: 데이터 검증
- [ ] 칵테일 레시피 검증 (실제 레시피와 비교)
- [ ] ABV 값 검증
- [ ] 재료 매핑 검증 (ingredient → products)

### 데이터 소스 후보
- IBA (International Bartenders Association) 공식 레시피
- Difford's Guide
- Liquor.com
- 주류 브랜드 공식 사이트

---

## Priority 4: Base Substitution (베이스 변경)

### 개요
마티니의 베이스를 Gin에서 Vodka로 바꾸는 것처럼, 칵테일의 베이스 주류를 다른 것으로 대체하는 기능입니다.

### 사용 시나리오
- Gin Martini를 Vodka Martini로 변경해서 보기
- 위스키 기반 칵테일을 럼으로 대체할 때 추천받기
- "내가 가진 재료로 이 칵테일을 만들 수 있을까?" 질문에 대체 레시피 제안

### 데이터베이스 변경

#### 확장 테이블: `ingredient_substitutes`
현재 6개 데이터만 있음. 대폭 확장 필요.

```sql
-- 기존 테이블 활용, 데이터 확장
-- 카테고리 내 대체 (gin ↔ vodka, bourbon ↔ rye 등)

-- 대체 관계 유형 추가 (선택적)
ALTER TABLE ingredient_substitutes
  ADD COLUMN substitution_type TEXT DEFAULT 'similar',  -- similar, category, creative
  ADD COLUMN flavor_change TEXT,                         -- "더 드라이함", "스모키함 추가" 등
  ADD COLUMN ratio NUMERIC DEFAULT 1.0;                  -- 대체 비율 (1:1이 아닌 경우)
```

### UI/UX 설계

#### 베이스 변경 UI
```
┌─────────────────────────────────────────────────┐
│  Classic Martini                                │
│  ─────────────────────────────────────────────  │
│  현재 베이스: 🍸 Gin                            │
│                                                 │
│  다른 베이스로 변경:                            │
│  ┌───────────────────────────────────────────┐ │
│  │ 🍸 Vodka     "더 깔끔한 맛"               │ │
│  │ 🥃 Tequila   "시트러스 노트 강조"         │ │
│  └───────────────────────────────────────────┘ │
│                                                 │
│  [변경된 레시피 보기]                           │
└─────────────────────────────────────────────────┘
```

### 기능 요구사항
- [ ] 베이스 재료 자동 탐지 (레시피에서 가장 많은 양의 스피릿)
- [ ] 같은 카테고리 대체재 추천 (spirits 내에서)
- [ ] 대체 시 레시피 자동 조정
- [ ] 변형 레시피 저장 (→ Custom Cocktails 연동)

---

## Priority 5: Glass Visualization (칵테일 잔 시각화)

### 개요
칵테일 잔의 mock 이미지 위에 주류 색상/레이어를 합성하여 칵테일의 시각적 이미지를 동적으로 생성하는 시스템입니다.

### 기술적 접근

#### Option A: SVG 기반 (추천)
```
┌─────────────────────────────────────────────────┐
│  Glass Templates (SVG)                          │
│  ┌─────┐  ┌─────┐  ┌─────┐  ┌─────┐           │
│  │     │  │  ╱  │  │     │  │     │           │
│  │     │  │ ╱   │  │     │  │     │           │
│  │     │  ╱     │  │     │  │     │           │
│  │  ─  │  ─     │  │  ─  │  │  ─  │           │
│  │     │        │  │ ─── │  │ ─── │           │
│  └──┴──┘  └──┴──┘  └──┴──┘  └──┴──┘           │
│  Martini   Highball Coupe   Collins            │
└─────────────────────────────────────────────────┘
```

#### 레이어 구조
```
┌─────────────────────┐
│   Garnish Layer     │  ← 가니시 (올리브, 체리 등)
├─────────────────────┤
│   Glass Rim         │  ← 잔 테두리
├─────────────────────┤
│   Liquid Layer 1    │  ← 상층 (Float)
│   Liquid Layer 2    │  ← 중층
│   Liquid Layer 3    │  ← 하층
├─────────────────────┤
│   Ice Layer         │  ← 얼음
├─────────────────────┤
│   Glass Base        │  ← 잔 기본 형태
└─────────────────────┘
```

### 데이터베이스 변경

#### 신규 테이블: `glass_templates`
```sql
CREATE TABLE glass_templates (
  id TEXT PRIMARY KEY,           -- "martini", "highball" 등
  name TEXT NOT NULL,
  svg_template TEXT NOT NULL,    -- SVG 템플릿 코드
  capacity_ml INTEGER,
  sort_order INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT now()
);
```

#### 확장: `ingredients` 테이블
```sql
ALTER TABLE ingredients
  ADD COLUMN color TEXT,              -- hex color code
  ADD COLUMN opacity NUMERIC DEFAULT 1.0,
  ADD COLUMN layer_behavior TEXT;     -- 'float', 'sink', 'mix'
```

### 기능 요구사항
- [ ] 8종 기본 잔 템플릿 (Martini, Highball, Old Fashioned, Collins, Coupe, Flute, Hurricane, Rocks)
- [ ] 재료 색상 데이터 정제
- [ ] 레이어 시뮬레이션 (밀도 기반)
- [ ] 가니시 오버레이
- [ ] 얼음 효과

### 기술 스택 고려
- React Native SVG 라이브러리
- 색상 블렌딩 알고리즘
- 캐싱 전략 (생성된 이미지)

---

## Priority 6: Product Data Expansion (상품 데이터 확충)

### 개요
현재 110개의 상품 데이터를 대폭 확장합니다.

### 현재 상태
```
products: 110 rows
├── spirits: ~40개 (예상)
├── liqueurs: ~30개 (예상)
├── bitters: ~10개 (예상)
└── mixers/others: ~30개 (예상)
```

### 목표
```
products: 500+ rows
├── spirits: 150개 (주요 브랜드별 제품)
├── liqueurs: 100개
├── bitters: 30개
├── mixers: 50개
├── syrups: 30개
└── others: 140개
```

### 데이터 수집 전략

#### Option A: 공개 API 활용
- Open Food Facts API
- UPC Database
- 주류 전문 API (TheBar, Difford's 등)

#### Option B: 크롤링
- 주요 주류 온라인 샵
- 브랜드 공식 사이트
- 주류 리뷰 사이트

#### Option C: 수동 입력 + 커뮤니티
- 관리자 대시보드로 수동 입력
- 사용자 제보 시스템

### 데이터 필드 우선순위
1. **필수**: name, ingredient_id, brand
2. **중요**: image_url, abv, volume_ml, country
3. **선택**: barcode, description, external_id

### 마이그레이션 계획
- [ ] 데이터 수집 스크립트 작성
- [ ] 중복 감지 로직 구현
- [ ] ingredient_id 자동 매핑 로직
- [ ] 이미지 다운로드 및 저장

---

## Implementation Timeline

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Phase 1 (Foundation)                                                        │
│  ├── P3: Data Quality - 데이터 감사 및 이미지 보완                           │
│  └── P6: Product Data - 상품 데이터 확충                                     │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 2 (Core Features)                                                     │
│  ├── P1: Multiple My Bar - DB 변경 및 기본 UI                                │
│  └── P2: Custom Cocktails - 레시피 CRUD                                      │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 3 (Enhancement)                                                       │
│  ├── P4: Base Substitution - 베이스 변경 로직                                │
│  └── P5: Glass Visualization - SVG 기반 시각화                               │
├─────────────────────────────────────────────────────────────────────────────┤
│  Phase 4 (Polish)                                                            │
│  ├── 공개 레시피 검색/공유                                                    │
│  └── 커뮤니티 기능                                                           │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Technical Considerations

### Breaking Changes
- `user_products.bar_id` 추가로 인한 쿼리 변경
- 기존 RLS 정책 업데이트 필요

### Migration Strategy
- 모든 변경은 backward-compatible하게 진행
- Feature flag로 새 기능 점진적 롤아웃
- 데이터 마이그레이션은 별도 스크립트로 처리

### Performance Considerations
- Glass Visualization: 클라이언트 사이드 렌더링 vs 서버 사이드 생성
- Custom Cocktails: 인덱스 추가 필요 (`user_id`, `is_public`)
- Product Data: 검색 성능을 위한 Full-text search 고려

---

## Open Questions

1. **Multiple My Bar**: 바 간 재료 동기화가 필요한가? (같은 제품을 여러 바에 추가)
2. **Custom Cocktails**: 공개 레시피의 저작권/라이선스 정책?
3. **Glass Visualization**: 실제 사진 vs SVG 생성 이미지 중 사용자 선호도?
4. **Data Quality**: 데이터 검증의 자동화 수준? (AI 활용 가능성)

---

## References

- [Database Schema](./database-schema.md)
- [User Experience Design](./user-experience-design.md)
