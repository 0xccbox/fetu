import 'package:fetu/features/connection/models/connection_metrics.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionMetrics', () {
    test('создаётся с корректными значениями', () {
      const metrics = ConnectionMetrics(
        downloadSpeed: 1000000,
        uploadSpeed: 500000,
        totalDownloaded: 10000000,
        totalUploaded: 5000000,
        connectionDuration: 120,
        latency: 50,
      );

      expect(metrics.downloadSpeed, 1000000);
      expect(metrics.uploadSpeed, 500000);
      expect(metrics.totalDownloaded, 10000000);
      expect(metrics.totalUploaded, 5000000);
      expect(metrics.connectionDuration, 120);
      expect(metrics.latency, 50);
    });

    test('создаёт пустые метрики', () {
      const metrics = ConnectionMetrics.empty();

      expect(metrics.downloadSpeed, 0);
      expect(metrics.uploadSpeed, 0);
      expect(metrics.totalDownloaded, 0);
      expect(metrics.totalUploaded, 0);
      expect(metrics.connectionDuration, 0);
      expect(metrics.latency, null);
    });

    test('copyWith корректно создаёт новый экземпляр', () {
      const original = ConnectionMetrics(
        downloadSpeed: 1000,
        uploadSpeed: 500,
        totalDownloaded: 10000,
        totalUploaded: 5000,
        connectionDuration: 60,
      );

      final updated = original.copyWith(downloadSpeed: 2000);

      expect(updated.downloadSpeed, 2000);
      expect(updated.uploadSpeed, 500);
      expect(updated.totalDownloaded, 10000);
    });

    group('formatSpeed', () {
      test('форматирует байты в секунду', () {
        expect(ConnectionMetrics.formatSpeed(500), '500 B/s');
      });

      test('форматирует килобайты в секунду', () {
        expect(ConnectionMetrics.formatSpeed(1024), '1.0 KB/s');
        expect(ConnectionMetrics.formatSpeed(512 * 1024), '512.0 KB/s');
      });

      test('форматирует мегабайты в секунду', () {
        expect(ConnectionMetrics.formatSpeed(1024 * 1024), '1.0 MB/s');
        expect(ConnectionMetrics.formatSpeed(5 * 1024 * 1024), '5.0 MB/s');
      });
    });

    group('formatBytes', () {
      test('форматирует байты', () {
        expect(ConnectionMetrics.formatBytes(500), '500 B');
      });

      test('форматирует килобайты', () {
        expect(ConnectionMetrics.formatBytes(1024), '1.0 KB');
        expect(ConnectionMetrics.formatBytes(1536), '1.5 KB');
      });

      test('форматирует мегабайты', () {
        expect(ConnectionMetrics.formatBytes(1024 * 1024), '1.0 MB');
        expect(ConnectionMetrics.formatBytes(5 * 1024 * 1024), '5.0 MB');
      });

      test('форматирует гигабайты', () {
        expect(ConnectionMetrics.formatBytes(1024 * 1024 * 1024), '1.00 GB');
        expect(
          ConnectionMetrics.formatBytes(3 * 1024 * 1024 * 1024),
          '3.00 GB',
        );
      });
    });

    group('formatDuration', () {
      test('форматирует секунды', () {
        expect(ConnectionMetrics.formatDuration(30), '00:30');
      });

      test('форматирует минуты и секунды', () {
        expect(ConnectionMetrics.formatDuration(90), '01:30');
        expect(ConnectionMetrics.formatDuration(600), '10:00');
      });

      test('форматирует часы, минуты и секунды', () {
        expect(ConnectionMetrics.formatDuration(3661), '01:01:01');
        expect(ConnectionMetrics.formatDuration(7200), '02:00:00');
      });
    });
  });
}
