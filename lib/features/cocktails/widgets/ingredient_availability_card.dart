import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../data/models/models.dart';
import '../../../data/providers/onboarding_provider.dart';
import '../../../l10n/app_localizations.dart';

/// 재료별 소유 정보를 표시하는 확장 가능한 카드
class IngredientAvailabilityCard extends StatelessWidget {
  final CocktailIngredient ingredient;
  final IngredientAvailability availability;
  final UnitSystem userUnit;
  final AppLocalizations l10n;

  const IngredientAvailabilityCard({
    super.key,
    required this.ingredient,
    required this.availability,
    required this.userUnit,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final canUse = availability.canUse;
    final hasProducts = availability.ownedProducts.isNotEmpty;
    final hasSubstitutes = availability.availableSubstitutes.isNotEmpty;

    // 확장 필요 여부: 제품이나 대체재가 있는 경우에만
    final needsExpansion = hasProducts || hasSubstitutes;

    if (needsExpansion) {
      return _buildExpandableTile(context, canUse);
    } else {
      return _buildSimpleTile(context, canUse);
    }
  }

  Widget _buildSimpleTile(BuildContext context, bool canUse) {
    return ListTile(
      leading: _buildLeadingIcon(context, canUse),
      title: Text(ingredient.name),
      subtitle: Text(
        UnitConverter.formatAmount(
          ingredient.amount,
          ingredient.units,
          userUnit,
          amountMax: ingredient.amountMax,
        ),
      ),
      trailing: ingredient.optional
          ? Chip(
              label: Text(l10n.optional),
              visualDensity: VisualDensity.compact,
            )
          : null,
    );
  }

  Widget _buildExpandableTile(BuildContext context, bool canUse) {
    final displayItems = availability.displayItems;
    final moreCount = availability.moreCount;

    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: _buildLeadingIcon(context, canUse),
        title: Text(ingredient.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 용량 정보
            Text(
              UnitConverter.formatAmount(
                ingredient.amount,
                ingredient.units,
                userUnit,
                amountMax: ingredient.amountMax,
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),

            // 소유 제품/대체재 미리보기
            if (canUse && displayItems.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                _buildPreviewText(displayItems, moreCount),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: availability.isOwned
                          ? AppColors.success
                          : AppColors.warning,
                      fontWeight: FontWeight.w500,
                    ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
        trailing: ingredient.optional
            ? Chip(
                label: Text(l10n.optional),
                visualDensity: VisualDensity.compact,
              )
            : null,
        children: [
          // 확장된 영역: 상세 정보
          _buildExpandedContent(context),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(BuildContext context, bool canUse) {
    // 대체재만 있는 경우 다른 아이콘
    final hasSubstituteOnly =
        !availability.isOwned && availability.availableSubstitutes.isNotEmpty;

    return Icon(
      canUse
          ? (hasSubstituteOnly ? Icons.swap_horiz : Icons.check_circle)
          : Icons.circle_outlined,
      color: canUse
          ? (hasSubstituteOnly ? AppColors.warning : AppColors.success)
          : Theme.of(context).colorScheme.outline,
    );
  }

  String _buildPreviewText(List<String> items, int moreCount) {
    final preview = items.join(', ');
    if (moreCount > 0) {
      return '$preview +$moreCount';
    }
    return preview;
  }

  Widget _buildExpandedContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 직접 소유 제품
          if (availability.isOwned && availability.ownedProducts.isNotEmpty) ...[
            _buildSectionTitle(context, l10n.myBarProducts),
            const SizedBox(height: 8),
            ...availability.ownedProducts.map(
              (product) => _buildProductItem(context, product),
            ),
          ],

          // 대체재
          if (availability.availableSubstitutes.isNotEmpty) ...[
            if (availability.isOwned && availability.ownedProducts.isNotEmpty)
              const SizedBox(height: 16),
            _buildSectionTitle(context, l10n.availableSubstitutes),
            const SizedBox(height: 8),
            ...availability.availableSubstitutes.map(
              (substitute) => _buildSubstituteItem(context, substitute),
            ),
          ],

          // 소유하지 않은 경우
          if (!availability.canUse) ...[
            Text(
              l10n.ingredientNotOwned,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildProductItem(BuildContext context, Product product) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            Icons.liquor,
            size: 16,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              product.displayName,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubstituteItem(BuildContext context, SubstituteInfo substitute) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.swap_horiz,
                size: 16,
                color: AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  substitute.substituteName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ),
            ],
          ),
          if (substitute.ownedProducts.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: substitute.ownedProducts
                    .map(
                      (product) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text(
                          '• ${product.displayName}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.warning,
                                  ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
