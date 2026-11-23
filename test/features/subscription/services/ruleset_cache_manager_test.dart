import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:fetu/core/constants/subscription_constants.dart';
import 'package:fetu/features/subscription/services/ruleset_cache_manager.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_storage.dart';

void main() {
  late TestStorage storage;
  late RuleSetFetcher fetcherImpl;

  RuleSetCacheManager manager() => RuleSetCacheManager(
        storage: storage,
        fetcher: (url, etag) => fetcherImpl(url, etag),
      );

  Uint8List bytesOf(List<int> data) => Uint8List.fromList(data);

  setUp(() {
    storage = TestStorage();
    fetcherImpl = (_, __) async => null;
  });

  group('RuleSetCacheManager.fetch', () {
    test('200: скачивает, считает sha256, кэширует по ETag', () async {
      final data = bytesOf([1, 2, 3, 4, 5]);
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: data,
            etag: 'v1',
          );

      final result = await manager().fetch(id: 'test', url: 'https://r/s.srs');

      expect(result.status, RuleSetFetchStatus.updated);
      expect(result.ruleSet!.sha256, crypto.sha256.convert(data).toString());
      expect(result.ruleSet!.etag, 'v1');
      expect(result.ruleSet!.sizeKb, 1);
      expect(result.isAvailable, isTrue);
    });

    test('304: возвращает кэш без скачивания (ETag передаётся)', () async {
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([10, 20]),
            etag: 'e1',
          );
      await manager().fetch(id: 'test', url: 'u');

      var seenEtag = 'not-set';
      fetcherImpl = (url, etag) async {
        seenEtag = etag ?? 'null';
        return const RuleSetDownload(statusCode: 304);
      };

      final result = await manager().fetch(id: 'test', url: 'u');

      expect(seenEtag, 'e1', reason: 'условный запрос по If-None-Match');
      expect(result.status, RuleSetFetchStatus.notModified);
      expect(result.ruleSet!.bytes, bytesOf([10, 20]));
    });

    test('сетевой сбой → Last-Known-Good, без кэша → failed', () async {
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([7]),
            etag: 'e1',
          );
      final warm = manager();
      await warm.fetch(id: 'test', url: 'u');

      fetcherImpl = (_, __) async => null;
      final lkg = await warm.fetch(id: 'test', url: 'u');

      expect(lkg.status, RuleSetFetchStatus.lkgFallback);
      expect(lkg.isAvailable, isTrue);
      expect(lkg.error, isNotNull);
      expect(lkg.ruleSet!.bytes, bytesOf([7]));

      final cold = await manager().fetch(id: 'other', url: 'u');
      expect(cold.status, RuleSetFetchStatus.failed);
      expect(cold.isAvailable, isFalse);
    });

    test('sha256 не совпал → свежие данные отбрасываются, LKG', () async {
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([1, 1, 1]),
            etag: 'good',
          );
      final warm = manager();
      final first = await warm.fetch(id: 'test', url: 'u');
      final goodSha = first.ruleSet!.sha256;

      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([9, 9, 9]),
            etag: 'bad',
          );
      final result = await warm.fetch(
        id: 'test',
        url: 'u',
        expectedSha256: goodSha,
      );

      expect(result.status, RuleSetFetchStatus.lkgFallback);
      expect(result.ruleSet!.bytes, bytesOf([1, 1, 1]));
      expect(result.error, contains('sha256'));
    });

    test('превышение max_size_kb → LKG/failed (правило 32)', () async {
      final oversized = Uint8List(
        SubscriptionConstants.srsMaxSizeKb * 1024 + 1,
      );
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: oversized,
            etag: 'big',
          );

      final result = await manager().fetch(id: 'test', url: 'u');

      expect(result.status, RuleSetFetchStatus.failed);
      expect(result.error, contains('лимит'));
    });

    test('кэш переживает создание нового менеджера (LKG персистентен)',
        () async {
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([3, 3, 3]),
            etag: 'e9',
          );
      await manager().fetch(id: 'persist', url: 'u');

      fetcherImpl = (_, __) async => null;
      final restored = await manager().fetch(id: 'persist', url: 'u');

      expect(restored.status, RuleSetFetchStatus.lkgFallback);
      expect(restored.ruleSet!.bytes, bytesOf([3, 3, 3]));
    });

    test('cachedSet и invalidate работают', () async {
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([5]),
            etag: 'e',
          );
      final warm = manager();
      await warm.fetch(id: 'test', url: 'u');

      expect((await warm.cachedSet('test'))?.bytes, bytesOf([5]));

      await warm.invalidate('test');
      expect(await warm.cachedSet('test'), isNull);
    });

    test('битый кэш в хранилище не ломает менеджер', () async {
      await storage.write(
        key: RuleSetCacheManager.storageKeyFor('broken'),
        value: 'not-json',
      );
      fetcherImpl = (url, etag) async => RuleSetDownload(
            statusCode: 200,
            bytes: bytesOf([8]),
            etag: 'fresh',
          );

      final result = await manager().fetch(id: 'broken', url: 'u');

      expect(result.status, RuleSetFetchStatus.updated);
      expect(result.ruleSet!.bytes, bytesOf([8]));
    });
  });
}
