/// Зонд Real-Delay: сквозная задержка до интернета через туннель.
///
/// Измеряет время HTTP 204-ответа (connectivity-check) через общий
/// пул соединений (AGENTS.md, правило 3): при активном VPN-туннеле
/// запрос проходит через него, и зонд показывает реальную
/// end-to-end задержку, а не ICMP-ping.
library;

import 'package:dio/dio.dart';
import 'package:meta/meta.dart';

import '../../../core/constants/diagnostics_constants.dart';
import '../../../core/network/http_connection_pool.dart';

/// Инъекцируемая реализация зонда (для тестов, без реальной сети).
typedef RealDelayProbeImpl = Future<Duration?> Function(
  Uri url,
  Duration timeout,
);

/// Измеритель Real-Delay.
class RealDelayProbe {
  /// Создаёт зонд.
  ///
  /// [probeImpl] — переопределение транспортного слоя (тесты).
  RealDelayProbe({@visibleForTesting RealDelayProbeImpl? probeImpl})
      : _probeImpl = probeImpl ?? _probeViaConnectionPool;

  final RealDelayProbeImpl _probeImpl;

  /// Выполняет зонд.
  ///
  /// Returns: задержка; null — зонд не удался (таймаут/сеть).
  Future<Duration?> probe() => _probeImpl(
        Uri.parse(DiagnosticsConstants.realDelayProbeUrl),
        DiagnosticsConstants.realDelayTimeout,
      );

  /// Транспорт через общий пул (правило 3: никаких HttpClient()).
  static Future<Duration?> _probeViaConnectionPool(
    Uri url,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      await HttpConnectionPool.instance.client.getUri<dynamic>(
        url,
        options: Options(
          receiveTimeout: timeout,
          sendTimeout: timeout,
          // Real-Delay-канон: успешным считается ответ 204 No Content.
          validateStatus: (status) => status == 204 || status == 200,
        ),
      );
      return stopwatch.elapsed;
    } on DioException {
      return null;
    }
  }
}
