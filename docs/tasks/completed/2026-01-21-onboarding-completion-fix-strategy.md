# 온보딩 완료 상태 관리 개선 전략

## 개요
- **목적**: 로그인된 사용자가 온보딩을 완료했음에도 계속 온보딩 화면이 표시되는 문제 해결
- **범위**: 온보딩 완료 상태 확인 로직 개선, 비동기 데이터 로딩 처리
- **예상 소요 기간**: 1-2시간

## 현재 상태 분석

### DB 상태 확인 결과
```sql
-- user_preferences 테이블 (존재함)
SELECT * FROM user_preferences;
-- 결과:
-- user_id: 37d47e49-84fd-4a28-91d3-0e1a16e2502e
-- onboarding_completed: true  ← 정상 저장됨
-- unit_system: oz
```

### 문제점 및 근본 원인

#### 🚨 핵심 문제: FutureProvider의 비동기 로딩 타이밍 문제

**코드 흐름 분석**:

```dart
// 1. SplashScreen initState에서 2초 후 네비게이션 결정
// lib/features/splash/splash_screen.dart:46-50
Future.delayed(const Duration(milliseconds: 2000), () {
  if (mounted) {
    _navigateToNextScreen();
  }
});

// 2. 네비게이션 결정 시 온보딩 상태 확인
// lib/features/splash/splash_screen.dart:53-58
void _navigateToNextScreen() {
  final onboardingCompleted = ref.read(effectiveOnboardingCompletedProvider);
  final nextScreen = onboardingCompleted
      ? const HomeScreen()
      : const OnboardingScreen();  // ← 여기로 감
  ...
}

// 3. effectiveOnboardingCompletedProvider 로직
// lib/data/providers/onboarding_provider.dart:105-114
final effectiveOnboardingCompletedProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);
  if (isAuthenticated) {
    final dbPrefs = ref.watch(userPreferencesDbProvider);
    return dbPrefs.valueOrNull?['onboarding_completed'] ?? false;  // ← 문제!
  } else {
    return ref.watch(onboardingCompletedLocalProvider);
  }
});

// 4. userPreferencesDbProvider는 FutureProvider (비동기)
// lib/data/providers/onboarding_provider.dart:86-100
final userPreferencesDbProvider =
    FutureProvider<Map<String, dynamic>?>((ref) async {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);
  if (userId == null) return null;

  final response = await supabase  // ← 네트워크 요청
      .from('user_preferences')
      .select()
      .eq('user_id', userId)
      .maybeSingle();

  return response;
});
```

**문제 발생 시퀀스**:
```
시간   0ms: SplashScreen initState 실행
시간   0ms: userPreferencesDbProvider 구독 시작 (아직 데이터 없음)
시간 100ms: Supabase DB 요청 시작
시간 2000ms: _navigateToNextScreen() 호출
            → userPreferencesDbProvider.valueOrNull = null (로딩 중)
            → null?['onboarding_completed'] ?? false = false
            → OnboardingScreen으로 이동 ❌
시간 2500ms: DB 응답 도착 (너무 늦음, 이미 네비게이션 완료)
```

**결론**: 2초 딜레이가 DB 응답 시간보다 짧거나, 응답이 아직 도착하지 않은 상태에서 네비게이션 결정이 이루어짐

### 관련 코드/모듈

```
lib/features/splash/splash_screen.dart
├── _navigateToNextScreen() - 온보딩 완료 여부 확인 (문제 지점)
└── Future.delayed(2000ms) - 고정 딜레이 (문제 지점)

lib/data/providers/onboarding_provider.dart
├── effectiveOnboardingCompletedProvider - 통합 온보딩 상태
├── userPreferencesDbProvider (FutureProvider) - DB에서 비동기 로드
└── onboardingCompletedLocalProvider - 로컬 상태
```

## 구현 전략

### 접근 방식
1. **비동기 로딩 완료 대기**: FutureProvider 로딩 완료 후 네비게이션 결정
2. **폴백 전략**: 로딩 중에는 로컬 값 사용, 타임아웃 시 안전한 기본값
3. **상태 기반 UI**: 로딩 상태를 명시적으로 처리

### 세부 구현 단계

#### 1단계: SplashScreen에서 비동기 로딩 완료 대기 (핵심)

**현재 코드 문제점**:
```dart
void _navigateToNextScreen() {
  final onboardingCompleted = ref.read(effectiveOnboardingCompletedProvider);
  // FutureProvider가 아직 로딩 중이면 false 반환
}
```

**해결 방안 A: 새로운 AsyncValue 기반 Provider 사용**

```dart
// lib/data/providers/onboarding_provider.dart 수정

/// 온보딩 완료 상태 (AsyncValue로 로딩 상태 포함)
final effectiveOnboardingCompletedAsyncProvider = Provider<AsyncValue<bool>>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final dbPrefs = ref.watch(userPreferencesDbProvider);
    return dbPrefs.when(
      data: (prefs) => AsyncData(prefs?['onboarding_completed'] ?? false),
      loading: () => const AsyncLoading(),
      error: (e, s) {
        // 에러 시 로컬 값으로 폴백
        final localValue = ref.read(onboardingCompletedLocalProvider);
        return AsyncData(localValue);
      },
    );
  } else {
    return AsyncData(ref.watch(onboardingCompletedLocalProvider));
  }
});
```

**해결 방안 B: SplashScreen에서 로딩 완료 대기**

```dart
// lib/features/splash/splash_screen.dart 수정

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  // ... 기존 애니메이션 코드 유지 ...
  bool _navigationDone = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(/* ... */);
    // ... 애니메이션 설정 ...
    _controller.forward();

    // 네비게이션 결정을 별도 메서드로
    _checkAndNavigate();
  }

  Future<void> _checkAndNavigate() async {
    // 최소 스플래시 표시 시간 보장
    await Future.delayed(const Duration(milliseconds: 1500));

    // 인증된 사용자면 DB 로딩 완료 대기
    if (ref.read(isAuthenticatedProvider)) {
      // 최대 5초 대기, 타임아웃 시 로컬 값 사용
      final startTime = DateTime.now();
      const timeout = Duration(seconds: 5);

      while (DateTime.now().difference(startTime) < timeout) {
        final dbPrefs = ref.read(userPreferencesDbProvider);
        if (dbPrefs.hasValue || dbPrefs.hasError) {
          break;
        }
        await Future.delayed(const Duration(milliseconds: 100));
      }
    }

    if (mounted && !_navigationDone) {
      _navigationDone = true;
      _navigateToNextScreen();
    }
  }

  void _navigateToNextScreen() {
    final isAuthenticated = ref.read(isAuthenticatedProvider);
    bool onboardingCompleted;

    if (isAuthenticated) {
      final dbPrefs = ref.read(userPreferencesDbProvider);
      // 데이터가 있으면 DB 값 사용, 없으면 로컬 값으로 폴백
      onboardingCompleted = dbPrefs.valueOrNull?['onboarding_completed']
          ?? ref.read(onboardingCompletedLocalProvider);
    } else {
      onboardingCompleted = ref.read(onboardingCompletedLocalProvider);
    }

    final nextScreen = onboardingCompleted
        ? const HomeScreen()
        : const OnboardingScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => nextScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }
}
```

#### 2단계: effectiveOnboardingCompletedProvider 폴백 로직 개선

```dart
// lib/data/providers/onboarding_provider.dart

/// Unified onboarding completed status (with local fallback)
final effectiveOnboardingCompletedProvider = Provider<bool>((ref) {
  final isAuthenticated = ref.watch(isAuthenticatedProvider);

  if (isAuthenticated) {
    final dbPrefs = ref.watch(userPreferencesDbProvider);
    final localValue = ref.read(onboardingCompletedLocalProvider);

    return dbPrefs.when(
      data: (prefs) => prefs?['onboarding_completed'] ?? localValue,
      loading: () => localValue,  // 로딩 중에는 로컬 값 사용
      error: (e, s) => localValue,  // 에러 시에도 로컬 값 사용
    );
  } else {
    return ref.watch(onboardingCompletedLocalProvider);
  }
});
```

#### 3단계: 로그인 후 로컬 상태 동기화 추가

**문제**: 로그인 후 DB에는 `onboarding_completed: true`가 있지만, 로컬에는 `false`일 수 있음

```dart
// lib/data/providers/onboarding_provider.dart
// OnboardingService에 메서드 추가

/// Sync DB preferences to local (after login, for offline support)
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
      // DB 값을 로컬에 동기화
      final onboardingCompleted = response['onboarding_completed'] ?? false;
      final unitSystem = UnitSystem.fromString(response['unit_system'] ?? 'ml');

      await _ref.read(onboardingCompletedLocalProvider.notifier).setCompleted(onboardingCompleted);
      await _ref.read(unitSystemLocalProvider.notifier).setUnitSystem(unitSystem);
    }
  } catch (e) {
    // 에러 무시 (오프라인 등)
    debugPrint('Failed to sync DB to local: $e');
  }
}
```

**로그인 후 동기화 호출**:
```dart
// lib/features/auth/login_screen.dart 또는 auth_page.dart
// 로그인 성공 후:
await ref.read(onboardingServiceProvider).syncDbToLocal();
```

### 권장 구현 방식 (가장 간단)

**방안 B를 권장**: SplashScreen에서 DB 로딩 완료를 명시적으로 대기

장점:
- 기존 Provider 구조 변경 최소화
- 명시적인 타임아웃 처리
- 폴백 로직이 한 곳에 집중됨

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| 네트워크 지연으로 스플래시 화면 오래 표시 | 중간 | 5초 타임아웃 설정, 로컬 값으로 폴백 |
| 로컬과 DB 값 불일치 | 낮음 | 로그인 시 DB→로컬 동기화 |
| 오프라인 상태에서 앱 실행 | 낮음 | 로컬 값 우선 사용 |

## 테스트 시나리오

### 시나리오 1: 로그인된 사용자, 온보딩 완료 상태
1. 앱 실행 → SplashScreen 표시
2. DB 로딩 완료 대기 (최대 5초)
3. `onboarding_completed: true` 확인
4. HomeScreen으로 이동 ✅

### 시나리오 2: 로그인된 사용자, 네트워크 지연
1. 앱 실행 → SplashScreen 표시
2. DB 로딩 5초 타임아웃
3. 로컬 값 (`true`) 사용
4. HomeScreen으로 이동 ✅

### 시나리오 3: 비로그인 사용자
1. 앱 실행 → SplashScreen 표시
2. 로컬 값 즉시 확인
3. 상태에 따라 OnboardingScreen 또는 HomeScreen 이동 ✅

## 성공 기준
- [ ] 로그인된 사용자가 앱 재실행 시 HomeScreen 직접 표시
- [ ] 스플래시 화면 최대 표시 시간 6.5초 (1.5초 최소 + 5초 타임아웃) 이내
- [ ] 오프라인 상태에서도 정상 작동 (로컬 값 사용)
- [ ] 신규 사용자는 기존대로 OnboardingScreen 표시

## 구현 순서 요약

1. **SplashScreen 수정** (30분)
   - `_checkAndNavigate()` 메서드 추가
   - DB 로딩 완료 대기 로직 구현
   - 타임아웃 및 폴백 처리

2. **effectiveOnboardingCompletedProvider 개선** (15분)
   - 로딩/에러 시 로컬 값 폴백 추가

3. **(선택) syncDbToLocal 메서드 추가** (15분)
   - 로그인 후 DB→로컬 동기화

4. **테스트** (30분)
   - 각 시나리오 수동 테스트
   - 네트워크 지연 시뮬레이션

## 참고 자료
- [Riverpod AsyncValue 문서](https://riverpod.dev/docs/essentials/first_request)
- [Flutter Supabase Auth 상태 관리](https://supabase.com/docs/guides/auth/auth-helpers/flutter-auth-ui)
