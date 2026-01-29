import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';

/// Modern section header with premium styling
class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? accentColor;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  const SectionHeader({
    super.key,
    required this.title,
    this.count,
    this.accentColor,
    this.onViewAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final effectiveColor = accentColor ?? colors.primary;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppTheme.spacingMd,
        AppTheme.spacingLg,
        AppTheme.spacingSm,
        AppTheme.spacingSm,
      ),
      child: Row(
        children: [
          // Accent bar
          Container(
            width: 4,
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  effectiveColor,
                  effectiveColor.withValues(alpha: 0.6),
                ],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: AppTheme.spacingSm),
          // Title
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
          ),
          // Count badge
          if (count != null) ...[
            const SizedBox(width: AppTheme.spacingSm),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.spacingSm,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: effectiveColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppTheme.radiusRound),
              ),
              child: Text(
                '$count',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: effectiveColor,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
          ],
          const Spacer(),
          // Trailing or View All button
          if (trailing != null)
            trailing!
          else if (onViewAll != null && (count == null || count! > 10))
            TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.spacingSm,
                ),
                foregroundColor: colors.primary,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.viewAll,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: colors.primary,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Sliver version of SectionHeader for use in CustomScrollView
class SliverSectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? accentColor;
  final VoidCallback? onViewAll;
  final Widget? trailing;

  const SliverSectionHeader({
    super.key,
    required this.title,
    this.count,
    this.accentColor,
    this.onViewAll,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: SectionHeader(
        title: title,
        count: count,
        accentColor: accentColor,
        onViewAll: onViewAll,
        trailing: trailing,
      ),
    );
  }
}
