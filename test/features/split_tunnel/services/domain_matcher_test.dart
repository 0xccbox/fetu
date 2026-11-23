import 'package:fetu/features/split_tunnel/models/rule_type.dart';
import 'package:fetu/features/split_tunnel/services/domain_matcher.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DomainMatcher normalize', () {
    test('должен приводить домен к каноническому виду', () {
      expect(DomainMatcher.normalize('  VK.COM '), 'vk.com');
      expect(DomainMatcher.normalize('.vk.com.'), 'vk.com');
      expect(DomainMatcher.normalize('m.VK.com'), 'm.vk.com');
    });
  });

  group('DomainMatcher matchesExact', () {
    test('должен совпадать только при полном равенстве', () {
      expect(DomainMatcher.matchesExact('vk.com', 'VK.COM'), isTrue);
      expect(DomainMatcher.matchesExact('m.vk.com', 'vk.com'), isFalse);
      expect(DomainMatcher.matchesExact('vk.com', ''), isFalse);
    });
  });

  group('DomainMatcher matchesSuffix', () {
    test('должен покрывать домен и поддомены', () {
      expect(DomainMatcher.matchesSuffix('vk.com', 'vk.com'), isTrue);
      expect(DomainMatcher.matchesSuffix('m.vk.com', 'vk.com'), isTrue);
      expect(DomainMatcher.matchesSuffix('a.b.vk.com', 'vk.com'), isTrue);
      expect(
        DomainMatcher.matchesSuffix('evk.com', 'vk.com'),
        isFalse,
        reason: 'суффикс должен совпадать по меткам домена',
      );
      expect(DomainMatcher.matchesSuffix('vk.com', 'm.vk.com'), isFalse);
    });

    test('wildcard *.example.com должен покрывать поддомены, но не apex', () {
      expect(
        DomainMatcher.matchesSuffix('a.example.com', '*.example.com'),
        isTrue,
      );
      expect(
        DomainMatcher.matchesSuffix('example.com', '*.example.com'),
        isFalse,
      );
      expect(
        DomainMatcher.matchesSuffix('b.a.example.com', '*.example.com'),
        isTrue,
      );
    });
  });

  group('DomainMatcher matchesKeyword', () {
    test('должен находить подстроку без учёта регистра', () {
      expect(DomainMatcher.matchesKeyword('google.com', 'GOO'), isTrue);
      expect(DomainMatcher.matchesKeyword('youtube.com', 'tube'), isTrue);
      expect(DomainMatcher.matchesKeyword('youtube.com', 'yt'), isFalse);
      expect(DomainMatcher.matchesKeyword('youtube.com', ''), isFalse);
    });
  });

  group('DomainMatcher matchesRegex', () {
    test('должен матчить регулярное выражение на домен', () {
      expect(
        DomainMatcher.matchesRegex('ads1.example.com', r'^ads\d*\.'),
        isTrue,
      );
      expect(
        DomainMatcher.matchesRegex('ads.example.com', r'^ads\d+\.'),
        isFalse,
      );
    });

    test('некорректный regex должен безопасно возвращать false', () {
      expect(DomainMatcher.matchesRegex('vk.com', r'^[invalid'), isFalse);
    });
  });

  group('DomainMatcher matches', () {
    test('должен диспетчеризовать по типу правила', () {
      expect(
        DomainMatcher.matches('m.vk.com', RuleType.domainSuffix, 'vk.com'),
        isTrue,
      );
      expect(
        DomainMatcher.matches('vk.com', RuleType.domain, 'vk.com'),
        isTrue,
      );
      expect(
        DomainMatcher.matches('vk.com', RuleType.domainKeyword, 'vk'),
        isTrue,
      );

      // Не-доменные типы не матчятся локально (их считает sing-box).
      expect(
        DomainMatcher.matches('vk.com', RuleType.ipCidr, '0.0.0.0/0'),
        isFalse,
      );
      expect(DomainMatcher.matches('vk.com', RuleType.geoip, 'ru'), isFalse);
      expect(DomainMatcher.matches('vk.com', RuleType.app, 'com.vk'), isFalse);
    });
  });
}
