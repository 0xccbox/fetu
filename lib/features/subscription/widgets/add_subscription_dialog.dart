import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../services/vpn_subscription_url.dart';

/// Диалог добавления подписки по URL.
///
/// Чистая форма: возвращает URL через [Navigator.pop]; загрузка и
/// парсинг остаются в контроллере.
class AddSubscriptionDialog extends StatefulWidget {
  /// Создаёт диалог.
  const AddSubscriptionDialog({super.key});

  @override
  State<AddSubscriptionDialog> createState() => _AddSubscriptionDialogState();
}

class _AddSubscriptionDialogState extends State<AddSubscriptionDialog> {
  final _urlController = TextEditingController();
  final _inputKey = GlobalKey();
  String? _urlError;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  void _submit() {
    final l10n = AppLocalizations.of(context)!;
    final url = VpnSubscriptionUrl.sanitizeUrl(_urlController.text);
    if (url.isEmpty) {
      setState(() => _urlError = l10n.subUrlEmpty);
      return;
    }
    // Credentials подписки передаются только по TLS;
    // http — исключительно для локальной отладки.
    final uri = Uri.tryParse(url);
    final isAllowed = uri != null &&
        uri.hasAuthority &&
        uri.host.isNotEmpty &&
        (uri.isScheme('https') ||
            (kDebugMode && uri.isScheme('http')) ||
            (uri.isScheme('vpn') &&
                uri.host.toLowerCase() == VpnSubscriptionUrl.host));
    if (!isAllowed) {
      setState(() => _urlError = l10n.subUrlScheme);
      return;
    }
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final padding = MediaQuery.paddingOf(context);
    final availableHeight = MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        padding.vertical;
    final field = TextField(
      key: _inputKey,
      controller: _urlController,
      autofocus: true,
      keyboardType: TextInputType.url,
      autocorrect: false,
      enableSuggestions: false,
      inputFormatters: [
        FilteringTextInputFormatter.deny(
          VpnSubscriptionUrl.controlCharsPattern,
        ),
      ],
      decoration: InputDecoration(
        labelText: l10n.subDialogFieldLabel,
        hintText: l10n.subDialogFieldHint,
        errorText: _urlError,
      ),
      onSubmitted: (_) => _submit(),
    );
    final actions = [
      TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(l10n.actionCancel),
      ),
      FilledButton(onPressed: _submit, child: Text(l10n.subDialogLoad)),
    ];
    if (availableHeight < 200) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Semantics(
          scopesRoute: true,
          explicitChildNodes: true,
          namesRoute: true,
          label: l10n.subDialogAddTitle,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                field,
                OverflowBar(
                  alignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ],
            ),
          ),
        ),
      );
    }
    return AlertDialog(
      scrollable: true,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        l10n.subDialogAddTitle,
        style: AppTypography.h4.copyWith(color: textPrimary),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.subDialogHint,
            style: AppTypography.bodySmall.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 12),
          field,
        ],
      ),
      actions: actions,
    );
  }
}
