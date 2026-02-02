# 나만의 칵테일(Custom Cocktails) 기능 구현 전략

## 개요
- **목적**: Apple App Store 가이드라인 4.2.2 준수 - 사용자 생성 콘텐츠(UGC) 기능 추가로 네이티브 앱으로서의 가치 제공
- **범위**: 사용자가 직접 칵테일을 생성, 수정, 삭제할 수 있는 CRUD 기능 구현 (MVP)
- **예상 소요 기간**: 7-10일
- **우선순위**: 필수 (App Store 심사 통과를 위한 핵심 기능)

## 현재 상태 분석

### 프로젝트 구조
- **프레임워크**: Flutter 3.8.1
- **백엔드**: Supabase (PostgreSQL, Storage, Edge Functions)
- **상태관리**: Riverpod 2.6.1
- **이미지 처리**: cached_network_image ^3.4.1 (기존 사용 중)
- **패키지**: supabase_flutter ^2.8.3

### 기존 구현 패턴 분석

#### 데이터 모델 구조
**참조 파일**: `lib/data/models/cocktail.dart`, `lib/data/models/ingredient.dart`

**현재 Cocktail 모델**:
- `Cocktail` 클래스: 칵테일 기본 정보
- `CocktailIngredient` 클래스: 칵테일의 재료 정보 (amount, units, optional 등)
- 다국어 지원: `name`, `name_ko`, `instructions`, `instructions_ko` 등
- Supabase 연동: `fromSupabase()`, `toSupabase()` 메서드

#### Provider 패턴
**참조 파일**: `lib/data/providers/cocktail_provider.dart`, `lib/data/providers/auth_provider.dart`

**현재 패턴**:
- `FutureProvider`: 비동기 데이터 로딩 (cocktailsProvider)
- `StreamProvider`: 실시간 데이터 동기화 (userFavoritesDbProvider)
- `Provider`: 서비스 인스턴스 제공 (authServiceProvider)
- Family Provider: 파라미터 기반 데이터 로딩 (cocktailIngredientsProvider.family)

#### Feature 구조
**참조 디렉토리**: `lib/features/`

**기존 패턴**:
```
lib/features/[feature_name]/
├── pages/              # 화면 (optional)
├── widgets/            # 재사용 위젯 (optional)
└── [feature_name]_screen.dart  # 메인 화면
```

**예시**:
- `lib/features/cocktails/`: cocktails_screen.dart, cocktail_detail_screen.dart
- `lib/features/profile/`: profile_screen.dart
- `lib/features/onboarding/pages/`: auth_page.dart, products_page.dart 등

### 기존 리소스 활용 가능 항목
1. **이미지 처리**: `cached_network_image` 패키지 이미 사용 중
2. **Supabase Storage**: 이미지 저장소 활용 가능
3. **인증 시스템**: 현재 사용자 ID 기반 RLS 정책 활용
4. **다국어 지원**: 기존 l10n 시스템 확장
5. **UI 컴포넌트**: `CocktailCard`, `StorageImage` 등 재사용 가능

### 구현 필요 항목
1. **Database Schema**: `user_cocktails`, `user_cocktail_ingredients` 테이블
2. **Storage Bucket**: `user-cocktail-images` 버킷 및 RLS 정책
3. **Data Models**: `UserCocktail`, `UserCocktailIngredient` 클래스
4. **Providers**: `userCocktailsProvider`, `userCocktailServiceProvider`
5. **Service**: `UserCocktailService` (CRUD 로직)
6. **Image Service**: `ImageUploadService` (이미지 업로드/삭제)
7. **UI Components**: 목록, 생성, 편집 화면 및 관련 위젯

---

## 구현 전략

### 접근 방식
**Phase-based Implementation**: 데이터 계층 → 서비스 계층 → UI 계층 순서로 점진적 구현

**핵심 원칙**:
1. **기존 패턴 준수**: 프로젝트의 기존 아키텍처와 코딩 스타일 유지
2. **점진적 검증**: 각 레이어 완성 시마다 테스트 및 검증
3. **MVP 우선**: 필수 기능만 구현, 고급 기능은 Phase 2로 연기
4. **오프라인 대응**: Supabase Stream 기반 실시간 동기화 활용

### 세부 구현 단계

#### Phase 1: Database Layer (Day 1, 1일)
**목표**: Supabase 데이터베이스 스키마 및 RLS 정책 구축

**1.1 Migration 파일 작성**
- **파일**: `supabase/migrations/[timestamp]_add_user_cocktails.sql`
- **내용**:
  - `user_cocktails` 테이블 생성
  - `user_cocktail_ingredients` 테이블 생성
  - 인덱스 추가 (user_id, created_at)
  - RLS 정책 설정 (본인만 CRUD 가능)
  - `updated_at` 자동 업데이트 트리거

**스키마 설계**:

```sql
-- user_cocktails 테이블
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
  method TEXT,  -- Stir, Shake, Build 등
  abv NUMERIC,
  tags TEXT[] DEFAULT '{}',
  image_url TEXT,
  is_public BOOLEAN DEFAULT false,  -- Phase 2 준비
  based_on_cocktail_id TEXT REFERENCES cocktails(id),  -- 원본 칵테일 참조
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- user_cocktail_ingredients 테이블
CREATE TABLE user_cocktail_ingredients (
  id SERIAL PRIMARY KEY,
  user_cocktail_id TEXT NOT NULL REFERENCES user_cocktails(id) ON DELETE CASCADE,
  ingredient_id TEXT REFERENCES ingredients(id),  -- NULL 허용 (커스텀 재료)
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
CREATE INDEX idx_user_cocktail_ingredients_cocktail_id
  ON user_cocktail_ingredients(user_cocktail_id);

-- RLS 활성화
ALTER TABLE user_cocktails ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cocktail_ingredients ENABLE ROW LEVEL SECURITY;

-- RLS 정책: user_cocktails
CREATE POLICY "Users can view their own cocktails or public ones"
ON user_cocktails FOR SELECT
USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create their own cocktails"
ON user_cocktails FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cocktails"
ON user_cocktails FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cocktails"
ON user_cocktails FOR DELETE
USING (auth.uid() = user_id);

-- RLS 정책: user_cocktail_ingredients
CREATE POLICY "Users can manage their cocktail ingredients"
ON user_cocktail_ingredients FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_cocktails
    WHERE user_cocktails.id = user_cocktail_ingredients.user_cocktail_id
    AND user_cocktails.user_id = auth.uid()
  )
);

-- updated_at 자동 업데이트 트리거
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

**1.2 Storage Bucket 설정**
- **버킷명**: `user-cocktail-images`
- **공개 여부**: Private (본인만 접근)
- **RLS 정책**:
  - 업로드: 본인 폴더에만 가능 (`{user_id}/{filename}`)
  - 조회: 본인 폴더만 가능
  - 삭제: 본인 파일만 가능

```sql
-- Storage 정책 (Supabase Dashboard에서 설정 또는 SQL로)
CREATE POLICY "Users can upload their own cocktail images"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can view their own cocktail images"
ON storage.objects FOR SELECT
USING (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

CREATE POLICY "Users can delete their own cocktail images"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'user-cocktail-images' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

**1.3 Migration 적용 및 검증**
- Supabase Dashboard에서 Migration 실행
- 테이블, 인덱스, RLS 정책 정상 생성 확인
- Storage Bucket 생성 및 정책 확인

**검증 체크리스트**:
- [ ] `user_cocktails` 테이블 생성 확인
- [ ] `user_cocktail_ingredients` 테이블 생성 확인
- [ ] RLS 정책 활성화 확인
- [ ] Storage Bucket `user-cocktail-images` 생성 확인
- [ ] Storage RLS 정책 설정 확인

---

#### Phase 2: Data Models (Day 2, 0.5일)
**목표**: Flutter 데이터 모델 클래스 작성

**2.1 UserCocktail 모델**
- **파일**: `lib/data/models/user_cocktail.dart`
- **내용**:
  - 기존 `Cocktail` 모델과 유사한 구조
  - `fromJson()`, `toJson()`, `toSupabase()` 메서드
  - 다국어 메서드: `getLocalizedName()`, `getLocalizedInstructions()` 등

```dart
import 'package:flutter/foundation.dart';

@immutable
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

  const UserCocktail({
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

  factory UserCocktail.fromSupabase(Map<String, dynamic> json) {
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

  Map<String, dynamic> toSupabase() {
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

  String getLocalizedName(String locale) {
    if (locale == 'ko' && nameKo != null && nameKo!.isNotEmpty) {
      return nameKo!;
    }
    return name;
  }

  String getLocalizedInstructions(String locale) {
    if (locale == 'ko' && instructionsKo != null && instructionsKo!.isNotEmpty) {
      return instructionsKo!;
    }
    return instructions;
  }

  String? getLocalizedDescription(String locale) {
    if (locale == 'ko' && descriptionKo != null && descriptionKo!.isNotEmpty) {
      return descriptionKo;
    }
    return description;
  }

  String? getLocalizedGarnish(String locale) {
    if (locale == 'ko' && garnishKo != null && garnishKo!.isNotEmpty) {
      return garnishKo;
    }
    return garnish;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCocktail && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

**2.2 UserCocktailIngredient 모델**
- **파일**: `lib/data/models/user_cocktail_ingredient.dart`
- **내용**: CocktailIngredient와 유사하지만 `custom_ingredient_name` 지원

```dart
import 'package:flutter/foundation.dart';

@immutable
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

  const UserCocktailIngredient({
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

  factory UserCocktailIngredient.fromSupabase(Map<String, dynamic> json) {
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

  Map<String, dynamic> toSupabase() {
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

  String get displayName => customIngredientName ?? ingredientId ?? '';

  String get formattedAmount {
    if (amount == null || units == null) return '';
    final amountStr = amount == amount!.roundToDouble()
        ? amount!.round().toString()
        : amount.toString();
    return '$amountStr $units';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserCocktailIngredient && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
```

**2.3 models.dart 업데이트**
- **파일**: `lib/data/models/models.dart`
- **추가**: `export 'user_cocktail.dart';`, `export 'user_cocktail_ingredient.dart';`

**검증 체크리스트**:
- [ ] UserCocktail 클래스 정의 완료
- [ ] UserCocktailIngredient 클래스 정의 완료
- [ ] fromSupabase/toSupabase 메서드 구현
- [ ] 다국어 메서드 구현
- [ ] models.dart export 추가

---

#### Phase 3: Service Layer (Day 2-3, 1.5일)
**목표**: 이미지 업로드 서비스 및 UserCocktail 서비스 구현

**3.1 ImageUploadService**
- **파일**: `lib/core/services/image_upload_service.dart`
- **기능**: 이미지 업로드, 삭제, URL 생성

```dart
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class ImageUploadService {
  final SupabaseClient _supabase;

  ImageUploadService(this._supabase);

  /// 칵테일 이미지 업로드
  Future<String?> uploadCocktailImage(File imageFile) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final fileExt = imageFile.path.split('.').last.toLowerCase();
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
      final pathSegments = uri.pathSegments;

      // /storage/v1/object/public/user-cocktail-images/{userId}/{fileName}
      if (pathSegments.length < 2) return false;

      final fileName = pathSegments.last;
      final filePath = '$userId/$fileName';

      await _supabase.storage
          .from('user-cocktail-images')
          .remove([filePath]);

      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }
}
```

**3.2 UserCocktailService**
- **파일**: `lib/core/services/user_cocktail_service.dart`
- **기능**: CRUD 작업, 트랜잭션 처리

```dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user_cocktail.dart';
import '../../data/models/user_cocktail_ingredient.dart';

class UserCocktailService {
  final SupabaseClient _supabase;

  UserCocktailService(this._supabase);

  /// 칵테일 생성 (재료 포함)
  Future<String?> createCocktail({
    required UserCocktail cocktail,
    required List<UserCocktailIngredient> ingredients,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // 1. 칵테일 생성
      final cocktailData = {
        ...cocktail.toSupabase(),
        'user_id': userId,
      };

      final response = await _supabase
          .from('user_cocktails')
          .insert(cocktailData)
          .select('id')
          .single();

      final cocktailId = response['id'] as String;

      // 2. 재료 추가
      if (ingredients.isNotEmpty) {
        final ingredientsData = ingredients.map((ing) {
          return {
            ...ing.toSupabase(),
            'user_cocktail_id': cocktailId,
          };
        }).toList();

        await _supabase
            .from('user_cocktail_ingredients')
            .insert(ingredientsData);
      }

      return cocktailId;
    } catch (e) {
      print('Error creating cocktail: $e');
      return null;
    }
  }

  /// 칵테일 수정
  Future<bool> updateCocktail({
    required String id,
    required UserCocktail cocktail,
    List<UserCocktailIngredient>? ingredients,
  }) async {
    try {
      // 1. 칵테일 업데이트
      await _supabase
          .from('user_cocktails')
          .update(cocktail.toSupabase())
          .eq('id', id);

      // 2. 재료 업데이트 (제공된 경우)
      if (ingredients != null) {
        // 기존 재료 삭제
        await _supabase
            .from('user_cocktail_ingredients')
            .delete()
            .eq('user_cocktail_id', id);

        // 새 재료 추가
        if (ingredients.isNotEmpty) {
          final ingredientsData = ingredients.map((ing) {
            return {
              ...ing.toSupabase(),
              'user_cocktail_id': id,
            };
          }).toList();

          await _supabase
              .from('user_cocktail_ingredients')
              .insert(ingredientsData);
        }
      }

      return true;
    } catch (e) {
      print('Error updating cocktail: $e');
      return false;
    }
  }

  /// 칵테일 삭제
  Future<bool> deleteCocktail(String id) async {
    try {
      // CASCADE로 재료도 자동 삭제됨
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
          .map((json) => UserCocktailIngredient.fromSupabase(json))
          .toList();
    } catch (e) {
      print('Error getting ingredients: $e');
      return [];
    }
  }

  /// 특정 칵테일 조회 (상세)
  Future<UserCocktail?> getCocktail(String id) async {
    try {
      final response = await _supabase
          .from('user_cocktails')
          .select()
          .eq('id', id)
          .single();

      return UserCocktail.fromSupabase(response);
    } catch (e) {
      print('Error getting cocktail: $e');
      return null;
    }
  }
}
```

**검증 체크리스트**:
- [ ] ImageUploadService 구현 완료
- [ ] UserCocktailService CRUD 메서드 구현
- [ ] 에러 핸들링 추가
- [ ] Transaction-like 처리 (칵테일 + 재료 생성)

---

#### Phase 4: Providers (Day 3-4, 1일)
**목표**: Riverpod Provider 구현

**4.1 UserCocktailProvider**
- **파일**: `lib/data/providers/user_cocktail_provider.dart`
- **내용**: Stream 기반 실시간 동기화, Service Provider

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_cocktail.dart';
import '../models/user_cocktail_ingredient.dart';
import '../../core/services/user_cocktail_service.dart';
import '../../core/services/image_upload_service.dart';
import 'auth_provider.dart';
import 'unified_providers.dart';

/// 사용자 칵테일 서비스
final userCocktailServiceProvider = Provider<UserCocktailService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return UserCocktailService(supabase);
});

/// 이미지 업로드 서비스
final imageUploadServiceProvider = Provider<ImageUploadService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return ImageUploadService(supabase);
});

/// 사용자 칵테일 목록 (실시간 스트림)
final userCocktailsProvider = StreamProvider<List<UserCocktail>>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final userId = ref.watch(currentUserIdProvider);

  if (userId == null) return Stream.value([]);

  return supabase
      .from('user_cocktails')
      .stream(primaryKey: ['id'])
      .eq('user_id', userId)
      .order('created_at', ascending: false)
      .map((data) => data.map((json) => UserCocktail.fromSupabase(json)).toList());
});

/// 특정 사용자 칵테일 조회 (Family Provider)
final userCocktailProvider = FutureProvider.family<UserCocktail?, String>((ref, id) async {
  final service = ref.watch(userCocktailServiceProvider);
  return await service.getCocktail(id);
});

/// 특정 사용자 칵테일 재료 조회 (Family Provider)
final userCocktailIngredientsProvider =
    FutureProvider.family<List<UserCocktailIngredient>, String>((ref, cocktailId) async {
  final service = ref.watch(userCocktailServiceProvider);
  return await service.getIngredients(cocktailId);
});
```

**4.2 providers.dart 업데이트**
- **파일**: `lib/data/providers/providers.dart`
- **추가**: `export 'user_cocktail_provider.dart';`

**검증 체크리스트**:
- [ ] userCocktailServiceProvider 정의
- [ ] imageUploadServiceProvider 정의
- [ ] userCocktailsProvider (Stream) 정의
- [ ] Family Providers 정의
- [ ] providers.dart export 추가

---

#### Phase 5: UI Implementation (Day 4-7, 3일)
**목표**: 사용자 인터페이스 구현 (목록, 생성, 편집)

**5.1 Feature 디렉토리 구조**
```
lib/features/user_cocktails/
├── pages/
│   ├── user_cocktails_list_page.dart
│   ├── create_user_cocktail_page.dart
│   ├── edit_user_cocktail_page.dart
│   └── user_cocktail_detail_page.dart
└── widgets/
    ├── user_cocktail_card.dart
    ├── ingredient_input_list.dart
    ├── cocktail_image_picker.dart
    └── cocktail_form_fields.dart
```

**5.2 목록 화면 (1일)**
- **파일**: `lib/features/user_cocktails/pages/user_cocktails_list_page.dart`
- **기능**:
  - userCocktailsProvider 구독 (Stream)
  - 칵테일 목록 표시 (UserCocktailCard 사용)
  - FloatingActionButton → 생성 화면 이동
  - 카드 클릭 → 상세/편집 화면 이동
  - 빈 상태 표시 (칵테일이 없을 때)

**구현 스니펫**:
```dart
class UserCocktailsListPage extends ConsumerWidget {
  const UserCocktailsListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cocktailsAsync = ref.watch(userCocktailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('나만의 칵테일'),
      ),
      body: cocktailsAsync.when(
        data: (cocktails) {
          if (cocktails.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_bar, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    '아직 만든 칵테일이 없습니다',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '하단 버튼을 눌러 나만의 칵테일을 만들어보세요!',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: cocktails.length,
            itemBuilder: (context, index) {
              final cocktail = cocktails[index];
              return UserCocktailCard(
                cocktail: cocktail,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => EditUserCocktailPage(cocktail: cocktail),
                    ),
                  );
                },
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('오류 발생: $error'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateUserCocktailPage(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('칵테일 만들기'),
      ),
    );
  }
}
```

**5.3 위젯: UserCocktailCard**
- **파일**: `lib/features/user_cocktails/widgets/user_cocktail_card.dart`
- **기능**: 칵테일 카드 표시 (이미지, 이름, 설명 미리보기)

```dart
class UserCocktailCard extends StatelessWidget {
  final UserCocktail cocktail;
  final VoidCallback onTap;

  const UserCocktailCard({
    super.key,
    required this.cocktail,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final name = cocktail.getLocalizedName(locale);
    final description = cocktail.getLocalizedDescription(locale);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            // 이미지
            if (cocktail.imageUrl != null)
              CachedNetworkImage(
                imageUrl: cocktail.imageUrl!,
                width: 100,
                height: 100,
                fit: BoxFit.cover,
                placeholder: (context, url) =>
                    const Center(child: CircularProgressIndicator()),
                errorWidget: (context, url, error) =>
                    const Icon(Icons.local_bar, size: 48),
              )
            else
              Container(
                width: 100,
                height: 100,
                color: Colors.grey[200],
                child: const Icon(Icons.local_bar, size: 48, color: Colors.grey),
              ),

            // 정보
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        if (cocktail.glass != null) ...[
                          const Icon(Icons.wine_bar, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            cocktail.glass!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(width: 12),
                        ],
                        if (cocktail.method != null) ...[
                          const Icon(Icons.ac_unit, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            cocktail.method!,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const Icon(Icons.chevron_right),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }
}
```

**5.4 생성 화면 (2일)**
- **파일**: `lib/features/user_cocktails/pages/create_user_cocktail_page.dart`
- **기능**:
  - Form 기반 입력 (이름, 설명, 만드는 법 등)
  - 재료 추가 (IngredientInputList 위젯 사용)
  - 이미지 선택 (CocktailImagePicker 위젯 사용)
  - 저장 버튼: UserCocktailService.createCocktail() 호출
  - 로딩 상태 표시

**구현 스니펫 (핵심 부분)**:
```dart
class CreateUserCocktailPage extends ConsumerStatefulWidget {
  const CreateUserCocktailPage({super.key});

  @override
  ConsumerState<CreateUserCocktailPage> createState() =>
      _CreateUserCocktailPageState();
}

class _CreateUserCocktailPageState extends ConsumerState<CreateUserCocktailPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _garnishController = TextEditingController();

  String? _selectedGlass;
  String? _selectedMethod;
  File? _imageFile;
  bool _isLoading = false;

  final List<UserCocktailIngredient> _ingredients = [];

  @override
  void dispose() {
    _nameController.dispose();
    _instructionsController.dispose();
    _descriptionController.dispose();
    _garnishController.dispose();
    super.dispose();
  }

  Future<void> _saveCocktail() async {
    if (!_formKey.currentState!.validate()) return;
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('재료를 최소 1개 이상 추가해주세요')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl;

      // 1. 이미지 업로드
      if (_imageFile != null) {
        final imageService = ref.read(imageUploadServiceProvider);
        imageUrl = await imageService.uploadCocktailImage(_imageFile!);
      }

      // 2. 칵테일 생성
      final cocktail = UserCocktail(
        id: '', // 서버에서 생성됨
        userId: '', // 서버에서 설정됨
        name: _nameController.text,
        instructions: _instructionsController.text,
        description: _descriptionController.text.isEmpty
            ? null
            : _descriptionController.text,
        garnish: _garnishController.text.isEmpty
            ? null
            : _garnishController.text,
        glass: _selectedGlass,
        method: _selectedMethod,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final service = ref.read(userCocktailServiceProvider);
      final cocktailId = await service.createCocktail(
        cocktail: cocktail,
        ingredients: _ingredients,
      );

      if (!mounted) return;

      if (cocktailId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('칵테일이 저장되었습니다')),
        );
        Navigator.pop(context);
      } else {
        throw Exception('Failed to create cocktail');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류 발생: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('칵테일 만들기'),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: CircularProgressIndicator(),
              ),
            )
          else
            TextButton(
              onPressed: _saveCocktail,
              child: const Text('저장'),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 이미지 선택
            CocktailImagePicker(
              imageFile: _imageFile,
              onImageSelected: (file) {
                setState(() => _imageFile = file);
              },
            ),
            const SizedBox(height: 24),

            // 이름
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '칵테일 이름',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '칵테일 이름을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 설명
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: '설명 (선택)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),

            // 만드는 법
            TextFormField(
              controller: _instructionsController,
              decoration: const InputDecoration(
                labelText: '만드는 법',
                border: OutlineInputBorder(),
                hintText: '재료를 섞는 방법을 설명해주세요',
              ),
              maxLines: 5,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '만드는 법을 입력해주세요';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // 가니시
            TextFormField(
              controller: _garnishController,
              decoration: const InputDecoration(
                labelText: '가니시 (선택)',
                border: OutlineInputBorder(),
                hintText: '예: 레몬 슬라이스',
              ),
            ),
            const SizedBox(height: 16),

            // 잔 종류
            DropdownButtonFormField<String>(
              value: _selectedGlass,
              decoration: const InputDecoration(
                labelText: '잔 종류 (선택)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Highball', child: Text('Highball')),
                DropdownMenuItem(value: 'Rocks', child: Text('Rocks')),
                DropdownMenuItem(value: 'Coupe', child: Text('Coupe')),
                DropdownMenuItem(value: 'Martini', child: Text('Martini')),
                DropdownMenuItem(value: 'Flute', child: Text('Flute')),
              ],
              onChanged: (value) {
                setState(() => _selectedGlass = value);
              },
            ),
            const SizedBox(height: 16),

            // 방법
            DropdownButtonFormField<String>(
              value: _selectedMethod,
              decoration: const InputDecoration(
                labelText: '만드는 방법 (선택)',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Shake', child: Text('Shake')),
                DropdownMenuItem(value: 'Stir', child: Text('Stir')),
                DropdownMenuItem(value: 'Build', child: Text('Build')),
                DropdownMenuItem(value: 'Blend', child: Text('Blend')),
              ],
              onChanged: (value) {
                setState(() => _selectedMethod = value);
              },
            ),
            const SizedBox(height: 24),

            // 재료 목록
            IngredientInputList(
              ingredients: _ingredients,
              onIngredientsChanged: (ingredients) {
                setState(() {
                  _ingredients.clear();
                  _ingredients.addAll(ingredients);
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
```

**5.5 위젯: IngredientInputList**
- **파일**: `lib/features/user_cocktails/widgets/ingredient_input_list.dart`
- **기능**: 재료 추가/삭제, 양/단위 입력

**5.6 위젯: CocktailImagePicker**
- **파일**: `lib/features/user_cocktails/widgets/cocktail_image_picker.dart`
- **기능**: 이미지 선택 (갤러리, 카메라)
- **패키지**: `image_picker` (pubspec.yaml에 추가 필요)

**5.7 편집 화면**
- **파일**: `lib/features/user_cocktails/pages/edit_user_cocktail_page.dart`
- **기능**: CreateUserCocktailPage와 유사하지만 기존 데이터 로드 및 업데이트

**검증 체크리스트**:
- [ ] 목록 화면 구현 및 Stream 연동
- [ ] 생성 화면 Form 구현
- [ ] 재료 추가/삭제 기능
- [ ] 이미지 선택 기능
- [ ] 저장 로직 (Service 호출)
- [ ] 편집 화면 구현
- [ ] 삭제 기능 (편집 화면에서)

---

#### Phase 6: Navigation Integration (Day 7, 0.5일)
**목표**: Profile 화면에 진입점 추가

**6.1 Profile Screen 수정**
- **파일**: `lib/features/profile/profile_screen.dart`
- **추가 내용**: ListTile 추가 (인증된 사용자만)

```dart
// profile_screen.dart 내부, 인증된 사용자 섹션에 추가

if (isAuthenticated) ...[
  const Divider(),
  ListTile(
    leading: const Icon(Icons.local_bar),
    title: const Text('나만의 칵테일'),
    subtitle: const Text('내가 만든 칵테일 레시피'),
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

**6.2 l10n 업데이트 (옵션)**
- **파일**: `lib/l10n/app_en.arb`, `lib/l10n/app_ko.arb`
- **추가**:
  - `myCocktails`: "My Cocktails" / "나만의 칵테일"
  - `myCocktailsDescription`: "My custom cocktail recipes" / "내가 만든 칵테일 레시피"
  - `createCocktail`: "Create Cocktail" / "칵테일 만들기"
  - 기타 필요한 문자열

**검증 체크리스트**:
- [ ] Profile 화면에 진입점 추가
- [ ] 내비게이션 정상 작동 확인
- [ ] l10n 문자열 추가 (선택)

---

#### Phase 7: Testing & Bug Fixes (Day 7-8, 1일)
**목표**: 통합 테스트 및 버그 수정

**7.1 기능 테스트**
- [ ] 칵테일 생성 플로우
  - [ ] 이미지 없이 생성
  - [ ] 이미지 포함 생성
  - [ ] 재료 추가/삭제
  - [ ] Validation 테스트
- [ ] 칵테일 편집 플로우
  - [ ] 기존 데이터 로드 확인
  - [ ] 수정 후 저장
  - [ ] 이미지 변경
- [ ] 칵테일 삭제 플로우
  - [ ] 삭제 확인 다이얼로그
  - [ ] CASCADE 삭제 (재료도 함께 삭제)
  - [ ] 이미지 삭제 (Storage)
- [ ] 목록 화면
  - [ ] Stream 실시간 업데이트
  - [ ] 빈 상태 표시

**7.2 에러 시나리오 테스트**
- [ ] 오프라인 상태에서 생성 시도
- [ ] 이미지 업로드 실패
- [ ] 네트워크 오류
- [ ] 인증 만료

**7.3 UI/UX 검증**
- [ ] 로딩 상태 표시
- [ ] 에러 메시지 표시
- [ ] 성공 메시지 표시
- [ ] 반응형 레이아웃 (다양한 화면 크기)

**7.4 성능 테스트**
- [ ] 이미지 로딩 성능
- [ ] 목록 스크롤 성능
- [ ] 대량 재료 입력 (10개 이상)

---

#### Phase 8: Package Dependencies (Day 1, 준비 단계)
**목표**: 필요한 패키지 추가

**8.1 pubspec.yaml 업데이트**
- **추가 패키지**:
  - `image_picker: ^1.0.4` (이미지 선택)

```yaml
dependencies:
  # ... 기존 패키지 ...

  # Image Picker
  image_picker: ^1.0.4
```

**8.2 iOS 권한 설정**
- **파일**: `ios/Runner/Info.plist`
- **추가**:
```xml
<key>NSPhotoLibraryUsageDescription</key>
<string>칵테일 사진을 업로드하기 위해 사진 라이브러리 접근이 필요합니다.</string>
<key>NSCameraUsageDescription</key>
<string>칵테일 사진을 촬영하기 위해 카메라 접근이 필요합니다.</string>
```

**8.3 패키지 설치**
```bash
flutter pub get
```

**검증 체크리스트**:
- [ ] image_picker 패키지 추가
- [ ] iOS 권한 설정 완료
- [ ] 패키지 정상 설치 확인

---

## 기술적 고려사항

### 아키텍처
- **레이어 분리**: Data Layer (Models, Providers) → Service Layer → UI Layer
- **상태관리**: Riverpod StreamProvider로 실시간 동기화
- **에러 처리**: try-catch 및 사용자 피드백 (SnackBar)

### 의존성
- **기존 패키지 활용**: cached_network_image, riverpod, supabase_flutter
- **신규 패키지**: image_picker (이미지 선택)
- **Supabase 기능**: RLS, Storage, Real-time Stream

### API 설계
- **Service 메서드**:
  - `createCocktail(cocktail, ingredients)`: 칵테일 생성
  - `updateCocktail(id, cocktail, ingredients)`: 칵테일 수정
  - `deleteCocktail(id)`: 칵테일 삭제
  - `getIngredients(cocktailId)`: 재료 조회
  - `uploadCocktailImage(file)`: 이미지 업로드
  - `deleteCocktailImage(url)`: 이미지 삭제

### 데이터 모델
- **UserCocktail**: 기존 Cocktail 모델과 유사하지만 `user_id`, `is_public` 추가
- **UserCocktailIngredient**: `custom_ingredient_name` 지원으로 기존 재료 외 커스텀 재료 입력 가능

### 보안
- **RLS 정책**: 본인이 생성한 칵테일만 CRUD 가능
- **Storage 정책**: 본인 폴더에만 이미지 업로드/조회/삭제 가능
- **CASCADE 삭제**: 칵테일 삭제 시 재료도 자동 삭제

---

## 위험 요소 및 대응 방안

| 위험 요소 | 영향도 | 대응 방안 |
|-----------|--------|----------|
| Apple 심사에서 여전히 부족하다고 판단 | 높음 | Phase 2 기능(공유, 커뮤니티) 제안 준비, 온보딩에 기능 강조 |
| 이미지 업로드 실패 (네트워크, 용량) | 중간 | 이미지 없이도 저장 가능, 재시도 메커니즘, 압축 처리 |
| 구현 일정 지연 (UI 복잡도) | 중간 | MVP 범위 엄격히 준수, 고급 기능은 Phase 2로 연기 |
| RLS 정책 설정 오류 | 중간 | Supabase Dashboard에서 정책 테스트, 실기기 테스트 |
| 사용자가 기능을 찾지 못함 | 낮음 | Profile 화면에 눈에 띄게 배치, 온보딩 추가 |
| 이미지 삭제 실패 (URL 파싱) | 낮음 | URL 파싱 로직 검증, 삭제 실패 시 로깅 |
| 재료 입력 UX 복잡 | 낮음 | 간단한 텍스트 입력 + 기존 재료 선택 옵션 제공 |

---

## 테스트 전략

### 단위 테스트
- [ ] **UserCocktailService**:
  - `createCocktail()`: 칵테일 + 재료 생성 검증
  - `updateCocktail()`: 수정 로직 검증
  - `deleteCocktail()`: CASCADE 삭제 검증
  - `getIngredients()`: 재료 조회 검증
- [ ] **ImageUploadService**:
  - `uploadCocktailImage()`: 업로드 성공/실패
  - `deleteCocktailImage()`: URL 파싱 및 삭제

### 통합 테스트
- [ ] **칵테일 생성 플로우**:
  - 이미지 업로드 → 칵테일 생성 → DB 저장 → Stream 업데이트
- [ ] **칵테일 삭제 플로우**:
  - 칵테일 삭제 → 재료 CASCADE 삭제 → 이미지 삭제 → Stream 업데이트
- [ ] **RLS 정책 검증**:
  - 다른 사용자의 칵테일 접근 시도 (실패해야 함)
  - 본인 칵테일 CRUD (성공해야 함)

### 수동 테스트
- [ ] iOS 실기기에서 전체 플로우 테스트
- [ ] 오프라인 상태 에러 처리 확인
- [ ] 다양한 화면 크기에서 UI 확인
- [ ] 이미지 업로드 (다양한 포맷: jpg, png, heic)
- [ ] 재료 10개 이상 추가 시 UI 확인

### 성능 테스트
- [ ] 이미지 로딩 시간 측정
- [ ] 칵테일 목록 스크롤 성능 (50개 이상)
- [ ] 대용량 이미지 업로드 (5MB 이상)

---

## 성공 기준

### 기능 요구사항
- [x] 사용자가 칵테일을 생성할 수 있다
- [x] 재료를 추가/삭제할 수 있다 (기존 재료 + 커스텀 입력)
- [x] 이미지를 업로드할 수 있다 (선택 사항)
- [x] 생성한 칵테일을 목록에서 볼 수 있다
- [x] 칵테일을 수정할 수 있다
- [x] 칵테일을 삭제할 수 있다
- [x] Profile 화면에서 진입 가능

### 기술 요구사항
- [x] RLS 정책으로 본인 데이터만 접근
- [x] Stream 기반 실시간 동기화
- [x] 이미지 Storage 연동
- [x] CASCADE 삭제 (칵테일 삭제 시 재료도 삭제)
- [x] 기존 프로젝트 패턴 준수

### UX 요구사항
- [x] 로딩 상태 명확히 표시
- [x] 에러 발생 시 사용자 친화적 메시지
- [x] 빈 상태 안내 (칵테일이 없을 때)
- [x] 직관적인 재료 입력 UI

### Apple 심사 기준
- [x] 사용자 생성 콘텐츠(UGC) 기능 제공
- [x] 단순 조회 앱에서 크리에이티브 앱으로 전환
- [x] 네이티브 앱으로서의 가치 증명
- [x] Apple 가이드라인 4.2.2 준수

---

## 우선순위 및 일정

### Phase 1: MVP 구현 (7-10일)

**Day 1**: Database Layer
- Migration 작성 및 적용
- Storage Bucket 설정
- RLS 정책 검증

**Day 2**: Data Models & Service (Part 1)
- UserCocktail, UserCocktailIngredient 모델 작성
- ImageUploadService 구현

**Day 3**: Service Layer (Part 2) & Providers
- UserCocktailService 구현
- Riverpod Providers 구현

**Day 4**: UI - 목록 화면
- UserCocktailsListPage 구현
- UserCocktailCard 위젯 구현

**Day 5-6**: UI - 생성/편집 화면
- CreateUserCocktailPage 구현
- IngredientInputList 위젯 구현
- CocktailImagePicker 위젯 구현

**Day 7**: Navigation & 편집 화면
- Profile 화면 진입점 추가
- EditUserCocktailPage 구현
- l10n 추가

**Day 8-10**: Testing & Bug Fixes
- 통합 테스트
- 실기기 테스트
- 버그 수정
- 성능 최적화

### Phase 2: 제출 준비 (3일)
- TestFlight 빌드
- App Store 메타데이터 업데이트 (스크린샷 추가)
- 심사 제출

### Phase 3: 추가 기능 (이후 버전)
- 칵테일 공유 기능 (is_public = true)
- 커뮤니티 레시피 검색
- 좋아요/댓글 기능

---

## 참고 자료

### Apple 가이드라인
- [App Store Review Guidelines 4.2.2 - Minimum Functionality](https://developer.apple.com/app-store/review/guidelines/#minimum-functionality)
  - 단순 웹 래핑 앱 거부
  - 사용자 생성 콘텐츠 권장

### Supabase 문서
- [Row Level Security (RLS)](https://supabase.com/docs/guides/auth/row-level-security)
- [Storage](https://supabase.com/docs/guides/storage)
- [Real-time Subscriptions](https://supabase.com/docs/guides/realtime)

### Flutter 패키지
- [image_picker](https://pub.dev/packages/image_picker) - 이미지 선택
- [cached_network_image](https://pub.dev/packages/cached_network_image) - 이미지 캐싱 (기존 사용 중)
- [riverpod](https://pub.dev/packages/flutter_riverpod) - 상태관리 (기존 사용 중)

### 기존 프로젝트 문서
- `docs/tasks/2026-01-28-appstore-rejection-resolution-strategy.md` - 전체 App Store 대응 전략
- `docs/roadmap-v2.0.md` - Custom Cocktails 장기 로드맵
- 기존 코드:
  - `lib/data/models/cocktail.dart` - Cocktail 모델 참조
  - `lib/data/providers/cocktail_provider.dart` - Provider 패턴 참조
  - `lib/features/cocktails/` - UI 패턴 참조

---

## 부록: 코드 템플릿

### Migration SQL 전체 파일
**파일**: `supabase/migrations/20260128000000_add_user_cocktails.sql`

```sql
-- ============================================
-- User Cocktails Migration
-- ============================================

-- 1. user_cocktails 테이블
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
  method TEXT,
  abv NUMERIC,
  tags TEXT[] DEFAULT '{}',
  image_url TEXT,
  is_public BOOLEAN DEFAULT false,
  based_on_cocktail_id TEXT REFERENCES cocktails(id),
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- 2. user_cocktail_ingredients 테이블
CREATE TABLE user_cocktail_ingredients (
  id SERIAL PRIMARY KEY,
  user_cocktail_id TEXT NOT NULL REFERENCES user_cocktails(id) ON DELETE CASCADE,
  ingredient_id TEXT REFERENCES ingredients(id),
  custom_ingredient_name TEXT,
  amount NUMERIC,
  units TEXT,
  sort_order INTEGER DEFAULT 0,
  is_optional BOOLEAN DEFAULT false,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  CONSTRAINT check_ingredient_source CHECK (
    (ingredient_id IS NOT NULL AND custom_ingredient_name IS NULL) OR
    (ingredient_id IS NULL AND custom_ingredient_name IS NOT NULL)
  )
);

-- 3. 인덱스
CREATE INDEX idx_user_cocktails_user_id ON user_cocktails(user_id);
CREATE INDEX idx_user_cocktails_created_at ON user_cocktails(created_at DESC);
CREATE INDEX idx_user_cocktails_is_public ON user_cocktails(is_public) WHERE is_public = true;
CREATE INDEX idx_user_cocktail_ingredients_cocktail_id ON user_cocktail_ingredients(user_cocktail_id);

-- 4. RLS 활성화
ALTER TABLE user_cocktails ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_cocktail_ingredients ENABLE ROW LEVEL SECURITY;

-- 5. RLS 정책: user_cocktails
CREATE POLICY "Users can view their own cocktails or public ones"
ON user_cocktails FOR SELECT
USING (auth.uid() = user_id OR is_public = true);

CREATE POLICY "Users can create their own cocktails"
ON user_cocktails FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own cocktails"
ON user_cocktails FOR UPDATE
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own cocktails"
ON user_cocktails FOR DELETE
USING (auth.uid() = user_id);

-- 6. RLS 정책: user_cocktail_ingredients
CREATE POLICY "Users can manage their cocktail ingredients"
ON user_cocktail_ingredients FOR ALL
USING (
  EXISTS (
    SELECT 1 FROM user_cocktails
    WHERE user_cocktails.id = user_cocktail_ingredients.user_cocktail_id
    AND user_cocktails.user_id = auth.uid()
  )
);

-- 7. updated_at 자동 업데이트
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

-- 8. 코멘트
COMMENT ON TABLE user_cocktails IS 'User-created custom cocktails';
COMMENT ON TABLE user_cocktail_ingredients IS 'Ingredients for user-created cocktails';
COMMENT ON COLUMN user_cocktail_ingredients.ingredient_id IS 'Reference to existing ingredient (NULL if custom)';
COMMENT ON COLUMN user_cocktail_ingredients.custom_ingredient_name IS 'Custom ingredient name (NULL if using existing ingredient)';
```

---

## 체크리스트 요약

### 구현 체크리스트
- [ ] **Phase 1**: Database Migration 완료
- [ ] **Phase 2**: Data Models 완료
- [ ] **Phase 3**: Service Layer 완료
- [ ] **Phase 4**: Providers 완료
- [ ] **Phase 5**: UI Implementation 완료
- [ ] **Phase 6**: Navigation Integration 완료
- [ ] **Phase 7**: Testing & Bug Fixes 완료
- [ ] **Phase 8**: Package Dependencies 완료

### 최종 검증 체크리스트
- [ ] 사용자가 칵테일을 생성, 수정, 삭제할 수 있음
- [ ] 이미지 업로드/삭제가 정상 작동
- [ ] Stream 기반 실시간 동기화 확인
- [ ] RLS 정책으로 보안 검증
- [ ] 오프라인 상태 에러 처리 확인
- [ ] iOS 실기기 테스트 통과
- [ ] Apple 가이드라인 4.2.2 준수 확인

---

**작성일**: 2026-01-28
**담당자**: Development Team
**검토자**: Architecture Team, QA Team
