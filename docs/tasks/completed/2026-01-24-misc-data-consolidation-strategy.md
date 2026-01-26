# Misc 데이터 통합 전략

## 개요

- **목적**: `ingredients` 테이블의 misc 카테고리와 `misc_items` 테이블 간 데이터 중복을 제거하고 단일 소스로 통합
- **범위**: 데이터베이스 스키마, 데이터 마이그레이션, Flutter 애플리케이션 로직 업데이트
- **예상 소요 기간**: 2-3일

## 현재 상태 분석

### 기존 구현

1. **데이터베이스 스키마**
   - `ingredients` 테이블: 260개 레코드 (18개가 category='misc')
   - `misc_items` 테이블: 42개 레코드 (7개 카테고리로 세분화)
   - `cocktail_ingredients` 테이블: 2,735개 레코드 (772개가 misc 재료 참조)

2. **중복 데이터**
   - **동일 ID 중복 (11개)**: `agave-syrup`, `cola`, `cranberry-juice`, `egg-white`, `ginger-beer`, `grenadine`, `honey-syrup`, `orange-juice`, `pineapple-juice`, `simple-syrup`, `tonic-water`
   - **이름 유사 중복 (1개)**: `cream` (ingredients) ↔ `heavy-cream` (misc_items)
   - **ingredients에만 존재 (6개)**: `club-soda`, `grapefruit-juice`, `lemon-juice`, `lime-juice`, `mint-leaves`, `sugar`

3. **사용자 소유 데이터**
   - `user_products`: 제품 소유 정보 (products.ingredient_id 참조)
   - `user_ingredients`: 재료 직접 선택 (ingredients.id 참조)
   - `user_misc_items`: misc 아이템 선택 (misc_items.id 참조)

4. **칵테일 매칭 로직**
   - `ingredient_availability_provider.dart`: 제품 기반 소유와 직접 선택 재료만 확인
   - misc_items 소유 정보는 칵테일 가용성 체크에 포함되지 않음

### 문제점/한계

1. **데이터 중복**: 동일한 아이템이 두 테이블에 존재하여 관리 복잡도 증가
2. **불완전한 매칭**: misc_items 소유 정보가 칵테일 재료 가용성 체크에서 누락됨
3. **네이밍 불일치**: 한국어/영어 이름이 테이블 간 불일치 (예: `cream` vs `heavy-cream`)
4. **카테고리 불일치**: ingredients는 단일 'misc' 카테고리, misc_items는 7개 세부 카테고리
5. **FK 제약**: `cocktail_ingredients.ingredient_id` → `ingredients.id` 참조로 직접 misc_items 사용 불가

### 관련 코드/모듈

- **Models**: `lib/data/models/ingredient.dart`, `lib/data/models/misc_item.dart`
- **Providers**:
  - `lib/data/providers/ingredient_availability_provider.dart`
  - `lib/data/providers/misc_item_provider.dart`
  - `lib/data/providers/ingredient_provider.dart`
- **Services**: `lib/core/services/migration_service.dart`
- **Database**: `ingredients`, `misc_items`, `cocktail_ingredients`, `user_misc_items`, `user_ingredients`

## 구현 전략

### 접근 방식

**단일 소스 원칙**: `misc_items` 테이블을 유일한 진실의 원천(Single Source of Truth)으로 설정하고, `ingredients` 테이블에서 misc 카테고리를 제거합니다.

**점진적 마이그레이션**: 데이터 무결성을 보장하기 위해 검증 단계를 포함한 단계별 마이그레이션을 수행합니다.

**브릿지 메커니즘**: `cocktail_ingredients` FK 제약을 유지하면서 misc_items를 참조할 수 있도록 중간 레이어를 구현합니다.

### 세부 구현 단계

#### 1단계: 데이터 분석 및 준비 (0.5일)

**1.1 중복 데이터 매핑**
```sql
-- 중복 데이터 전체 분석
SELECT
  i.id as ingredient_id,
  i.name as ingredient_name,
  i.name_ko as ingredient_name_ko,
  m.id as misc_id,
  m.name as misc_name,
  m.name_ko as misc_name_ko,
  m.category as misc_category
FROM ingredients i
LEFT JOIN misc_items m ON (i.id = m.id OR LOWER(i.name) = LOWER(m.name))
WHERE i.category = 'misc'
ORDER BY i.name;
```

**1.2 누락 데이터 식별**
- ingredients에만 있는 6개 아이템을 misc_items에 추가할 카테고리 결정
- 제안 카테고리 매핑:
  - `club-soda` → mixer
  - `grapefruit-juice` → mixer
  - `lemon-juice` → mixer (또는 fresh 카테고리에 `fresh-lemon`과 병합)
  - `lime-juice` → mixer (또는 fresh 카테고리에 `fresh-lime`과 병합)
  - `mint-leaves` → fresh (또는 `fresh-mint`와 병합)
  - `sugar` → syrup

**1.3 cocktail_ingredients 사용 빈도 분석**
```sql
-- 각 misc 재료가 사용되는 칵테일 수 확인
SELECT
  i.id,
  i.name,
  COUNT(DISTINCT ci.cocktail_id) as cocktail_count
FROM ingredients i
JOIN cocktail_ingredients ci ON ci.ingredient_id = i.id
WHERE i.category = 'misc'
GROUP BY i.id, i.name
ORDER BY cocktail_count DESC;
```

#### 2단계: 데이터베이스 마이그레이션 (1일)

**2.1 misc_items 테이블 보강**
```sql
-- Migration: add_missing_misc_items
-- 누락된 재료를 misc_items에 추가
INSERT INTO misc_items (id, name, name_ko, category, sort_order)
VALUES
  ('club-soda', 'Club Soda', '클럽 소다', 'mixer', 100),
  ('grapefruit-juice', 'Grapefruit Juice', '자몽 주스', 'mixer', 101),
  ('lemon-juice', 'Lemon Juice', '레몬 주스', 'mixer', 102),
  ('lime-juice', 'Lime Juice', '라임 주스', 'mixer', 103),
  ('mint-leaves', 'Mint Leaves', '민트', 'fresh', 104),
  ('sugar', 'Sugar', '설탕', 'syrup', 105)
ON CONFLICT (id) DO NOTHING;

-- 이름 불일치 수정
UPDATE misc_items
SET name_ko = '생크림'
WHERE id = 'heavy-cream' AND name_ko IS NULL;
```

**2.2 중간 매핑 테이블 생성 (옵션 A - 권장)**
```sql
-- Migration: create_ingredient_misc_mapping
-- ingredients와 misc_items 간 매핑 테이블 생성
CREATE TABLE IF NOT EXISTS ingredient_misc_mapping (
  ingredient_id TEXT PRIMARY KEY REFERENCES ingredients(id) ON DELETE CASCADE,
  misc_item_id TEXT NOT NULL REFERENCES misc_items(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS 활성화
ALTER TABLE ingredient_misc_mapping ENABLE ROW LEVEL SECURITY;

-- 읽기 권한 부여
CREATE POLICY "Anyone can read ingredient_misc_mapping"
  ON ingredient_misc_mapping FOR SELECT
  USING (true);

-- 초기 매핑 데이터 삽입
INSERT INTO ingredient_misc_mapping (ingredient_id, misc_item_id)
SELECT i.id, m.id
FROM ingredients i
JOIN misc_items m ON i.id = m.id
WHERE i.category = 'misc';

-- 이름이 다른 경우 수동 매핑
INSERT INTO ingredient_misc_mapping (ingredient_id, misc_item_id)
VALUES ('cream', 'heavy-cream')
ON CONFLICT (ingredient_id) DO NOTHING;
```

**2.3 사용자 데이터 통합**
```sql
-- Migration: consolidate_user_misc_data
-- user_ingredients의 misc 카테고리 데이터를 user_misc_items로 마이그레이션
INSERT INTO user_misc_items (user_id, misc_item_id)
SELECT DISTINCT
  ui.user_id,
  COALESCE(imm.misc_item_id, ui.ingredient_id) as misc_item_id
FROM user_ingredients ui
JOIN ingredients i ON ui.ingredient_id = i.id
LEFT JOIN ingredient_misc_mapping imm ON ui.ingredient_id = imm.ingredient_id
WHERE i.category = 'misc'
ON CONFLICT (user_id, misc_item_id) DO NOTHING;

-- user_ingredients에서 misc 카테고리 데이터 삭제
DELETE FROM user_ingredients
WHERE ingredient_id IN (
  SELECT id FROM ingredients WHERE category = 'misc'
);
```

**2.4 View 생성 (옵션 B - 대안)**
```sql
-- Migration: create_unified_ingredients_view
-- ingredients와 misc_items를 통합한 View
CREATE OR REPLACE VIEW unified_ingredients AS
SELECT
  id,
  name,
  name_ko,
  category,
  description,
  strength,
  origin,
  image_url,
  thumbnail_url,
  'ingredient' as source_table
FROM ingredients
WHERE category != 'misc'
UNION ALL
SELECT
  id,
  name,
  name_ko,
  category,
  description,
  NULL as strength,
  NULL as origin,
  image_url,
  thumbnail_url,
  'misc_item' as source_table
FROM misc_items;
```

#### 3단계: Flutter 애플리케이션 업데이트 (1일)

**3.1 CocktailIngredient 모델 확장**
```dart
// lib/data/models/ingredient.dart
class CocktailIngredient {
  final String id;
  final String name;
  final int sort;
  final double amount;
  final String units;
  final bool optional;
  final double? amountMax;
  final String? note;
  final List<String> substitutes;
  final IngredientSource source; // 추가

  // ... 기존 코드
}

enum IngredientSource {
  ingredient,  // 일반 재료
  miscItem,    // misc_items 테이블
}
```

**3.2 재료 가용성 체크 로직 업데이트**
```dart
// lib/data/providers/ingredient_availability_provider.dart
final cocktailIngredientAvailabilityProvider =
    Provider.family<AsyncValue<List<IngredientAvailability>>, String>(
  (ref, cocktailId) {
    final cocktailIngredientsAsync = ref.watch(cocktailIngredientsProvider(cocktailId));
    final ingredientsAsync = ref.watch(ingredientsProvider);
    final productsAsync = ref.watch(productsProvider);
    final miscItemsAsync = ref.watch(miscItemsProvider); // 추가

    final isAuthenticated = ref.watch(isAuthenticatedProvider);
    final selectedProductIds = isAuthenticated
        ? ref.watch(effectiveSelectedProductsProvider)
        : ref.watch(selectedProductsProvider);
    final selectedIngredientIds = isAuthenticated
        ? ref.watch(effectiveSelectedIngredientsProvider)
        : ref.watch(selectedIngredientsProvider);
    final selectedMiscItemIds = ref.watch(effectiveSelectedMiscItemsProvider); // 추가

    return cocktailIngredientsAsync.whenData((cocktailIngredients) {
      // ... 기존 로직

      // misc_items 매핑 테이블 로드
      final ingredientMiscMappingAsync = ref.watch(ingredientMiscMappingProvider);
      final miscMapping = ingredientMiscMappingAsync.valueOrNull ?? {};

      return cocktailIngredients.map((cocktailIngredient) {
        final ingredientId = cocktailIngredient.id;

        // 1. 일반 재료 소유 확인
        final directlyOwned = selectedIngredientIds.contains(ingredientId);
        final ownedProductsForIngredient = productsByIngredient[ingredientId] ?? [];

        // 2. misc_item으로 매핑되는지 확인
        final miscItemId = miscMapping[ingredientId];
        final miscOwned = miscItemId != null && selectedMiscItemIds.contains(miscItemId);

        final isOwned = directlyOwned ||
                       ownedProductsForIngredient.isNotEmpty ||
                       miscOwned; // misc 소유 추가

        // ... 나머지 로직
      }).toList();
    });
  },
);

// 매핑 테이블 provider 추가
final ingredientMiscMappingProvider = FutureProvider<Map<String, String>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('ingredient_misc_mapping')
      .select('ingredient_id, misc_item_id');

  final mapping = <String, String>{};
  for (final row in response as List) {
    mapping[row['ingredient_id']] = row['misc_item_id'];
  }
  return mapping;
});
```

**3.3 마이그레이션 서비스 업데이트**
```dart
// lib/core/services/migration_service.dart
class DataMigrationService {
  // 기존 코드...

  // misc_items 마이그레이션 추가
  static const _miscItemsKey = 'selected_misc_items';

  LocalDataSummary getLocalDataSummary() {
    final products = _prefs.getStringList(_productsKey) ?? [];
    final ingredients = _prefs.getStringList(_ingredientsKey) ?? [];
    final miscItems = _prefs.getStringList(_miscItemsKey) ?? []; // 추가
    final favorites = _prefs.getStringList(_favoritesKey) ?? [];

    return LocalDataSummary(
      productsCount: products.length,
      ingredientsCount: ingredients.length,
      miscItemsCount: miscItems.length, // 추가
      favoritesCount: favorites.length,
    );
  }

  Future<MigrationResult> migrateToCloud(String userId) async {
    // ... 기존 코드

    // 4. misc_items 마이그레이션 추가
    final localMiscItems = _prefs.getStringList(_miscItemsKey) ?? [];
    if (localMiscItems.isNotEmpty) {
      try {
        await _supabase.from('user_misc_items').upsert(
          localMiscItems
              .map((id) => {'user_id': userId, 'misc_item_id': id})
              .toList(),
          onConflict: 'user_id,misc_item_id',
        );
        result.miscItemsMigrated = localMiscItems.length;
      } catch (e) {
        debugPrint('Failed to migrate misc items: $e');
      }
    }

    return result;
  }
}
```

**3.4 UI 업데이트**
```dart
// lib/features/cocktails/widgets/ingredient_availability_card.dart
// misc 재료 소유 상태 표시 로직 추가

Widget _buildAvailabilityBadge(IngredientAvailability availability) {
  if (availability.isOwned) {
    // 어떤 방식으로 소유했는지 구분 표시
    if (availability.ownedViaProduct) {
      return Badge(label: '제품 소유');
    } else if (availability.ownedViaMiscItem) {
      return Badge(label: 'Misc 소유');
    } else {
      return Badge(label: '재료 소유');
    }
  }
  // ... 대체재 표시
}
```

#### 4단계: 테스트 및 검증 (0.5일)

**4.1 데이터 무결성 검증**
```sql
-- 마이그레이션 후 검증 쿼리
-- 1. 모든 cocktail_ingredients가 여전히 유효한지 확인
SELECT COUNT(*) as orphaned_count
FROM cocktail_ingredients ci
LEFT JOIN ingredients i ON ci.ingredient_id = i.id
WHERE i.id IS NULL;
-- 예상: 0

-- 2. user_misc_items에 중복이 없는지 확인
SELECT user_id, misc_item_id, COUNT(*) as dup_count
FROM user_misc_items
GROUP BY user_id, misc_item_id
HAVING COUNT(*) > 1;
-- 예상: 0 rows

-- 3. 모든 misc 재료가 misc_items에 존재하는지 확인
SELECT i.id, i.name
FROM ingredients i
LEFT JOIN ingredient_misc_mapping imm ON i.id = imm.ingredient_id
LEFT JOIN misc_items m ON imm.misc_item_id = m.id
WHERE i.category = 'misc' AND m.id IS NULL;
-- 예상: 0 rows
```

**4.2 애플리케이션 테스트**
- [ ] 칵테일 상세 화면에서 misc 재료 소유 상태가 올바르게 표시되는지 확인
- [ ] misc_items 선택 시 칵테일 매칭이 올바르게 작동하는지 확인
- [ ] 비회원 → 회원 전환 시 misc_items 데이터가 올바르게 마이그레이션되는지 확인
- [ ] 기존 제품 및 재료 소유 데이터가 영향받지 않았는지 확인
- [ ] 대체재 매칭이 여전히 작동하는지 확인

**4.3 성능 테스트**
- [ ] 칵테일 목록 로딩 시간 측정 (목표: 변화 없음 또는 개선)
- [ ] 재료 가용성 체크 성능 측정
- [ ] 매핑 테이블 조인 성능 확인

#### 5단계: 정리 및 최적화 (선택사항)

**5.1 ingredients 테이블에서 misc 카테고리 제거 (신중하게)**
```sql
-- Migration: remove_misc_from_ingredients
-- WARNING: 이 단계는 모든 검증이 완료된 후에만 실행
-- 롤백 어려움 - 반드시 백업 후 실행

-- 1. cocktail_ingredients FK를 매핑 테이블을 통해 업데이트 (복잡함)
-- 또는 ingredients 테이블에 misc 카테고리를 유지하되 사용 안 함으로 표시

-- 대안: soft delete
ALTER TABLE ingredients ADD COLUMN IF NOT EXISTS deprecated BOOLEAN DEFAULT FALSE;
UPDATE ingredients SET deprecated = TRUE WHERE category = 'misc';

-- View를 통한 접근 강제
CREATE OR REPLACE VIEW active_ingredients AS
SELECT * FROM ingredients WHERE deprecated = FALSE;
```

### 기술적 고려사항

#### 아키텍처

**옵션 A: 매핑 테이블 접근 (권장)**
- 장점:
  - 기존 FK 제약 유지
  - 점진적 마이그레이션 가능
  - 롤백 용이
  - 명확한 데이터 계층 분리
- 단점:
  - 추가 조인 필요 (성능 영향 최소)
  - 테이블 하나 추가

**옵션 B: View 접근**
- 장점:
  - 통합된 인터페이스
  - 쿼리 단순화
- 단점:
  - View 성능 오버헤드
  - 복잡한 업데이트 로직
  - 롤백 어려움

**권장 사항**: 옵션 A (매핑 테이블)를 먼저 구현하고, 필요 시 옵션 B를 추가적으로 고려

#### 의존성

- Supabase Flutter SDK (기존)
- Riverpod (기존)
- 새로운 테이블: `ingredient_misc_mapping`
- 새로운 컬럼: `ingredients.deprecated` (옵션)

#### API 설계

**새로운 Provider**
```dart
// 매핑 테이블 provider
final ingredientMiscMappingProvider = FutureProvider<Map<String, String>>;

// misc 재료 체크 provider
final isMiscIngredientProvider = Provider.family<bool, String>;

// 통합 재료 가용성 provider (업데이트)
final cocktailIngredientAvailabilityProvider; // 기존에 misc 로직 추가
```

**새로운 Service 메서드**
```dart
class EffectiveMiscItemsService {
  // 기존 메서드 유지
  Future<void> toggle(String itemId);
  Future<void> clear();

  // 새로운 메서드
  Future<String?> getMiscItemIdForIngredient(String ingredientId);
  Future<bool> isIngredientMappedToMiscItem(String ingredientId);
}
```

#### 데이터 모델

**확장 모델**
```dart
class IngredientAvailability {
  final String ingredientId;
  final String ingredientName;
  final bool isOwned;
  final List<Product> ownedProducts;
  final List<SubstituteInfo> availableSubstitutes;

  // 추가 필드
  final bool ownedViaProduct;
  final bool ownedViaMiscItem;
  final bool ownedDirectly;
  final String? miscItemId; // 매핑된 misc_item ID
}
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 데이터 손실 (마이그레이션 실패) | 높음 | 1. 마이그레이션 전 전체 DB 백업<br>2. 트랜잭션 내에서 마이그레이션 수행<br>3. 단계별 검증 쿼리 실행<br>4. 롤백 스크립트 준비 |
| FK 제약 위반 | 높음 | 1. 마이그레이션 전 FK 검증<br>2. 매핑 테이블 먼저 생성 후 데이터 이동<br>3. 검증 쿼리로 orphan 레코드 확인 |
| 사용자 데이터 불일치 | 중간 | 1. user_ingredients와 user_misc_items 중복 제거 로직<br>2. 마이그레이션 후 사용자별 검증<br>3. 불일치 발견 시 알림 메커니즘 |
| 성능 저하 (매핑 테이블 조인) | 중간 | 1. ingredient_misc_mapping에 인덱스 추가<br>2. 자주 사용되는 쿼리 캐싱<br>3. 성능 벤치마크 측정 및 비교 |
| 칵테일 매칭 로직 오류 | 높음 | 1. 기존 매칭 로직 철저한 테스트<br>2. A/B 테스트로 점진적 롤아웃<br>3. 매칭 결과 로그 수집 및 검증 |
| 네이밍 충돌 | 낮음 | 1. 사전에 모든 이름 불일치 식별<br>2. 수동 매핑 테이블 작성<br>3. 사용자에게 명확한 이름 표시 |
| 롤백 복잡성 | 중간 | 1. 각 마이그레이션 단계별 롤백 스크립트 작성<br>2. 롤백 테스트 수행<br>3. 프로덕션 적용 전 스테이징 환경 검증 |

## 테스트 전략

### 단위 테스트

**Provider 테스트**
```dart
// test/data/providers/ingredient_availability_provider_test.dart
testWidgets('misc item ownership is reflected in availability', (tester) async {
  // Given: user owns a misc item
  final container = ProviderContainer(
    overrides: [
      effectiveSelectedMiscItemsProvider.overrideWith((ref) => {'simple-syrup'}),
      ingredientMiscMappingProvider.overrideWith((ref) async => {'simple-syrup': 'simple-syrup'}),
    ],
  );

  // When: check ingredient availability
  final availability = await container.read(
    cocktailIngredientAvailabilityProvider('mojito').future,
  );

  // Then: simple syrup should be marked as owned
  final simpleSyrup = availability.firstWhere((a) => a.ingredientId == 'simple-syrup');
  expect(simpleSyrup.isOwned, isTrue);
  expect(simpleSyrup.ownedViaMiscItem, isTrue);
});
```

**마이그레이션 서비스 테스트**
```dart
// test/core/services/migration_service_test.dart
test('migrates misc items to cloud', () async {
  // Given: local misc items
  final prefs = await SharedPreferences.getInstance();
  await prefs.setStringList('selected_misc_items', ['cola', 'tonic-water']);

  // When: migrate to cloud
  final result = await service.migrateToCloud(userId);

  // Then: cloud has the data
  expect(result.miscItemsMigrated, equals(2));
  final cloudData = await supabase.from('user_misc_items')
    .select()
    .eq('user_id', userId);
  expect(cloudData.length, equals(2));
});
```

### 통합 테스트

**E2E 칵테일 매칭 테스트**
```dart
// integration_test/cocktail_matching_test.dart
testWidgets('cocktail shows as available when user owns misc items', (tester) async {
  // Given: user owns all required misc items for Mojito
  await selectMiscItem(tester, 'simple-syrup');
  await selectMiscItem(tester, 'fresh-lime');
  await selectMiscItem(tester, 'fresh-mint');
  await selectMiscItem(tester, 'club-soda');

  // When: view Mojito detail
  await navigateToCocktail(tester, 'mojito');

  // Then: all ingredients should show as owned
  expect(find.text('모든 재료 소유'), findsOneWidget);
});
```

**데이터 마이그레이션 통합 테스트**
```dart
// integration_test/migration_test.dart
testWidgets('non-auth to auth migration preserves misc items', (tester) async {
  // Given: non-authenticated user with misc items
  await selectMiscItemAsGuest(tester, 'cola');
  await selectMiscItemAsGuest(tester, 'simple-syrup');

  // When: user signs up
  await signUp(tester, 'test@example.com', 'password');

  // Then: misc items are in cloud
  final cloudData = await getCloudMiscItems();
  expect(cloudData, containsAll(['cola', 'simple-syrup']));

  // And: local data is cleared
  final localData = getLocalMiscItems();
  expect(localData, isEmpty);
});
```

### 성능 테스트

**칵테일 매칭 성능**
```dart
test('ingredient availability check completes within 100ms', () async {
  final stopwatch = Stopwatch()..start();

  await container.read(
    cocktailIngredientAvailabilityProvider('mojito').future,
  );

  stopwatch.stop();
  expect(stopwatch.elapsedMilliseconds, lessThan(100));
});
```

**데이터베이스 쿼리 성능**
```sql
-- 매핑 테이블 조인 성능 측정
EXPLAIN ANALYZE
SELECT ci.*, m.name, m.category
FROM cocktail_ingredients ci
JOIN ingredient_misc_mapping imm ON ci.ingredient_id = imm.ingredient_id
JOIN misc_items m ON imm.misc_item_id = m.id
WHERE ci.cocktail_id = 'mojito';
-- 목표: < 10ms
```

## 성공 기준

- [ ] **데이터 무결성**: 모든 마이그레이션 검증 쿼리가 예상 결과 반환 (orphan 레코드 0개)
- [ ] **기능 완전성**: misc 재료 소유 정보가 칵테일 가용성 체크에 올바르게 반영됨
- [ ] **사용자 경험**: 비회원 → 회원 전환 시 misc_items 데이터가 100% 보존됨
- [ ] **성능**: 칵테일 매칭 성능이 기존 대비 10% 이상 저하되지 않음 (목표: 100ms 이내)
- [ ] **테스트 커버리지**: 핵심 로직 단위 테스트 커버리지 80% 이상
- [ ] **코드 품질**: 모든 lint 및 type check 통과
- [ ] **문서화**: 마이그레이션 가이드 및 롤백 절차 문서 작성 완료
- [ ] **롤백 검증**: 롤백 스크립트가 정상 작동하며 데이터 복원 가능
- [ ] **프로덕션 검증**: 스테이징 환경에서 7일 이상 안정적 운영 확인

## 참고 자료

### 데이터베이스 설계 패턴
- [Supabase Foreign Key Constraints](https://supabase.com/docs/guides/database/tables#foreign-key-constraints)
- [PostgreSQL Mapping Tables](https://www.postgresql.org/docs/current/ddl-constraints.html)
- [Data Migration Best Practices](https://supabase.com/docs/guides/database/migrations)

### Flutter/Riverpod 패턴
- [Riverpod Family Providers](https://riverpod.dev/docs/concepts/modifiers/family)
- [Supabase Flutter Real-time](https://supabase.com/docs/reference/dart/stream)
- [Data Migration in Flutter Apps](https://docs.flutter.dev/cookbook/persistence/sqlite#4-migrate-the-database)

### 유사 사례
- [Consolidating Duplicate Data in E-commerce Apps](https://stackoverflow.com/questions/tagged/data-migration)
- [Bridge Tables for Many-to-Many Relationships](https://vertabelo.com/blog/many-to-many-relationship/)

### 롤백 전략
```sql
-- Rollback Script Template
-- 1. 백업에서 ingredients 테이블 복원
-- 2. user_misc_items에서 user_ingredients로 데이터 복원
-- 3. ingredient_misc_mapping 테이블 삭제
-- 4. 애플리케이션 이전 버전으로 롤백

BEGIN;

-- Step 1: Restore user_ingredients from backup
INSERT INTO user_ingredients (user_id, ingredient_id)
SELECT user_id, misc_item_id
FROM user_misc_items_backup
WHERE misc_item_id IN (SELECT id FROM ingredients WHERE category = 'misc');

-- Step 2: Drop mapping table
DROP TABLE IF EXISTS ingredient_misc_mapping;

-- Step 3: Restore ingredients table from backup
-- (Use pg_restore or manual INSERT from backup)

COMMIT;
```
