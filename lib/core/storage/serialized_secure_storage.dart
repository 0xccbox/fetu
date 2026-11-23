import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'key_value_storage.dart';

/// Сериализует обращения к одному защищённому хранилищу ОС.
/// На Windows плагин перезаписывает общий файл даже при изменении одного ключа.
final class SerializedSecureStorage implements KeyValueStorage {
  /// Принимает платформенное хранилище с общими параметрами для всех ключей.
  SerializedSecureStorage(
    this._storage, {
    Duration operationTimeout = const Duration(seconds: 5),
  }) : _operationTimeout = operationTimeout;

  final FlutterSecureStorage _storage;
  final Duration _operationTimeout;
  Future<void> _tail = Future<void>.value();

  /// Выполняет группу операций без параллельного доступа к платформенному файлу.
  Future<T> run<T>(Future<T> Function(FlutterSecureStorage) operation) {
    final done = Completer<void>();
    final previous = _tail;
    _tail = done.future;
    return previous
        .catchError((Object _) {})
        .then((_) => operation(_storage).timeout(_operationTimeout))
        .whenComplete(() {
      if (!done.isCompleted) {
        done.complete();
      }
    });
  }

  @override
  Future<String?> read({required String key}) =>
      run((storage) => storage.read(key: key));

  @override
  Future<void> write({required String key, required String value}) =>
      run((storage) => storage.write(key: key, value: value));

  @override
  Future<void> delete({required String key}) =>
      run((storage) => storage.delete(key: key));
}
