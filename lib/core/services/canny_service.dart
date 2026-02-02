import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Canny 피드백 위젯 서비스
///
/// SSO 토큰 생성 및 Canny URL 빌드를 담당합니다.
class CannyService {
  static const String _subdomain = 'cockat';
  static const String _defaultBoard = 'feature-requests';

  final SupabaseClient _supabase;

  CannyService(this._supabase);

  /// Canny SSO 토큰 생성
  ///
  /// Supabase Edge Function을 호출하여 JWT 토큰을 생성합니다.
  /// 로그인하지 않은 사용자는 null을 반환합니다.
  Future<String?> generateSSOToken() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase.functions.invoke(
        'generate-canny-token',
        body: {
          'userId': user.id,
          'email': user.email,
          'name': user.userMetadata?['full_name'] as String? ??
              user.userMetadata?['name'] as String? ??
              user.email?.split('@')[0] ??
              'User',
        },
      );

      if (response.status == 200 && response.data != null) {
        return response.data['token'] as String?;
      }

      debugPrint('Canny token generation failed: status=${response.status}');
      return null;
    } catch (e) {
      debugPrint('Canny token generation error: $e');
      return null;
    }
  }

  /// Canny URL 생성
  ///
  /// 로그인 사용자는 SSO 토큰 포함, 비로그인 사용자는 일반 URL 반환
  Future<String> buildCannyUrl({
    required bool isDarkMode,
    String? boardName,
  }) async {
    final board = boardName ?? _defaultBoard;
    final theme = isDarkMode ? 'dark' : 'light';

    final ssoToken = await generateSSOToken();

    final baseUrl = 'https://$_subdomain.canny.io/$board';

    if (ssoToken != null) {
      return '$baseUrl?ssoToken=$ssoToken&theme=$theme';
    } else {
      // 비로그인 사용자 - SSO 없이 접근 가능
      return '$baseUrl?theme=$theme';
    }
  }

  /// 게시판 URL 직접 반환 (SSO 없이)
  String getCannyBoardUrl({
    required bool isDarkMode,
    String? boardName,
  }) {
    final board = boardName ?? _defaultBoard;
    final theme = isDarkMode ? 'dark' : 'light';
    return 'https://$_subdomain.canny.io/$board?theme=$theme';
  }
}
