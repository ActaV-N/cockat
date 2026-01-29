import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_colors_extension.dart';
import '../theme/app_theme.dart';

/// Premium error view with retry functionality
class ErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;
  final IconData icon;
  final bool showDetails;

  const ErrorView({
    super.key,
    this.title,
    this.message,
    this.error,
    this.onRetry,
    this.icon = Icons.error_outline,
    this.showDetails = false,
  });

  /// Creates a network error view
  factory ErrorView.network({
    VoidCallback? onRetry,
  }) {
    return ErrorView(
      icon: Icons.wifi_off_rounded,
      onRetry: onRetry,
    );
  }

  /// Creates an empty state view
  factory ErrorView.empty({
    String? title,
    String? message,
    IconData icon = Icons.inbox_outlined,
  }) {
    return ErrorView(
      title: title,
      message: message,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final theme = Theme.of(context);

    final displayTitle = title ?? l10n.errorOccurred;
    final displayMessage = message ?? _getErrorMessage(error, l10n);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon with gradient background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.error.withValues(alpha: 0.15),
                    AppColors.error.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: AppColors.error,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Title
            Text(
              displayTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Message
            Text(
              displayMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Error details (for debugging)
            if (showDetails && error != null) ...[
              const SizedBox(height: AppTheme.spacingMd),
              Container(
                padding: const EdgeInsets.all(AppTheme.spacingSm),
                decoration: BoxDecoration(
                  color: colors.card,
                  borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                ),
                child: Text(
                  error.toString(),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textTertiary,
                    fontFamily: 'monospace',
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: Text(l10n.retry),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.spacingLg,
                    vertical: AppTheme.spacingSm + 4,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getErrorMessage(Object? error, AppLocalizations l10n) {
    if (error == null) {
      return l10n.somethingWentWrong;
    }

    final errorString = error.toString().toLowerCase();

    // Network errors
    if (errorString.contains('socket') ||
        errorString.contains('network') ||
        errorString.contains('connection')) {
      return l10n.networkError;
    }

    // Timeout errors
    if (errorString.contains('timeout')) {
      return l10n.timeoutError;
    }

    // Default message
    return l10n.somethingWentWrong;
  }
}

/// Sliver version of error view
class SliverErrorView extends StatelessWidget {
  final String? title;
  final String? message;
  final Object? error;
  final VoidCallback? onRetry;
  final IconData icon;

  const SliverErrorView({
    super.key,
    this.title,
    this.message,
    this.error,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: ErrorView(
        title: title,
        message: message,
        error: error,
        onRetry: onRetry,
        icon: icon,
      ),
    );
  }
}

/// Empty state view with illustration
class EmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;

  const EmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);
    final displayIconColor = iconColor ?? colors.primary;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTheme.spacingXl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with gradient background
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    displayIconColor.withValues(alpha: 0.15),
                    displayIconColor.withValues(alpha: 0.05),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48,
                color: displayIconColor,
              ),
            ),
            const SizedBox(height: AppTheme.spacingLg),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.3,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppTheme.spacingSm),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (action != null) ...[
              const SizedBox(height: AppTheme.spacingLg),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}

/// Sliver version of empty state view
class SliverEmptyStateView extends StatelessWidget {
  final String title;
  final String message;
  final IconData icon;
  final Color? iconColor;
  final Widget? action;

  const SliverEmptyStateView({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: EmptyStateView(
        title: title,
        message: message,
        icon: icon,
        iconColor: iconColor,
        action: action,
      ),
    );
  }
}

/// Loading overlay with optional message
class LoadingOverlay extends StatelessWidget {
  final String? message;
  final bool isLoading;
  final Widget child;

  const LoadingOverlay({
    super.key,
    this.message,
    required this.isLoading,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final theme = Theme.of(context);

    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: Container(
              color: colors.background.withValues(alpha: 0.8),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    if (message != null) ...[
                      const SizedBox(height: AppTheme.spacingMd),
                      Text(
                        message!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
