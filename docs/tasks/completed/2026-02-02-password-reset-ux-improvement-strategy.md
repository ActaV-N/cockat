# 비밀번호 재설정 UX 개선 전략

## 개요
- **목적**: 비밀번호 재설정 링크 클릭 후 전용 화면 제공
- **범위**: Auth 이벤트 감지, 비밀번호 재설정 화면, 에러 처리
- **예상 소요**: 3-4시간

## 현재 상태

### 동작 플로우
```
1. 로그인 화면 → "비밀번호를 잊으셨나요?" 클릭
2. 이메일 입력 → Supabase가 재설정 이메일 발송
3. 이메일 링크 클릭:
   https://xxx.supabase.co/auth/v1/verify?token=xxx&type=recovery&redirect_to=io.supabase.cockat://
4. Supabase 서버가 토큰 검증 후 앱으로 리다이렉트
5. ❌ 현재: 빈 화면 (SizedBox.shrink) → 사용자 혼란
```

### 문제점
- `onAuthStateChange`에서 `passwordRecovery` 이벤트 미처리
- 전용 PasswordResetScreen 없음
- `auth.updateUser()` 메서드 미구현

## Supabase 동작 원리

### 실제 플로우
```
1. 이메일 링크 클릭
2. Supabase 서버에서 토큰 검증
3. io.supabase.cockat:// 으로 리다이렉트 (세션 토큰 포함)
4. Supabase Flutter SDK가 자동으로 세션 복구
5. onAuthStateChange에서 AuthChangeEvent.passwordRecovery 이벤트 발생
6. 앱에서 이 이벤트를 감지하여 PasswordResetScreen으로 이동
```

### 핵심 포인트
- URL 파싱 불필요 (SDK가 자동 처리)
- `onAuthStateChange` 리스너에서 `passwordRecovery` 이벤트 감지
- 이벤트 발생 시 이미 세션이 복구된 상태

## 구현 전략

### Phase 1: AuthService 확장 (20분)

**파일**: `lib/data/providers/auth_provider.dart`

```dart
/// 비밀번호 업데이트
Future<AuthResult> updatePassword(String newPassword) async {
  try {
    final response = await _supabase.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    if (response.user != null) {
      return AuthResult.success(response.user);
    }
    return AuthResult.failure('비밀번호 변경에 실패했습니다.');
  } on AuthException catch (e) {
    return AuthResult.failure(_translateAuthError(e.message));
  } catch (e) {
    return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
  }
}
```

### Phase 2: PasswordResetScreen 생성 (60분)

**파일**: `lib/features/auth/password_reset_screen.dart`

**UI 구성**:
```
┌─────────────────────────────┐
│ 비밀번호 재설정              │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────┐   │
│  │  🔒 안내 메시지      │   │
│  └─────────────────────┘   │
│                             │
│  새 비밀번호               │
│  ┌─────────────────────┐   │
│  │ ••••••••       👁   │   │
│  └─────────────────────┘   │
│                             │
│  비밀번호 확인             │
│  ┌─────────────────────┐   │
│  │ ••••••••       👁   │   │
│  └─────────────────────┘   │
│                             │
│  [ 비밀번호 변경 ]          │
│  [ 취소 ]                   │
│                             │
└─────────────────────────────┘
```

**핵심 로직**:
- Form validation (6자 이상, 일치 확인)
- 비밀번호 표시/숨김 토글
- 성공 시 홈 화면 이동 (이미 로그인 상태)
- 실패 시 에러 메시지

### Phase 3: Auth 이벤트 리스너 (30분)

**파일**: `lib/features/splash/splash_screen.dart`

**현재 코드 분석 필요**: `authStateChangesProvider` 사용 위치 확인

**구현 방식**:
```dart
Supabase.instance.client.auth.onAuthStateChange.listen((data) {
  final event = data.event;

  if (event == AuthChangeEvent.passwordRecovery) {
    // PasswordResetScreen으로 네비게이션
    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PasswordResetScreen()),
      (route) => false,
    );
  }
});
```

**고려사항**:
- GlobalKey<NavigatorState> 필요 또는 다른 네비게이션 방식
- 리스너 중복 등록 방지
- 앱 어느 화면에서든 이벤트 감지 필요

### Phase 4: 다국어 문자열 (15분)

**app_ko.arb**:
```json
{
  "resetPasswordTitle": "비밀번호 재설정",
  "resetPasswordInstruction": "새로운 비밀번호를 입력해주세요",
  "newPassword": "새 비밀번호",
  "confirmNewPassword": "비밀번호 확인",
  "passwordMinLength": "비밀번호는 최소 6자 이상이어야 합니다",
  "passwordsDoNotMatch": "비밀번호가 일치하지 않습니다",
  "changePassword": "비밀번호 변경",
  "passwordChangeSuccess": "비밀번호가 변경되었습니다"
}
```

**app_en.arb**:
```json
{
  "resetPasswordTitle": "Reset Password",
  "resetPasswordInstruction": "Please enter your new password",
  "newPassword": "New Password",
  "confirmNewPassword": "Confirm Password",
  "passwordMinLength": "Password must be at least 6 characters",
  "passwordsDoNotMatch": "Passwords do not match",
  "changePassword": "Change Password",
  "passwordChangeSuccess": "Password has been changed"
}
```

## 구현 순서

| # | 작업 | 파일 | 시간 |
|---|------|------|------|
| 1 | `updatePassword()` 추가 | `auth_provider.dart` | 20분 |
| 2 | `PasswordResetScreen` 생성 | `password_reset_screen.dart` | 60분 |
| 3 | `onAuthStateChange` 리스너 | `splash_screen.dart` 또는 `main.dart` | 30분 |
| 4 | 다국어 문자열 추가 | `app_ko.arb`, `app_en.arb` | 15분 |
| 5 | 테스트 | - | 45분 |

**총 예상 시간**: 약 3시간

## 기술적 고려사항

### 네비게이션 전략
`onAuthStateChange`는 앱 어디서든 발생할 수 있으므로:
- **옵션 A**: GlobalKey<NavigatorState> 사용
- **옵션 B**: main.dart에서 최상위 리스너 등록
- **옵션 C**: Riverpod provider로 상태 관리 후 UI에서 반응

### 리스너 위치
- `main.dart`의 Supabase 초기화 직후가 적절
- 또는 `CockatApp` StatefulWidget으로 변경 후 initState에서 등록

### 에러 시나리오
| 상황 | 처리 |
|------|------|
| 토큰 만료 | SDK가 에러 발생 → 세션 없음 → 로그인 화면 |
| 네트워크 오류 | updateUser 실패 → 에러 메시지 표시 |
| 중복 사용 | Supabase가 토큰 무효화 → 세션 복구 실패 |

## 테스트 시나리오

1. **정상 플로우**
   - 재설정 이메일 요청 → 링크 클릭 → 화면 표시 → 비밀번호 변경 → 홈 이동

2. **유효성 검증**
   - 6자 미만 입력 → 에러
   - 비밀번호 불일치 → 에러

3. **에러 처리**
   - 만료된 링크 클릭 → 로그인 화면으로 이동

## 성공 기준

- [ ] 이메일 링크 클릭 시 PasswordResetScreen 표시
- [ ] 비밀번호 변경 성공 후 홈 화면 이동
- [ ] Form validation 정상 작동
- [ ] 에러 시나리오 처리
- [ ] iOS/Android 양쪽 작동
- [ ] 한국어/영어 지원
