import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/config/supabase_config.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'data/providers/providers.dart';
import 'features/auth/password_reset_screen.dart';
import 'features/splash/splash_screen.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const CockatApp(),
    ),
  );
}

// Global navigator key for auth state navigation
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class CockatApp extends ConsumerStatefulWidget {
  const CockatApp({super.key});

  @override
  ConsumerState<CockatApp> createState() => _CockatAppState();
}

class _CockatAppState extends ConsumerState<CockatApp> {
  StreamSubscription<AuthState>? _authSubscription;

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    _authSubscription =
        Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;

      // 비밀번호 재설정 이벤트 감지
      if (event == AuthChangeEvent.passwordRecovery) {
        // PasswordResetScreen으로 이동
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Cockat',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme(),
      darkTheme: AppTheme.darkTheme(),
      themeMode: themeMode,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const SplashScreen(),
      // OAuth 콜백 딥링크를 빈 페이지로 처리 (Supabase가 auth 처리)
      onGenerateRoute: (settings) {
        final name = settings.name ?? '';
        // io.supabase.cockat:// 스킴의 딥링크는 Supabase가 처리함
        if (name.contains('login-callback') ||
            name.startsWith('io.supabase.cockat://')) {
          // 빈 페이지 반환하여 라우팅 에러 방지
          return MaterialPageRoute(
            builder: (_) => const SizedBox.shrink(),
          );
        }
        return null;
      },
    );
  }
}
