import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_footer.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../settings/pages/other_ingredients_settings_page.dart';
import '../settings/pages/unit_settings_page.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Profile Header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      colorScheme.primaryContainer,
                      colorScheme.surface,
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 48),
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: colorScheme.primary,
                        child: Icon(
                          isAuthenticated ? Icons.person : Icons.person_outline,
                          size: 40,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        isAuthenticated
                            ? (user.userMetadata?['full_name'] as String? ??
                                user.userMetadata?['name'] as String? ??
                                user.email ??
                                l10n.profile)
                            : l10n.guestUser,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      if (!isAuthenticated) ...[
                        const SizedBox(height: 4),
                        Text(
                          l10n.signInForMore,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
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
          SliverList(
            delegate: SliverChildListDelegate([
              // Auth Section (if not logged in)
              if (!isAuthenticated) ...[
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
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
                      const SizedBox(width: 12),
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
                ),
                const Divider(),
              ],

              // Ingredient Settings Section
              _SectionHeader(title: l10n.ingredientSettings),
              ListTile(
                leading: const Icon(Icons.kitchen),
                title: Text(l10n.otherIngredients),
                subtitle: Text(l10n.otherIngredientsDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const OtherIngredientsSettingsPage(),
                    ),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.straighten),
                title: Text(l10n.unitSettings),
                subtitle: Text(l10n.unitSettingsDescription),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const UnitSettingsPage(),
                    ),
                  );
                },
              ),

              const Divider(),

              // Settings Section
              ListTile(
                leading: const Icon(Icons.settings),
                title: Text(l10n.settings),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),

              // Logout Section (if logged in)
              if (isAuthenticated) ...[
                const Divider(),
                ListTile(
                  leading: Icon(Icons.logout, color: colorScheme.error),
                  title: Text(
                    l10n.logout,
                    style: TextStyle(color: colorScheme.error),
                  ),
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

              // Footer
              const AppFooter(),
            ]),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}

