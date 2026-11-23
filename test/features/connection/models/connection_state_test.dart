import 'package:fetu/features/connection/models/connection_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConnectionState', () {
    test('имеет все необходимые состояния', () {
      expect(ConnectionState.disconnected, isNotNull);
      expect(ConnectionState.connecting, isNotNull);
      expect(ConnectionState.connected, isNotNull);
      expect(ConnectionState.disconnecting, isNotNull);
      expect(ConnectionState.error, isNotNull);
    });

    test('isActive возвращает true только для connected', () {
      expect(ConnectionState.connected.isActive, true);
      expect(ConnectionState.disconnected.isActive, false);
      expect(ConnectionState.connecting.isActive, false);
      expect(ConnectionState.disconnecting.isActive, false);
      expect(ConnectionState.error.isActive, false);
    });

    test('isTransitioning возвращает true для connecting и disconnecting', () {
      expect(ConnectionState.connecting.isTransitioning, true);
      expect(ConnectionState.disconnecting.isTransitioning, true);
      expect(ConnectionState.connected.isTransitioning, false);
      expect(ConnectionState.disconnected.isTransitioning, false);
      expect(ConnectionState.error.isTransitioning, false);
    });
  });
}
