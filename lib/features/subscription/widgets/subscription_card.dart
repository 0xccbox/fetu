import 'package:fetu/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/theme/app_colors.dart';
import '../../../../design_system/typography/app_typography.dart';
import '../models/provider_cabinet.dart';

/// Карточка аккаунта из кабинета провайдера: тариф, трафик, устройства.
class SubscriptionCard extends StatelessWidget {
  /// Создаёт карточку.
  const SubscriptionCard({super.key, required this.account});

  /// Данные аккаунта.
  final AccountInfo account;

  String _trafficLabel(AppLocalizations l10n) {
    if (account.traffic.limitBytes <= 0) {
      return '${_formatBytes(l10n, account.traffic.usedBytes)} · '
          '${l10n.trafficUnlimited}';
    }
    return '${_formatBytes(l10n, account.traffic.usedBytes)} '
        '${l10n.trafficOutOf} '
        '${_formatBytes(l10n, account.traffic.limitBytes)}';
  }

  static String _formatBytes(AppLocalizations l10n, int bytes) {
    const gb = 1024 * 1024 * 1024;
    const mb = 1024 * 1024;
    if (bytes >= gb) {
      return '${(bytes / gb).toStringAsFixed(1)} ${l10n.unitGigabytes}';
    }
    if (bytes >= mb) {
      return '${(bytes / mb).toStringAsFixed(0)} ${l10n.unitMegabytes}';
    }
    return '$bytes ${l10n.unitBytes}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    final accent =
        account.isExpired ? AppColors.statusError : AppColors.accentCool;

    return Card(
      color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.workspace_premium_outlined, color: accent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    account.planName.isEmpty
                        ? l10n.accountPlanNotSpecified
                        : account.planName,
                    style: AppTypography.h4.copyWith(color: textPrimary),
                  ),
                ),
                Text(
                  account.isExpired ? l10n.accountExpiredLabel : account.status,
                  style: AppTypography.badge.copyWith(color: accent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (account.traffic.limitBytes > 0) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: account.traffic.usedFraction,
                  minHeight: 6,
                  backgroundColor: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.accentCool,
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            _infoRow(context, Icons.data_usage_outlined, _trafficLabel(l10n)),
            _infoRow(
              context,
              Icons.devices_outlined,
              l10n.accountDevices(
                account.devices.currentCount,
                account.devices.maxLimit,
              ),
            ),
            if (account.billing.balanceFormatted != null)
              _infoRow(
                context,
                Icons.account_balance_wallet_outlined,
                l10n.accountBalance(account.billing.balanceFormatted!),
              ),
            if (account.expireAt != null)
              _infoRow(
                context,
                Icons.event_outlined,
                l10n.accountValidUntil(
                  DateFormat('dd.MM.yyyy').format(account.expireAt!.toLocal()),
                ),
                color: textSecondary,
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(
    BuildContext context,
    IconData icon,
    String label, {
    Color? color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color ?? textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodySmall
                  .copyWith(color: color ?? textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
