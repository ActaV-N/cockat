import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/storage_image.dart';
import '../../data/models/models.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import 'create_user_cocktail_screen.dart';
import 'user_cocktail_detail_screen.dart';

class UserCocktailsListScreen extends ConsumerWidget {
  const UserCocktailsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final cocktailsAsync = ref.watch(userCocktailsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myCocktails),
        backgroundColor: colors.background,
      ),
      body: cocktailsAsync.when(
        data: (cocktails) {
          if (cocktails.isEmpty) {
            return _EmptyState(l10n: l10n, colors: colors);
          }
          return _CocktailsGrid(cocktails: cocktails, l10n: l10n, colors: colors);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.textSecondary),
              const SizedBox(height: AppTheme.spacingMd),
              Text(l10n.errorOccurred),
              const SizedBox(height: AppTheme.spacingSm),
              FilledButton(
                onPressed: () => ref.invalidate(userCocktailsProvider),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Phase 1.2: 결과값 받아서 리스트 새로고침
          final result = await Navigator.of(context).push<bool>(
            MaterialPageRoute(
              builder: (_) => const CreateUserCocktailScreen(),
            ),
          );
          if (result == true) {
            ref.invalidate(userCocktailsProvider);
          }
        },
        backgroundColor: AppColors.coralPeach,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(l10n.createCocktail),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _EmptyState({required this.l10n, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.coralPeach.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.local_bar_outlined,
                size: 64,
                color: AppColors.coralPeach,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),
            Text(
              l10n.noUserCocktails,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: AppTheme.spacingSm),
            Text(
              l10n.noUserCocktailsPrompt,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Phase 2.0: GridView 2열 레이아웃으로 변경
class _CocktailsGrid extends ConsumerWidget {
  final List<UserCocktail> cocktails;
  final AppLocalizations l10n;
  final AppColorsExtension colors;

  const _CocktailsGrid({
    required this.cocktails,
    required this.l10n,
    required this.colors,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppTheme.spacingMd),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72, // 표준 칵테일 카드와 동일
        crossAxisSpacing: AppTheme.spacingSm,
        mainAxisSpacing: AppTheme.spacingSm,
      ),
      itemCount: cocktails.length,
      itemBuilder: (context, index) {
        final cocktail = cocktails[index];
        return _UserCocktailCard(
          cocktail: cocktail,
          onNavigateBack: () {
            // 상세/수정 화면에서 돌아올 때 새로고침
            ref.invalidate(userCocktailsProvider);
          },
        );
      },
    );
  }
}

/// 표준 칵테일 카드와 동일한 스타일의 사용자 칵테일 카드
class _UserCocktailCard extends ConsumerWidget {
  final UserCocktail cocktail;
  final VoidCallback? onNavigateBack;

  const _UserCocktailCard({
    required this.cocktail,
    this.onNavigateBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.appColors;
    final locale = ref.watch(currentLocaleCodeProvider);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        child: Material(
          color: colors.card,
          child: InkWell(
            onTap: () async {
              // Phase 1.2: 상세 화면에서 수정/삭제 후 돌아올 때 새로고침
              final result = await Navigator.of(context).push<bool>(
                MaterialPageRoute(
                  builder: (_) => UserCocktailDetailScreen(cocktailId: cocktail.id),
                ),
              );
              if (result == true) {
                onNavigateBack?.call();
              }
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 이미지 섹션
                Expanded(
                  flex: 3,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // 칵테일 이미지
                      _buildImage(colors),
                      // Gradient overlay
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.3),
                              ],
                              stops: const [0.6, 1.0],
                            ),
                          ),
                        ),
                      ),
                      // "My Recipe" 배지 (좌측 하단)
                      Positioned(
                        bottom: AppTheme.spacingSm,
                        left: AppTheme.spacingSm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTheme.spacingSm,
                            vertical: AppTheme.spacingXs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.coralPeach.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coralPeach.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.edit_note,
                                size: 12,
                                color: AppColors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'My Recipe',
                                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // 정보 섹션
                Container(
                  padding: const EdgeInsets.all(AppTheme.spacingSm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 칵테일 이름
                      Text(
                        cocktail.getLocalizedName(locale),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // ABV 정보
                      Row(
                        children: [
                          if (cocktail.abv != null) ...[
                            Icon(
                              Icons.local_bar,
                              size: 12,
                              color: colors.textTertiary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${cocktail.abv!.toStringAsFixed(0)}%',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: colors.textTertiary,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImage(AppColorsExtension colors) {
    if (cocktail.imageUrl != null && cocktail.imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: cocktail.imageUrl!,
        fit: BoxFit.cover,
        fadeInDuration: const Duration(milliseconds: 200),
        placeholder: (context, url) => ShimmerPlaceholder(
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        errorWidget: (context, url, error) {
          // Phase 1.1: 디버그 로깅 추가
          if (kDebugMode) {
            debugPrint('❌ Image load failed: $url');
            debugPrint('   Error: $error');
          }
          return _buildPlaceholder(colors);
        },
        // Memory cache optimization
        memCacheWidth: 300,
        memCacheHeight: 300,
      );
    }
    return _buildPlaceholder(colors);
  }

  Widget _buildPlaceholder(AppColorsExtension colors) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.coralPeach.withValues(alpha: 0.2),
            AppColors.purple.withValues(alpha: 0.1),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.local_bar,
          size: 48,
          color: AppColors.coralPeach.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
