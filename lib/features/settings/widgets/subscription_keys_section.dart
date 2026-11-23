import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../controllers/settings_controller.dart';
import '../models/subscription_keys.dart';

/// Секция управления ключами vpn://-подписки.
///
/// Ключи хранятся в secure-storage (правило 17); ввод — два
/// Base64-поля (проверка подписи и расшифровка).
class SubscriptionKeysSection extends StatefulWidget {
  /// Создаёт секцию.
  const SubscriptionKeysSection({super.key});

  @override
  State<SubscriptionKeysSection> createState() =>
      _SubscriptionKeysSectionState();
}

class _SubscriptionKeysSectionState extends State<SubscriptionKeysSection> {
  late final TextEditingController _verifyController;
  late final TextEditingController _decryptController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _verifyController = TextEditingController();
    _decryptController = TextEditingController();
    // Ленивая загрузка: secure-storage читается только при открытии
    // настроек, чтобы не дёргать платформенный канал при старте приложения.
    _loadKeys();
  }

  Future<void> _loadKeys() async {
    final keys = await context.read<SettingsController>().loadKeys();
    if (!mounted) return;
    setState(() {
      _verifyController.text = keys.verifyKey ?? '';
      _decryptController.text = keys.decryptKey ?? '';
      _initialized = true;
    });
  }

  @override
  void dispose() {
    _verifyController.dispose();
    _decryptController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final controller = context.read<SettingsController>();
    final saved = await controller.saveKeys(
      SubscriptionKeys(
        verifyKey: _verifyController.text,
        decryptKey: _decryptController.text,
      ),
    );
    if (!mounted || !saved) return;
    _showMessage(AppLocalizations.of(context)!.settingsKeysSaved);
  }

  Future<void> _clear() async {
    await context.read<SettingsController>().clearKeys();
    if (!mounted) return;
    setState(() {
      _verifyController.clear();
      _decryptController.clear();
    });
    _showMessage(AppLocalizations.of(context)!.settingsKeysCleared);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final controller = context.watch<SettingsController>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.settingsKeysHint,
            style: AppTypography.caption.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _verifyController,
            enabled: _initialized,
            decoration: InputDecoration(
              labelText: l10n.settingsKeyVerifyLabel,
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _decryptController,
            enabled: _initialized,
            decoration: InputDecoration(
              labelText: l10n.settingsKeyDecryptLabel,
              isDense: true,
            ),
          ),
          if (controller.errorMessage != null) ...[
            const SizedBox(height: 8),
            Text(
              controller.errorMessage!,
              style: AppTypography.caption.copyWith(
                color: AppColors.statusError,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            children: [
              FilledButton.tonalIcon(
                onPressed: _save,
                icon: const Icon(Icons.key, size: 18),
                label: Text(l10n.settingsKeysSave),
              ),
              OutlinedButton.icon(
                onPressed: _clear,
                icon: const Icon(Icons.delete_outline, size: 18),
                label: Text(l10n.settingsKeysClear),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
