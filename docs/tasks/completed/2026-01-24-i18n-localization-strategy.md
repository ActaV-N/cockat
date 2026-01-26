# 다국어 지원(i18n) 및 현지화 개선 전략

## 개요
- **목적**: Supabase 데이터베이스의 다국어 지원 체계 개선 및 데이터 품질 향상
- **범위**: ingredients, products, cocktails, misc_items 테이블의 한국어 번역 및 구조 최적화
- **예상 소요 기간**: 2-3주 (데이터 번역 포함)
- **우선순위**: High (사용자 경험에 직접적인 영향)

## 현재 상태 분석

### 1. 데이터베이스 현황

#### ingredients 테이블 (260개)
```
✅ 구조: name_ko 컬럼 존재
❌ 데이터: 98% 누락 (255/260개)
⚠️  카테고리 불일치: "Bitters" vs "bitters", "Spirit" vs "spirits", "liqueurs" vs "Liqueur"
⚠️  uncategorized: 215개 (82.7%)
✅ 번역 완료: 5개만 (Vanilla Liqueur, Soju, Tequila 일부)
```

#### misc_items 테이블 (42개)
```
✅ 구조: name_ko 컬럼 존재
✅ 데이터: 100% 완료 (42/42개)
✅ 카테고리: 표준화됨 (bitters, dairy, fresh, garnish, ice, mixer, syrup)
```

#### products 테이블 (99개)
```
❌ 구조: name_ko 컬럼 없음
❌ 데이터: 영어만 존재
⚠️  description: 영어만
```

#### cocktails 테이블 (613개)
```
✅ 구조: name_ko 컬럼 존재
❌ 데이터: 대부분 null
❌ description, instructions: 영어만
```

### 2. 중복 데이터 문제

**ingredients와 misc_items 간 중복:**
- Angostura Bitters (ingredients) ↔ Angostura Bitters (misc_items)
- Cola, Tonic Water, Orange Juice (mixer 카테고리 중복)
- Bitters, Juice 카테고리 겹침

**영향:**
- 사용자 혼란 (어느 테이블에서 선택해야 하는지 불명확)
- 데이터 일관성 문제
- 칵테일 매칭 로직 복잡도 증가

### 3. Flutter 앱 현황

**긍정적:**
- ✅ Flutter l10n 시스템 구현됨 (app_en.arb, app_ko.arb)
- ✅ Locale-aware 모델 메서드 존재 (`getLocalizedName(locale)`)
- ✅ user_preferences.locale 컬럼 존재

**개선 필요:**
- ⚠️ 데이터베이스 데이터 번역 누락
- ⚠️ Product 모델에 localization 메서드 없음
- ⚠️ Cocktail 상세 정보 (instructions, description) 번역 없음

## 아키텍처 설계

### 옵션 A: 컬럼 기반 접근법 (권장)

**구조:**
```sql
-- 각 테이블에 언어별 컬럼 추가
ALTER TABLE products ADD COLUMN name_ko TEXT;
ALTER TABLE products ADD COLUMN description_ko TEXT;

ALTER TABLE cocktails ADD COLUMN description_ko TEXT;
ALTER TABLE cocktails ADD COLUMN instructions_ko TEXT;
ALTER TABLE cocktails ADD COLUMN garnish_ko TEXT;
```

**장점:**
- ✅ 간단한 쿼리 (JOIN 불필요)
- ✅ 빠른 성능
- ✅ 기존 코드와 일관성 유지
- ✅ 오프라인 지원 용이
- ✅ Flutter 모델과 직접 매핑

**단점:**
- ❌ 새 언어 추가 시 스키마 변경 필요
- ❌ 컬럼 수 증가 (3개 언어 = 3배)
- ❌ NULL 값 많을 경우 공간 낭비

**적합성:**
- 소규모 앱 (2-3개 언어)
- 빠른 구현 필요
- 오프라인 우선 앱
- **→ Cockat에 최적**

### 옵션 B: 별도 번역 테이블

**구조:**
```sql
CREATE TABLE translations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  table_name TEXT NOT NULL,
  record_id TEXT NOT NULL,
  field_name TEXT NOT NULL,
  locale TEXT NOT NULL,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(table_name, record_id, field_name, locale)
);

-- 인덱스
CREATE INDEX idx_translations_lookup
ON translations(table_name, record_id, locale);
```

**장점:**
- ✅ 새 언어 추가가 쉬움 (스키마 변경 불필요)
- ✅ 언어별 번역 진행 상황 추적 용이
- ✅ 번역 이력 관리 가능
- ✅ 확장성 우수 (10개 이상 언어)

**단점:**
- ❌ 복잡한 JOIN 쿼리 필요
- ❌ 성능 오버헤드
- ❌ 캐싱 전략 필요
- ❌ 오프라인 지원 복잡

**적합성:**
- 대규모 앱 (5개 이상 언어)
- 번역 관리 시스템 필요
- CMS 기반 번역 워크플로우

### 권장 사항: 옵션 A (컬럼 기반)

**이유:**
1. Cockat은 현재 2개 언어 (en, ko) 지원
2. 향후 일본어(ja) 추가 가능성만 있음 (3개 최대)
3. 기존 코드 패턴과 일관성 (ingredients, misc_items 이미 사용 중)
4. 모바일 앱 특성상 성능 우선
5. 오프라인 지원 중요

## 데이터 중복 해결 방안

### 전략: 테이블 역할 명확화

**ingredients 테이블:**
- **역할**: 칵테일 레시피의 주재료 (base spirits, liqueurs, wines)
- **범위**: 알코올 음료 및 핵심 재료 (ABV > 0 또는 주요 맛 구성요소)
- **예시**: Gin, Vodka, Triple Sec, Vermouth, Campari

**misc_items 테이블:**
- **역할**: 보조 재료 및 소모품
- **범위**: 얼음, 가니쉬, 신선한 재료, 믹서, 시럽
- **예시**: Ice, Lemon, Sugar, Tonic Water, Simple Syrup

**products 테이블:**
- **역할**: 실제 구매 가능한 상품 (브랜드별)
- **관계**: ingredient_id로 ingredients와 연결
- **예시**: Bombay Sapphire Gin → Gin (ingredient)

### 중복 데이터 정리 계획

**Step 1: 중복 식별**
```sql
-- 중복 찾기
SELECT i.name, m.name
FROM ingredients i
JOIN misc_items m ON LOWER(i.name) = LOWER(m.name);
```

**Step 2: 카테고리별 분류 규칙**

| 항목 | ingredients | misc_items | 비고 |
|------|------------|-----------|------|
| Angostura Bitters | ✅ 유지 | ❌ 삭제 | 핵심 재료 |
| Orange Bitters | ✅ 유지 | ❌ 삭제 | 핵심 재료 |
| Orange Juice | ❌ 삭제 | ✅ 유지 | 신선한 재료 |
| Simple Syrup | ❌ 삭제 | ✅ 유지 | 소모품 |
| Tonic Water | ❌ 삭제 | ✅ 유지 | 믹서 |
| Cola | ❌ 삭제 | ✅ 유지 | 믹서 |

**Step 3: 데이터 마이그레이션**
```sql
-- 1. cocktail_ingredients 업데이트 (misc_items로 이동되는 항목)
UPDATE cocktail_ingredients ci
SET ingredient_id = (SELECT id FROM misc_items WHERE name = ...)
WHERE ingredient_id IN (...);

-- 2. user_ingredients → user_misc_items 마이그레이션
INSERT INTO user_misc_items (user_id, misc_item_id)
SELECT user_id, (SELECT id FROM misc_items WHERE name = ...)
FROM user_ingredients
WHERE ingredient_id IN (...);

-- 3. ingredients에서 삭제
DELETE FROM ingredients WHERE id IN (...);
```

## 카테고리 표준화 방안

### 현재 문제
```
Inconsistent:
- "Bitters" vs "bitters"
- "Spirit" vs "spirits"
- "liqueurs" vs "Liqueur"
- "uncategorized" (215개, 82.7%)
```

### 표준 카테고리 정의

**ingredients 카테고리:**
```yaml
spirits:        # 증류주 (Gin, Vodka, Rum, Whiskey, Tequila, etc.)
liqueurs:       # 리큐르 (Triple Sec, Cointreau, Amaretto, etc.)
wines:          # 와인 및 강화 와인 (Vermouth, Sherry, Port, etc.)
bitters:        # 비터스 (Angostura, Peychaud's, Orange Bitters)
vermouths:      # 베르무트 (Sweet, Dry, Blanc)
fortified_wines: # 강화 와인 (Port, Sherry, Madeira)
```

**misc_items 카테고리:** (이미 표준화됨)
```yaml
ice:     # 얼음
fresh:   # 신선한 재료 (레몬, 라임, 민트 등)
dairy:   # 유제품 (계란, 우유, 크림)
garnish: # 가니쉬 (체리, 올리브, 오렌지 필 등)
mixer:   # 믹서 (토닉워터, 콜라, 주스 등)
syrup:   # 시럽 (심플 시럽, 그레나딘 등)
bitters: # 비터스 (misc_items에서는 삭제 예정)
```

### 카테고리 매핑 전략

**AI 기반 자동 분류:**
```python
def categorize_ingredient(name: str, description: str, strength: float) -> str:
    # 규칙 기반 분류
    if strength is None or strength == 0:
        return 'uncategorized'

    if strength >= 35:
        # Spirits: Gin, Vodka, Whiskey, etc.
        if any(spirit in name.lower() for spirit in ['gin', 'vodka', 'rum', 'whiskey', 'tequila', 'mezcal', 'brandy', 'cognac']):
            return 'spirits'

    if 15 <= strength < 35:
        # Liqueurs
        if any(word in name.lower() for word in ['liqueur', 'amaretto', 'cointreau', 'triple sec', 'schnapps']):
            return 'liqueurs'

    if 10 <= strength < 25:
        # Wines and Fortified Wines
        if any(word in name.lower() for word in ['vermouth', 'wine', 'sherry', 'port', 'madeira']):
            return 'wines'

    # Bitters (usually high strength but small amounts)
    if 'bitters' in name.lower():
        return 'bitters'

    return 'uncategorized'
```

**수동 검토 필요:**
- uncategorized 항목 (215개)
- 애매한 경계선 (strength가 null인 경우)

## 마이그레이션 계획

### Phase 1: 스키마 확장 (1일)

**1.1 products 테이블 컬럼 추가**
```sql
ALTER TABLE products ADD COLUMN name_ko TEXT;
ALTER TABLE products ADD COLUMN description_ko TEXT;
```

**1.2 cocktails 테이블 컬럼 추가**
```sql
ALTER TABLE cocktails ADD COLUMN description_ko TEXT;
ALTER TABLE cocktails ADD COLUMN instructions_ko TEXT;
ALTER TABLE cocktails ADD COLUMN garnish_ko TEXT;
```

**1.3 인덱스 최적화**
```sql
-- 로케일 기반 검색을 위한 인덱스 (선택적)
CREATE INDEX idx_products_name_ko ON products(name_ko) WHERE name_ko IS NOT NULL;
CREATE INDEX idx_ingredients_name_ko ON ingredients(name_ko) WHERE name_ko IS NOT NULL;
```

### Phase 2: 데이터 정리 (3-5일)

**2.1 카테고리 표준화**
```sql
-- 1. 카테고리 소문자 통일
UPDATE ingredients SET category = LOWER(category);

-- 2. 복수형 통일
UPDATE ingredients
SET category = CASE
  WHEN category = 'spirit' THEN 'spirits'
  WHEN category = 'liqueur' THEN 'liqueurs'
  WHEN category IN ('wine', 'fortified wine') THEN 'wines'
  ELSE category
END;

-- 3. uncategorized 재분류 (수동 + AI)
-- Python 스크립트 실행
```

**2.2 중복 데이터 정리**
```sql
-- Migration 스크립트 작성
-- 1. cocktail_ingredients 업데이트
-- 2. user_ingredients → user_misc_items
-- 3. ingredients 삭제
```

### Phase 3: 번역 데이터 입력 (1-2주)

**우선순위:**

**High Priority (1주차):**
1. **misc_items**: ✅ 완료 (42개)
2. **ingredients (핵심 100개)**:
   - 자주 사용되는 spirits: 30개
   - 인기 liqueurs: 20개
   - 필수 wines/vermouths: 15개
   - 주요 bitters: 5개
   - 기타 핵심: 30개

**Medium Priority (2주차):**
3. **products (상위 50개)**:
   - 판매량/사용 빈도 기준
   - 한국 시장 인기 브랜드 우선
4. **cocktails (인기 50개)**:
   - IBA 공식 칵테일
   - 즐겨찾기 상위 칵테일

**Low Priority (추후):**
5. **ingredients (나머지 160개)**
6. **products (나머지 49개)**
7. **cocktails (나머지 563개)**

**번역 방법:**

**Option 1: 반자동 (권장)**
```python
# 1. OpenAI API로 초벌 번역
import openai

def translate_batch(items: list) -> dict:
    prompt = f"""
    다음 칵테일 재료 이름을 한국어로 번역해주세요.
    전문 용어는 음차 표기하되, 일반적인 한국어 표현이 있으면 사용하세요.

    예시:
    - Gin → 진 (또는 드라이 진)
    - Triple Sec → 트리플 섹
    - Angostura Bitters → 앙고스투라 비터스

    Items: {items}

    JSON 형식으로 반환:
    {{"name_en": "name_ko", ...}}
    """

    # OpenAI API 호출
    # 결과 검토 후 적용

# 2. 수동 검토 및 수정
# 3. CSV로 저장 → PostgreSQL COPY 명령으로 일괄 업데이트
```

**Option 2: 수동 번역**
- Google Sheets에서 작업
- 전문가 검토
- CSV export → DB import

### Phase 4: Flutter 앱 연동 (2-3일)

**4.1 모델 업데이트**
```dart
// Product 모델 확장
class Product {
  final String? nameKo;
  final String? descriptionKo;

  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null) {
      return nameKo!;
    }
    return name;
  }

  String? getLocalizedDescription(String locale) {
    if (locale == 'ko' && descriptionKo != null) {
      return descriptionKo;
    }
    return description;
  }
}

// Cocktail 모델 확장
class Cocktail {
  final String? descriptionKo;
  final String? instructionsKo;
  final String? garnishKo;

  String? getLocalizedDescription(String locale) {
    if (locale == 'ko' && descriptionKo != null) {
      return descriptionKo;
    }
    return description;
  }

  String getLocalizedInstructions(String locale) {
    if (locale == 'ko' && instructionsKo != null) {
      return instructionsKo!;
    }
    return instructions;
  }
}
```

**4.2 Provider 업데이트**
```dart
// 현재 locale 가져오기
final localeProvider = Provider<String>((ref) {
  final prefs = ref.watch(userPreferencesDbProvider);
  return prefs.valueOrNull?['locale'] as String? ?? 'en';
});

// 사용 예
final locale = ref.watch(localeProvider);
final localizedName = product.getLocalizedName(locale);
```

**4.3 UI 업데이트**
```dart
// 기존 코드 수정 (예시)
Text(product.name)
  → Text(product.getLocalizedName(locale))

Text(cocktail.description ?? '')
  → Text(cocktail.getLocalizedDescription(locale) ?? '')
```

### Phase 5: 검증 및 배포 (2-3일)

**5.1 데이터 품질 검증**
```sql
-- 번역 누락 확인
SELECT
  'ingredients' as table_name,
  COUNT(*) as total,
  COUNT(name_ko) as translated,
  COUNT(*) - COUNT(name_ko) as missing
FROM ingredients
WHERE category != 'uncategorized'

UNION ALL

SELECT
  'products',
  COUNT(*),
  COUNT(name_ko),
  COUNT(*) - COUNT(name_ko)
FROM products;

-- 예상 결과
-- ingredients: 100/260 (38.5%) → 목표: 100% (uncategorized 제외)
-- products: 50/99 (50.5%) → 목표: 100%
```

**5.2 QA 체크리스트**
- [ ] 모든 핵심 재료 한국어 이름 확인
- [ ] 상품 카드 한국어 표시 확인
- [ ] 칵테일 상세 페이지 한국어 표시 확인
- [ ] 언어 전환 시 즉시 반영 확인
- [ ] 누락된 번역 시 영어 fallback 확인
- [ ] 카테고리 필터 한국어 표시 확인

**5.3 성능 테스트**
- [ ] 데이터 로딩 시간 측정 (before/after)
- [ ] 검색 성능 확인 (한국어/영어)
- [ ] 메모리 사용량 확인

## Flutter 앱 구현 방안

### 1. Locale Provider 구조

**현재 구조:**
```dart
// user_preferences.locale 존재하지만 활용도 낮음
// UnitSystem은 getLocalizedLabel(locale) 구현됨
```

**개선 방안:**
```dart
// 1. Locale을 전역 상태로 관리
final currentLocaleProvider = Provider<String>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final prefs = ref.watch(userPreferencesDbProvider);
    return prefs.valueOrNull?['locale'] as String? ?? 'en';
  } else {
    // 로컬 저장소에서 가져오기
    final prefs = ref.watch(sharedPreferencesProvider);
    return prefs.getString('locale') ?? 'en';
  }
});

// 2. Locale 변경 서비스
class LocaleService {
  Future<void> setLocale(String locale) async {
    if (isAuthenticated) {
      await _updateDbPreferences(locale: locale);
    } else {
      await _prefs.setString('locale', locale);
    }
  }
}
```

### 2. 모델 패턴 표준화

**공통 Mixin 정의:**
```dart
mixin LocalizedContent {
  String name;
  String? nameKo;

  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }
}

// 적용
class Product with LocalizedContent {
  @override
  final String name;
  @override
  final String? nameKo;
  // ...
}

class Ingredient with LocalizedContent {
  @override
  final String name;
  @override
  final String? nameKo;
  // ...
}
```

### 3. UI 컴포넌트 패턴

**LocalizedText 위젯 생성:**
```dart
class LocalizedText extends ConsumerWidget {
  final String text;
  final String? textKo;
  final TextStyle? style;

  const LocalizedText({
    required this.text,
    this.textKo,
    this.style,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(currentLocaleProvider);
    final displayText = (locale == 'ko' && textKo != null) ? textKo! : text;

    return Text(displayText, style: style);
  }
}

// 사용 예
LocalizedText(
  text: product.name,
  textKo: product.nameKo,
  style: Theme.of(context).textTheme.titleLarge,
)
```

### 4. 검색 기능 개선

**다국어 검색 지원:**
```dart
// Provider 수정
final filteredProductsProvider = Provider<AsyncValue<List<Product>>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final query = ref.watch(productSearchQueryProvider).toLowerCase();
  final locale = ref.watch(currentLocaleProvider);

  return productsAsync.whenData((products) {
    if (query.isEmpty) return products;

    return products.where((p) {
      // 영어 이름 검색
      if (p.name.toLowerCase().contains(query)) return true;
      if (p.brand?.toLowerCase().contains(query) ?? false) return true;

      // 한국어 이름 검색
      if (locale == 'ko' && p.nameKo != null) {
        if (p.nameKo!.contains(query)) return true;
      }

      return false;
    }).toList();
  });
});
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 확률 | 대응 방안 |
|-----------|--------|------|-----------|
| 번역 품질 불량 | 높음 | 중간 | 전문가 검토, 사용자 피드백 수집 |
| 데이터 마이그레이션 오류 | 높음 | 낮음 | 백업 필수, 트랜잭션 사용, 롤백 계획 |
| 성능 저하 | 중간 | 낮음 | 인덱싱, 쿼리 최적화, 성능 테스트 |
| 중복 정리 시 데이터 손실 | 높음 | 낮음 | FK 확인, 단계별 검증, 사용자 데이터 우선 |
| 일관성 없는 번역 | 중간 | 높음 | 용어집 작성, 번역 가이드라인 |
| 스키마 변경으로 인한 앱 충돌 | 높음 | 낮음 | 하위 호환성 유지, nullable 컬럼, 단계적 배포 |

### 세부 대응 계획

**1. 데이터 백업 및 복구 전략**
```sql
-- 마이그레이션 전 백업
CREATE TABLE ingredients_backup AS SELECT * FROM ingredients;
CREATE TABLE cocktail_ingredients_backup AS SELECT * FROM cocktail_ingredients;
CREATE TABLE user_ingredients_backup AS SELECT * FROM user_ingredients;

-- 롤백 스크립트 준비
-- rollback.sql
```

**2. 단계적 배포 전략**
```yaml
Step 1: 스키마 변경 (nullable 컬럼)
  - 기존 앱 영향 없음
  - DB 변경만 배포

Step 2: 데이터 입력 (번역)
  - 앱 업데이트 불필요
  - 점진적 데이터 입력

Step 3: 앱 업데이트
  - getLocalizedName() 메서드 추가
  - 기존 코드는 그대로 작동 (fallback to English)
  - 점진적으로 UI 컴포넌트 업데이트

Step 4: 중복 데이터 정리
  - 사용자 데이터 마이그레이션
  - FK 업데이트
  - 검증 후 삭제
```

**3. 번역 품질 관리**
```markdown
# 번역 가이드라인

## 일반 원칙
- 전문 용어는 음차 표기 (예: Gin → 진)
- 일반적인 한국어 표현 우선 (예: Orange Juice → 오렌지 주스)
- 브랜드명은 원어 유지 (예: Bombay Sapphire)

## 카테고리별 가이드
- Spirits: ~진, ~보드카, ~럼 등
- Liqueurs: ~리큐르, ~슈냅스 등
- Wines: ~와인, ~베르무트 등

## 용어집
- Simple Syrup → 심플 시럽
- Bitters → 비터스
- Dry Vermouth → 드라이 베르무트
- Sweet Vermouth → 스위트 베르무트
```

## 테스트 전략

### 1. 단위 테스트
```dart
void main() {
  group('LocalizedContent', () {
    test('returns Korean name when locale is ko', () {
      final product = Product(
        name: 'Gin',
        nameKo: '진',
      );

      expect(product.getLocalizedName('ko'), '진');
      expect(product.getLocalizedName('en'), 'Gin');
    });

    test('falls back to English when Korean is null', () {
      final product = Product(name: 'Gin', nameKo: null);

      expect(product.getLocalizedName('ko'), 'Gin');
    });
  });
}
```

### 2. 통합 테스트
```dart
void main() {
  testWidgets('Product list shows Korean names', (tester) async {
    // Setup locale to Korean
    // Load products
    // Verify Korean names are displayed
  });

  testWidgets('Search works with Korean input', (tester) async {
    // Setup products with Korean names
    // Enter Korean search query
    // Verify filtering works
  });
}
```

### 3. 데이터 무결성 테스트
```sql
-- 1. FK 무결성 확인
SELECT ci.cocktail_id, ci.ingredient_id
FROM cocktail_ingredients ci
LEFT JOIN ingredients i ON ci.ingredient_id = i.id
LEFT JOIN misc_items m ON ci.ingredient_id = m.id
WHERE i.id IS NULL AND m.id IS NULL;
-- 결과: 0 rows (정상)

-- 2. 중복 확인
SELECT name, COUNT(*)
FROM (
  SELECT name FROM ingredients
  UNION ALL
  SELECT name FROM misc_items
) combined
GROUP BY name
HAVING COUNT(*) > 1;
-- 결과: 0 rows (정상)

-- 3. 카테고리 유효성
SELECT DISTINCT category
FROM ingredients
WHERE category NOT IN ('spirits', 'liqueurs', 'wines', 'bitters', 'vermouths', 'fortified_wines', 'uncategorized');
-- 결과: 0 rows (정상)
```

## 성공 기준

### Phase 1-2 (데이터 정리)
- [ ] ingredients 카테고리 100% 표준화 (uncategorized 제외)
- [ ] 중복 데이터 0건
- [ ] FK 무결성 100% 유지

### Phase 3 (번역)
- [ ] misc_items: 100% (42/42) ✅ 완료
- [ ] ingredients (핵심): 100% (100/100)
- [ ] products (상위): 100% (50/50)
- [ ] cocktails (인기): 100% (50/50)

### Phase 4-5 (앱 연동)
- [ ] 모든 UI 컴포넌트 다국어 지원
- [ ] 언어 전환 시 즉시 반영
- [ ] 검색 기능 한국어 지원
- [ ] 성능 저하 없음 (로딩 시간 < 500ms)
- [ ] QA 통과율 100%

### 사용자 경험
- [ ] 한국어 사용자 만족도 90% 이상
- [ ] 번역 오류 신고 건수 < 5%
- [ ] 앱스토어 리뷰 언어 관련 불만 0건

## 후속 작업

### 단기 (1-2개월)
1. 나머지 데이터 번역 (ingredients 160개, products 49개)
2. 사용자 피드백 기반 번역 개선
3. 검색 알고리즘 최적화 (한국어 형태소 분석)

### 중기 (3-6개월)
1. 일본어(ja) 지원 추가
2. 사용자 기여 번역 시스템 (crowdsourcing)
3. AI 기반 자동 번역 개선

### 장기 (6개월 이상)
1. 추가 언어 지원 (중국어, 스페인어 등)
2. 번역 관리 대시보드 개발
3. 다국어 콘텐츠 CMS 구축

## 참고 자료

### 기술 문서
- [Flutter Internationalization](https://docs.flutter.dev/development/accessibility-and-localization/internationalization)
- [Supabase Localization Best Practices](https://supabase.com/docs/guides/database/tables#localization)
- [PostgreSQL i18n Patterns](https://www.postgresql.org/docs/current/locale.html)

### 번역 가이드
- [한국 바텐더 협회 용어집](https://www.koreanbartenders.or.kr/)
- [IBA 공식 칵테일 한국어 명칭](https://iba-world.com/)
- [주류 용어 표준화 가이드](https://www.kati.net/)

### 프로젝트 문서
- `/docs/tasks/completed/2026-01-21-auth-data-sync-redesign-strategy.md`
- `/docs/tasks/completed/2026-01-23-color-system-integration-strategy.md`
- Flutter l10n 파일: `/lib/l10n/app_en.arb`, `/lib/l10n/app_ko.arb`

## 구현 타임라인

```
Week 1:
  Day 1-2: Phase 1 (스키마 확장)
  Day 3-5: Phase 2 (데이터 정리 및 카테고리 표준화)

Week 2:
  Day 1-3: Phase 3.1 (핵심 번역 100개)
  Day 4-5: Phase 4.1 (Flutter 모델 업데이트)

Week 3:
  Day 1-2: Phase 3.2 (products, cocktails 번역)
  Day 3-4: Phase 4.2-4.3 (UI 업데이트)
  Day 5: Phase 5 (QA 및 배포)
```

## 결론

**권장 접근법:**
1. ✅ 컬럼 기반 다국어 지원 (옵션 A)
2. ✅ 테이블 역할 명확화 (ingredients vs misc_items)
3. ✅ 단계적 번역 (핵심 → 전체)
4. ✅ 점진적 배포 (스키마 → 데이터 → 앱)

**핵심 성공 요인:**
- 데이터 백업 및 롤백 계획 철저
- 번역 품질 관리 (용어집, 가이드라인)
- 사용자 피드백 적극 수용
- 성능 모니터링 및 최적화

**기대 효과:**
- 🇰🇷 한국 사용자 경험 대폭 개선
- 📊 앱 사용률 및 만족도 향상
- 🌏 향후 글로벌 확장 기반 마련
- 🏗️ 확장 가능한 다국어 아키텍처 구축
