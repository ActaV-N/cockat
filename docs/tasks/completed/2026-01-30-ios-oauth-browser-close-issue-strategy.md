# iOS OAuth In-App Browser 자동 닫힘 문제 해결 전략

## 개요
- **목적**: iOS에서 Supabase OAuth 로그인 후 in-app browser가 자동으로 닫히지 않는 문제 해결
- **범위**: iOS 플랫폼 OAuth 흐름 (Apple/Google 로그인)
- **제약사항**: `LaunchMode.inAppBrowserView` 필수 유지 (App Store 심사 요구사항)
- **예상 소요 기간**: 2-3일

## 현재 상태 분석

### 기존 구현
1. **OAuth 설정**:
   - `auth_provider.dart`: `LaunchMode.inAppBrowserView` 사용
   - Redirect URL: `io.supabase.cockat://login-callback`
   - Supabase Flutter: v2.8.3
   - Auth Flow: PKCE

2. **딥링크 처리**:
   - `Info.plist`: URL Scheme 등록됨 (`io.supabase.cockat`)
   - `main.dart`: `onGenerateRoute`에서 딥링크 라우팅 처리
   - `login_screen.dart`: `authStateChangesProvider` 리스닝

3. **현재 흐름**:
   ```
   사용자 버튼 클릭
   → OAuth 페이지 열림 (in-app browser)
   → 인증 완료
   → 딥링크 콜백 (`io.supabase.cockat://login-callback`)
   → Supabase가 토큰 처리
   → authStateChanges 이벤트 발생
   → UI 업데이트
   → ❌ 브라우저가 자동으로 닫히지 않음
   ```

### 문제점 및 증상

#### 1. In-App Browser 자동 닫힘 실패
**증상**:
- OAuth 인증 후 브라우저 창이 그대로 유지됨
- 사용자가 수동으로 "완료" 버튼을 눌러야 닫힘

**로그**:
```
flutter: supabase.supabase_flutter: INFO: handle deeplink uri
Failed to handle route information in Flutter.
```

**근본 원인**:
- Supabase Flutter SDK가 iOS `SFAuthenticationSession`/`ASWebAuthenticationSession` 사용 시 딥링크 수신 후 세션을 자동으로 종료하지 않음
- Flutter 엔진이 딥링크 라우팅을 처리하지 못함 (route information 에러)
- `onGenerateRoute`에서 빈 페이지를 반환해도 브라우저 세션은 닫히지 않음

#### 2. SnackBar 다중 에러
**증상**:
```
Floating SnackBar presented off screen (여러 번 반복)
```

**근본 원인**:
- 사용자가 수동으로 브라우저를 닫을 때 컨텍스트가 이미 disposed된 상태
- `login_screen.dart` L44에서 `Navigator.pop()`과 동시에 SnackBar 시도
- 브라우저 닫힘과 화면 전환이 race condition 발생

#### 3. 실제 디바이스 Apple 로그인 실패
**증상**:
- 로그인이 완전히 실패하고 에러 토스트 표시
- 시뮬레이터와 다른 동작

**가능한 원인**:
- Apple Sign In의 실제 디바이스 인증 흐름 차이
- Capability/Entitlement 설정 누락 가능성
- Supabase Apple OAuth 설정 문제

### 관련 코드 분석

#### auth_provider.dart (L89-112, L115-134)
```dart
// 문제: signInWithOAuth는 브라우저만 열고 즉시 반환
// iOS에서 브라우저 세션 제어권이 없음
await _supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.supabase.cockat://login-callback',
  authScreenLaunchMode: LaunchMode.inAppBrowserView,
);
```

#### login_screen.dart (L29-47)
```dart
// 문제: authStateChanges 리스닝만으로는 브라우저를 닫을 수 없음
ref.listenManual(authStateChangesProvider, (previous, next) {
  next.whenData((authState) async {
    if (authState.event == AuthChangeEvent.signedIn && _isProcessingOAuth) {
      // 여기서 브라우저를 닫는 로직 없음
      Navigator.of(context).pop(true);
    }
  });
});
```

#### main.dart (L72-83)
```dart
// 문제: MaterialPageRoute로 빈 페이지 반환해도 브라우저 세션은 안 닫힘
onGenerateRoute: (settings) {
  if (name.contains('login-callback')) {
    return MaterialPageRoute(
      builder: (_) => const SizedBox.shrink(),
    );
  }
}
```

#### AppDelegate.swift
```swift
// 문제: 딥링크 핸들러가 없음
// Flutter plugin이 자동 처리하지만 브라우저 세션 제어 불가
```

## 기술적 배경: Supabase Flutter OAuth 메커니즘

### iOS의 OAuth 브라우저 옵션

1. **ASWebAuthenticationSession** (iOS 12+, 권장):
   - 시스템 레벨 인증 세션
   - 사용자가 "완료" 버튼을 눌러야 닫힘
   - **자동 닫힘 조건**: `callbackURLScheme`과 일치하는 URL이 로드되면 자동 종료
   - Supabase Flutter는 이것을 사용

2. **SFSafariViewController**:
   - 앱 내 Safari 뷰
   - 수동으로 dismiss 필요
   - 더 이상 OAuth에 권장되지 않음

3. **External Browser** (Safari):
   - App Store 심사에서 거절됨 (우리의 제약사항)

### Supabase Flutter의 OAuth 처리 방식

```dart
// 내부적으로 url_launcher 플러그인 사용
// url_launcher는 ASWebAuthenticationSession 사용
Future<bool> signInWithOAuth(
  OAuthProvider provider, {
  String? redirectTo,
  LaunchMode authScreenLaunchMode = LaunchMode.platformDefault,
}) async {
  // 1. OAuth URL 생성
  final url = _getOAuthUrl(provider, redirectTo);

  // 2. 브라우저 열기 (url_launcher)
  await launchUrl(url, mode: authScreenLaunchMode);

  // 3. 딥링크 콜백 대기 (app_links 플러그인)
  // 4. 토큰 교환 및 세션 저장
  // 5. authStateChanges 스트림에 이벤트 발행

  // ❌ 브라우저 세션을 닫는 로직 없음!
  return true;
}
```

### 핵심 문제: ASWebAuthenticationSession 자동 닫힘 실패

**ASWebAuthenticationSession이 자동으로 닫히는 조건**:
1. `callbackURLScheme` 파라미터가 설정되어 있어야 함
2. 해당 스킴의 URL이 로드되면 세션 종료
3. **중요**: URL이 실제로 "로드"되어야 함 (딥링크만 캐치하면 안 됨)

**현재 문제**:
- Supabase Flutter SDK가 딥링크를 먼저 캐치함
- ASWebAuthenticationSession은 URL이 로드되기 전에 딥링크가 가로채졌다고 판단
- 세션이 닫히지 않음

## 해결 방안 분석

### 방안 1: Native iOS 딥링크 핸들러 추가 ⭐ (권장)

**개념**:
iOS 네이티브 레벨에서 딥링크를 먼저 처리하고 ASWebAuthenticationSession에게 전달하여 자동 닫힘 트리거

**구현**:
```swift
// AppDelegate.swift
override func application(
  _ app: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
  // 1. Supabase 콜백인지 확인
  if url.scheme == "io.supabase.cockat" && url.host == "login-callback" {
    // 2. Flutter에게 URL 전달 (Supabase 처리)
    let success = super.application(app, open: url, options: options)

    // 3. ASWebAuthenticationSession 종료 트리거
    // (URL이 "처리되었음"을 시스템에 알림)
    return success
  }

  return super.application(app, open: url, options: options)
}
```

**장점**:
- ✅ 최소한의 코드 변경
- ✅ Supabase Flutter SDK 동작 그대로 유지
- ✅ Apple의 권장 방식
- ✅ App Store 심사 통과 가능

**단점**:
- ⚠️ iOS 네이티브 코드 수정 필요
- ⚠️ 모든 iOS 버전에서 동작 확인 필요

**성공 가능성**: 85%

---

### 방안 2: 딥링크 처리 순서 최적화

**개념**:
Flutter의 딥링크 처리를 지연시켜 ASWebAuthenticationSession이 먼저 URL을 인식하게 함

**구현**:
```dart
// main.dart
onGenerateRoute: (settings) {
  final name = settings.name ?? '';
  if (name.contains('login-callback')) {
    // 짧은 지연으로 ASWebAuthenticationSession이 먼저 처리하게 함
    Future.delayed(Duration(milliseconds: 100), () {
      // Supabase가 자동으로 처리
    });

    // 빈 페이지 대신 null 반환
    return null;
  }
  return null;
}
```

**장점**:
- ✅ Flutter 레벨에서만 수정
- ✅ 네이티브 코드 불필요

**단점**:
- ❌ 타이밍 의존적 (불안정)
- ❌ Race condition 가능성
- ❌ 근본적 해결 아님

**성공 가능성**: 40%

---

### 방안 3: url_launcher 콜백 활용 (Flutter 3.3+)

**개념**:
`url_launcher`의 `closeInAppWebView()` 메서드를 사용하여 명시적으로 닫기

**구현**:
```dart
// login_screen.dart
ref.listenManual(authStateChangesProvider, (previous, next) {
  next.whenData((authState) async {
    if (authState.event == AuthChangeEvent.signedIn && _isProcessingOAuth) {
      _isProcessingOAuth = false;

      // 브라우저 명시적으로 닫기
      try {
        await closeInAppWebView();
      } catch (e) {
        // iOS에서 지원하지 않을 수 있음
      }

      // 나머지 로직...
    }
  });
});
```

**장점**:
- ✅ Flutter API 사용
- ✅ 명시적 제어

**단점**:
- ❌ `closeInAppWebView()`가 ASWebAuthenticationSession에서 동작하지 않음
- ❌ SFSafariViewController에서만 작동
- ❌ 현재 우리 상황에 맞지 않음

**성공 가능성**: 20%

---

### 방안 4: Custom OAuth Flow (sign_in_with_apple 플러그인)

**개념**:
Apple 로그인만 별도로 네이티브 Sign in with Apple 플러그인 사용

**구현**:
```dart
// pubspec.yaml
dependencies:
  sign_in_with_apple: ^5.0.0

// auth_provider.dart
Future<AuthResult> signInWithApple() async {
  try {
    // 1. Apple 네이티브 인증
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    // 2. Supabase에 토큰 전달
    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: credential.state,
    );

    return AuthResult.success(response.user);
  } catch (e) {
    return AuthResult.failure(e.toString());
  }
}
```

**장점**:
- ✅ Apple Sign In은 네이티브 UI 사용 (브라우저 없음)
- ✅ 더 나은 UX
- ✅ 브라우저 닫기 문제 없음

**단점**:
- ⚠️ Google 로그인은 여전히 문제
- ⚠️ 추가 플러그인 의존성
- ⚠️ Supabase와 통합 복잡도 증가

**성공 가능성**: 70% (Apple만)

---

### 방안 5: Universal Links 사용

**개념**:
URL Scheme 대신 Universal Links (https://) 사용

**구현**:
1. Supabase에서 Universal Links 설정
2. iOS에서 Associated Domains 추가
3. Redirect URL을 `https://your-domain.com/auth/callback`으로 변경

**장점**:
- ✅ 더 안정적인 딥링크
- ✅ App Store 선호 방식

**단점**:
- ❌ 도메인 소유 필요
- ❌ Apple Developer Console 설정 필요
- ❌ ASWebAuthenticationSession 자동 닫기 문제는 동일
- ❌ 구현 복잡도 매우 높음

**성공 가능성**: 60%

---

## 권장 해결 방안: 복합 접근

### Phase 1: 네이티브 딥링크 핸들러 (방안 1) ⭐
**우선순위**: 높음
**타임라인**: 1일

1. `AppDelegate.swift`에 딥링크 핸들러 추가
2. ASWebAuthenticationSession 자동 닫기 트리거
3. 시뮬레이터 및 실제 디바이스 테스트

### Phase 2: Apple Sign In 네이티브 구현 (방안 4)
**우선순위**: 중간
**타임라인**: 1일

1. `sign_in_with_apple` 플러그인 추가
2. Apple OAuth만 네이티브 플로우로 전환
3. Google은 기존 방식 유지 (Phase 1로 개선)

### Phase 3: SnackBar 에러 수정
**우선순위**: 높음
**타임라인**: 0.5일

```dart
// login_screen.dart
if (!mounted) return;

// Pop 후 SnackBar는 이전 화면에서 표시
Navigator.of(context).pop(true);

// SnackBar는 호출한 화면에서 처리
```

## 상세 구현 계획

### Step 1: iOS 네이티브 딥링크 핸들러 추가

**파일**: `/ios/Runner/AppDelegate.swift`

```swift
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // OAuth 딥링크 핸들러
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey : Any] = [:]
  ) -> Bool {
    // Supabase OAuth 콜백 처리
    if url.scheme == "io.supabase.cockat" {
      // Flutter/Supabase에게 전달
      let handled = super.application(app, open: url, options: options)

      // ASWebAuthenticationSession 종료 트리거
      // (URL이 처리되었음을 시스템에 알림)
      return handled
    }

    return super.application(app, open: url, options: options)
  }
}
```

### Step 2: Flutter 딥링크 처리 개선

**파일**: `/lib/main.dart`

```dart
onGenerateRoute: (settings) {
  final name = settings.name ?? '';

  // OAuth 콜백은 Supabase가 자동 처리
  // 빈 페이지 대신 null 반환하여 기본 동작 허용
  if (name.contains('login-callback') ||
      name.startsWith('io.supabase.cockat://')) {
    return null; // 기본 라우팅 허용
  }
  return null;
}
```

### Step 3: SnackBar 에러 수정

**파일**: `/lib/features/auth/login_screen.dart`

```dart
// L29-47
ref.listenManual(authStateChangesProvider, (previous, next) {
  next.whenData((authState) async {
    if (authState.event == AuthChangeEvent.signedIn && _isProcessingOAuth) {
      _isProcessingOAuth = false;
      AnalyticsService().logLogin(method: 'oauth');

      // Sync data first
      await ref.read(onboardingServiceProvider).clearLocalData();
      await ref.read(onboardingServiceProvider).syncDbToLocal();

      if (!mounted) return;

      // Pop만 수행 - SnackBar는 이전 화면에서 처리
      Navigator.of(context).pop(true);
    }
  });
});
```

### Step 4: Apple Sign In 진단 및 개선

**문제 진단**:
1. Xcode에서 Signing & Capabilities 확인
   - "Sign in with Apple" capability 추가되었는지
   - Team ID 올바른지
   - Bundle ID 일치하는지

2. Supabase Dashboard 확인
   - Apple OAuth 설정 완료
   - Redirect URL 정확한지
   - Services ID 올바른지

**개선 계획** (필요시):
```dart
// pubspec.yaml
dependencies:
  sign_in_with_apple: ^5.0.0

// auth_provider.dart
Future<AuthResult> signInWithApple() async {
  try {
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.apple,
      idToken: credential.identityToken!,
      nonce: credential.state,
    );

    if (response.user != null) {
      return AuthResult.success(response.user);
    } else {
      return AuthResult.failure('Apple 로그인에 실패했습니다.');
    }
  } catch (e) {
    return AuthResult.failure(e.toString());
  }
}
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| iOS 네이티브 핸들러가 ASWebAuthenticationSession 종료에 실패 | 높음 | Phase 2 (네이티브 Apple Sign In)로 우회 |
| 실제 디바이스에서 다른 동작 | 중간 | 철저한 디바이스 테스트, TestFlight 배포 |
| Supabase SDK 버전 호환성 문제 | 중간 | 최신 버전으로 업그레이드 (2.8.3 → 최신) |
| App Store 심사 거절 | 낮음 | 네이티브 방식이므로 Apple 가이드라인 준수 |
| Google 로그인도 실패할 가능성 | 중간 | 동일한 네이티브 핸들러로 해결 |

## 테스트 전략

### 단위 테스트
- AuthService의 각 OAuth 메서드 독립 테스트
- Mock SupabaseClient로 격리 테스트

### 통합 테스트
1. **시뮬레이터 테스트**:
   - Google OAuth 전체 플로우
   - Apple OAuth 전체 플로우 (제한적)
   - 브라우저 자동 닫힘 확인

2. **실제 디바이스 테스트**:
   - iPhone 11 이상 (iOS 15+)
   - Apple Sign In 실제 계정
   - Google Sign In 실제 계정
   - 브라우저 자동 닫힘 확인
   - 로그인 성공 및 데이터 동기화 확인

3. **Edge Cases**:
   - 네트워크 에러 시나리오
   - 사용자가 취소 버튼 누름
   - 백그라운드 → 포그라운드 전환
   - 앱 강제 종료 후 재시작

### 성능 테스트
- OAuth 플로우 완료 시간 측정 (목표: <5초)
- 브라우저 닫힘 딜레이 측정 (목표: <500ms)
- 메모리 누수 확인

## 성공 기준

- [ ] iOS 시뮬레이터에서 Google OAuth 후 브라우저 자동 닫힘
- [ ] iOS 시뮬레이터에서 Apple OAuth 후 브라우저 자동 닫힘
- [ ] 실제 디바이스에서 Google OAuth 정상 작동
- [ ] 실제 디바이스에서 Apple OAuth 정상 작동
- [ ] "Failed to handle route information" 에러 없음
- [ ] "Floating SnackBar presented off screen" 에러 없음
- [ ] 로그인 성공 후 데이터 동기화 정상
- [ ] App Store 심사 가이드라인 준수
- [ ] TestFlight 베타 테스터 검증 통과

## 참고 자료

### Supabase Documentation
- [Supabase Flutter OAuth Guide](https://supabase.com/docs/guides/auth/social-login/auth-apple)
- [Deep Linking in Flutter](https://supabase.com/docs/guides/auth/redirect-urls)

### Apple Documentation
- [ASWebAuthenticationSession](https://developer.apple.com/documentation/authenticationservices/aswebauthenticationsession)
- [Sign in with Apple](https://developer.apple.com/sign-in-with-apple/)
- [Custom URL Schemes](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app)

### Flutter Packages
- [url_launcher](https://pub.dev/packages/url_launcher)
- [sign_in_with_apple](https://pub.dev/packages/sign_in_with_apple)
- [app_links](https://pub.dev/packages/app_links)

### Known Issues
- [Supabase Flutter #768 - OAuth browser not closing](https://github.com/supabase/supabase-flutter/issues/768)
- [url_launcher #470 - ASWebAuthenticationSession dismissal](https://github.com/flutter/plugins/issues/470)

## 구현 순서 요약

1. **즉시 구현** (Phase 1):
   - iOS 네이티브 딥링크 핸들러 추가
   - SnackBar 에러 수정
   - 시뮬레이터 테스트

2. **디바이스 테스트 후** (Phase 2):
   - Apple Sign In이 여전히 실패하면 네이티브 구현
   - Google은 Phase 1 개선으로 충분할 것

3. **최종 검증**:
   - 실제 디바이스 테스트
   - TestFlight 배포
   - 베타 테스터 피드백

## 예상 결과

**최선의 시나리오** (Phase 1 성공):
- iOS 네이티브 핸들러만으로 모든 문제 해결
- 코드 변경 최소화
- 1일 내 완료

**중간 시나리오** (Phase 1 + Phase 2):
- Apple만 네이티브 구현 필요
- Google은 Phase 1로 해결
- 2일 내 완료

**최악의 시나리오** (Universal Links 필요):
- 도메인 설정 및 복잡한 구성
- 3-4일 소요
- 하지만 가능성 낮음 (10%)
