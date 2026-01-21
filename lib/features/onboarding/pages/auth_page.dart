import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/providers.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';

class OnboardingAuthPage extends ConsumerWidget {
  final VoidCallback onComplete;
  final VoidCallback onSkip;

  const OnboardingAuthPage({
    super.key,
    required this.onComplete,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isAuthenticated = ref.watch(isAuthenticatedProvider);

    // If already authenticated, show success and complete
    if (isAuthenticated) {
      return _AuthenticatedView(onComplete: onComplete);
    }

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.cloud_sync_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.onboardingAuthTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingAuthSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Benefits list
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _BenefitItem(
                  icon: Icons.sync,
                  title: l10n.benefitSync,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.favorite,
                  title: l10n.benefitFavorites,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 16),
                _BenefitItem(
                  icon: Icons.backup,
                  title: l10n.benefitBackup,
                  colorScheme: colorScheme,
                ),
              ],
            ),
          ),
        ),

        // Auth buttons
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => _navigateToSignUp(context, ref),
                    child: Text(l10n.signUp),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => _navigateToLogin(context, ref),
                    child: Text(l10n.login),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: onSkip,
                  child: Text(l10n.maybeLater),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _navigateToSignUp(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const SignUpScreen(),
      ),
    );
    if (result == true && context.mounted) {
      // User signed up successfully, migrate data and complete
      await ref.read(onboardingServiceProvider).migrateLocalToDb();
      onComplete();
    }
  }

  Future<void> _navigateToLogin(BuildContext context, WidgetRef ref) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
    if (result == true && context.mounted) {
      // User logged in successfully, migrate data and complete
      await ref.read(onboardingServiceProvider).migrateLocalToDb();
      onComplete();
    }
  }
}

class _AuthenticatedView extends StatelessWidget {
  final VoidCallback onComplete;

  const _AuthenticatedView({required this.onComplete});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.allSet,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.dataSyncMessage,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            FilledButton.icon(
              onPressed: onComplete,
              icon: const Icon(Icons.arrow_forward),
              label: Text(l10n.getStarted),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenefitItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final ColorScheme colorScheme;

  const _BenefitItem({
    required this.icon,
    required this.title,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ],
    );
  }
}
