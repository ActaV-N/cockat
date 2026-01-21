# 사용성 설계 (User Experience Design)

## 개요

로그인 없이도 핵심 기능을 체험할 수 있게 하되, 데이터 영속성이 필요한 시점에 자연스럽게 회원가입을 유도하는 설계.

---

## 1. 로그인 없이 이용 가능한 범위

### 비회원 이용 가능 기능

| 기능 | 이용 가능 | 저장 방식 | 제한사항 |
|------|----------|----------|----------|
| 칵테일 목록 조회 | ✅ | - | 없음 |
| 칵테일 상세 레시피 | ✅ | - | 없음 |
| 칵테일 검색 | ✅ | - | 없음 |
| 재료 종류 선택 | ✅ | SharedPreferences (로컬) | 기기 변경 시 소실 |
| 상품(술병) 선택 | ✅ | SharedPreferences (로컬) | 기기 변경 시 소실 |
| 칵테일 매칭 결과 | ✅ | - | 없음 |
| 즐겨찾기 | ⚠️ | SharedPreferences (로컬) | 기기 변경 시 소실, 개수 제한(20개) |
| 언어/테마 설정 | ✅ | SharedPreferences (로컬) | 기기 변경 시 소실 |

### 회원 전용 기능

| 기능 | 설명 |
|------|------|
| 데이터 동기화 | 여러 기기에서 동일한 데이터 접근 |
| 무제한 즐겨찾기 | 개수 제한 없음 |
| 커스텀 칵테일 등록 | 나만의 레시피 저장 |
| 히스토리 | 만들어본 칵테일 기록 |
| 추천 알고리즘 | 취향 기반 개인화 추천 |

---

## 2. 로그인/회원가입 유도 시점

### 유도 전략: "가치를 먼저 제공하고, 필요할 때 요청"

```
[비회원 진입] → [핵심 기능 체험] → [가치 인식] → [자연스러운 유도] → [회원가입]
```

### 유도 시점 (Trigger Points)

#### 2.1 Soft Prompt (권유, 차단 없음)

| 시점 | 메시지 예시 | UI |
|------|------------|-----|
| 앱 첫 실행 후 재료 5개 이상 선택 | "로그인하면 다른 기기에서도 내 술장을 볼 수 있어요" | 하단 배너 (닫기 가능) |
| 즐겨찾기 10개 도달 | "회원가입하면 즐겨찾기를 무제한으로 저장할 수 있어요" | 토스트 메시지 |
| 3일 연속 앱 사용 | "자주 오시네요! 회원가입하고 기록을 안전하게 보관하세요" | 설정 화면 배너 |
| 앱 업데이트 후 첫 실행 | "새로운 기능을 모두 이용하려면 로그인하세요" | 업데이트 노트 하단 |

#### 2.2 Hard Prompt (기능 제한, 회원 전용)

| 시점 | 동작 | UI |
|------|------|-----|
| 즐겨찾기 20개 초과 시도 | 추가 불가, 로그인 유도 | 바텀시트 (로그인/취소) |
| 커스텀 칵테일 등록 시도 | 로그인 필요 안내 | 바텀시트 (로그인/취소) |
| 히스토리 조회 시도 | 로그인 필요 안내 | 바텀시트 (로그인/취소) |
| 데이터 내보내기 시도 | 로그인 필요 안내 | 바텀시트 (로그인/취소) |

### 유도 UI 컴포넌트

```dart
// Soft Prompt - 하단 배너
class LoginPromptBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  final VoidCallback onLogin;

  // 닫기 버튼 포함, 24시간 후 다시 표시
}

// Hard Prompt - 바텀시트
class LoginRequiredSheet extends StatelessWidget {
  final String feature; // "즐겨찾기", "커스텀 칵테일" 등
  final VoidCallback onLogin;
  final VoidCallback onCancel;

  // 기능 설명 + 로그인 버튼 + 나중에 버튼
}
```

---

## 3. 비회원 칵테일 매칭 로직

### 3.1 데이터 저장 구조

```dart
// SharedPreferences 키
const String kSelectedIngredients = 'selected_ingredients';  // List<String>
const String kSelectedProducts = 'selected_products';        // List<String>
const String kFavorites = 'favorites';                       // List<String>
const String kLastSyncPrompt = 'last_sync_prompt';          // DateTime
```

### 3.2 매칭 플로우

```
┌─────────────────────────────────────────────────────────┐
│                    비회원 매칭 플로우                      │
├─────────────────────────────────────────────────────────┤
│                                                         │
│  ┌─────────────┐    ┌─────────────┐                    │
│  │   Products   │    │ Ingredients │                    │
│  │   (로컬)     │    │   (로컬)    │                    │
│  └──────┬──────┘    └──────┬──────┘                    │
│         │                  │                            │
│         ▼                  │                            │
│  ┌─────────────┐          │                            │
│  │ ingredient_ │          │                            │
│  │     id      │          │                            │
│  └──────┬──────┘          │                            │
│         │                  │                            │
│         ▼                  ▼                            │
│  ┌──────────────────────────┐                          │
│  │  allSelectedIngredientIds │  ← 합집합                │
│  │  (Riverpod Provider)      │                          │
│  └────────────┬─────────────┘                          │
│               │                                         │
│               ▼                                         │
│  ┌──────────────────────────┐                          │
│  │   cocktailMatchesProvider │                          │
│  │   (실시간 계산)            │                          │
│  └────────────┬─────────────┘                          │
│               │                                         │
│               ▼                                         │
│  ┌──────────────────────────┐                          │
│  │  UI: 만들 수 있는 칵테일   │                          │
│  │      거의 다 된 칵테일     │                          │
│  │      더 필요한 칵테일      │                          │
│  └──────────────────────────┘                          │
│                                                         │
└─────────────────────────────────────────────────────────┘
```

### 3.3 로컬 저장 Provider

```dart
/// 비회원용 - SharedPreferences 기반 선택 상태
final localSelectedIngredientsProvider =
    StateNotifierProvider<SelectedIngredientsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedIngredientsNotifier(prefs);
});

final localSelectedProductsProvider =
    StateNotifierProvider<SelectedProductsNotifier, Set<String>>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return SelectedProductsNotifier(prefs);
});

/// 통합 Provider - 비회원/회원 구분 없이 동일 인터페이스
final selectedIngredientIdsProvider = Provider<Set<String>>((ref) {
  final authState = ref.watch(authStateProvider);

  if (authState.isAuthenticated) {
    // 회원: DB에서 가져옴
    return ref.watch(userIngredientIdsFromDbProvider);
  } else {
    // 비회원: 로컬에서 가져옴
    return ref.watch(allSelectedIngredientIdsProvider);
  }
});
```

---

## 4. 회원 DB 연동 설계

### 4.1 기존 데이터베이스 스키마 (Supabase)

#### 마스터 테이블 (이미 존재)

```sql
-- 재료 마스터
CREATE TABLE ingredients (
  id TEXT PRIMARY KEY,                -- 'tequila', 'vodka', 'lime-juice'
  name TEXT NOT NULL,                 -- 'Tequila'
  name_ko TEXT,                       -- '데킬라'
  category TEXT,                      -- 'spirit', 'liqueur', 'juice'
  description TEXT,
  strength DECIMAL(5,2),              -- ABV (예: 40.0)
  origin TEXT
);

-- 재료 대체품
CREATE TABLE ingredient_substitutes (
  ingredient_id TEXT REFERENCES ingredients(id),
  substitute_id TEXT REFERENCES ingredients(id),
  PRIMARY KEY (ingredient_id, substitute_id)
);

-- 칵테일 마스터
CREATE TABLE cocktails (
  id TEXT PRIMARY KEY,                -- 'margarita', 'mojito'
  name TEXT NOT NULL,                 -- 'Margarita'
  name_ko TEXT,                       -- '마가리타'
  instructions TEXT NOT NULL,         -- 레시피 설명
  description TEXT,
  garnish TEXT,                       -- '라임 웨지'
  abv DECIMAL(5,2),                   -- 예상 도수
  tags TEXT[],                        -- ['classic', 'sour']
  glass TEXT,                         -- 'margarita glass'
  method TEXT,                        -- 'shake', 'stir', 'build'
  image_url TEXT
);

-- 칵테일-재료 매핑
CREATE TABLE cocktail_ingredients (
  cocktail_id TEXT REFERENCES cocktails(id),
  ingredient_id TEXT REFERENCES ingredients(id),
  amount DECIMAL(10,2),               -- 양 (예: 45)
  units TEXT,                         -- 'ml', 'oz', 'dash'
  is_optional BOOLEAN DEFAULT FALSE,
  note TEXT,                          -- '신선한 것으로'
  sort_order INTEGER DEFAULT 0,
  PRIMARY KEY (cocktail_id, ingredient_id)
);

-- 상품 마스터 (술병/제품)
CREATE TABLE products (
  id TEXT PRIMARY KEY,                -- 'el-jimador-reposado'
  name TEXT NOT NULL,                 -- 'Reposado'
  brand TEXT,                         -- 'El Jimador'
  ingredient_id TEXT REFERENCES ingredients(id),  -- → 'tequila-reposado'
  description TEXT,
  country TEXT,                       -- 'Mexico'
  volume_ml INTEGER,                  -- 750
  abv DECIMAL(5,2),                   -- 40.0
  image_url TEXT,
  thumbnail_url TEXT,
  barcode TEXT,                       -- UPC/EAN
  external_id TEXT,                   -- 외부 DB ID
  data_source TEXT DEFAULT 'manual'   -- 'manual', 'openfoodfacts', 'user'
);
```

#### 회원 연동 테이블 (추가 필요)

```sql
-- 회원 보유 상품
CREATE TABLE user_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  product_id TEXT NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  quantity INTEGER DEFAULT 1,
  note TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, product_id)
);

-- 회원 선택 재료 (직접 선택, fallback)
CREATE TABLE user_ingredients (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  ingredient_id TEXT NOT NULL REFERENCES ingredients(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, ingredient_id)
);

-- 회원 즐겨찾기
CREATE TABLE user_favorites (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  cocktail_id TEXT NOT NULL REFERENCES cocktails(id) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(user_id, cocktail_id)
);

-- RLS 정책 (각 테이블에 적용)
ALTER TABLE user_products ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_ingredients ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_favorites ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own data" ON user_products
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own data" ON user_ingredients
  FOR ALL USING (auth.uid() = user_id);
CREATE POLICY "Users manage own data" ON user_favorites
  FOR ALL USING (auth.uid() = user_id);

-- 인덱스
CREATE INDEX idx_user_products_user ON user_products(user_id);
CREATE INDEX idx_user_ingredients_user ON user_ingredients(user_id);
CREATE INDEX idx_user_favorites_user ON user_favorites(user_id);
CREATE INDEX idx_products_ingredient ON products(ingredient_id);
CREATE INDEX idx_products_barcode ON products(barcode);
```

### 4.2 테이블 관계도

```
┌─────────────────────────────────────────────────────────────────┐
│                        데이터 관계도                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │   products   │────────▶│  ingredients │                     │
│  │  (상품/술병)  │ ingredient_id  (재료 종류)  │                     │
│  └──────┬───────┘         └──────┬───────┘                     │
│         │                        │                              │
│         │                        │                              │
│         │                        ▼                              │
│         │                 ┌──────────────────┐                 │
│         │                 │ cocktail_        │                 │
│         │                 │ ingredients      │                 │
│         │                 │ (칵테일-재료 매핑) │                 │
│         │                 └────────┬─────────┘                 │
│         │                          │                            │
│         │                          ▼                            │
│         │                 ┌──────────────┐                     │
│         │                 │   cocktails   │                     │
│         │                 │   (칵테일)     │                     │
│         │                 └──────┬───────┘                     │
│         │                        │                              │
│         ▼                        ▼                              │
│  ┌──────────────┐         ┌──────────────┐                     │
│  │ user_products│         │user_favorites│                     │
│  │ (회원 보유)   │         │ (회원 즐찾)   │                     │
│  └──────┬───────┘         └──────────────┘                     │
│         │                                                       │
│         │         ┌──────────────┐                             │
│         │         │user_ingredients│                           │
│         │         │(회원 재료 직접선택)│                           │
│         │         └──────┬───────┘                             │
│         │                │                                      │
│         ▼                ▼                                      │
│  ┌─────────────────────────┐                                   │
│  │      auth.users         │                                   │
│  │    (Supabase Auth)      │                                   │
│  └─────────────────────────┘                                   │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

### 4.3 Provider 구현 (현재 구조 기반)

#### 현재 구현된 Provider (로컬 저장)

```dart
// lib/data/providers/product_provider.dart

/// 전체 상품 목록 (Supabase에서 조회)
final productsProvider = FutureProvider<List<Product>>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final response = await supabase.from('products').select().order('brand').order('name');
  return (response as List).map((row) => Product.fromSupabase(row)).toList();
});

/// 선택된 상품 ID (로컬 SharedPreferences)
final selectedProductsProvider = StateNotifierProvider<SelectedProductsNotifier, Set<String>>(...);

/// 상품에서 추출한 재료 ID
final ingredientIdsFromProductsProvider = Provider<Set<String>>((ref) {
  final productsAsync = ref.watch(productsProvider);
  final selectedProductIds = ref.watch(selectedProductsProvider);
  final products = productsAsync.valueOrNull ?? [];

  return products
      .where((p) => selectedProductIds.contains(p.id) && p.ingredientId != null)
      .map((p) => p.ingredientId!)
      .toSet();
});
```

```dart
// lib/data/providers/cocktail_provider.dart

/// 상품 + 직접선택 재료 통합
final allSelectedIngredientIdsProvider = Provider<Set<String>>((ref) {
  final fromProducts = ref.watch(ingredientIdsFromProductsProvider);
  final directSelection = ref.watch(selectedIngredientsProvider);
  return {...fromProducts, ...directSelection};
});

/// 선택 개수 합산
final totalSelectedCountProvider = Provider<int>((ref) {
  return ref.watch(selectedProductCountProvider) + ref.watch(selectedIngredientCountProvider);
});

/// 칵테일 매칭 (통합 재료 ID 사용)
final cocktailMatchesProvider = Provider<AsyncValue<List<CocktailMatch>>>((ref) {
  final selectedIngredients = ref.watch(allSelectedIngredientIdsProvider);
  // ... 매칭 로직
});
```

#### 회원 연동 시 추가할 Provider

```dart
// lib/data/providers/auth_provider.dart (추가 예정)

/// 현재 사용자 ID
final currentUserIdProvider = Provider<String?>((ref) {
  return Supabase.instance.client.auth.currentUser?.id;
});

/// 인증 상태
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserIdProvider) != null;
});

/// 회원 상품 목록 (DB 실시간 동기화)
final userProductsDbProvider = StreamProvider<List<UserProduct>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_products')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map(UserProduct.fromJson).toList());
});

/// 회원 재료 ID (DB 기반)
final userIngredientIdsFromDbProvider = Provider<Set<String>>((ref) {
  final userProducts = ref.watch(userProductsDbProvider).valueOrNull ?? [];
  final products = ref.watch(productsProvider).valueOrNull ?? [];
  final userIngredients = ref.watch(userIngredientsDbProvider).valueOrNull ?? [];

  final ingredientIds = <String>{};

  // 상품 → 재료 매핑
  for (final up in userProducts) {
    final product = products.firstWhereOrNull((p) => p.id == up.productId);
    if (product?.ingredientId != null) {
      ingredientIds.add(product!.ingredientId!);
    }
  }

  // 직접 선택 재료
  ingredientIds.addAll(userIngredients.map((ui) => ui.ingredientId));

  return ingredientIds;
});

/// 통합 Provider (비회원/회원 자동 분기)
final effectiveIngredientIdsProvider = Provider<Set<String>>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    return ref.watch(userIngredientIdsFromDbProvider);
  } else {
    return ref.watch(allSelectedIngredientIdsProvider);  // 로컬 저장
  }
});
```

### 4.4 로그인 시 데이터 마이그레이션

```dart
// lib/core/services/migration_service.dart (추가 예정)

class MigrationResult {
  int productsMigrated = 0;
  int ingredientsMigrated = 0;
  int favoritesMigrated = 0;
  bool get hasData => productsMigrated + ingredientsMigrated + favoritesMigrated > 0;
}

/// 비회원 → 회원 전환 시 로컬 데이터를 DB로 마이그레이션
class DataMigrationService {
  final SupabaseClient _supabase;
  final SharedPreferences _prefs;

  DataMigrationService(this._supabase, this._prefs);

  /// 마이그레이션 필요 여부 확인
  bool needsMigration() {
    final products = _prefs.getStringList('selected_products') ?? [];
    final ingredients = _prefs.getStringList('selected_ingredients') ?? [];
    final favorites = _prefs.getStringList('favorites') ?? [];
    return products.isNotEmpty || ingredients.isNotEmpty || favorites.isNotEmpty;
  }

  /// 로컬 데이터를 클라우드로 마이그레이션
  Future<MigrationResult> migrateToCloud(String userId) async {
    final result = MigrationResult();

    // 1. 선택된 상품 마이그레이션
    final localProducts = _prefs.getStringList('selected_products') ?? [];
    if (localProducts.isNotEmpty) {
      await _supabase.from('user_products').upsert(
        localProducts.map((id) => {'user_id': userId, 'product_id': id}).toList(),
        onConflict: 'user_id,product_id',
      );
      result.productsMigrated = localProducts.length;
    }

    // 2. 직접 선택된 재료 마이그레이션
    final localIngredients = _prefs.getStringList('selected_ingredients') ?? [];
    if (localIngredients.isNotEmpty) {
      await _supabase.from('user_ingredients').upsert(
        localIngredients.map((id) => {'user_id': userId, 'ingredient_id': id}).toList(),
        onConflict: 'user_id,ingredient_id',
      );
      result.ingredientsMigrated = localIngredients.length;
    }

    // 3. 즐겨찾기 마이그레이션
    final localFavorites = _prefs.getStringList('favorites') ?? [];
    if (localFavorites.isNotEmpty) {
      await _supabase.from('user_favorites').upsert(
        localFavorites.map((id) => {'user_id': userId, 'cocktail_id': id}).toList(),
        onConflict: 'user_id,cocktail_id',
      );
      result.favoritesMigrated = localFavorites.length;
    }

    return result;
  }

  /// 마이그레이션 후 로컬 데이터 정리 (선택적)
  Future<void> clearLocalData() async {
    await _prefs.remove('selected_products');
    await _prefs.remove('selected_ingredients');
    await _prefs.remove('favorites');
  }
}
```

### 4.5 칵테일 매칭 통합 플로우

```
┌─────────────────────────────────────────────────────────────────┐
│                     통합 칵테일 매칭 플로우                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌─────────────┐                   ┌─────────────┐             │
│  │   비회원     │                   │    회원     │             │
│  └──────┬──────┘                   └──────┬──────┘             │
│         │                                 │                     │
│         ▼                                 ▼                     │
│  ┌──────────────┐                 ┌──────────────┐             │
│  │SharedPreferences│                 │ Supabase DB │             │
│  │ • selected_products │             │ • user_products│             │
│  │ • selected_ingredients│           │ • user_ingredients│          │
│  └──────┬───────┘                 └──────┬───────┘             │
│         │                                │                      │
│         └────────────┬───────────────────┘                      │
│                      │                                          │
│                      ▼                                          │
│         ┌────────────────────────┐                             │
│         │effectiveIngredientIds  │  ← isAuthenticated 분기      │
│         │       Provider         │                             │
│         └───────────┬────────────┘                             │
│                     │                                           │
│                     ▼                                           │
│         ┌────────────────────────┐                             │
│         │ cocktailMatchesProvider│  ← 동일한 매칭 로직           │
│         │ (canMake, missingCount)│                             │
│         └───────────┬────────────┘                             │
│                     │                                           │
│                     ▼                                           │
│         ┌────────────────────────┐                             │
│         │    CocktailsScreen     │  ← 동일한 UI                 │
│         │  • 만들 수 있는 칵테일   │                             │
│         │  • 하나만 더 있으면      │                             │
│         │  • 전체 칵테일          │                             │
│         └────────────────────────┘                             │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## 5. 구현 우선순위

### Phase 1: 비회원 기능 완성 ✅
- [x] 로컬 재료 선택 및 저장
- [x] 로컬 상품 선택 및 저장
- [x] 칵테일 매칭 로직
- [x] 로컬 즐겨찾기 (20개 제한)

### Phase 2: 인증 기반 구축
- [ ] Supabase Auth 연동 (이메일, 소셜 로그인)
- [ ] 회원 테이블 생성 (user_products, user_ingredients, user_favorites)
- [ ] 인증 상태 Provider
- [ ] 로그인/회원가입 UI

### Phase 3: 데이터 동기화
- [ ] 통합 Provider (비회원/회원 자동 분기)
- [ ] 로컬 → 클라우드 마이그레이션
- [ ] 실시간 동기화 (Supabase Realtime)

### Phase 4: 회원 전용 기능
- [ ] 무제한 즐겨찾기
- [ ] 커스텀 칵테일 등록
- [ ] 만든 칵테일 히스토리
- [ ] 취향 기반 추천

---

## 6. UI/UX 가이드라인

### 로그인 유도 원칙

1. **가치 선제공**: 핵심 기능은 로그인 없이 체험 가능
2. **투명한 이유 설명**: 왜 로그인이 필요한지 명확히 안내
3. **쉬운 거절**: 항상 "나중에" 옵션 제공
4. **빈도 제한**: 같은 유도는 24시간에 1회만
5. **맥락적 유도**: 사용자 행동과 관련된 시점에 유도

### 마이그레이션 UX

```
┌────────────────────────────────────┐
│  🎉 환영합니다!                     │
│                                    │
│  기존에 저장해둔 재료 정보를          │
│  계정에 연결할까요?                  │
│                                    │
│  • 선택한 재료: 12개                │
│  • 선택한 상품: 5개                 │
│  • 즐겨찾기: 8개                    │
│                                    │
│  ┌──────────┐  ┌──────────┐       │
│  │  연결하기  │  │  건너뛰기  │       │
│  └──────────┘  └──────────┘       │
└────────────────────────────────────┘
```
