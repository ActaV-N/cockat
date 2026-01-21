import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/migration_service.dart';
import '../../data/providers/providers.dart';
import '../../l10n/app_localizations.dart';

/// 로그인 후 로컬 데이터 마이그레이션 다이얼로그
class MigrationDialog extends ConsumerStatefulWidget {
  const MigrationDialog({super.key});

  /// 마이그레이션이 필요한 경우에만 다이얼로그를 표시
  static Future<void> showIfNeeded(BuildContext context, WidgetRef ref) async {
    final needsMigration = ref.read(needsMigrationProvider);
    if (!needsMigration) return;

    if (!context.mounted) return;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const MigrationDialog(),
    );
  }

  @override
  ConsumerState<MigrationDialog> createState() => _MigrationDialogState();
}

class _MigrationDialogState extends ConsumerState<MigrationDialog> {
  bool _isLoading = false;

  Future<void> _migrate() async {
    setState(() => _isLoading = true);

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    final migrationService = ref.read(migrationServiceProvider);
    final l10n = AppLocalizations.of(context)!;

    try {
      final result = await migrationService.migrateAndClear(userId);

      if (!mounted) return;

      Navigator.of(context).pop();

      if (result.hasData) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.migrationSuccess(result.totalMigrated)),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.migrationFailed),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _skip() async {
    // 건너뛰기 시에도 로컬 데이터 삭제 (다음 로그인 시 팝업 방지)
    final migrationService = ref.read(migrationServiceProvider);
    await migrationService.clearLocalData();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final summary = ref.watch(localDataSummaryProvider);

    return AlertDialog(
      title: Row(
        children: [
          const Text('🎉 '),
          Text(l10n.migrationTitle),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.migrationPrompt,
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          if (summary.productsCount > 0)
            _DataRow(
              icon: Icons.liquor,
              text: l10n.migrationProducts(summary.productsCount),
            ),
          if (summary.ingredientsCount > 0)
            _DataRow(
              icon: Icons.inventory_2,
              text: l10n.migrationIngredients(summary.ingredientsCount),
            ),
          if (summary.favoritesCount > 0)
            _DataRow(
              icon: Icons.favorite,
              text: l10n.migrationFavorites(summary.favoritesCount),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _skip,
          child: Text(l10n.skipSync),
        ),
        FilledButton(
          onPressed: _isLoading ? null : _migrate,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(l10n.syncNow),
        ),
      ],
    );
  }
}

class _DataRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _DataRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Text(text),
        ],
      ),
    );
  }
}
