# Firebase Analytics 통합 구현 전략

## 개요

### 목적
- Flutter 앱(iOS/Android)에 Firebase Analytics를 통합하여 사용자 행동 데이터 수집
- 주요 사용자 여정 및 인게이지먼트 메트릭 추적
- 데이터 기반 의사결정을 위한 인사이트 확보
- 앱 성능 및 사용성 개선을 위한 근거 마련

### 범위
- Firebase 프로젝트 설정 및 Flutter 앱 연동
- iOS/Android 플랫폼별 네이티브 설정
- Analytics 서비스 추상화 레이어 구현
- 핵심 사용자 여정 이벤트 추적 구현
- 디버그 모드 설정 및 검증

### 예상 소요 기간
- 초기 설정 및 통합: 2-3시간
- 이벤트 추적 구현: 3-4시간
- 테스트 및 검증: 1-2시간
- **총 예상 시간**: 6-9시간

---

## 현재 상태 분석

### 기존 구현
**확인된 현재 상태**:
- ✅ Flutter 프로젝트 구조: 표준 Flutter 앱 구조
- ✅ 상태 관리: Riverpod 사용 중
- ✅ 백엔드: Supabase 통합 완료 (인증, 데이터베이스)
- ✅ 네비게이션: MaterialApp 기반
- ✅ iOS 설정: Info.plist 존재, 딥링크 설정 완료
- ✅ Android 설정: build.gradle.kts (Kotlin DSL)
- ❌ Firebase 설정: 미존재 (google-services.json, GoogleService-Info.plist 없음)
- ❌ firebase_options.dart: 미존재
- ❌ Firebase 관련 패키지: 미설치

### 문제점/한계
1. **분석 데이터 부재**: 현재 사용자 행동 데이터 수집 없음
2. **인사이트 부족**: 어떤 기능이 많이 사용되는지, 사용자 여정이 어떤지 파악 불가
3. **성능 모니터링 부재**: 앱 성능 및 크래시 데이터 추적 불가
4. **A/B 테스트 불가**: 데이터 기반 실험 및 최적화 어려움

### 관련 코드/모듈
**주요 화면 및 기능**:
- `/lib/main.dart`: 앱 진입점, Supabase 초기화
- `/lib/features/splash/`: 스플래시 화면
- `/lib/features/onboarding/`: 온보딩 플로우
- `/lib/features/auth/`: 로그인/회원가입
- `/lib/features/home/`: 홈 화면
- `/lib/features/cocktails/`: 칵테일 탐색, 검색, 상세
- `/lib/features/products/`: 제품 카탈로그, My Bar
- `/lib/features/ingredients/`: 재료 관리
- `/lib/features/settings/`: 설정 화면
- `/lib/features/profile/`: 프로필

---

## 구현 전략

### 접근 방식

**단계적 통합 전략**:
1. **Phase 1**: Firebase 프로젝트 설정 및 기본 통합
2. **Phase 2**: Analytics 서비스 레이어 구현
3. **Phase 3**: 핵심 이벤트 추적 구현
4. **Phase 4**: 검증 및 최적화

**설계 원칙**:
- **추상화**: Analytics 로직을 서비스 레이어로 분리
- **타입 안전성**: 이벤트 이름과 파라미터를 상수로 관리
- **확장성**: 향후 다른 분석 도구 추가 가능한 구조
- **성능**: 비동기 처리로 UI 블로킹 방지
- **프라이버시**: GDPR/앱스토어 가이드라인 준수

---

### 세부 구현 단계

#### 1. Firebase 프로젝트 설정 (1시간)

**1.1 Firebase Console 작업**
```yaml
작업:
  - Firebase Console(https://console.firebase.google.com) 접속
  - 새 프로젝트 생성 또는 기존 프로젝트 선택
  - 프로젝트명: "Cockat" (또는 선호하는 이름)
  - Google Analytics 활성화 선택
  - iOS 앱 추가:
      - Bundle ID: "com.cockat.cockat" (Info.plist 기준)
      - App nickname: "Cockat iOS"
      - GoogleService-Info.plist 다운로드
  - Android 앱 추가:
      - Package name: "com.cockat.cockat" (build.gradle.kts 기준)
      - App nickname: "Cockat Android"
      - google-services.json 다운로드
```

**1.2 FlutterFire CLI 설정 (권장 방법)**
```bash
# FlutterFire CLI 설치
dart pub global activate flutterfire_cli

# Firebase 프로젝트와 Flutter 앱 연결 (자동 설정)
flutterfire configure

# 선택사항:
# - Firebase 프로젝트 선택
# - iOS/Android 플랫폼 선택
# - 자동으로 firebase_options.dart 생성
```

**결과물**:
- `ios/Runner/GoogleService-Info.plist`
- `android/app/google-services.json`
- `lib/firebase_options.dart` (FlutterFire CLI 사용 시 자동 생성)

---

#### 2. Flutter 패키지 추가 (30분)

**2.1 pubspec.yaml 수정**
```yaml
dependencies:
  # 기존 패키지들...

  # Firebase
  firebase_core: ^3.12.0
  firebase_analytics: ^11.6.0

dev_dependencies:
  # 기존 dev 패키지들...
```

**2.2 패키지 설치**
```bash
flutter pub get
```

**2.3 패키지 버전 확인**
- 최신 안정 버전 사용 권장
- 호환성 확인: https://pub.dev/packages/firebase_analytics

---

#### 3. iOS 플랫폼 설정 (30분)

**3.1 GoogleService-Info.plist 배치**
```bash
# Firebase Console에서 다운로드한 파일을
# ios/Runner/ 디렉토리에 배치

cp ~/Downloads/GoogleService-Info.plist ios/Runner/
```

**3.2 Xcode 프로젝트 설정**
```
1. ios/Runner.xcworkspace 열기 (Xcode)
2. Runner 프로젝트 선택
3. GoogleService-Info.plist를 Runner 타겟에 추가
   - 파일 트리에서 Runner 폴더에 드래그
   - "Copy items if needed" 체크
   - Target: Runner 선택
4. 빌드 설정 확인
```

**3.3 Podfile 업데이트 (필요시)**
```ruby
# ios/Podfile
platform :ios, '12.0'  # Firebase 최소 요구사항
```

**3.4 CocoaPods 설치**
```bash
cd ios
pod install --repo-update
cd ..
```

---

#### 4. Android 플랫폼 설정 (30분)

**4.1 google-services.json 배치**
```bash
# Firebase Console에서 다운로드한 파일을
# android/app/ 디렉토리에 배치

cp ~/Downloads/google-services.json android/app/
```

**4.2 build.gradle.kts 수정**

**android/build.gradle.kts** (프로젝트 레벨):
```kotlin
plugins {
    // 기존 plugins...
    id("com.google.gms.google-services") version "4.4.2" apply false
}

buildscript {
    dependencies {
        // Firebase BoM으로 버전 관리 (선택사항)
        classpath("com.google.gms:google-services:4.4.2")
    }
}
```

**android/app/build.gradle.kts** (앱 레벨):
```kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")  // 추가
}

android {
    namespace = "com.cockat.cockat"
    compileSdk = flutter.compileSdkVersion
    // 기존 설정...

    defaultConfig {
        applicationId = "com.cockat.cockat"
        minSdk = 21  // Firebase 최소 요구사항
        // 기존 설정...
    }
}

dependencies {
    // Firebase BoM 사용 (선택사항, 버전 자동 관리)
    implementation(platform("com.google.firebase:firebase-bom:33.7.0"))
    implementation("com.google.firebase:firebase-analytics")
}
```

---

#### 5. Firebase 초기화 구현 (1시간)

**5.1 main.dart 수정**

```dart
// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';  // FlutterFire CLI로 생성된 파일

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 기존 초기화 코드...
  await dotenv.load(fileName: '.env');

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
```

**5.2 firebase_options.dart 생성 (FlutterFire CLI 미사용 시)**

FlutterFire CLI를 사용하지 않는 경우, 수동으로 생성:

```dart
// lib/firebase_options.dart
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Web platform is not supported');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'YOUR_ANDROID_API_KEY',
    appId: 'YOUR_ANDROID_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'YOUR_IOS_API_KEY',
    appId: 'YOUR_IOS_APP_ID',
    messagingSenderId: 'YOUR_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_STORAGE_BUCKET',
    iosBundleId: 'com.cockat.cockat',
  );
}
```

**참고**: GoogleService-Info.plist와 google-services.json에서 값 확인

---

#### 6. Analytics 서비스 레이어 구현 (2-3시간)

**6.1 Analytics 서비스 클래스**

```dart
// lib/core/services/analytics_service.dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  AnalyticsService._();
  static final instance = AnalyticsService._();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // 화면 조회 추적
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('📊 Screen View: $screenName');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: $e');
      }
    }
  }

  // 커스텀 이벤트 추적
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  }) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      if (kDebugMode) {
        print('📊 Event: $name ${parameters ?? ""}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: $e');
      }
    }
  }

  // 사용자 속성 설정
  Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
      if (kDebugMode) {
        print('📊 User Property: $name = $value');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: $e');
      }
    }
  }

  // 사용자 ID 설정
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
      if (kDebugMode) {
        print('📊 User ID: $userId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Analytics Error: $e');
      }
    }
  }

  // 로그인 이벤트
  Future<void> logLogin({String? method}) async {
    await logEvent(
      name: 'login',
      parameters: {'method': method ?? 'unknown'},
    );
  }

  // 회원가입 이벤트
  Future<void> logSignUp({String? method}) async {
    await logEvent(
      name: 'sign_up',
      parameters: {'method': method ?? 'email'},
    );
  }

  // 칵테일 조회 이벤트
  Future<void> logViewCocktail({
    required String cocktailId,
    required String cocktailName,
  }) async {
    await logEvent(
      name: AnalyticsEvents.viewCocktail,
      parameters: {
        'cocktail_id': cocktailId,
        'cocktail_name': cocktailName,
      },
    );
  }

  // 검색 이벤트
  Future<void> logSearch({
    required String searchTerm,
    String? category,
  }) async {
    await logEvent(
      name: 'search',
      parameters: {
        'search_term': searchTerm,
        if (category != null) 'category': category,
      },
    );
  }

  // My Bar 제품 추가
  Future<void> logAddToMyBar({
    required String productId,
    required String productName,
  }) async {
    await logEvent(
      name: AnalyticsEvents.addToMyBar,
      parameters: {
        'product_id': productId,
        'product_name': productName,
      },
    );
  }

  // 디버그 모드 설정 (개발 중)
  Future<void> setAnalyticsCollectionEnabled(bool enabled) async {
    await _analytics.setAnalyticsCollectionEnabled(enabled);
  }
}
```

**6.2 Analytics 이벤트 상수**

```dart
// lib/core/services/analytics_events.dart
class AnalyticsEvents {
  // Screen Names
  static const String screenSplash = 'splash_screen';
  static const String screenOnboarding = 'onboarding_screen';
  static const String screenHome = 'home_screen';
  static const String screenCocktails = 'cocktails_screen';
  static const String screenCocktailDetail = 'cocktail_detail_screen';
  static const String screenCocktailSearch = 'cocktail_search_screen';
  static const String screenMyBar = 'my_bar_screen';
  static const String screenProducts = 'products_screen';
  static const String screenProductDetail = 'product_detail_screen';
  static const String screenIngredients = 'ingredients_screen';
  static const String screenSettings = 'settings_screen';
  static const String screenProfile = 'profile_screen';
  static const String screenLogin = 'login_screen';
  static const String screenSignUp = 'signup_screen';

  // User Actions
  static const String viewCocktail = 'view_cocktail';
  static const String searchCocktail = 'search_cocktail';
  static const String addToMyBar = 'add_to_my_bar';
  static const String removeFromMyBar = 'remove_from_my_bar';
  static const String viewProduct = 'view_product';
  static const String shareRecipe = 'share_recipe';
  static const String toggleTheme = 'toggle_theme';
  static const String changeLanguage = 'change_language';
  static const String completeOnboarding = 'complete_onboarding';

  // Onboarding Steps
  static const String onboardingPreferences = 'onboarding_preferences';
  static const String onboardingProducts = 'onboarding_products';
  static const String onboardingMiscItems = 'onboarding_misc_items';
  static const String onboardingAuth = 'onboarding_auth';

  // User Properties
  static const String propThemeMode = 'theme_mode';
  static const String propLanguage = 'language';
  static const String propMyBarCount = 'my_bar_count';
  static const String propFavoriteSpirit = 'favorite_spirit';
}

class AnalyticsParameters {
  static const String cocktailId = 'cocktail_id';
  static const String cocktailName = 'cocktail_name';
  static const String productId = 'product_id';
  static const String productName = 'product_name';
  static const String searchTerm = 'search_term';
  static const String category = 'category';
  static const String method = 'method';
  static const String source = 'source';
}
```

**6.3 Riverpod Provider 생성**

```dart
// lib/core/services/providers.dart (또는 기존 providers.dart에 추가)
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_service.dart';

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return AnalyticsService.instance;
});
```

---

#### 7. 화면 추적 구현 (1-2시간)

**7.1 Base Screen Mixin 생성 (옵션)**

```dart
// lib/core/mixins/analytics_mixin.dart
import 'package:flutter/material.dart';
import '../services/analytics_service.dart';

mixin AnalyticsMixin<T extends StatefulWidget> on State<T> {
  String get screenName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(screenName: screenName);
    });
  }
}
```

**7.2 주요 화면에 추적 추가**

**예시 1: 홈 화면**
```dart
// lib/features/home/home_screen.dart
import '../../core/services/analytics_service.dart';
import '../../core/services/analytics_events.dart';

class HomeScreen extends ConsumerStatefulWidget {
  // 기존 코드...
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AnalyticsService.instance.logScreenView(
        screenName: AnalyticsEvents.screenHome,
      );
    });
  }

  // 기존 코드...
}
```

**예시 2: 칵테일 상세 화면**
```dart
// lib/features/cocktails/cocktail_detail_screen.dart
import '../../core/services/analytics_service.dart';
import '../../core/services/analytics_events.dart';

class CocktailDetailScreen extends ConsumerStatefulWidget {
  final String cocktailId;
  final String cocktailName;
  // 기존 코드...
}

class _CocktailDetailScreenState extends ConsumerState<CocktailDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // 화면 조회 추적
      AnalyticsService.instance.logScreenView(
        screenName: AnalyticsEvents.screenCocktailDetail,
        parameters: {
          'cocktail_id': widget.cocktailId,
          'cocktail_name': widget.cocktailName,
        },
      );

      // 칵테일 조회 이벤트
      AnalyticsService.instance.logViewCocktail(
        cocktailId: widget.cocktailId,
        cocktailName: widget.cocktailName,
      );
    });
  }

  // 기존 코드...
}
```

---

#### 8. 사용자 액션 추적 구현 (1-2시간)

**8.1 My Bar 추가/제거 추적**

```dart
// lib/features/products/my_bar_screen.dart
void _addToMyBar(Product product) async {
  // 기존 비즈니스 로직...

  // Analytics 추적
  await AnalyticsService.instance.logAddToMyBar(
    productId: product.id,
    productName: product.name,
  );
}

void _removeFromMyBar(Product product) async {
  // 기존 비즈니스 로직...

  // Analytics 추적
  await AnalyticsService.instance.logEvent(
    name: AnalyticsEvents.removeFromMyBar,
    parameters: {
      'product_id': product.id,
      'product_name': product.name,
    },
  );
}
```

**8.2 검색 추적**

```dart
// lib/features/cocktails/cocktail_search_screen.dart
void _performSearch(String searchTerm) {
  // 기존 검색 로직...

  // Analytics 추적
  AnalyticsService.instance.logSearch(
    searchTerm: searchTerm,
    category: 'cocktails',
  );
}
```

**8.3 온보딩 완료 추적**

```dart
// lib/features/onboarding/onboarding_screen.dart
void _completeOnboarding() async {
  // 기존 온보딩 완료 로직...

  // Analytics 추적
  await AnalyticsService.instance.logEvent(
    name: AnalyticsEvents.completeOnboarding,
  );
}
```

**8.4 로그인/회원가입 추적**

```dart
// lib/features/auth/login_screen.dart
Future<void> _handleLogin(String method) async {
  // 기존 로그인 로직...

  // Analytics 추적
  await AnalyticsService.instance.logLogin(method: method);

  // 사용자 ID 설정
  final userId = supabase.auth.currentUser?.id;
  await AnalyticsService.instance.setUserId(userId);
}
```

---

#### 9. 사용자 속성 추적 구현 (30분)

**9.1 테마 변경 추적**

```dart
// lib/data/providers/theme_provider.dart (또는 해당 위치)
Future<void> toggleTheme() async {
  // 기존 테마 변경 로직...

  // Analytics 사용자 속성 설정
  await AnalyticsService.instance.setUserProperty(
    name: AnalyticsEvents.propThemeMode,
    value: isDarkMode ? 'dark' : 'light',
  );

  // 이벤트 추적
  await AnalyticsService.instance.logEvent(
    name: AnalyticsEvents.toggleTheme,
    parameters: {'theme': isDarkMode ? 'dark' : 'light'},
  );
}
```

**9.2 언어 변경 추적**

```dart
// lib/data/providers/locale_provider.dart (또는 해당 위치)
Future<void> changeLanguage(String languageCode) async {
  // 기존 언어 변경 로직...

  // Analytics 사용자 속성 설정
  await AnalyticsService.instance.setUserProperty(
    name: AnalyticsEvents.propLanguage,
    value: languageCode,
  );

  // 이벤트 추적
  await AnalyticsService.instance.logEvent(
    name: AnalyticsEvents.changeLanguage,
    parameters: {'language': languageCode},
  );
}
```

---

### 기술적 고려사항

#### 아키텍처
```
┌─────────────────────────────────────────┐
│           UI Layer (Screens)            │
│  - Screen View Tracking                 │
│  - User Action Events                   │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│      Analytics Service Layer            │
│  - AnalyticsService (Singleton)         │
│  - Event Abstraction                    │
│  - Error Handling                       │
└────────────────┬────────────────────────┘
                 │
┌────────────────▼────────────────────────┐
│     Firebase Analytics SDK              │
│  - firebase_core                        │
│  - firebase_analytics                   │
└─────────────────────────────────────────┘
```

**설계 패턴**:
- **Singleton Pattern**: AnalyticsService 인스턴스 하나만 유지
- **Service Layer Pattern**: UI와 Analytics SDK 분리
- **Constants Pattern**: 이벤트명/파라미터 상수화로 타입 안전성 확보

#### 의존성

**필수 패키지**:
```yaml
firebase_core: ^3.12.0        # Firebase 핵심 SDK
firebase_analytics: ^11.6.0   # Analytics 기능
```

**호환성 요구사항**:
- **Flutter SDK**: >=3.8.1 (현재 프로젝트 사양)
- **iOS**: >=12.0 (Firebase 요구사항)
- **Android**: minSdkVersion >= 21 (Firebase 요구사항)
- **기존 패키지 호환성**: Supabase, Riverpod와 충돌 없음

#### API 설계

**AnalyticsService 핵심 메서드**:
```dart
class AnalyticsService {
  // 싱글톤 인스턴스
  static final instance = AnalyticsService._();

  // 화면 조회
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
    Map<String, dynamic>? parameters,
  });

  // 커스텀 이벤트
  Future<void> logEvent({
    required String name,
    Map<String, dynamic>? parameters,
  });

  // 사용자 속성
  Future<void> setUserProperty({
    required String name,
    required String value,
  });

  // 사용자 ID
  Future<void> setUserId(String? userId);

  // 편의 메서드들
  Future<void> logLogin({String? method});
  Future<void> logSignUp({String? method});
  Future<void> logSearch({required String searchTerm, String? category});
  Future<void> logViewCocktail({required String cocktailId, required String cocktailName});
  // ... 기타 도메인별 메서드
}
```

#### 데이터 모델

**이벤트 파라미터 표준**:
```dart
// 칵테일 관련
{
  'cocktail_id': String,
  'cocktail_name': String,
  'category': String?,
  'ingredients_count': int?,
}

// 제품 관련
{
  'product_id': String,
  'product_name': String,
  'product_type': String?,
  'price': double?,
}

// 검색 관련
{
  'search_term': String,
  'category': String?,
  'results_count': int?,
}

// 사용자 여정
{
  'source': String,  // 유입 경로
  'method': String,  // 액션 방법
  'success': bool,   // 성공 여부
}
```

---

## 추적할 주요 이벤트 정의

### 화면 조회 이벤트 (Screen Views)

**우선순위 1 (필수)**:
```yaml
splash_screen:
  description: "앱 시작 스플래시"
  parameters: {}

onboarding_screen:
  description: "온보딩 플로우"
  parameters:
    - step: "preferences|products|misc_items|auth"

home_screen:
  description: "메인 홈 화면"
  parameters: {}

cocktails_screen:
  description: "칵테일 목록 화면"
  parameters:
    - category: String?

cocktail_detail_screen:
  description: "칵테일 상세 화면"
  parameters:
    - cocktail_id: String
    - cocktail_name: String

my_bar_screen:
  description: "내 바 화면"
  parameters:
    - products_count: int
```

**우선순위 2 (중요)**:
```yaml
cocktail_search_screen:
  description: "칵테일 검색 화면"

products_screen:
  description: "제품 카탈로그 화면"

product_detail_screen:
  description: "제품 상세 화면"
  parameters:
    - product_id: String
    - product_name: String

settings_screen:
  description: "설정 화면"

profile_screen:
  description: "프로필 화면"
```

### 사용자 액션 이벤트 (User Actions)

**우선순위 1 (필수)**:
```yaml
login:
  description: "로그인 완료"
  parameters:
    - method: "email|google|apple|kakao"

sign_up:
  description: "회원가입 완료"
  parameters:
    - method: "email|google|apple|kakao"

complete_onboarding:
  description: "온보딩 완료"
  parameters:
    - duration_seconds: int

view_cocktail:
  description: "칵테일 조회"
  parameters:
    - cocktail_id: String
    - cocktail_name: String
    - source: "home|search|list|recommendation"

search:
  description: "검색 수행"
  parameters:
    - search_term: String
    - category: "cocktails|products"
    - results_count: int?

add_to_my_bar:
  description: "My Bar에 제품 추가"
  parameters:
    - product_id: String
    - product_name: String
    - source: "onboarding|product_detail|catalog"
```

**우선순위 2 (중요)**:
```yaml
remove_from_my_bar:
  description: "My Bar에서 제품 제거"
  parameters:
    - product_id: String
    - product_name: String

view_product:
  description: "제품 상세 조회"
  parameters:
    - product_id: String
    - product_name: String

share_recipe:
  description: "레시피 공유"
  parameters:
    - cocktail_id: String
    - method: "copy|native_share"

toggle_theme:
  description: "테마 변경"
  parameters:
    - theme: "light|dark"

change_language:
  description: "언어 변경"
  parameters:
    - language: String
```

### 사용자 속성 (User Properties)

```yaml
theme_mode:
  description: "현재 테마 모드"
  values: "light|dark"

language:
  description: "앱 언어 설정"
  values: "en|ko|..."

my_bar_count:
  description: "My Bar 제품 수"
  values: int

user_type:
  description: "사용자 유형"
  values: "free|premium|..."

onboarding_completed:
  description: "온보딩 완료 여부"
  values: "true|false"

favorite_spirit:
  description: "가장 많이 추가한 주류 타입"
  values: "gin|vodka|rum|whiskey|..."
```

---

## 테스트 및 검증 방법

### 1. 로컬 디버그 모드 테스트

**1.1 DebugView 활성화**

**iOS**:
```bash
# Xcode에서 scheme 편집
# Edit Scheme > Run > Arguments > Arguments Passed On Launch
-FIRDebugEnabled

# 또는 터미널에서
flutter run --dart-define=FIREBASE_DEBUG=true
```

**Android**:
```bash
# Android Studio 또는 터미널
adb shell setprop debug.firebase.analytics.app com.cockat.cockat

# 실행
flutter run
```

**1.2 Firebase Console DebugView 확인**
```
1. Firebase Console 접속
2. Analytics > DebugView 메뉴
3. 실시간 이벤트 스트림 확인
4. 이벤트 파라미터 검증
```

### 2. 통합 테스트

**2.1 화면 전환 플로우 테스트**
```
시나리오:
1. 앱 시작 (splash_screen)
2. 온보딩 완료 (onboarding_*)
3. 홈 화면 진입 (home_screen)
4. 칵테일 검색 (search_cocktail)
5. 칵테일 상세 조회 (view_cocktail)
6. My Bar 추가 (add_to_my_bar)

확인 사항:
- 모든 이벤트가 DebugView에 표시되는가?
- 파라미터가 정확한가?
- 이벤트 순서가 논리적인가?
```

**2.2 사용자 속성 테스트**
```
시나리오:
1. 로그인 (user_id 설정)
2. 테마 변경 (theme_mode 속성)
3. 언어 변경 (language 속성)
4. My Bar 제품 추가 (my_bar_count 업데이트)

확인 사항:
- Firebase Console User Properties에 반영되는가?
- 값이 정확한가?
```

### 3. 프로덕션 검증

**3.1 Staging 환경 테스트**
```yaml
준비:
  - Firebase 프로젝트에 Staging 앱 추가
  - 별도 google-services.json/GoogleService-Info.plist
  - 환경 분리 (--dart-define=ENV=staging)

검증:
  - 실제 사용자 플로우 시뮬레이션
  - 24시간 후 Analytics 대시보드 확인
  - 이벤트 정확성, 데이터 무결성 검증
```

**3.2 A/B 테스트 준비**
```yaml
테스트 시나리오:
  - 온보딩 플로우 변형 (3단계 vs 4단계)
  - 홈 화면 레이아웃 변형
  - 칵테일 추천 알고리즘 변형

측정 지표:
  - complete_onboarding 비율
  - view_cocktail 이벤트 수
  - add_to_my_bar 전환율
```

### 4. 자동화 테스트

**4.1 Unit 테스트**
```dart
// test/core/services/analytics_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AnalyticsService', () {
    late AnalyticsService analyticsService;

    setUp(() {
      analyticsService = AnalyticsService.instance;
    });

    test('should log screen view with correct parameters', () async {
      // Arrange
      const screenName = 'test_screen';

      // Act
      await analyticsService.logScreenView(screenName: screenName);

      // Assert
      // Mock Firebase Analytics를 사용하여 호출 검증
    });

    test('should log event with parameters', () async {
      // Arrange
      const eventName = 'test_event';
      final parameters = {'key': 'value'};

      // Act
      await analyticsService.logEvent(
        name: eventName,
        parameters: parameters,
      );

      // Assert
      // 검증 로직
    });
  });
}
```

**4.2 Integration 테스트**
```dart
// integration_test/analytics_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Analytics tracking throughout user journey', (tester) async {
    // 앱 시작
    await tester.pumpWidget(const CockatApp());

    // 온보딩 완료
    // ... 탭 액션 시뮬레이션

    // 홈 화면 진입
    await tester.pump();

    // 칵테일 검색
    // ... 검색 액션

    // Analytics 이벤트 확인
    // (실제로는 Mock을 사용하거나 Firebase Test Lab)
  });
}
```

---

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| **Firebase 설정 오류** | 높음 | - FlutterFire CLI 사용으로 자동화<br>- 설정 파일 체크리스트 작성<br>- DebugView로 즉시 검증 |
| **iOS/Android 빌드 실패** | 높음 | - 단계별 빌드 테스트<br>- 플랫폼별 설정 가이드 준수<br>- CocoaPods/Gradle 버전 호환성 확인 |
| **성능 영향** | 중간 | - 비동기 처리로 UI 블로킹 방지<br>- 과도한 이벤트 추적 지양<br>- 배치 처리 활용 |
| **프라이버시 규정 위반** | 높음 | - 개인정보 파라미터 제외<br>- GDPR/앱스토어 가이드라인 준수<br>- 사용자 동의 메커니즘 구현 |
| **데이터 정확성 문제** | 중간 | - 이벤트명/파라미터 상수화<br>- 타입 안전성 확보<br>- 정기적인 데이터 검증 |
| **Supabase와 충돌** | 낮음 | - 독립적인 서비스 레이어 구현<br>- user_id 동기화 전략 수립 |
| **과도한 이벤트 추적** | 중간 | - 우선순위 기반 단계적 구현<br>- 월별 이벤트 쿼터 모니터링<br>- 중요도 낮은 이벤트 제거 |

---

## 성공 기준

### 기술적 성공 기준
- [ ] Firebase 프로젝트 설정 완료 (iOS/Android)
- [ ] firebase_core, firebase_analytics 패키지 통합
- [ ] AnalyticsService 클래스 구현 완료
- [ ] 주요 화면 10개 이상 추적 구현
- [ ] 핵심 사용자 액션 5개 이상 추적
- [ ] 사용자 속성 3개 이상 설정
- [ ] DebugView에서 실시간 이벤트 확인 가능
- [ ] iOS/Android 빌드 및 실행 정상 작동
- [ ] 프로덕션 환경 배포 후 Analytics Console 데이터 수집 확인

### 비즈니스 성공 기준
- [ ] 일일 활성 사용자(DAU) 추적 가능
- [ ] 온보딩 완료율 측정 가능
- [ ] 칵테일 조회/검색 인게이지먼트 측정
- [ ] My Bar 전환율 추적 가능
- [ ] 사용자 유지율(Retention) 분석 가능
- [ ] 인기 칵테일/제품 TOP 10 식별 가능
- [ ] A/B 테스트 실행 준비 완료

### 품질 기준
- [ ] 앱 성능 저하 없음 (Analytics 추가로 인한)
- [ ] 크래시 발생 없음
- [ ] 프라이버시 정책 준수
- [ ] 코드 리뷰 통과
- [ ] 문서화 완료 (README, 주석)

---

## 참고 자료

### 공식 문서
- [Firebase Analytics 공식 문서](https://firebase.google.com/docs/analytics)
- [FlutterFire Analytics 플러그인](https://firebase.flutter.dev/docs/analytics/overview)
- [Firebase Analytics 이벤트 가이드](https://firebase.google.com/docs/analytics/events)
- [Firebase Console](https://console.firebase.google.com)

### Flutter 통합 가이드
- [FlutterFire CLI 사용법](https://firebase.flutter.dev/docs/cli)
- [Firebase Analytics Best Practices](https://firebase.google.com/docs/analytics/best-practices)
- [iOS 설정 가이드](https://firebase.google.com/docs/ios/setup)
- [Android 설정 가이드](https://firebase.google.com/docs/android/setup)

### 예제 및 패턴
- [Firebase Samples - Flutter](https://github.com/firebase/flutterfire/tree/master/packages/firebase_analytics/firebase_analytics/example)
- [Google Analytics 측정 프로토콜](https://developers.google.com/analytics/devguides/collection/protocol/v1)

### 관련 도구
- [Firebase DebugView](https://firebase.google.com/docs/analytics/debugview)
- [Google Analytics 4 Events Builder](https://ga-dev-tools.google)
- [Firebase Test Lab](https://firebase.google.com/docs/test-lab)

### 프라이버시 및 규정
- [GDPR 가이드라인](https://firebase.google.com/support/privacy)
- [Apple App Privacy Details](https://developer.apple.com/app-store/app-privacy-details/)
- [Google Play Data Safety](https://support.google.com/googleplay/android-developer/answer/10787469)

---

## 예상 작업 목록

### Phase 1: 기본 설정 (2-3시간)
1. [ ] Firebase Console에서 프로젝트 생성
2. [ ] iOS 앱 추가 및 GoogleService-Info.plist 다운로드
3. [ ] Android 앱 추가 및 google-services.json 다운로드
4. [ ] FlutterFire CLI 설치 및 실행 (`flutterfire configure`)
5. [ ] pubspec.yaml에 firebase_core, firebase_analytics 추가
6. [ ] flutter pub get 실행
7. [ ] iOS Podfile 업데이트 및 pod install
8. [ ] Android build.gradle.kts 수정 (google-services 플러그인)
9. [ ] main.dart에 Firebase 초기화 코드 추가
10. [ ] 빌드 테스트 (iOS/Android)

### Phase 2: Analytics 서비스 구현 (2-3시간)
11. [ ] `lib/core/services/analytics_service.dart` 생성
12. [ ] `lib/core/services/analytics_events.dart` 생성 (상수 정의)
13. [ ] AnalyticsService 싱글톤 구현
14. [ ] logScreenView, logEvent, setUserProperty 메서드 구현
15. [ ] 도메인별 편의 메서드 구현 (logLogin, logViewCocktail 등)
16. [ ] Riverpod Provider 생성
17. [ ] 에러 핸들링 및 디버그 로깅 추가

### Phase 3: 화면 추적 구현 (1-2시간)
18. [ ] SplashScreen에 screen_view 추적
19. [ ] OnboardingScreen에 screen_view 추적
20. [ ] HomeScreen에 screen_view 추적
21. [ ] CocktailsScreen에 screen_view 추적
22. [ ] CocktailDetailScreen에 screen_view + view_cocktail 이벤트
23. [ ] MyBarScreen에 screen_view 추적
24. [ ] ProductsScreen에 screen_view 추적
25. [ ] ProductDetailScreen에 screen_view 추적
26. [ ] SettingsScreen에 screen_view 추적
27. [ ] ProfileScreen에 screen_view 추적

### Phase 4: 사용자 액션 추적 (1-2시간)
28. [ ] 로그인 이벤트 추적 (LoginScreen)
29. [ ] 회원가입 이벤트 추적 (SignUpScreen)
30. [ ] 온보딩 완료 이벤트 추적
31. [ ] 칵테일 검색 이벤트 추적 (CocktailSearchScreen)
32. [ ] My Bar 제품 추가 이벤트 추적
33. [ ] My Bar 제품 제거 이벤트 추적
34. [ ] 테마 변경 이벤트 + 사용자 속성
35. [ ] 언어 변경 이벤트 + 사용자 속성
36. [ ] 공유 기능 이벤트 추적 (있을 경우)

### Phase 5: 테스트 및 검증 (1-2시간)
37. [ ] iOS 디바이스/시뮬레이터에서 DebugView 활성화
38. [ ] Android 디바이스/에뮬레이터에서 DebugView 활성화
39. [ ] Firebase Console DebugView에서 실시간 이벤트 확인
40. [ ] 화면 전환 플로우 전체 테스트
41. [ ] 사용자 액션 이벤트 정확성 검증
42. [ ] 사용자 속성 정확성 검증
43. [ ] 프로덕션 빌드 테스트 (release 모드)
44. [ ] 프라이버시 규정 준수 확인
45. [ ] 성능 영향 측정

### Phase 6: 문서화 및 배포 준비 (1시간)
46. [ ] README에 Analytics 설정 가이드 추가
47. [ ] 주요 이벤트 목록 문서화
48. [ ] 개발팀 가이드 작성 (새 이벤트 추가 방법)
49. [ ] 프라이버시 정책 업데이트 (필요 시)
50. [ ] 코드 리뷰 요청
51. [ ] 최종 테스트 후 main 브랜치 병합

---

## 향후 확장 계획

### 추가 Firebase 서비스 통합
- **Firebase Crashlytics**: 크래시 리포팅 및 안정성 모니터링
- **Firebase Performance Monitoring**: 앱 성능 추적
- **Firebase Remote Config**: 원격 설정 및 A/B 테스트
- **Firebase Cloud Messaging**: 푸시 알림

### 고급 Analytics 기능
- **사용자 코호트 분석**: 특정 사용자 그룹 행동 패턴 분석
- **퍼널 분석**: 온보딩 → 칵테일 조회 → My Bar 추가 전환율
- **리텐션 분석**: 주간/월간 사용자 유지율
- **예측 분석**: Firebase Predictions로 이탈 가능성 예측

### 데이터 활용
- **BigQuery 연동**: 심화 분석 및 커스텀 쿼리
- **Data Studio 대시보드**: 시각화 및 리포팅
- **자동화된 인사이트**: 이상 탐지, 트렌드 분석

---

**문서 버전**: 1.0
**작성일**: 2026-01-25
**작성자**: Claude (Strategic Implementation Architect)
**검토 필요**: Firebase 프로젝트 설정 전 기술 리뷰
**관련 문서**: 없음 (최초 Analytics 통합)
