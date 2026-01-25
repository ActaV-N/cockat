import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_provider.dart';
import 'favorites_provider.dart';
import 'ingredient_provider.dart';
import 'misc_item_provider.dart';
import 'product_provider.dart';
import 'settings_provider.dart';

// ==================== Unit System ====================

/// Available unit systems for measurements
enum UnitSystem {
  ml('ml', 'Milliliters', '밀리리터'),
  oz('oz', 'Ounces', '온스'),
  parts('parts', 'Parts', '비율');

  final String value;
  final String label;
  final String labelKo;

  const UnitSystem(this.value, this.label, this.labelKo);

  String getLocalizedLabel(String locale) {
    return locale == 'ko' ? labelKo : label;
  }

  static UnitSystem fromString(String value) {
    return UnitSystem.values.firstWhere(
      (u) => u.value == value,
      orElse: () => UnitSystem.ml,
    );
  }
}

// ==================== Local Preferences (Non-authenticated) ====================

/// Onboarding completed flag (local)
final onboardingCompletedLocalProvider =
    StateNotifierProvider<OnboardingCompletedNotifier, bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return OnboardingCompletedNotifier(prefs);
});

class OnboardingCompletedNotifier extends StateNotifier<bool> {
  final SharedPreferences _prefs;
  static const _key = 'onboarding_completed';

  OnboardingCompletedNotifier(this._prefs) : super(_prefs.getBool(_key) ?? false);

  Future<void> setCompleted(bool value) async {
    state = value;
    await _prefs.setBool(_key, value);
  }

  Future<void> reset() async {
    state = false;
    await _prefs.setBool(_key, false);
  }
}

/// Unit system preference (local)
final unitSystemLocalProvider =
    StateNotifierProvider<UnitSystemNotifier, UnitSystem>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return UnitSystemNotifier(prefs);
});

class UnitSystemNotifier extends StateNotifier<UnitSystem> {
  final SharedPreferences _prefs;
  static const _key = 'unit_system';

  UnitSystemNotifier(this._prefs)
      : super(UnitSystem.fromString(_prefs.getString(_key) ?? 'ml'));

  Future<void> setUnitSystem(UnitSystem unit) async {
    state = unit;
    await _prefs.setString(_key, unit.value);
  }
}

// ==================== DB Preferences (Authenticated) ====================

/// User preferences from DB
final userPreferencesDbProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return null;

  final response = await supabase
      .from('user_preferences')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  return response;
});

// ==================== Unified Providers (Auto-switch) ====================

/// Unified onboarding completed status (with local fallback)
final effectiveOnboardingCompletedProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final dbPrefs = ref.watch(userPreferencesDbProvider);
    final localValue = ref.read(onboardingCompletedLocalProvider);

    return dbPrefs.when(
      data: (prefs) => prefs?['onboarding_completed'] ?? localValue,
      loading: () => localValue, // Use local value while loading
      error: (e, s) => localValue, // Fallback to local on error
    );
  } else {
    return ref.watch(onboardingCompletedLocalProvider);
  }
});

/// Unified unit system preference
final effectiveUnitSystemProvider = Provider<UnitSystem>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final dbPrefs = ref.watch(userPreferencesDbProvider);
    final unitStr = dbPrefs.valueOrNull?['unit_system'] as String?;
    return UnitSystem.fromString(unitStr ?? 'ml');
  } else {
    return ref.watch(unitSystemLocalProvider);
  }
});

// ==================== Onboarding Service ====================

/// Unified onboarding service
final onboardingServiceProvider = Provider<OnboardingService>((ref) {
  return OnboardingService(ref);
});

class OnboardingService {
  final Ref _ref;

  OnboardingService(this._ref);

  bool get isAuthenticated => _ref.read(isAuthenticatedProvider);

  /// Mark onboarding as completed
  Future<void> completeOnboarding() async {
    if (isAuthenticated) {
      await _updateDbPreferences(onboardingCompleted: true);
    } else {
      await _ref.read(onboardingCompletedLocalProvider.notifier).setCompleted(true);
    }
  }

  /// Reset onboarding (to re-show setup flow)
  Future<void> resetOnboarding() async {
    if (isAuthenticated) {
      await _updateDbPreferences(onboardingCompleted: false);
    } else {
      await _ref.read(onboardingCompletedLocalProvider.notifier).reset();
    }
  }

  /// Set unit system preference
  Future<void> setUnitSystem(UnitSystem unit) async {
    if (isAuthenticated) {
      await _updateDbPreferences(unitSystem: unit.value);
    } else {
      await _ref.read(unitSystemLocalProvider.notifier).setUnitSystem(unit);
    }
  }

  /// Update DB preferences (upsert)
  Future<void> _updateDbPreferences({
    bool? onboardingCompleted,
    String? unitSystem,
  }) async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    final updates = <String, dynamic>{
      'user_id': userId,
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (onboardingCompleted != null) {
      updates['onboarding_completed'] = onboardingCompleted;
    }
    if (unitSystem != null) {
      updates['unit_system'] = unitSystem;
    }

    await supabase.from('user_preferences').upsert(updates);
    _ref.invalidate(userPreferencesDbProvider);
  }

  /// Migrate local preferences to DB after login
  Future<void> migrateLocalToDb() async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    // Migrate user preferences
    final localOnboarding = _ref.read(onboardingCompletedLocalProvider);
    final localUnit = _ref.read(unitSystemLocalProvider);

    await supabase.from('user_preferences').upsert({
      'user_id': userId,
      'onboarding_completed': localOnboarding,
      'unit_system': localUnit.value,
      'updated_at': DateTime.now().toIso8601String(),
    });

    // Migrate selected products
    final localProducts = _ref.read(selectedProductsProvider);
    if (localProducts.isNotEmpty) {
      final productRows = localProducts
          .map((id) => {'user_id': userId, 'product_id': id})
          .toList();
      await supabase.from('user_products').upsert(productRows);
    }

    // Migrate selected misc items
    final localMiscItems = _ref.read(selectedMiscItemsLocalProvider);
    if (localMiscItems.isNotEmpty) {
      final miscItemRows = localMiscItems
          .map((id) => {'user_id': userId, 'misc_item_id': id})
          .toList();
      await supabase.from('user_misc_items').upsert(miscItemRows);
    }

    // Migrate selected ingredients
    final localIngredients = _ref.read(selectedIngredientsProvider);
    if (localIngredients.isNotEmpty) {
      final ingredientRows = localIngredients
          .map((id) => {'user_id': userId, 'ingredient_id': id})
          .toList();
      await supabase.from('user_ingredients').upsert(ingredientRows);
    }

    // Migrate favorites
    final localFavorites = _ref.read(favoriteCocktailsProvider);
    if (localFavorites.isNotEmpty) {
      final favoriteRows = localFavorites
          .map((id) => {'user_id': userId, 'cocktail_id': id})
          .toList();
      await supabase.from('user_favorites').upsert(favoriteRows);
    }

    // Invalidate all providers to refresh from DB
    _ref.invalidate(userPreferencesDbProvider);
    _ref.invalidate(userProductsDbProvider);
    _ref.invalidate(userMiscItemsDbProvider);
    _ref.invalidate(userIngredientsDbProvider);
    _ref.invalidate(userFavoritesDbProvider);
  }

  /// Sync DB preferences to local (for offline support after login)
  Future<void> syncDbToLocal() async {
    final supabase = _ref.read(supabaseClientProvider);
    final userId = _ref.read(currentUserIdProvider);
    if (userId == null) return;

    try {
      final response = await supabase
          .from('user_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        // Sync DB values to local storage
        final onboardingCompleted = response['onboarding_completed'] ?? false;
        final unitSystem = UnitSystem.fromString(response['unit_system'] ?? 'ml');

        await _ref.read(onboardingCompletedLocalProvider.notifier).setCompleted(onboardingCompleted);
        await _ref.read(unitSystemLocalProvider.notifier).setUnitSystem(unitSystem);
      }
    } catch (e) {
      // Ignore errors (offline, etc.)
    }
  }

  /// Clear all local data (used after login to use DB data only)
  Future<void> clearLocalData() async {
    // Clear local preferences
    await _ref.read(onboardingCompletedLocalProvider.notifier).setCompleted(true);
    await _ref.read(unitSystemLocalProvider.notifier).setUnitSystem(UnitSystem.ml);

    // Clear selected products (sync method, uses fire-and-forget pattern)
    _ref.read(selectedProductsProvider.notifier).clear();

    // Clear selected misc items
    await _ref.read(selectedMiscItemsLocalProvider.notifier).clear();

    // Clear selected ingredients
    await _ref.read(selectedIngredientsProvider.notifier).clear();

    // Clear favorites
    await _ref.read(favoriteCocktailsProvider.notifier).clear();
  }
}

// ==================== Local Data Detection ====================

/// Check if user has any local data (products, misc items, ingredients, favorites)
final hasLocalDataProvider = Provider<bool>((ref) {
  final products = ref.watch(selectedProductsProvider);
  final miscItems = ref.watch(selectedMiscItemsLocalProvider);
  final ingredients = ref.watch(selectedIngredientsProvider);
  final favorites = ref.watch(favoriteCocktailsProvider);

  return products.isNotEmpty ||
      miscItems.isNotEmpty ||
      ingredients.isNotEmpty ||
      favorites.isNotEmpty;
});

// ==================== Onboarding Step Management ====================

/// Current onboarding step (for multi-page onboarding)
final onboardingStepProvider = StateProvider<int>((ref) => 0);

/// Total number of onboarding steps
const int totalOnboardingSteps = 4; // Products, Misc Items, Preferences, Auth
