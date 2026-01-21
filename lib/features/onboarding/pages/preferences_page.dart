import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/providers/providers.dart';
import '../../../l10n/app_localizations.dart';

class OnboardingPreferencesPage extends ConsumerWidget {
  final VoidCallback onNext;

  const OnboardingPreferencesPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final currentUnit = ref.watch(effectiveUnitSystemProvider);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(
                Icons.settings_rounded,
                size: 64,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                l10n.onboardingPreferencesTitle,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                l10n.onboardingPreferencesSubtitle,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),

        // Unit selection
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _UnitOptionCard(
                  icon: Icons.water_drop_outlined,
                  title: l10n.unitMl,
                  subtitle: '30ml, 45ml, 60ml...',
                  isSelected: currentUnit == UnitSystem.ml,
                  onTap: () => ref
                      .read(onboardingServiceProvider)
                      .setUnitSystem(UnitSystem.ml),
                ),
                const SizedBox(height: 16),
                _UnitOptionCard(
                  icon: Icons.local_drink_outlined,
                  title: l10n.unitOz,
                  subtitle: '1oz, 1.5oz, 2oz...',
                  isSelected: currentUnit == UnitSystem.oz,
                  onTap: () => ref
                      .read(onboardingServiceProvider)
                      .setUnitSystem(UnitSystem.oz),
                ),
                const SizedBox(height: 16),
                _UnitOptionCard(
                  icon: Icons.straighten_outlined,
                  title: l10n.unitParts,
                  subtitle: '1 part, 2 parts...',
                  isSelected: currentUnit == UnitSystem.parts,
                  onTap: () => ref
                      .read(onboardingServiceProvider)
                      .setUnitSystem(UnitSystem.parts),
                ),
              ],
            ),
          ),
        ),

        // Bottom bar with next button
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
            child: Row(
              children: [
                const Spacer(),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(l10n.next),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UnitOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
        color: isSelected
            ? colorScheme.primaryContainer.withValues(alpha: 0.3)
            : colorScheme.surface,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.1)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color:
                        isSelected ? colorScheme.primary : colorScheme.onSurface,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
