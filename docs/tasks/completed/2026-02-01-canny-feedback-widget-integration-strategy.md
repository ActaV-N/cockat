# Canny 피드백 위젯 통합 전략

## 개요
- **목적**: 사용자 피드백 수집 및 기능 요청을 위한 Canny 위젯을 Flutter 앱에 통합
- **범위**: WebView 기반 Canny 위젯 구현, SSO 인증 연동, UI/UX 통합
- **예상 소요 기간**: 2-3일

## 확정 설정
| 항목 | 값 |
|------|-----|
| Subdomain | `cockat` |
| Board | `feature-requests` |
| URL | `https://cockat.canny.io/feature-requests` |
| 비로그인 허용 | ✅ Yes |

## 현재 상태 분석

### 기존 구현
- **인증 시스템**: Supabase Auth (Google/Apple OAuth, 이메일 인증) 완비
- **WebView 사용**: 현재 프로젝트에 WebView 사용 사례 없음 (신규 구현 필요)
- **네비게이션**: 4개 탭 기반 홈 화면 (Cocktails, MyBar, Products, Profile)
- **테마**: Coral Peach 기반 Material 3 디자인 시스템, 다크/라이트 모드 지원
- **다국어**: 한국어/영어 지원 (ARB 파일 기반)

### 관련 코드/모듈
```
lib/
├── features/
│   ├── home/home_screen.dart         # 메인 네비게이션 (탭 추가 가능)
│   ├── profile/profile_screen.dart   # 프로필 화면 (피드백 버튼 추가 예정)
│   └── settings/settings_screen.dart # 설정 화면 (피드백 링크 추가 예정)
├── data/providers/
│   └── auth_provider.dart            # 사용자 인증 정보 제공
├── core/theme/
│   └── app_theme.dart                # 디자인 시스템
└── l10n/
    ├── app_ko.arb                    # 한국어 번역
    └── app_en.arb                    # 영어 번역
```

### 문제점/한계
- WebView 플러그인 미설치
- Canny SSO 구현 필요 (사용자 인증 연동)
- iOS/Android 플랫폼별 WebView 권한 설정 필요
- 피드백 위젯 접근 UX 설계 필요

## 구현 전략

### 접근 방식
1. **WebView 플러그인 통합**: `webview_flutter` 사용 (공식 Flutter 플러그인)
2. **Canny SSO 연동**: Supabase 사용자 정보로 Canny JWT 토큰 생성
3. **전용 피드백 화면**: 모달 또는 전체 화면으로 Canny 위젯 표시
4. **다중 진입점**: Profile 화면, Settings 화면에서 접근 가능

### 세부 구현 단계

#### 1. 의존성 추가 및 플랫폼 설정
**작업 내용**:
- `pubspec.yaml`에 `webview_flutter` 추가
- iOS: `Info.plist`에 `NSAppTransportSecurity` 설정
- Android: `AndroidManifest.xml`에 인터넷 권한 확인

**예상 시간**: 30분

#### 2. Canny 위젯 화면 구현
**작업 내용**:
- `lib/features/feedback/feedback_screen.dart` 생성
- WebView로 Canny 위젯 로드
- 로딩 상태, 에러 처리 구현
- 테마 모드에 따른 Canny 테마 동적 적용

**기술 세부사항**:
```dart
// Canny 위젯 URL 구조
// https://[YOUR_SUBDOMAIN].canny.io/board/[BOARD_URL]?ssoToken=[JWT_TOKEN]&theme=[light|dark]

class FeedbackScreen extends ConsumerStatefulWidget {
  const FeedbackScreen({super.key});

  @override
  ConsumerState<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends ConsumerState<FeedbackScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    final user = ref.read(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cannyUrl = await _buildCannyUrl(user, isDark);

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (url) => setState(() => _isLoading = false),
        onWebResourceError: (error) => _handleError(error),
      ))
      ..loadRequest(Uri.parse(cannyUrl));
  }
}
```

**예상 시간**: 3시간

#### 3. Canny SSO 토큰 생성 서비스
**작업 내용**:
- `lib/core/services/canny_service.dart` 생성
- Supabase Edge Function으로 JWT 토큰 생성 API 호출
- 사용자 정보 (이름, 이메일, ID) 매핑

**기술 세부사항**:
```dart
class CannyService {
  final SupabaseClient _supabase;

  CannyService(this._supabase);

  /// Canny SSO 토큰 생성
  Future<String?> generateSSOToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase.functions.invoke(
        'generate-canny-token',
        body: {
          'userId': user.id,
          'email': user.email,
          'name': user.userMetadata?['full_name'] ?? user.email?.split('@')[0],
        },
      );

      if (response.status == 200) {
        return response.data['token'] as String;
      }
      return null;
    } catch (e) {
      debugPrint('Canny token generation error: $e');
      return null;
    }
  }

  /// Canny URL 생성 (인증 유무에 따라)
  Future<String> buildCannyUrl({
    required bool isDarkMode,
    String? boardUrl,
  }) async {
    final subdomain = dotenv.env['CANNY_SUBDOMAIN'] ?? 'cockat';
    final board = boardUrl ?? 'feature-requests';
    final theme = isDarkMode ? 'dark' : 'light';

    final ssoToken = await generateSSOToken();

    if (ssoToken != null) {
      return 'https://$subdomain.canny.io/board/$board?ssoToken=$ssoToken&theme=$theme';
    } else {
      // 비로그인 사용자는 SSO 없이 접근
      return 'https://$subdomain.canny.io/board/$board?theme=$theme';
    }
  }
}
```

**예상 시간**: 2시간

#### 4. Supabase Edge Function 구현
**작업 내용**:
- `supabase/functions/generate-canny-token/index.ts` 생성
- Canny SSO JWT 토큰 생성 로직 구현
- HMAC-SHA256 서명 추가

**기술 세부사항**:
```typescript
import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { encode } from "https://deno.land/std@0.168.0/encoding/base64url.ts"
import { hmac } from "https://deno.land/x/hmac@v2.0.1/mod.ts"

const CANNY_SECRET = Deno.env.get('CANNY_SSO_SECRET')!

serve(async (req) => {
  try {
    // 인증 확인
    const authHeader = req.headers.get('Authorization')!
    const supabase = createClient(
      Deno.env.get('SUPABASE_URL')!,
      Deno.env.get('SUPABASE_ANON_KEY')!,
      { global: { headers: { Authorization: authHeader } } }
    )

    const { data: { user }, error } = await supabase.auth.getUser()
    if (error || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    const { userId, email, name } = await req.json()

    // JWT Payload
    const userData = {
      email,
      id: userId,
      name: name || email.split('@')[0],
      created: Math.floor(Date.now() / 1000),
    }

    // JWT 생성
    const header = encode(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    const payload = encode(JSON.stringify(userData))
    const signature = encode(
      hmac('sha256', CANNY_SECRET, `${header}.${payload}`, 'utf8', 'arraybuffer')
    )

    const token = `${header}.${payload}.${signature}`

    return new Response(JSON.stringify({ token }), {
      headers: { 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

**예상 시간**: 2시간

#### 5. UI/UX 통합
**작업 내용**:
- Profile 화면에 "피드백 보내기" 버튼 추가
- Settings 화면에 "의견 남기기" 메뉴 항목 추가
- 피드백 화면을 모달로 표시 (iOS: Cupertino style, Android: Material style)

**UI 설계**:
```dart
// Profile Screen 수정
class ProfileScreen extends ConsumerWidget {
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ListView(
        children: [
          // 기존 프로필 섹션...

          const Divider(),
          ListTile(
            leading: const Icon(Icons.feedback_outlined),
            title: Text(l10n.sendFeedback),
            subtitle: Text(l10n.sendFeedbackSubtitle),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFeedbackScreen(context),
          ),
        ],
      ),
    );
  }

  void _showFeedbackScreen(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const FeedbackScreen(),
    );
  }
}
```

**예상 시간**: 2시간

#### 6. 다국어 지원
**작업 내용**:
- `app_ko.arb`, `app_en.arb`에 피드백 관련 문자열 추가
- Canny 위젯 언어 설정 (locale 파라미터)

**추가 문자열**:
```json
// app_ko.arb
{
  "sendFeedback": "피드백 보내기",
  "sendFeedbackSubtitle": "의견과 기능 제안을 들려주세요",
  "feedback": "피드백",
  "featureRequests": "기능 제안",
  "bugReports": "버그 신고",
  "feedbackLoadError": "피드백을 불러올 수 없습니다",
  "feedbackRetry": "다시 시도"
}

// app_en.arb
{
  "sendFeedback": "Send Feedback",
  "sendFeedbackSubtitle": "Share your ideas and suggestions",
  "feedback": "Feedback",
  "featureRequests": "Feature Requests",
  "bugReports": "Bug Reports",
  "feedbackLoadError": "Failed to load feedback",
  "feedbackRetry": "Retry"
}
```

**예상 시간**: 30분

#### 7. 환경 변수 설정
**작업 내용**:
- `.env` 파일에 Canny 관련 설정 추가
- Canny 계정 생성 및 SSO 키 발급

**환경 변수**:
```env
# Canny Configuration
CANNY_SUBDOMAIN=cockat
CANNY_SSO_SECRET=your_canny_sso_secret_key
CANNY_BOARD_FEATURE_REQUESTS=feature-requests
CANNY_BOARD_BUG_REPORTS=bug-reports
```

**예상 시간**: 1시간 (Canny 계정 설정 포함)

### 기술적 고려사항

#### 아키텍처
- **서비스 레이어**: `CannyService`로 비즈니스 로직 분리
- **Provider 통합**: Riverpod으로 상태 관리
- **Edge Function**: 서버 사이드 JWT 서명으로 보안 강화

#### 의존성
- **신규 추가**:
  - `webview_flutter: ^4.7.0` - Flutter WebView 플러그인
  - `webview_flutter_android: ^3.16.0` - Android 구현체
  - `webview_flutter_wkwebview: ^3.13.0` - iOS 구현체

#### API 설계
```dart
// Provider 정의
final cannyServiceProvider = Provider<CannyService>((ref) {
  return CannyService(Supabase.instance.client);
});

// Canny URL Provider (테마 모드 반응형)
final cannyUrlProvider = FutureProvider.autoDispose<String>((ref) async {
  final cannyService = ref.watch(cannyServiceProvider);
  final isDark = ref.watch(themeModeProvider) == ThemeMode.dark;

  return cannyService.buildCannyUrl(isDarkMode: isDark);
});
```

#### 플랫폼별 설정

**iOS (Info.plist)**:
```xml
<key>NSAppTransportSecurity</key>
<dict>
  <key>NSAllowsArbitraryLoads</key>
  <true/>
  <!-- 또는 특정 도메인만 허용 -->
  <key>NSExceptionDomains</key>
  <dict>
    <key>canny.io</key>
    <dict>
      <key>NSIncludesSubdomains</key>
      <true/>
      <key>NSTemporaryExceptionAllowsInsecureHTTPLoads</key>
      <true/>
    </dict>
  </dict>
</dict>
```

**Android (AndroidManifest.xml)**:
```xml
<!-- 이미 존재하는 인터넷 권한 확인 -->
<uses-permission android:name="android.permission.INTERNET" />
```

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Canny SSO 토큰 생성 실패 | 중간 | 비로그인 사용자도 피드백 가능하도록 폴백 구현 |
| WebView 렌더링 성능 이슈 | 낮음 | 하드웨어 가속 활성화, JavaScript 최적화 |
| iOS App Store 심사 거부 (WebView) | 중간 | WebView 사용 목적 명시, 네이티브 대안 제시 |
| Canny 위젯 테마 불일치 | 낮음 | 다크/라이트 모드 동적 전달, CSS 커스터마이징 |
| Edge Function Cold Start 지연 | 낮음 | 토큰 캐싱 구현 (5분 TTL) |
| 다국어 지원 제한 (Canny) | 낮음 | 앱 언어 설정과 무관하게 영어로 표시 (Canny 기본 언어) |

## 테스트 전략

### 단위 테스트
```dart
// test/core/services/canny_service_test.dart
void main() {
  group('CannyService', () {
    late CannyService cannyService;
    late MockSupabaseClient mockSupabase;

    setUp(() {
      mockSupabase = MockSupabaseClient();
      cannyService = CannyService(mockSupabase);
    });

    test('로그인 사용자의 SSO 토큰 생성', () async {
      // Given: 로그인된 사용자
      when(mockSupabase.auth.currentUser).thenReturn(mockUser);
      when(mockSupabase.functions.invoke('generate-canny-token'))
        .thenAnswer((_) async => mockResponse);

      // When: 토큰 생성
      final token = await cannyService.generateSSOToken();

      // Then: 토큰 반환
      expect(token, isNotNull);
      expect(token, contains('.'));
    });

    test('비로그인 사용자의 URL 생성 (SSO 없음)', () async {
      // Given: 비로그인 상태
      when(mockSupabase.auth.currentUser).thenReturn(null);

      // When: URL 생성
      final url = await cannyService.buildCannyUrl(isDarkMode: false);

      // Then: SSO 토큰 없는 URL
      expect(url, isNot(contains('ssoToken')));
      expect(url, contains('theme=light'));
    });
  });
}
```

### 통합 테스트
- **WebView 로딩 테스트**: Canny 페이지 정상 로드 확인
- **SSO 인증 테스트**: 로그인 사용자 정보 Canny에 전달 확인
- **테마 전환 테스트**: 다크/라이트 모드 동적 변경 확인

### UI 테스트
```dart
// integration_test/feedback_flow_test.dart
void main() {
  testWidgets('피드백 화면 접근 및 표시 테스트', (tester) async {
    // Given: 앱 실행 및 로그인
    await tester.pumpWidget(const CockatApp());
    await loginAsTestUser(tester);

    // When: Profile 화면에서 피드백 버튼 탭
    await tester.tap(find.byIcon(Icons.person));
    await tester.pumpAndSettle();
    await tester.tap(find.text('피드백 보내기'));
    await tester.pumpAndSettle();

    // Then: 피드백 화면 표시
    expect(find.byType(FeedbackScreen), findsOneWidget);
    expect(find.byType(WebViewWidget), findsOneWidget);
  });
}
```

### 수동 테스트 체크리스트
- [ ] iOS 실제 기기에서 WebView 렌더링 확인
- [ ] Android 실제 기기에서 WebView 렌더링 확인
- [ ] 로그인 사용자의 이름/이메일 Canny에 표시 확인
- [ ] 비로그인 사용자 피드백 게시 가능 여부 확인
- [ ] 다크/라이트 모드 전환 시 Canny 테마 변경 확인
- [ ] 네트워크 오류 시 에러 처리 확인
- [ ] 뒤로 가기 버튼 동작 확인

## 성공 기준

- [ ] WebView 플러그인 설치 및 iOS/Android 빌드 성공
- [ ] Supabase Edge Function으로 Canny SSO 토큰 생성 성공
- [ ] 로그인 사용자의 정보가 Canny에 자동 입력됨
- [ ] 비로그인 사용자도 익명으로 피드백 게시 가능
- [ ] Profile, Settings 화면에서 피드백 접근 가능
- [ ] 다크/라이트 모드에 따라 Canny 테마 동적 변경
- [ ] 한국어/영어 번역 완료
- [ ] iOS, Android 실제 기기에서 정상 동작 확인
- [ ] WebView 로딩 시간 3초 이내
- [ ] App Store/Play Store 정책 준수 (WebView 사용 목적 명시)

## 참고 자료

### Canny 공식 문서
- [Canny SSO Documentation](https://developers.canny.io/install/sso)
- [Canny Widget SDK](https://developers.canny.io/install/widget)
- [Canny URL Parameters](https://developers.canny.io/install/url-parameters)

### Flutter WebView
- [webview_flutter Package](https://pub.dev/packages/webview_flutter)
- [Flutter WebView Cookbook](https://docs.flutter.dev/cookbook/plugins/picture-using-camera)

### 기술 패턴
- [Flutter 다크 모드 구현](https://docs.flutter.dev/cookbook/design/themes)
- [Supabase Edge Functions](https://supabase.com/docs/guides/functions)
- [JWT 생성 및 검증](https://jwt.io/introduction)

### 보안 고려사항
- Canny SSO Secret은 서버 사이드에서만 사용 (클라이언트 노출 금지)
- JWT 토큰 만료 시간 설정 (5-10분 권장)
- HTTPS 통신 강제 (ATS 설정)
