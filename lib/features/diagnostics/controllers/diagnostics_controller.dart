/// Контроллер экрана диагностики (ChangeNotifier).
///
/// Управляет измерением Real-Delay и сборкой диагностического
/// отчёта; зонд выполняется только по кнопке пользователя
/// (AGENTS.md, правило 23: никакого фонового поллинга).
library;

import 'package:flutter/foundation.dart';

import '../models/diagnostic_report.dart';
import '../services/diagnostic_report_builder.dart';
import '../services/real_delay_probe.dart';

/// Контроллер диагностики для UI.
class DiagnosticsController extends ChangeNotifier {
  /// Создаёт контроллер.
  ///
  /// [builder] — сборщик отчёта; [probe] — зонд Real-Delay;
  /// [isTunnelActive] — провайдер активности туннеля (зонд имеет
  /// смысл только при подключённом VPN).
  DiagnosticsController({
    required DiagnosticReportBuilder builder,
    required RealDelayProbe probe,
    required bool Function() isTunnelActive,
  })  : _builder = builder,
        _probe = probe,
        _isTunnelActive = isTunnelActive;

  final DiagnosticReportBuilder _builder;
  final RealDelayProbe _probe;
  final bool Function() _isTunnelActive;

  DiagnosticReport? _report;
  int? _realDelayMs;
  bool _isProbing = false;

  /// Последний собранный отчёт (null — ещё не собирали).
  DiagnosticReport? get report => _report;

  /// Последний результат зонда Real-Delay (null — не измерялся).
  int? get realDelayMs => _realDelayMs;

  /// Выполняется ли зонд прямо сейчас.
  bool get isProbing => _isProbing;

  /// Пересобирает отчёт с текущим состоянием.
  void refresh() {
    _report = _builder.build(realDelayMs: _realDelayMs);
    notifyListeners();
  }

  /// Запускает зонд Real-Delay (только при активном туннеле).
  ///
  /// Returns: true — зонд выполнен (результат или сбой в
  /// [realDelayMs]); false — туннель не активен, зонд пропущен.
  Future<bool> measureRealDelay() async {
    if (!_isTunnelActive()) {
      _realDelayMs = null;
      notifyListeners();
      return false;
    }

    _isProbing = true;
    notifyListeners();

    try {
      final delay = await _probe.probe();
      _realDelayMs = delay?.inMilliseconds;
      return true;
    } finally {
      _isProbing = false;
      refresh();
    }
  }
}
