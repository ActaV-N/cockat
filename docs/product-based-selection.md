# 상품 기반 재료 선택 기능 개선안

## 문제 정의

### 현재 상태
- 사용자가 **재료 종류**(Tequila, Vodka 등)를 선택
- 실제 바/레스토랑에서는 특정 **상품**(El Jimador Reposado, Absolut Vodka 등)을 보유

### 문제점
1. 술병을 보고 "이게 무슨 종류의 술인지" 모르는 경우가 많음
2. 같은 종류라도 상품마다 특성이 다름 (예: 데킬라 블랑코 vs 레포사도)
3. 보유 상품을 직관적으로 관리하기 어려움

### 목표
- 사용자가 **실제 보유한 술병/상품**을 선택
- 앱이 해당 상품의 **재료 종류를 자동 매핑**
- **상품 이미지**로 시각적 식별 지원

---

## 데이터 모델 변경

### 새로운 테이블: `products`

```sql
CREATE TABLE products (
  id TEXT PRIMARY KEY,                    -- 'el-jimador-reposado'
  name TEXT NOT NULL,                     -- 'El Jimador Reposado'
  brand TEXT,                             -- 'El Jimador'
  ingredient_id TEXT REFERENCES ingredients(id),  -- 'tequila-reposado'

  -- 상품 정보
  description TEXT,
  country TEXT,                           -- 'Mexico'
  volume_ml INT,                          -- 750
  abv DECIMAL(5,2),                       -- 40.0

  -- 이미지
  image_url TEXT,                         -- 병 이미지 URL
  thumbnail_url TEXT,                     -- 썸네일

  -- 메타데이터
  barcode TEXT,                           -- UPC/EAN 바코드
  external_id TEXT,                       -- 외부 DB 참조 ID
  data_source TEXT,                       -- 'manual', 'openfoodfacts', 'user'

  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 인덱스
CREATE INDEX idx_products_ingredient ON products(ingredient_id);
CREATE INDEX idx_products_brand ON products(brand);
CREATE INDEX idx_products_barcode ON products(barcode);
```

### 수정: `user_ingredients` → `user_products`

```sql
-- 기존: 사용자가 재료 종류를 선택
-- 변경: 사용자가 상품을 선택

CREATE TABLE user_products (
  id SERIAL PRIMARY KEY,
  user_id UUID NOT NULL,
  product_id TEXT NOT NULL REFERENCES products(id),

  -- 선택적: 수량/메모
  quantity INT DEFAULT 1,
  note TEXT,

  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);
```

### 관계도

```
products (상품)
    │
    ├── ingredient_id ──→ ingredients (재료 종류)
    │                          │
    │                          └──→ cocktail_ingredients
    │                                      │
    │                                      └──→ cocktails
    │
    └── user_products (사용자 보유 상품)
            │
            └── user_id ──→ users
```

---

## 상품 데이터 소스

### 1. Open Food Facts (추천)
- **URL**: https://world.openfoodfacts.org/
- **장점**:
  - 무료, 오픈소스 (ODBL 라이선스)
  - 바코드 기반 검색 가능
  - 이미지 포함
  - API 제공
- **단점**:
  - 주류 데이터가 완전하지 않음
  - 품질이 일정하지 않음 (크라우드소싱)
- **API 예시**:
  ```
  GET https://world.openfoodfacts.org/api/v0/product/{barcode}.json
  ```

### 2. UPC Item DB
- **URL**: https://www.upcitemdb.com/
- **장점**: 바코드 데이터베이스, API 제공
- **단점**: 유료 (월 100건 무료)

### 3. 수동 크롤링/큐레이션
- **대상 사이트**:
  - Drizly (미국)
  - Master of Malt (영국)
  - Wine-Searcher
  - 데일리샷, 와인앤모어 (한국)
- **주의**: 이용약관 확인 필요, 이미지 저작권 이슈

### 4. 사용자 기여 (User-Generated)
- 바코드 스캔 → 정보 없으면 사용자가 입력
- 커뮤니티 검증 시스템

### 추천 전략
```
1순위: Open Food Facts API (바코드 스캔)
2순위: 사전 큐레이션된 인기 상품 DB
3순위: 사용자 직접 입력 (이미지 업로드)
```

---

## 이미지 처리

### 이미지 소스
1. **Open Food Facts**: 제품 이미지 직접 제공
2. **사용자 업로드**: Supabase Storage 활용
3. **큐레이션**: 공개 이미지 수집 및 저장

### Supabase Storage 설정

```sql
-- 스토리지 버킷 생성 (Supabase 대시보드 또는 SQL)
INSERT INTO storage.buckets (id, name, public)
VALUES ('product-images', 'product-images', true);

-- 공개 읽기 정책
CREATE POLICY "Public read access"
ON storage.objects FOR SELECT
USING (bucket_id = 'product-images');

-- 인증된 사용자 업로드
CREATE POLICY "Authenticated upload"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'product-images'
  AND auth.role() = 'authenticated'
);
```

### 이미지 URL 구조
```
// Supabase Storage
https://{project}.supabase.co/storage/v1/object/public/product-images/{product-id}.jpg

// Open Food Facts
https://images.openfoodfacts.org/images/products/{barcode}/front_en.jpg
```

### Flutter 이미지 처리
```dart
// cached_network_image 패키지 사용
CachedNetworkImage(
  imageUrl: product.imageUrl,
  placeholder: (context, url) => Shimmer(...),
  errorWidget: (context, url, error) => Icon(Icons.liquor),
)
```

---

## 바코드 스캔 기능

### 패키지
```yaml
dependencies:
  mobile_scanner: ^5.2.3  # 카메라 바코드 스캔
```

### 플로우
```
1. 사용자가 "상품 추가" 버튼 탭
2. 카메라로 바코드 스캔
3. Open Food Facts API 조회
   ├─ 있음 → 상품 정보 표시 → 재료 종류 매핑 확인 → 저장
   └─ 없음 → 수동 입력 화면 (이름, 종류 선택, 사진 촬영)
4. user_products에 저장
```

---

## UI/UX 변경사항

### 1. 홈 화면
```
기존: "내 재료" (Vodka, Gin, Lime Juice...)
변경: "내 술장" / "My Bar" (Absolut Vodka, Tanqueray Gin...)
       - 병 이미지 그리드 표시
       - 빈 상태: "바코드를 스캔하거나 상품을 검색하세요"
```

### 2. 상품 추가 화면
```
┌─────────────────────────────┐
│  [바코드 스캔]  [검색]  [직접 입력]  │
├─────────────────────────────┤
│                             │
│  최근 추가된 상품            │
│  ┌─────┐ ┌─────┐ ┌─────┐   │
│  │ 🍾  │ │ 🍾  │ │ 🍾  │   │
│  │Abs..│ │Tan..│ │Bac..│   │
│  └─────┘ └─────┘ └─────┘   │
│                             │
│  인기 상품                   │
│  ...                        │
└─────────────────────────────┘
```

### 3. 상품 상세/추가 화면
```
┌─────────────────────────────┐
│        [병 이미지]           │
│                             │
│  El Jimador Reposado        │
│  브랜드: El Jimador          │
│  종류: Tequila Reposado ←── 자동 매핑됨
│  도수: 40%                   │
│  용량: 750ml                 │
│                             │
│  [내 술장에 추가]            │
└─────────────────────────────┘
```

### 4. 칵테일 매칭 로직 변경
```
기존:
  user_ingredients → ingredients → cocktail_ingredients

변경:
  user_products → products.ingredient_id → ingredients → cocktail_ingredients
```

---

## 구현 단계

### Phase 1: 데이터 모델 (1-2일)
- [ ] `products` 테이블 생성
- [ ] `user_products` 테이블 생성 (기존 `user_ingredients` 대체 또는 병행)
- [ ] 인기 상품 50-100개 시드 데이터

### Phase 2: 백엔드 연동 (1-2일)
- [ ] Product 모델 클래스 생성
- [ ] ProductProvider 구현
- [ ] 칵테일 매칭 로직 수정

### Phase 3: 바코드/검색 (2-3일)
- [ ] Open Food Facts API 연동
- [ ] mobile_scanner 패키지 통합
- [ ] 상품 검색 기능

### Phase 4: UI 구현 (2-3일)
- [ ] 상품 그리드 화면
- [ ] 바코드 스캔 화면
- [ ] 상품 상세/추가 화면
- [ ] 이미지 캐싱 및 플레이스홀더

### Phase 5: 이미지 처리 (1-2일)
- [ ] Supabase Storage 설정
- [ ] 이미지 업로드 기능
- [ ] 이미지 최적화 (리사이즈, 압축)

---

## 마이그레이션 고려사항

### 기존 사용자 데이터
```sql
-- user_ingredients → user_products 마이그레이션
-- 기존 재료 선택을 "대표 상품"으로 변환

INSERT INTO user_products (user_id, product_id)
SELECT ui.user_id, p.id
FROM user_ingredients ui
JOIN products p ON p.ingredient_id = ui.ingredient_id
WHERE p.is_default = true;  -- 각 재료당 기본 상품 지정
```

### 하위 호환성
- `user_ingredients` 테이블 유지 (deprecated)
- 점진적 마이그레이션 지원
- 재료 직접 선택 옵션 유지 (고급 설정)

---

## 추가 고려사항

### 1. 재료 종류 자동 추천
- 상품명에서 키워드 추출 (NLP)
- 예: "El Jimador Reposado Tequila" → `tequila-reposado`

### 2. 유사 상품 제안
- 보유하지 않은 재료 → "이 상품으로 대체 가능" 제안
- 가격대별 추천

### 3. 상품 리뷰/평점
- 추후 커뮤니티 기능 확장 시 고려

---

## 참고 자료

- [Open Food Facts API](https://openfoodfacts.github.io/openfoodfacts-server/api/)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [mobile_scanner 패키지](https://pub.dev/packages/mobile_scanner)
- [cached_network_image](https://pub.dev/packages/cached_network_image)
