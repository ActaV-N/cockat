import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/models.dart';
import 'auth_provider.dart';
import 'ingredient_provider.dart';

// ============ Providers ============

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
      .map((data) => data.map((row) => UserCocktail.fromSupabase(row)).toList());
});

/// 사용자 칵테일 개수
final userCocktailCountProvider = Provider<int>((ref) {
  final cocktailsAsync = ref.watch(userCocktailsProvider);
  return cocktailsAsync.valueOrNull?.length ?? 0;
});

/// 특정 칵테일의 재료 목록
final userCocktailIngredientsProvider =
    FutureProvider.family<List<UserCocktailIngredient>, String>(
        (ref, cocktailId) async {
  final supabase = ref.watch(supabaseClientProvider);

  final response = await supabase
      .from('user_cocktail_ingredients')
      .select()
      .eq('user_cocktail_id', cocktailId)
      .order('sort_order');

  return (response as List)
      .map((row) => UserCocktailIngredient.fromSupabase(row))
      .toList();
});

/// 재료가 포함된 완전한 사용자 칵테일
final userCocktailWithIngredientsProvider =
    FutureProvider.family<UserCocktail?, String>((ref, cocktailId) async {
  final cocktailsAsync = ref.watch(userCocktailsProvider);
  final cocktails = cocktailsAsync.valueOrNull;
  if (cocktails == null) return null;

  final cocktail = cocktails.where((c) => c.id == cocktailId).firstOrNull;
  if (cocktail == null) return null;

  final ingredients =
      await ref.watch(userCocktailIngredientsProvider(cocktailId).future);

  return cocktail.copyWith(ingredients: ingredients);
});

/// 사용자 칵테일 서비스 Provider
final userCocktailServiceProvider = Provider<UserCocktailService>((ref) {
  return UserCocktailService(Supabase.instance.client);
});

// ============ Service ============

/// 사용자 칵테일 CRUD 서비스
class UserCocktailService {
  final SupabaseClient _supabase;

  UserCocktailService(this._supabase);

  /// 칵테일 생성
  /// 반환: 생성된 칵테일 ID 또는 null (실패 시)
  Future<String?> createCocktail({
    required String name,
    String? nameKo,
    String? description,
    String? descriptionKo,
    required String instructions,
    String? instructionsKo,
    String? garnish,
    String? garnishKo,
    String? glass,
    String? method,
    double? abv,
    List<String> tags = const [],
    String? imageUrl,
    bool isPublic = false,
    String? basedOnCocktailId,
    List<UserCocktailIngredient> ingredients = const [],
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      // 1. 칵테일 생성
      final cocktailData = {
        'user_id': userId,
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

      final response = await _supabase
          .from('user_cocktails')
          .insert(cocktailData)
          .select('id')
          .single();

      final cocktailId = response['id'] as String;

      // 2. 재료 추가
      if (ingredients.isNotEmpty) {
        final ingredientData = ingredients
            .map((ing) => ing.copyWith(userCocktailId: cocktailId).toInsertData())
            .toList();
        await _supabase.from('user_cocktail_ingredients').insert(ingredientData);
      }

      return cocktailId;
    } catch (e) {
      return null;
    }
  }

  /// 칵테일 수정
  Future<bool> updateCocktail({
    required String cocktailId,
    String? name,
    String? nameKo,
    String? description,
    String? descriptionKo,
    String? instructions,
    String? instructionsKo,
    String? garnish,
    String? garnishKo,
    String? glass,
    String? method,
    double? abv,
    List<String>? tags,
    String? imageUrl,
    bool? isPublic,
  }) async {
    try {
      final updateData = <String, dynamic>{};

      if (name != null) updateData['name'] = name;
      if (nameKo != null) updateData['name_ko'] = nameKo;
      if (description != null) updateData['description'] = description;
      if (descriptionKo != null) updateData['description_ko'] = descriptionKo;
      if (instructions != null) updateData['instructions'] = instructions;
      if (instructionsKo != null) updateData['instructions_ko'] = instructionsKo;
      if (garnish != null) updateData['garnish'] = garnish;
      if (garnishKo != null) updateData['garnish_ko'] = garnishKo;
      if (glass != null) updateData['glass'] = glass;
      if (method != null) updateData['method'] = method;
      if (abv != null) updateData['abv'] = abv;
      if (tags != null) updateData['tags'] = tags;
      if (imageUrl != null) updateData['image_url'] = imageUrl;
      if (isPublic != null) updateData['is_public'] = isPublic;

      if (updateData.isEmpty) return true;

      await _supabase
          .from('user_cocktails')
          .update(updateData)
          .eq('id', cocktailId);

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 칵테일 삭제
  Future<bool> deleteCocktail(String cocktailId) async {
    try {
      // CASCADE로 인해 재료도 자동 삭제됨
      await _supabase.from('user_cocktails').delete().eq('id', cocktailId);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 재료 일괄 업데이트 (기존 재료 삭제 후 새로 추가)
  Future<bool> updateIngredients({
    required String cocktailId,
    required List<UserCocktailIngredient> ingredients,
  }) async {
    try {
      // 기존 재료 삭제
      await _supabase
          .from('user_cocktail_ingredients')
          .delete()
          .eq('user_cocktail_id', cocktailId);

      // 새 재료 추가
      if (ingredients.isNotEmpty) {
        final ingredientData = ingredients
            .map((ing) => ing.copyWith(userCocktailId: cocktailId).toInsertData())
            .toList();
        await _supabase.from('user_cocktail_ingredients').insert(ingredientData);
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// 이미지 URL 업데이트
  Future<bool> updateImageUrl(String cocktailId, String? imageUrl) async {
    try {
      await _supabase
          .from('user_cocktails')
          .update({'image_url': imageUrl})
          .eq('id', cocktailId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
