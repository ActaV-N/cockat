import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_colors_extension.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_footer.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../settings/pages/other_ingredients_settings_page.dart';
import '../settings/pages/unit_settings_page.dart';
import '../settings/settings_screen.dart';
import '../user_cocktails/user_cocktails_list_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colors = context.appColors;
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Premium Profile Header
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: colors.background,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.coralPeach.withValues(alpha: 0.15),
                      AppColors.purple.withValues(alpha: 0.1),
                      colors.background,
                    ],
                    stops: const [0.0, 0.5, 1.0],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 56),
                      // Premium Avatar
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.coralPeach,
                              AppColors.coralPeach.withValues(alpha: 0.6),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.coralPeach.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 44,
                          backgroundColor: colors.card,
                          child: Icon(
                            isAuthenticated ? Icons.person : Icons.person_outline,
                            size: 44,
                            color: AppColors.coralPeach,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppTheme.spacingMd),
                      // User Name
                      Text(
                        isAuthenticated
                            ? (user.userMetadata?['full_name'] as String? ??
                                user.userMetadata?['name'] as String? ??
                                user.email ??
                                l10n.profile)
                            : l10n.guestUser,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.3,
                            ),
                      ),
                      if (!isAuthenticated) ...[
                        const SizedBox(height: AppTheme.spacingXs),
                        Text(
                          l10n.signInForMore,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colors.textSecondary,
                              ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            title: Text(l10n.profile),
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Auth Section (if not logged in)
                if (!isAuthenticated) ...[
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const SignUpScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.person_add),
                          label: Text(l10n.signUp),
                        ),
                      ),
                      const SizedBox(width: AppTheme.spacingSm),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                          icon: const Icon(Icons.login),
                          label: Text(l10n.login),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingLg),
                ],

                // My Cocktails Section (only for authenticated users)
                if (isAuthenticated) ...[
                  _PremiumSectionCard(
                    title: l10n.myCocktails,
                    icon: Icons.local_bar,
                    iconColor: AppColors.coralPeach,
                    children: [
                      _SettingsTile(
                        icon: Icons.local_bar,
                        iconColor: AppColors.coralPeach,
                        title: l10n.myCocktails,
                        subtitle: l10n.myCocktailsDescription,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const UserCocktailsListScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.spacingMd),
                ],

                // Ingredient Settings Section
                _PremiumSectionCard(
                  title: l10n.ingredientSettings,
                  icon: Icons.tune,
                  iconColor: AppColors.coralPeach,
                  children: [
                    _SettingsTile(
                      icon: Icons.kitchen,
                      iconColor: AppColors.purple,
                      title: l10n.otherIngredients,
                      subtitle: l10n.otherIngredientsDescription,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const OtherIngredientsSettingsPage(),
                          ),
                        );
                      },
                    ),
                    Divider(height: 1, color: colors.divider),
                    _SettingsTile(
                      icon: Icons.straighten,
                      iconColor: AppColors.success,
                      title: l10n.unitSettings,
                      subtitle: l10n.unitSettingsDescription,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const UnitSettingsPage(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: AppTheme.spacingMd),

                // General Settings Section
                _PremiumSectionCard(
                  title: l10n.settings,
                  icon: Icons.settings,
                  iconColor: AppColors.gray500,
                  children: [
                    _SettingsTile(
                      icon: Icons.settings,
                      iconColor: colors.textSecondary,
                      title: l10n.settings,
                      subtitle: l10n.general,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),

                // Logout Section (if logged in)
                if (isAuthenticated) ...[
                  const SizedBox(height: AppTheme.spacingMd),
                  _PremiumSectionCard(
                    title: l10n.account,
                    icon: Icons.person,
                    iconColor: AppColors.error,
                    children: [
                      _SettingsTile(
                        icon: Icons.logout,
                        iconColor: AppColors.error,
                        title: l10n.logout,
                        subtitle: user.email ?? '',
                        titleColor: AppColors.error,
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
                    ],
                  ),
                ],

                const SizedBox(height: AppTheme.spacingLg),

                // Footer
                const AppFooter(),

                // Bottom padding for floating nav
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

/// Premium section card with header and children
class _PremiumSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor;
  final List<Widget> children;

  const _PremiumSectionCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Header
          Padding(
            padding: const EdgeInsets.all(AppTheme.spacingMd),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusXs),
                  ),
                  child: Icon(icon, size: 18, color: iconColor),
                ),
                const SizedBox(width: AppTheme.spacingSm),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: colors.divider),
          // Children
          ...children,
        ],
      ),
    );
  }
}

/// Premium settings tile with icon
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMd,
          vertical: AppTheme.spacingSm + 4,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: iconColor),
            ),
            const SizedBox(width: AppTheme.spacingSm + 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: titleColor,
                        ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.textTertiary,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: colors.textTertiary,
            ),
          ],
        ),
      ),
    );
  }
}

