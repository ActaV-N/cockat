import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'ingredient_provider.dart';

/// Supabase Auth 상태 스트림
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

/// 현재 사용자 (반응형 - auth 상태 변경 시 자동 업데이트)
final currentUserProvider = Provider<User?>((ref) {
  // authStateChangesProvider를 watch하여 auth 상태 변경 시 자동으로 재평가
  ref.watch(authStateChangesProvider);
  return Supabase.instance.client.auth.currentUser;
});

/// 현재 사용자 ID
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(currentUserProvider)?.id;
});

/// 인증 여부
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(currentUserProvider) != null;
});

/// 인증 서비스
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

/// 인증 서비스 클래스
class AuthService {
  final SupabaseClient _supabase;

  AuthService(this._supabase);

  /// 이메일로 회원가입
  Future<AuthResult> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(response.user);
      } else {
        return AuthResult.failure('회원가입에 실패했습니다.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 이메일로 로그인
  Future<AuthResult> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        return AuthResult.success(response.user);
      } else {
        return AuthResult.failure('로그인에 실패했습니다.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 소셜 로그인 (Google)
  Future<AuthResult> signInWithGoogle() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: kIsWeb ? null : 'io.supabase.cockat://login-callback',
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
        queryParams: {
          'prompt': 'select_account', // 항상 계정 선택 화면 표시
        },
      );

      if (response) {
        // OAuth는 리다이렉트 방식이라 여기서 직접 결과를 받지 않음
        return AuthResult.pending();
      } else {
        return AuthResult.failure('Google 로그인에 실패했습니다.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 소셜 로그인 (Apple)
  Future<AuthResult> signInWithApple() async {
    try {
      final response = await _supabase.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: kIsWeb ? null : 'io.supabase.cockat://login-callback',
        authScreenLaunchMode:
            kIsWeb ? LaunchMode.platformDefault : LaunchMode.inAppBrowserView,
      );

      if (response) {
        return AuthResult.pending();
      } else {
        return AuthResult.failure('Apple 로그인에 실패했습니다.');
      }
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  /// 계정 삭제
  Future<AuthResult> deleteAccount() async {
    try {
      final session = _supabase.auth.currentSession;
      if (session == null) {
        return AuthResult.failure('로그인이 필요합니다.');
      }

      final response = await _supabase.functions.invoke(
        'delete-user',
        method: HttpMethod.post,
        headers: {
          'Authorization': 'Bearer ${session.accessToken}',
        },
      );

      if (response.status == 200) {
        // 로컬 세션 정리
        await _supabase.auth.signOut();
        return AuthResult.success(null);
      } else {
        final error = response.data?['error'] ?? '계정 삭제에 실패했습니다.';
        return AuthResult.failure(error);
      }
    } catch (e) {
      return AuthResult.failure('계정 삭제 중 오류가 발생했습니다.');
    }
  }

  /// 비밀번호 재설정 이메일 발송
  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _supabase.auth.resetPasswordForEmail(email);
      return AuthResult.success(null);
    } on AuthException catch (e) {
      return AuthResult.failure(_translateAuthError(e.message));
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }

  /// 에러 메시지 번역
  String _translateAuthError(String message) {
    if (message.contains('Invalid login credentials')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (message.contains('Email not confirmed')) {
      return '이메일 인증이 필요합니다. 메일함을 확인해주세요.';
    }
    if (message.contains('User already registered')) {
      return '이미 가입된 이메일입니다.';
    }
    if (message.contains('Password should be at least')) {
      return '비밀번호는 최소 6자 이상이어야 합니다.';
    }
    if (message.contains('Invalid email')) {
      return '유효하지 않은 이메일 형식입니다.';
    }
    return message;
  }
}

/// 인증 결과
class AuthResult {
  final bool isSuccess;
  final bool isPending;
  final User? user;
  final String? errorMessage;

  AuthResult._({
    required this.isSuccess,
    this.isPending = false,
    this.user,
    this.errorMessage,
  });

  factory AuthResult.success(User? user) {
    return AuthResult._(isSuccess: true, user: user);
  }

  factory AuthResult.failure(String message) {
    return AuthResult._(isSuccess: false, errorMessage: message);
  }

  factory AuthResult.pending() {
    return AuthResult._(isSuccess: false, isPending: true);
  }
}

/// 회원 데이터 Provider들 (DB 기반)

/// 회원의 즐겨찾기 목록 (DB)
final userFavoritesDbProvider = StreamProvider<List<String>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_favorites')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((row) => row['cocktail_id'] as String).toList());
});

/// 회원의 선택 재료 목록 (DB)
final userIngredientsDbProvider = StreamProvider<List<String>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_ingredients')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((row) => row['ingredient_id'] as String).toList());
});

/// 회원의 선택 상품 목록 (DB)
final userProductsDbProvider = StreamProvider<List<String>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_products')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .map((data) => data.map((row) => row['product_id'] as String).toList());
});
