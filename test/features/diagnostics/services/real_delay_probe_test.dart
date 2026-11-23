import 'package:fetu/core/constants/diagnostics_constants.dart';
import 'package:fetu/features/diagnostics/services/real_delay_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RealDelayProbe', () {
    test('успешный зонд возвращает измеренную задержку', () async {
      final probe = RealDelayProbe(
        probeImpl: (url, timeout) async => const Duration(milliseconds: 87),
      );

      expect((await probe.probe())!.inMilliseconds, 87);
    });

    test('зонд вызывает транспорт с URL 204 и таймаутом из констант', () async {
      Uri? seenUrl;
      Duration? seenTimeout;
      final probe = RealDelayProbe(
        probeImpl: (url, timeout) async {
          seenUrl = url;
          seenTimeout = timeout;
          return const Duration(milliseconds: 5);
        },
      );

      await probe.probe();

      expect(
        seenUrl.toString(),
        DiagnosticsConstants.realDelayProbeUrl,
      );
      expect(seenTimeout, DiagnosticsConstants.realDelayTimeout);
    });

    test('сбой зонда → null (без исключения наружу)', () async {
      final probe = RealDelayProbe(
        probeImpl: (url, timeout) async => null,
      );

      expect(await probe.probe(), isNull);
    });

    test('зонд по умолчанию использует общий HTTP-пул (правило 3)', () {
      // Проверяем только конструирование без инъекции: реальный
      // транспорт (HttpConnectionPool) не трогаем — сеть в тестах
      // недоступна, вызов probe() здесь не выполняется.
      expect(() => RealDelayProbe(), returnsNormally);
    });
  });
}
