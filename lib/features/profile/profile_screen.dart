import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';
import '../auth/login_screen.dart';
import '../auth/signup_screen.dart';
import '../onboarding/onboarding_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final user = ref.watch(currentUserProvider);
    final isAuthenticated = user != null;
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

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
                      const SizedBox(height: 16),
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
                            ? (user.email ?? l10n.profile)
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

              // Account Section (if logged in)
              if (isAuthenticated) ...[
                _SectionHeader(title: l10n.account),
                ListTile(
                  leading: const Icon(Icons.sync),
                  title: Text(l10n.syncData),
                  subtitle: Text(l10n.comingSoon),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.featureComingSoon)),
                    );
                  },
                ),
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
                const Divider(),
              ],

              // Theme Section
              _SectionHeader(title: l10n.theme),
              _ThemeTile(
                title: l10n.systemMode,
                icon: Icons.brightness_auto,
                isSelected: themeMode == ThemeMode.system,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.system),
              ),
              _ThemeTile(
                title: l10n.lightMode,
                icon: Icons.light_mode,
                isSelected: themeMode == ThemeMode.light,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.light),
              ),
              _ThemeTile(
                title: l10n.darkMode,
                icon: Icons.dark_mode,
                isSelected: themeMode == ThemeMode.dark,
                onTap: () => ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(ThemeMode.dark),
              ),

              const Divider(),

              // Language Section
              _SectionHeader(title: l10n.language),
              _LanguageTile(
                title: 'System',
                subtitle: 'Use system language',
                isSelected: locale == null,
                onTap: () => ref.read(localeProvider.notifier).setLocale(null),
              ),
              _LanguageTile(
                title: 'English',
                subtitle: 'English',
                isSelected: locale?.languageCode == 'en',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('en')),
              ),
              _LanguageTile(
                title: '한국어',
                subtitle: 'Korean',
                isSelected: locale?.languageCode == 'ko',
                onTap: () => ref
                    .read(localeProvider.notifier)
                    .setLocale(const Locale('ko')),
              ),

              const Divider(),

              // Setup Section
              _SectionHeader(title: 'Setup'),
              ListTile(
                leading: const Icon(Icons.refresh),
                title: Text(l10n.reRunSetup),
                subtitle: Text(l10n.reRunSetupDescription),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(l10n.reRunSetup),
                      content: Text(l10n.reRunSetupDescription),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text(l10n.skip),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(l10n.getStarted),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    await ref.read(onboardingServiceProvider).resetOnboarding();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.setupReset)),
                      );
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => const OnboardingScreen(),
                        ),
                        (route) => false,
                      );
                    }
                  }
                },
              ),

              const Divider(),

              // About Section
              _SectionHeader(title: l10n.about),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text(l10n.version('1.0.0')),
              ),
              ListTile(
                leading: const Icon(Icons.data_object),
                title: const Text('Data Source'),
                subtitle: const Text('Bar Assistant (MIT License)'),
                onTap: () {
                  // Could open URL to Bar Assistant repo
                },
              ),

              const SizedBox(height: 32),
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

class _ThemeTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}

class _LanguageTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageTile({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: onTap,
    );
  }
}
