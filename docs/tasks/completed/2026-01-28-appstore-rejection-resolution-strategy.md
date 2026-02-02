# Apple App Store 심사 거부 대응 전략

## 개요
- **목적**: Apple App Store 심사 거부 사유 해결 및 재심사 통과
- **범위**: Google 로그인 개선, 계정 삭제 기능 추가, 네이티브 기능 보강
- **예상 소요 기간**: 2-3주
  - Issue 1 (Google 로그인): 2-3일
  - Issue 2 (계정 삭제): 3-4일
  - Issue 3 (네이티브 기능): 7-10일
- **우선순위**: 모두 필수 (App Store 정책 준수)

## 현재 상태 분석

### 프로젝트 구조
- **프레임워크**: Flutter 3.8.1
- **백엔드**: Supabase (인증, 데이터베이스)
- **상태관리**: Riverpod 2.6.1
- **인증 방식**: Email/Password, Google OAuth, Apple OAuth
- **패키지**: `supabase_flutter: ^2.8.3`

### 기존 인증 구현 분석
**파일**: `lib/data/providers/auth_provider.dart`

#### 현재 Google 로그인 구현
```dart
Future<AuthResult> signInWithGoogle() async {
  final response = await _supabase.auth.signInWithOAuth(
    OAuthProvider.google,
    redirectTo: kIsWeb ? null : 'io.supabase.cockat://login-callback',
    authScreenLaunchMode: kIsWeb
      ? LaunchMode.platformDefault
      : LaunchMode.externalApplication,  // ← 문제: 외부 브라우저로 열림
    queryParams: {
      'prompt': 'select_account',
    },
  );
}
```

**문제점**:
- `LaunchMode.externalApplication` 사용으로 외부 브라우저(Safari)에서 로그인 진행
- Apple 정책상 인앱에서 처리되어야 함

#### 현재 계정 삭제 기능
**상태**: 미구현
- `auth_provider.dart`에 삭제 메서드 없음
- `profile_screen.dart`에 삭제 UI 없음
- Supabase RLS 정책 미확인

---

## Issue 1: Google 로그인 인앱 처리

### 목표
Google 로그인 시 Safari가 아닌 인앱 WebView로 열리도록 변경

### 기술적 접근

#### Option A: LaunchMode 변경 (권장)
**변경사항**:
```dart
authScreenLaunchMode: kIsWeb
  ? LaunchMode.platformDefault
  : LaunchMode.inAppWebView,  // ← externalApplication에서 변경
```

**장점**:
- 최소한의 코드 변경
- Supabase 패키지 기본 지원
- 빠른 구현 (1일)

**단점**:
- WebView 커스터마이징 제한적
- 일부 디바이스에서 동작 확인 필요

#### Option B: 커스텀 WebView 구현
**패키지**: `flutter_inappwebview` 또는 `webview_flutter`

**장점**:
- 완전한 커스터마이징 가능
- UX 개선 여지 많음

**단점**:
- 구현 복잡도 증가 (3-4일)
- OAuth 플로우 직접 처리 필요
- 유지보수 부담

### 권장 접근: Option A

#### 구현 단계
1. **LaunchMode 변경** (1일)
   ```dart
   // lib/data/providers/auth_provider.dart
   Future<AuthResult> signInWithGoogle() async {
     final response = await _supabase.auth.signInWithOAuth(
       OAuthProvider.google,
       redirectTo: kIsWeb ? null : 'io.supabase.cockat://login-callback',
       authScreenLaunchMode: LaunchMode.inAppWebView,  // 변경
       queryParams: {
         'prompt': 'select_account',
       },
     );

     if (response) {
       return AuthResult.pending();
     } else {
       return AuthResult.failure('Google 로그인에 실패했습니다.');
     }
   }
   ```

2. **iOS 설정 확인** (0.5일)
   - `ios/Runner/Info.plist`에 URL Scheme 확인
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleURLSchemes</key>
       <array>
         <string>io.supabase.cockat</string>
       </array>
     </dict>
   </array>
   ```

3. **테스트** (0.5일)
   - iOS 실기기에서 Google 로그인 플로우 검증
   - WebView에서 로그인 완료 확인
   - 콜백 URL 리다이렉션 확인
   - 로그인 후 상태 동기화 확인

### 위험 요소 및 대응
| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| WebView가 일부 기기에서 작동 안 함 | 높음 | 실기기 다중 테스트, 폴백 메커니즘 |
| OAuth 콜백 처리 실패 | 중간 | Deep link 설정 재검증 |
| Supabase 패키지 버그 | 낮음 | 패키지 업데이트 또는 커스텀 구현 |

---

## Issue 2: 계정 삭제 기능 구현

### 목표
Apple 가이드라인 5.1.1 준수 - 사용자가 앱 내에서 계정을 삭제할 수 있어야 함

### 기술적 접근

#### 데이터 삭제 범위
**사용자 관련 데이터**:
1. `auth.users` (Supabase Auth)
2. `user_favorites` (즐겨찾기)
3. `user_ingredients` (선택 재료)
4. `user_products` (선택 상품)
5. `user_misc_items` (기타 재료)
6. *(향후)* `user_bars` (다중 바 관리)
7. *(향후)* `user_cocktails` (커스텀 칵테일)

### 구현 단계

#### 1. Supabase Database 함수 작성 (1일)

**SQL 함수**: `delete_user_account`
```sql
-- supabase/migrations/[timestamp]_add_user_deletion_function.sql

CREATE OR REPLACE FUNCTION delete_user_account(user_id_to_delete UUID)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 사용자 데이터 삭제 (CASCADE로 자동 처리되지 않는 경우)
  DELETE FROM user_favorites WHERE user_id = user_id_to_delete;
  DELETE FROM user_ingredients WHERE user_id = user_id_to_delete;
  DELETE FROM user_products WHERE user_id = user_id_to_delete;
  DELETE FROM user_misc_items WHERE user_id = user_id_to_delete;

  -- 향후 추가될 테이블 (주석 처리)
  -- DELETE FROM user_bars WHERE user_id = user_id_to_delete;
  -- DELETE FROM user_cocktails WHERE user_id = user_id_to_delete;

  -- Auth 사용자 삭제 (Admin API 필요)
  -- 클라이언트에서 auth.admin.deleteUser() 호출 필요
END;
$$;

-- RLS 정책: 본인만 자신의 계정 삭제 가능
CREATE POLICY "Users can delete their own account data"
ON user_favorites
FOR DELETE
USING (auth.uid() = user_id);

-- 다른 테이블에도 동일한 정책 적용
CREATE POLICY "Users can delete their own ingredients"
ON user_ingredients
FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own products"
ON user_products
FOR DELETE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own misc items"
ON user_misc_items
FOR DELETE
USING (auth.uid() = user_id);
```

**참고**: Supabase Auth 사용자 삭제는 Admin API가 필요하므로, Edge Function 또는 Backend에서 처리 필요

#### 2. Supabase Edge Function 생성 (1일)

**Edge Function**: `delete-user`
```typescript
// supabase/functions/delete-user/index.ts

import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  try {
    const authHeader = req.headers.get('Authorization')
    if (!authHeader) {
      return new Response(JSON.stringify({ error: 'No authorization header' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // Supabase 클라이언트 생성
    const supabaseAdmin = createClient(
      Deno.env.get('SUPABASE_URL') ?? '',
      Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '',
      {
        auth: {
          autoRefreshToken: false,
          persistSession: false,
        },
      }
    )

    // 현재 사용자 확인
    const token = authHeader.replace('Bearer ', '')
    const { data: { user }, error: userError } = await supabaseAdmin.auth.getUser(token)

    if (userError || !user) {
      return new Response(JSON.stringify({ error: 'Unauthorized' }), {
        status: 401,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 1. 사용자 데이터 삭제 (RPC 함수 호출)
    const { error: rpcError } = await supabaseAdmin
      .rpc('delete_user_account', { user_id_to_delete: user.id })

    if (rpcError) {
      console.error('Error deleting user data:', rpcError)
      return new Response(JSON.stringify({ error: 'Failed to delete user data' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    // 2. Auth 사용자 삭제 (Admin API)
    const { error: deleteError } = await supabaseAdmin.auth.admin.deleteUser(user.id)

    if (deleteError) {
      console.error('Error deleting auth user:', deleteError)
      return new Response(JSON.stringify({ error: 'Failed to delete auth user' }), {
        status: 500,
        headers: { 'Content-Type': 'application/json' },
      })
    }

    return new Response(
      JSON.stringify({ message: 'Account deleted successfully' }),
      { status: 200, headers: { 'Content-Type': 'application/json' } }
    )
  } catch (error) {
    console.error('Unexpected error:', error)
    return new Response(JSON.stringify({ error: 'Internal server error' }), {
      status: 500,
      headers: { 'Content-Type': 'application/json' },
    })
  }
})
```

#### 3. Flutter 클라이언트 구현 (1일)

**AuthService 확장**:
```dart
// lib/data/providers/auth_provider.dart

class AuthService {
  // ... 기존 코드 ...

  /// 계정 삭제
  Future<AuthResult> deleteAccount() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return AuthResult.failure('로그인이 필요합니다.');
      }

      // Edge Function 호출
      final response = await _supabase.functions.invoke(
        'delete-user',
        headers: {
          'Authorization': 'Bearer ${_supabase.auth.currentSession?.accessToken}',
        },
      );

      if (response.status == 200) {
        // 로그아웃 처리
        await signOut();
        return AuthResult.success(null);
      } else {
        return AuthResult.failure('계정 삭제에 실패했습니다.');
      }
    } on FunctionException catch (e) {
      return AuthResult.failure('서버 오류: ${e.message}');
    } catch (e) {
      return AuthResult.failure('알 수 없는 오류가 발생했습니다.');
    }
  }
}
```

#### 4. UI 구현 (1일)

**Profile Screen 수정**:
```dart
// lib/features/profile/profile_screen.dart

class ProfileScreen extends ConsumerWidget {
  // ... 기존 코드 ...

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteAccount),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.deleteAccountWarning),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountDataList,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              '• ${l10n.favorites}\n'
              '• ${l10n.selectedIngredients}\n'
              '• ${l10n.selectedProducts}\n'
              '• ${l10n.accountInfo}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            Text(
              l10n.deleteAccountIrreversible,
              style: TextStyle(
                color: Theme.of(context).colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteAccount(context, ref);
            },
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(l10n.deleteAccount),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    // 로딩 다이얼로그 표시
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final authService = ref.read(authServiceProvider);
    final result = await authService.deleteAccount();

    if (!context.mounted) return;
    Navigator.pop(context); // 로딩 다이얼로그 닫기

    final l10n = AppLocalizations.of(context)!;

    if (result.isSuccess) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.accountDeleted)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? l10n.deleteAccountFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ... 기존 코드 ...

    // 로그아웃 섹션 뒤에 추가
    if (isAuthenticated) ...[
      const Divider(),
      ListTile(
        leading: Icon(Icons.logout, color: colorScheme.error),
        title: Text(l10n.logout, style: TextStyle(color: colorScheme.error)),
        onTap: () async {
          final authService = ref.read(authServiceProvider);
          await authService.signOut();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.logoutSuccess)),
            );
          }
        },
      ),
      ListTile(
        leading: Icon(Icons.delete_forever, color: colorScheme.error),
        title: Text(
          l10n.deleteAccount,
          style: TextStyle(color: colorScheme.error),
        ),
        onTap: () => _showDeleteAccountDialog(context, ref),
      ),
    ],
  }
}
```

#### 5. 다국어 지원 (0.5일)

**l10n 추가**:
```arb
// lib/l10n/app_en.arb
{
  "deleteAccount": "Delete Account",
  "deleteAccountWarning": "Are you sure you want to delete your account? This action cannot be undone.",
  "deleteAccountDataList": "The following data will be permanently deleted:",
  "deleteAccountIrreversible": "This action is irreversible.",
  "accountDeleted": "Your account has been deleted successfully.",
  "deleteAccountFailed": "Failed to delete account. Please try again."
}

// lib/l10n/app_ko.arb
{
  "deleteAccount": "계정 삭제",
  "deleteAccountWarning": "정말로 계정을 삭제하시겠습니까? 이 작업은 취소할 수 없습니다.",
  "deleteAccountDataList": "다음 데이터가 영구적으로 삭제됩니다:",
  "deleteAccountIrreversible": "이 작업은 되돌릴 수 없습니다.",
  "accountDeleted": "계정이 성공적으로 삭제되었습니다.",
  "deleteAccountFailed": "계정 삭제에 실패했습니다. 다시 시도해주세요."
}
```

### 위험 요소 및 대응
| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Edge Function 권한 문제 | 높음 | Service Role Key 설정 확인 |
| 데이터 삭제 실패 (일부만 삭제) | 중간 | 트랜잭션 처리 또는 롤백 메커니즘 |
| CASCADE 삭제 누락 | 중간 | 모든 관련 테이블 수동 삭제 확인 |
| 향후 테이블 추가 시 누락 | 낮음 | 함수 업데이트 체크리스트 작성 |

---

## Issue 3: 네이티브 기능 보강 (가이드라인 4.2.2)

### 목표
Apple 가이드라인 4.2.2 준수 - 앱이 단순 웹 래핑이 아닌 네이티브 앱으로서의 가치 제공

### 현황 분석
**현재 앱의 강점**:
- Flutter 네이티브 앱
- 오프라인 지원 (SharedPreferences)
- 이미지 캐싱
- 네이티브 내비게이션

**부족한 부분**:
- 사용자 생성 콘텐츠(UGC) 기능 부재
- 단순 데이터 조회 위주
- 차별화된 네이티브 기능 부족

### 제안 해결책: "나만의 칵테일(Custom Cocktails)" 조기 구현

#### 선정 이유
1. **Apple 요구사항 충족**:
   - 사용자 생성 콘텐츠 (UGC)
   - 창의적 도구 제공
   - 단순 조회 앱에서 크리에이티브 앱으로 전환

2. **기술적 실현 가능성**:
   - 기존 DB 스키마 활용 가능 (`user_cocktails`, `user_cocktail_ingredients`)
   - roadmap-v2.0.md에 상세 스펙 존재
   - 7-10일 내 MVP 구현 가능

3. **사용자 가치**:
   - 앱의 차별화 포인트 강화
   - 재방문율 증가
   - 커뮤니티 형성 가능성

#### 구현 범위 (MVP)

**Phase 1: 기본 CRUD (7-10일)**
- [ ] 나만의 칵테일 생성 UI
- [ ] 재료 선택 (기존 ingredients + 커스텀 입력)
- [ ] 레시피 입력
- [ ] 사진 업로드 (선택)
- [ ] 나만의 칵테일 목록 보기
- [ ] 수정/삭제

**제외 항목 (Phase 2로 연기)**:
- 공개/공유 기능
- 커뮤니티 레시피 검색
- 좋아요/댓글

### 구현 전략

#### 1. 데이터베이스 스키마 (1일)

**Migration**:
```sql
-- supabase/migrations/[timestamp]_add_user_cocktails.sql

-- 사용자 칵테일 테이블
CREATE TABLE user_cocktails (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  name_ko TEXT,
  description TEXT,
  description_ko TEXT,
  instructions TEXT NOT NULL,
  instructions_ko TEXT,
  garnish TEXT,
  garnish_ko TEXT,
  glass TEXT,
  method TEXT,  -- Stir, Shake, Build
  abv NUMERIC,
  tags TEXT[] DEFAULT '{}',
  image_url TEXT,
  is_public BOOLEAN DEFAULT false,
  based_on_cocktail_id TEXT REFERENCES cocktails(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 사용자 칵테일 재료 테이블
CREATE TABLE user_cocktail_ingredients (
  id SERIAL PRIMARY KEY,
  user_cocktail_id TEXT NOT NULL REFERENCES user_cocktails(id) ON DELETE CASCADE,
  ingredient_id TEXT REFERENCES ingredients(id),
  custom_ingredient_name TEXT,  -- ingredient_id가 NULL일 때 사용
  amount NUMERIC,
  units TEXT,
  sort_order INTEGER DEFAULT 0,
  is_optional BOOLEAN DEFAULT false,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now()
);

-- 인덱스
CREATE INDEX idx_user_cocktails_user_id ON user_cocktails(user_id);
CREATE INDEX idx_user_cocktails_created_at ON user_cocktails(created_at DESC);
CREATE INDEX idx_user_cocktail_ingredients_cocktail_id ON user_cocktail_ingredients(user_cocktail_id);

-- RLS 정책
ALTER TABLE user_cocktails ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cocktail_ingredients ENABLE ROW LEVEL SECURITY;

-- 본인의 칵테일만 조회 가능
CREATE POLICY "Users can view their own cocktails"
ON user_cocktails
FOR SELECT
USING (auth.uid() = user_id OR is_public = true);

-- 본인만 생성 가능
CREATE POLICY "Users can create their own cocktails"
ON user_cocktails
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 본인만 수정 가능
CREATE POLICY "Users can update their own cocktails"
ON user_cocktails
FOR UPDATE
USING (auth.uid() = user_id);

-- 본인만 삭제 가능
CREATE POLICY "Users can delete their own cocktails"
ON user_cocktails
FOR DELETE
USING (auth.uid() = user_id);

-- 재료 테이블 RLS (칵테일 소유자만)
CREATE POLICY "Users can manage their cocktail ingredients"
ON user_cocktail_ingredients
FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_cocktails
    WHERE user_cocktails.id = user_cocktail_ingredients.user_cocktail_id
    AND user_cocktails.user_id = auth.uid()
  )
);

-- 업데이트 트리거
CREATE OR REPLACE FUNCTION update_user_cocktails_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_user_cocktails_updated_at
BEFORE UPDATE ON user_cocktails
FOR EACH ROW
EXECUTE FUNCTION update_user_cocktails_updated_at();
```

#### 2. 이미지 업로드 (1일)

**Supabase Storage 설정**:
```sql
-- Storage bucket 생성 (Supabase Dashboard에서)
-- Bucket name: user-cocktail-images
-- Public: false (본인만 접근)

-- Storage 정책
CREATE POLICY "Users can upload their own cocktail images"
ON storage.objects
FOR INSERT
WITH CHECK (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own cocktail images"
ON storage.objects
FOR SELECT
USING (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own cocktail images"
ON storage.objects
FOR DELETE
USING (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

**Flutter 구현**:
```dart
// lib/core/services/image_upload_service.dart

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  /// 칵테일 이미지 업로드
  Future<String?> uploadCocktailImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final fileExt = imageFile.path.split('.').last;
      final fileName = '${DateTime.now().millisecondsSinceEpoch}.$fileExt';
      final filePath = '$userId/$fileName';

      await _supabase.storage.from('user-cocktail-images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(
              cacheControl: '3600',
              upsert: false,
            ),
          );

      final publicUrl = _supabase.storage
          .from('user-cocktail-images')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  /// 이미지 삭제
  Future<bool> deleteCocktailImage(String imageUrl) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      // URL에서 파일 경로 추출
      final uri = Uri.parse(imageUrl);
      final filePath = uri.pathSegments.last;

      await _supabase.storage
          .from('user-cocktail-images')
          .remove(['$userId/$filePath']);

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
```

#### 3. Provider 및 Service 구현 (2일)

**Data Models**:
```dart
// lib/data/models/user_cocktail.dart

class UserCocktail {
  final String id;
  final String userId;
  final String name;
  final String? nameKo;
  final String? description;
  final String? descriptionKo;
  final String instructions;
  final String? instructionsKo;
  final String? garnish;
  final String? garnishKo;
  final String? glass;
  final String? method;
  final double? abv;
  final List<String> tags;
  final String? imageUrl;
  final bool isPublic;
  final String? basedOnCocktailId;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserCocktail({
    required this.id,
    required this.userId,
    required this.name,
    this.nameKo,
    this.description,
    this.descriptionKo,
    required this.instructions,
    this.instructionsKo,
    this.garnish,
    this.garnishKo,
    this.glass,
    this.method,
    this.abv,
    this.tags = const [],
    this.imageUrl,
    this.isPublic = false,
    this.basedOnCocktailId,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserCocktail.fromJson(Map<String, dynamic> json) {
    return UserCocktail(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      nameKo: json['name_ko'] as String?,
      description: json['description'] as String?,
      descriptionKo: json['description_ko'] as String?,
      instructions: json['instructions'] as String,
      instructionsKo: json['instructions_ko'] as String?,
      garnish: json['garnish'] as String?,
      garnishKo: json['garnish_ko'] as String?,
      glass: json['glass'] as String?,
      method: json['method'] as String?,
      abv: json['abv'] != null ? (json['abv'] as num).toDouble() : null,
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      imageUrl: json['image_url'] as String?,
      isPublic: json['is_public'] as bool? ?? false,
      basedOnCocktailId: json['based_on_cocktail_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'name_ko': nameKo,
      'description': description,
      'description_ko': descriptionKo,
      'instructions': instructions,
      'instructions_ko': instructionsKo,
      'garnish': garnish,
      'garnish_ko': garnishKo,
      'glass': glass,
      'method': method,
      'abv': abv,
      'tags': tags,
      'image_url': imageUrl,
      'is_public': isPublic,
      'based_on_cocktail_id': basedOnCocktailId,
    };
  }
}

class UserCocktailIngredient {
  final int id;
  final String userCocktailId;
  final String? ingredientId;
  final String? customIngredientName;
  final double? amount;
  final String? units;
  final int sortOrder;
  final bool isOptional;
  final String? note;

  UserCocktailIngredient({
    required this.id,
    required this.userCocktailId,
    this.ingredientId,
    this.customIngredientName,
    this.amount,
    this.units,
    this.sortOrder = 0,
    this.isOptional = false,
    this.note,
  });

  factory UserCocktailIngredient.fromJson(Map<String, dynamic> json) {
    return UserCocktailIngredient(
      id: json['id'] as int,
      userCocktailId: json['user_cocktail_id'] as String,
      ingredientId: json['ingredient_id'] as String?,
      customIngredientName: json['custom_ingredient_name'] as String?,
      amount: json['amount'] != null ? (json['amount'] as num).toDouble() : null,
      units: json['units'] as String?,
      sortOrder: json['sort_order'] as int? ?? 0,
      isOptional: json['is_optional'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_cocktail_id': userCocktailId,
      'ingredient_id': ingredientId,
      'custom_ingredient_name': customIngredientName,
      'amount': amount,
      'units': units,
      'sort_order': sortOrder,
      'is_optional': isOptional,
      'note': note,
    };
  }
}
```

**Provider**:
```dart
// lib/data/providers/user_cocktail_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_cocktail.dart';
import 'auth_provider.dart';

/// 사용자 칵테일 목록
final userCocktailsProvider = StreamProvider<List<UserCocktail>>((ref) {
  final supabase = Supabase.instance.client;
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_cocktails')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => UserCocktail.fromJson(json)).toList());
});

/// 사용자 칵테일 서비스
final userCocktailServiceProvider = Provider<UserCocktailService>((ref) {
  return UserCocktailService(Supabase.instance.client);
});

class UserCocktailService {
  final SupabaseClient _supabase;

  UserCocktailService(this._supabase);

  /// 칵테일 생성
  Future<String?> createCocktail(UserCocktail cocktail) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final data = {
        ...cocktail.toJson(),
        'user_id': userId,
      };

      final response = await _supabase
          .from('user_cocktails')
          .insert(data)
          .select('id')
          .single();

      return response['id'] as String;
    } catch (e) {
      print('Error creating cocktail: $e');
      return null;
    }
  }

  /// 칵테일 재료 추가
  Future<bool> addIngredients(
    String cocktailId,
    List<UserCocktailIngredient> ingredients,
  ) async {
    try {
      final data = ingredients.map((ing) => ing.toJson()).toList();
      await _supabase.from('user_cocktail_ingredients').insert(data);
      return true;
    } catch (e) {
      print('Error adding ingredients: $e');
      return false;
    }
  }

  /// 칵테일 수정
  Future<bool> updateCocktail(String id, UserCocktail cocktail) async {
    try {
      await _supabase
          .from('user_cocktails')
          .update(cocktail.toJson())
          .eq('id', id);
      return true;
    } catch (e) {
      print('Error updating cocktail: $e');
      return false;
    }
  }

  /// 칵테일 삭제
  Future<bool> deleteCocktail(String id) async {
    try {
      await _supabase.from('user_cocktails').delete().eq('id', id);
      return true;
    } catch (e) {
      print('Error deleting cocktail: $e');
      return false;
    }
  }

  /// 칵테일 재료 조회
  Future<List<UserCocktailIngredient>> getIngredients(String cocktailId) async {
    try {
      final response = await _supabase
          .from('user_cocktail_ingredients')
          .select()
          .eq('user_cocktail_id', cocktailId)
          .order('sort_order');

      return (response as List)
          .map((json) => UserCocktailIngredient.fromJson(json))
          .toList();
    } catch (e) {
      print('Error getting ingredients: $e');
      return [];
    }
  }
}
```

#### 4. UI 구현 (3일)

**파일 구조**:
```
lib/features/user_cocktails/
├── pages/
│   ├── user_cocktails_list_page.dart
│   ├── create_cocktail_page.dart
│   └── edit_cocktail_page.dart
└── widgets/
    ├── user_cocktail_card.dart
    ├── ingredient_input_widget.dart
    └── image_picker_widget.dart
```

**주요 화면**:

1. **목록 화면** (1일)
```dart
// lib/features/user_cocktails/pages/user_cocktails_list_page.dart
// - 사용자가 만든 칵테일 목록
// - FloatingActionButton으로 생성 화면 이동
// - 카드 클릭 시 상세/편집
```

2. **생성 화면** (2일)
```dart
// lib/features/user_cocktails/pages/create_cocktail_page.dart
// - 칵테일 이름 입력
// - 재료 추가 (기존 ingredients 선택 + 커스텀 입력)
// - 양, 단위 입력
// - 만드는 방법 입력
// - 가니시, 잔 종류 선택
// - 사진 업로드
// - 저장 버튼
```

#### 5. 내비게이션 통합 (0.5일)

**Profile 화면에 진입점 추가**:
```dart
// lib/features/profile/profile_screen.dart

// 인증된 사용자에게만 표시
if (isAuthenticated) ...[
  ListTile(
    leading: const Icon(Icons.local_bar),
    title: Text(l10n.myCocktails),
    subtitle: Text(l10n.myCocktailsDescription),
    trailing: const Icon(Icons.chevron_right),
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const UserCocktailsListPage(),
        ),
      );
    },
  ),
],
```

### 위험 요소 및 대응
| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Apple 심사에서 여전히 부족하다고 판단 | 높음 | 추가 기능 제안 준비 (예: 공유 기능) |
| 이미지 업로드 실패 | 중간 | 이미지 없이도 저장 가능하도록 |
| 구현 일정 지연 | 중간 | Phase 1 MVP만 구현, 나머지는 이후 |
| 사용자가 기능을 찾지 못함 | 낮음 | 온보딩에 안내 추가 |

---

## 테스트 전략

### 단위 테스트
- [ ] AuthService.deleteAccount() 메서드
- [ ] UserCocktailService CRUD 메서드
- [ ] ImageUploadService 업로드/삭제

### 통합 테스트
- [ ] Google 로그인 플로우 (WebView)
- [ ] 계정 삭제 플로우 (데이터 삭제 → Auth 삭제)
- [ ] 칵테일 생성 플로우 (이미지 업로드 → DB 저장)

### 수동 테스트
- [ ] iOS 실기기에서 Google 로그인 (WebView 확인)
- [ ] 계정 삭제 후 데이터 완전 삭제 확인
- [ ] 나만의 칵테일 생성/수정/삭제
- [ ] 이미지 업로드 및 표시
- [ ] 오프라인 상태에서 에러 처리

---

## 성공 기준

### Issue 1: Google 로그인
- [x] Google 로그인 시 인앱 WebView에서 진행
- [x] 로그인 완료 후 정상 콜백 처리
- [x] iOS 실기기 테스트 통과

### Issue 2: 계정 삭제
- [x] Profile 화면에 계정 삭제 버튼 노출
- [x] 삭제 확인 다이얼로그 표시
- [x] 모든 사용자 데이터 삭제 확인
- [x] Auth 사용자 삭제 확인
- [x] 다국어 지원 (한국어, 영어)

### Issue 3: 네이티브 기능
- [x] 나만의 칵테일 생성 기능 구현
- [x] 이미지 업로드 기능 구현
- [x] Profile 화면에서 진입 가능
- [x] CRUD 모든 작업 정상 동작
- [x] Apple 심사 통과

---

## 우선순위 및 일정

### Phase 1: 필수 구현 (12-15일)
**Week 1 (5일)**:
- Day 1-2: Issue 1 - Google 로그인 인앱 처리
- Day 3-5: Issue 2 - 계정 삭제 기능

**Week 2 (7-10일)**:
- Day 1: Issue 3 - DB 스키마 및 마이그레이션
- Day 2-3: Provider 및 Service 구현
- Day 4-6: UI 구현 (목록, 생성, 편집)
- Day 7: 통합 테스트 및 버그 수정

### Phase 2: 제출 및 대응 (3-5일)
- Day 1: TestFlight 빌드 및 내부 테스트
- Day 2: App Store Connect 메타데이터 업데이트
- Day 3: 제출
- Day 4-5: 심사 피드백 대응

---

## 참고 자료

### Apple 가이드라인
- [App Store Review Guidelines 4.2.2](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality)
- [App Store Review Guidelines 5.1.1](https://developer.apple.com/app-store/review/guidelines/#data-collection-and-storage)

### Supabase 문서
- [Supabase Auth - OAuth](https://supabase.com/docs/guides/auth/social-login)
- [Supabase Storage](https://supabase.com/docs/guides/storage)
- [Row Level Security](https://supabase.com/docs/guides/auth/row-level-security)

### Flutter 패키지
- [supabase_flutter](https://pub.dev/packages/supabase_flutter)
- [image_picker](https://pub.dev/packages/image_picker)
- [url_launcher](https://pub.dev/packages/url_launcher)

### 기존 문서
- [Roadmap v2.0](./roadmap-v2.0.md) - Custom Cocktails 상세 스펙
- [Database Schema](./database-schema.md) - 전체 DB 구조
