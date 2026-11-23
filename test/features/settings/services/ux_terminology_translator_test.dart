import 'package:fetu/features/connection/models/connection_error.dart';
import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:fetu/features/connection/models/server_node.dart';
import 'package:fetu/features/failover/models/failover_event.dart';
import 'package:fetu/features/failover/models/protocol_health.dart';
import 'package:fetu/features/settings/models/ui_experience_mode.dart';
import 'package:fetu/features/settings/services/ux_terminology_translator.dart';
import 'package:fetu/features/split_tunnel/models/split_tunnel_error.dart';
import 'package:fetu/l10n/app_localizations_en.dart';
import 'package:fetu/l10n/app_localizations_ru.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Прямые экземпляры сгенерированных классов (без виджет-байндинга).
  final ru = AppLocalizationsRu();
  final en = AppLocalizationsEn();

  group('UxTerminologyTranslator.protocolLabel', () {
    test('простой режим: UDP → «Умный доступ»', () {
      for (final protocol in [
        ProtocolType.hysteria2,
        ProtocolType.amneziaWg,
        ProtocolType.wireguard,
      ]) {
        expect(
          UxTerminologyTranslator.protocolLabel(
            ru,
            UiExperienceMode.simple,
            protocol,
          ),
          ru.uxTermSmartAccess,
        );
        expect(
          UxTerminologyTranslator.protocolLabel(
            en,
            UiExperienceMode.simple,
            protocol,
          ),
          en.uxTermSmartAccess,
        );
      }
    });

    test('простой режим: TCP-стелс → «Максимальная скрытность»', () {
      for (final protocol in [
        ProtocolType.vlessReality,
        ProtocolType.naive,
        ProtocolType.mieru,
        ProtocolType.vless,
      ]) {
        expect(
          UxTerminologyTranslator.protocolLabel(
            ru,
            UiExperienceMode.simple,
            protocol,
          ),
          ru.uxTermMaxStealth,
        );
      }
    });

    test('простой режим: Shadowsocks → «Классическая защита»', () {
      expect(
        UxTerminologyTranslator.protocolLabel(
          ru,
          UiExperienceMode.simple,
          ProtocolType.shadowsocks,
        ),
        ru.uxTermClassicProtection,
      );
    });

    test('расширенный режим: технические имена протоколов', () {
      expect(
        UxTerminologyTranslator.protocolLabel(
          ru,
          UiExperienceMode.advanced,
          ProtocolType.hysteria2,
        ),
        'Hysteria 2',
      );
      expect(
        UxTerminologyTranslator.protocolLabel(
          ru,
          UiExperienceMode.advanced,
          ProtocolType.vlessReality,
        ),
        'VLESS Reality',
      );
    });
  });

  group('UxTerminologyTranslator.connectionStateLabel', () {
    test('все состояния локализованы (RU/EN)', () {
      for (final state in ConnectionState.values) {
        expect(
          UxTerminologyTranslator.connectionStateLabel(ru, state),
          isNotEmpty,
        );
        expect(
          UxTerminologyTranslator.connectionStateLabel(en, state),
          isNotEmpty,
        );
      }
      expect(
        UxTerminologyTranslator.connectionStateLabel(
          ru,
          ConnectionState.connected,
        ),
        'Подключено',
      );
      expect(
        UxTerminologyTranslator.connectionStateLabel(
          en,
          ConnectionState.disconnected,
        ),
        'Disconnected',
      );
    });
  });

  group('UxTerminologyTranslator.failoverReasonLabel', () {
    FailoverEvent event(FailoverReason reason) => FailoverEvent(
          timestamp: DateTime(2026),
          fromProtocol: ProtocolType.hysteria2,
          toProtocol: ProtocolType.vlessReality,
          reason: reason,
          health: ProtocolHealth.degraded,
        );

    test('простой режим: без технических имён протоколов', () {
      final label = UxTerminologyTranslator.failoverReasonLabel(
        ru,
        UiExperienceMode.simple,
        event(FailoverReason.timeout),
      );
      expect(label, ru.failoverReasonTimeoutSimple);
      expect(label.contains('Hysteria'), isFalse);
    });

    test('расширенный режим: с именем протокола', () {
      final label = UxTerminologyTranslator.failoverReasonLabel(
        ru,
        UiExperienceMode.advanced,
        event(FailoverReason.timeout),
      );
      expect(label, ru.failoverReasonTimeoutAdvanced('Hysteria 2'));
    });

    test('сообщение о переключении: простое имя в simple', () {
      final message = UxTerminologyTranslator.failoverSwitchMessage(
        ru,
        UiExperienceMode.simple,
        event(FailoverReason.blocked),
      );
      expect(message, ru.failoverSwitchedTo(ru.uxTermMaxStealth));
    });
  });

  group('UxTerminologyTranslator.errorLabel', () {
    test('все коды ошибок подключения локализованы', () {
      for (final code in ConnectionError.values) {
        expect(
          UxTerminologyTranslator.connectionErrorLabel(ru, code),
          isNotEmpty,
        );
        expect(
          UxTerminologyTranslator.connectionErrorLabel(en, code),
          isNotEmpty,
        );
      }
    });

    test('все коды ошибок Split Tunneling локализованы', () {
      for (final code in SplitTunnelError.values) {
        expect(
          UxTerminologyTranslator.splitTunnelErrorLabel(ru, code),
          isNotEmpty,
        );
        expect(
          UxTerminologyTranslator.splitTunnelErrorLabel(en, code),
          isNotEmpty,
        );
      }
    });
  });
}
