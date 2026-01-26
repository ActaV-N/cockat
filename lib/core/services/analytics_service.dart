import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // User authentication events
  Future<void> logLogin({required String method}) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp({required String method}) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> logLogout() async {
    await _analytics.logEvent(name: 'logout');
  }

  // Search events
  Future<void> logSearch({required String searchTerm}) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  // Cocktail events
  Future<void> logViewCocktail({
    required String cocktailId,
    required String cocktailName,
  }) async {
    await _analytics.logEvent(
      name: 'view_cocktail',
      parameters: {
        'cocktail_id': cocktailId,
        'cocktail_name': cocktailName,
      },
    );
  }

  Future<void> logFilterCocktails({
    required String filterType,
    String? filterValue,
  }) async {
    await _analytics.logEvent(
      name: 'filter_cocktails',
      parameters: {
        'filter_type': filterType,
        if (filterValue != null) 'filter_value': filterValue,
      },
    );
  }

  // My Bar events
  Future<void> logAddToMyBar({
    required String productId,
    required String productName,
    required String category,
  }) async {
    await _analytics.logEvent(
      name: 'add_to_my_bar',
      parameters: {
        'product_id': productId,
        'product_name': productName,
        'category': category,
      },
    );
  }

  Future<void> logRemoveFromMyBar({
    required String productId,
    required String productName,
  }) async {
    await _analytics.logEvent(
      name: 'remove_from_my_bar',
      parameters: {
        'product_id': productId,
        'product_name': productName,
      },
    );
  }

  // Onboarding events
  Future<void> logOnboardingStart() async {
    await _analytics.logEvent(name: 'onboarding_start');
  }

  Future<void> logOnboardingComplete() async {
    await _analytics.logEvent(name: 'onboarding_complete');
  }

  Future<void> logOnboardingSkip({required int stepIndex}) async {
    await _analytics.logEvent(
      name: 'onboarding_skip',
      parameters: {'step_index': stepIndex},
    );
  }

  // Settings events
  Future<void> logChangeTheme({required String theme}) async {
    await _analytics.logEvent(
      name: 'change_theme',
      parameters: {'theme': theme},
    );
  }

  Future<void> logChangeLanguage({required String language}) async {
    await _analytics.logEvent(
      name: 'change_language',
      parameters: {'language': language},
    );
  }

  // User properties
  Future<void> setUserProperties({
    String? userId,
    String? themeMode,
    String? language,
    int? myBarProductCount,
  }) async {
    if (userId != null) {
      await _analytics.setUserId(id: userId);
    }
    if (themeMode != null) {
      await _analytics.setUserProperty(name: 'theme_mode', value: themeMode);
    }
    if (language != null) {
      await _analytics.setUserProperty(name: 'language', value: language);
    }
    if (myBarProductCount != null) {
      await _analytics.setUserProperty(
        name: 'my_bar_product_count',
        value: myBarProductCount.toString(),
      );
    }
  }

  // Generic event logging
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(name: name, parameters: parameters);
  }
}
