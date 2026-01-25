import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// SharedPreferences instance provider
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be overridden in main');
});

// Theme mode provider
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;
  static const _key = 'theme_mode';

  ThemeModeNotifier(this._prefs) : super(_loadThemeMode(_prefs));

  static ThemeMode _loadThemeMode(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    return switch (value) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(_key, mode.name);
  }
}

// Locale provider
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});

class LocaleNotifier extends StateNotifier<Locale?> {
  final SharedPreferences _prefs;
  static const _key = 'locale';

  LocaleNotifier(this._prefs) : super(_loadLocale(_prefs));

  static Locale? _loadLocale(SharedPreferences prefs) {
    final value = prefs.getString(_key);
    if (value == null) return null;
    return Locale(value);
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale != null) {
      await _prefs.setString(_key, locale.languageCode);
    } else {
      await _prefs.remove(_key);
    }
  }
}

/// Returns the current locale code as a string (e.g., 'en', 'ko')
/// Falls back to 'en' if no locale is set or system locale is not supported
final currentLocaleCodeProvider = Provider<String>((ref) {
  final locale = ref.watch(localeProvider);
  if (locale != null) {
    return locale.languageCode;
  }
  // Fall back to system locale if available, otherwise 'en'
  final systemLocale = WidgetsBinding.instance.platformDispatcher.locale;
  final supportedLocales = ['en', 'ko'];
  if (supportedLocales.contains(systemLocale.languageCode)) {
    return systemLocale.languageCode;
  }
  return 'en';
});
