/// Переводчик сетевой терминологии на язык пользователя (правило 33).
///
/// В простом режиме ([UiExperienceMode.simple]) протоколы, причины
/// failover и ошибки переведены на человеческий язык; в расширенном
/// ([UiExperienceMode.advanced]) показываются технические названия.
///
/// Чистые статические функции: только маппинг enum → строка
/// из [AppLocalizations], без состояния и побочных эффектов.
library;

import 'package:fetu/l10n/app_localizations.dart';

import '../../../core/constants/settings_constants.dart';
import '../../../core/constants/split_tunnel_constants.dart';
import '../../connection/models/connection_error.dart';
import '../../connection/models/connection_state.dart';
import '../../connection/models/server_node.dart';
import '../../failover/models/failover_event.dart';
import '../../split_tunnel/models/split_tunnel_error.dart';
import '../models/ui_experience_mode.dart';

/// Переводчик терминов между простым и расширенным режимами.
abstract final class UxTerminologyTranslator {
  /// Отображаемое имя протокола.
  ///
  /// simple: «Умный доступ» (UDP-рельсы HY2/AWG), «Максимальная
  /// скрытность» (TCP-стелс Reality/Naive/Mieru), «Классическая
  /// защита» (Shadowsocks); advanced: техническое имя протокола.
  static String protocolLabel(
    AppLocalizations l10n,
    UiExperienceMode mode,
    ProtocolType protocol,
  ) =>
      switch (mode) {
        UiExperienceMode.simple => switch (protocol) {
            ProtocolType.hysteria2 ||
            ProtocolType.amneziaWg ||
            ProtocolType.wireguard =>
              l10n.uxTermSmartAccess,
            ProtocolType.vlessReality ||
            ProtocolType.naive ||
            ProtocolType.mieru ||
            ProtocolType.vless =>
              l10n.uxTermMaxStealth,
            ProtocolType.shadowsocks => l10n.uxTermClassicProtection,
          },
        UiExperienceMode.advanced => protocol.displayName,
      };

  /// Метка состояния подключения.
  static String connectionStateLabel(
    AppLocalizations l10n,
    ConnectionState state,
  ) =>
      switch (state) {
        ConnectionState.disconnected => l10n.statusDisconnected,
        ConnectionState.connecting => l10n.statusConnecting,
        ConnectionState.connected => l10n.statusConnected,
        ConnectionState.disconnecting => l10n.statusDisconnecting,
        ConnectionState.error => l10n.statusError,
      };

  /// Причина failover: simple — человеческое описание, advanced —
  /// техническое с именем протокола.
  static String failoverReasonLabel(
    AppLocalizations l10n,
    UiExperienceMode mode,
    FailoverEvent event,
  ) {
    final protocol = event.fromProtocol.displayName;
    return switch (mode) {
      UiExperienceMode.simple => switch (event.reason) {
          FailoverReason.timeout => l10n.failoverReasonTimeoutSimple,
          FailoverReason.packetLoss => l10n.failoverReasonPacketLossSimple,
          FailoverReason.blocked => l10n.failoverReasonBlockedSimple,
          FailoverReason.handshakeFailed => l10n.failoverReasonHandshakeSimple,
          FailoverReason.manual => l10n.failoverReasonManual,
        },
      UiExperienceMode.advanced => switch (event.reason) {
          FailoverReason.timeout =>
            l10n.failoverReasonTimeoutAdvanced(protocol),
          FailoverReason.packetLoss =>
            l10n.failoverReasonPacketLossAdvanced(protocol),
          FailoverReason.blocked =>
            l10n.failoverReasonBlockedAdvanced(protocol),
          FailoverReason.handshakeFailed =>
            l10n.failoverReasonHandshakeAdvanced(protocol),
          FailoverReason.manual => l10n.failoverReasonManual,
        },
    };
  }

  /// Короткое сообщение «Переключение на X…» для снэкбара.
  ///
  /// simple: человеческое имя протокола; advanced: техническое.
  static String failoverSwitchMessage(
    AppLocalizations l10n,
    UiExperienceMode mode,
    FailoverEvent event,
  ) =>
      l10n.failoverSwitchedTo(
        protocolLabel(l10n, mode, event.toProtocol),
      );

  /// Сообщение об ошибке подключения по коду.
  static String connectionErrorLabel(
    AppLocalizations l10n,
    ConnectionError error,
  ) =>
      switch (error) {
        ConnectionError.nodeMissing => l10n.connectionErrorNodeMissing,
        ConnectionError.connectFailed => l10n.connectionErrorConnectFailed,
        ConnectionError.coreUnavailable => l10n.connectionErrorCoreUnavailable,
        ConnectionError.disconnectFailed =>
          l10n.connectionErrorDisconnectFailed,
      };

  /// Сообщение об ошибке правил Split Tunneling по коду.
  ///
  /// Числовые параметры (лимиты, длины) берутся из констант,
  /// поэтому код ошибки не требует параметров.
  static String splitTunnelErrorLabel(
    AppLocalizations l10n,
    SplitTunnelError error,
  ) =>
      switch (error) {
        SplitTunnelError.loadFailed => l10n.splitErrorLoadFailed,
        SplitTunnelError.saveFailed => l10n.splitErrorSaveFailed,
        SplitTunnelError.ruleNotFound => l10n.splitErrorRuleNotFound,
        SplitTunnelError.presetUnknown => l10n.splitErrorPresetUnknown,
        SplitTunnelError.noProviderRules => l10n.splitErrorNoProviderRules,
        SplitTunnelError.limitReached => l10n.splitErrorLimitReached(
            SplitTunnelConstants.maxInlineRules,
          ),
        SplitTunnelError.patternTooShort => l10n.splitErrorPatternTooShort(
            SplitTunnelConstants.minPatternLength,
          ),
        SplitTunnelError.patternTooLong => l10n.splitErrorPatternTooLong(
            SplitTunnelConstants.maxPatternLength,
          ),
        SplitTunnelError.patternEmpty => l10n.splitErrorPatternEmpty,
        SplitTunnelError.duplicate => l10n.splitErrorDuplicate,
        SplitTunnelError.invalidRegex => l10n.splitErrorInvalidRegex,
        SplitTunnelError.invalidDomain => l10n.splitErrorInvalidDomain,
        SplitTunnelError.invalidKeyword => l10n.splitErrorInvalidKeyword,
        SplitTunnelError.invalidGeoip => l10n.splitErrorInvalidGeoip,
        SplitTunnelError.invalidPackage => l10n.splitErrorInvalidPackage,
        SplitTunnelError.invalidCidr => l10n.splitErrorInvalidCidr,
        SplitTunnelError.reloadFailed => l10n.splitErrorReloadFailed,
      };

  /// Длина ключа подписки для сообщений об ошибках ключей.
  static const int subscriptionKeyLength =
      SettingsConstants.subscriptionKeyLengthBytes;
}
