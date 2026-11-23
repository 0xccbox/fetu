import 'dart:io';

/// Автоматическая проверка соблюдения архитектурных правил проекта.
Future<void> main() async {
  stdout.writeln('Проверка архитектурных инвариантов...');

  final errors = <String>[
    ...await checkFileLineLimits(),
    ...await checkFeatureIsolation(),
    ...await checkUiServiceSeparation(),
    ...await checkNoHardcodedColors(),
    ...await checkNoDirectHttpClient(),
  ];

  if (errors.isEmpty) {
    stdout.writeln('Все архитектурные правила соблюдены.');
    exit(0);
  } else {
    stderr.writeln('Обнаружены нарушения архитектуры:');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exit(1);
  }
}

/// Проверка 0: Ни один Dart-файл в lib/ не превышает 500 строк (SRP).
Future<List<String>> checkFileLineLimits() async {
  final errors = <String>[];
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return errors;

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final normalizedPath = file.path.replaceAll(r'\', '/');
    if (normalizedPath.endsWith('.g.dart') ||
        normalizedPath.endsWith('.freezed.dart') ||
        normalizedPath.contains('lib/l10n/app_localizations')) {
      continue;
    }
    final lines = await file.readAsLines();
    if (lines.length > 500) {
      errors.add('${file.path} превышает лимит в 500 строк (${lines.length}).');
    }
  }
  return errors;
}

/// Проверка 1: Фичи не импортируют друг друга напрямую (кроме models/).
Future<List<String>> checkFeatureIsolation() async {
  final errors = <String>[];
  final featuresRoot = Directory('lib/features');
  if (!featuresRoot.existsSync()) return errors;

  final featureDirs = featuresRoot.listSync().whereType<Directory>().toList();

  for (final featureDir in featureDirs) {
    final featureName = featureDir.path.replaceAll(r'\', '/').split('/').last;
    final dartFiles = featureDir
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'));

    for (final file in dartFiles) {
      final lines = await file.readAsLines();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.startsWith('import') && line.contains('features/')) {
          if (!line.contains('/models/')) {
            final importedFeature = _extractFeatureName(line);
            if (importedFeature != null && importedFeature != featureName) {
              errors.add(
                '${file.path}:${i + 1} — фича "$featureName" напрямую '
                'импортирует "$importedFeature". Используйте DI или models/.',
              );
            }
          }
        }
      }
    }
  }
  return errors;
}

/// Проверка 2: UI (screens/ и widgets/) не инстанциирует сервисы напрямую.
Future<List<String>> checkUiServiceSeparation() async {
  final errors = <String>[];
  final featuresRoot = Directory('lib/features');
  if (!featuresRoot.existsSync()) return errors;

  final uiFiles = <File>[];
  for (final featureDir in featuresRoot.listSync().whereType<Directory>()) {
    for (final sub in ['screens', 'widgets']) {
      final dir = Directory('${featureDir.path}/$sub');
      if (dir.existsSync()) {
        uiFiles.addAll(
          dir
              .listSync(recursive: true)
              .whereType<File>()
              .where((f) => f.path.endsWith('.dart')),
        );
      }
    }
  }

  final serviceRegex = RegExp(r'[A-Z]\w+Service\(');
  for (final file in uiFiles) {
    final lines = await file.readAsLines();
    for (var i = 0; i < lines.length; i++) {
      if (serviceRegex.hasMatch(lines[i])) {
        errors.add(
          '${file.path}:${i + 1} — UI создаёт сервис напрямую. '
          'Используйте контроллер через Provider/GetIt.',
        );
      }
    }
  }
  return errors;
}

/// Проверка 3: В фичах нет хардкод-цветов Color(0x...) или Colors.xxx.
Future<List<String>> checkNoHardcodedColors() async {
  final errors = <String>[];
  final featuresRoot = Directory('lib/features');
  if (!featuresRoot.existsSync()) return errors;

  final featureFiles = featuresRoot
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  final hexColorRegex = RegExp(r'Color\(0x[0-9A-Fa-f]+\)');
  final materialColorsRegex = RegExp(r'\bColors\.\w+');

  for (final file in featureFiles) {
    final lines = await file.readAsLines();
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      if (hexColorRegex.hasMatch(line) || materialColorsRegex.hasMatch(line)) {
        errors.add(
          '${file.path}:${i + 1} — обнаружен хардкод цвета. '
          'Используйте AppColors из design_system.',
        );
      }
    }
  }
  return errors;
}

/// Проверка 4: Запрет на прямое создание HttpClient() или Dio().
Future<List<String>> checkNoDirectHttpClient() async {
  final errors = <String>[];
  final libDir = Directory('lib');
  if (!libDir.existsSync()) return errors;

  final dartFiles = libDir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.endsWith('.dart'));

  for (final file in dartFiles) {
    final normalizedPath = file.path.replaceAll(r'\', '/');
    if (normalizedPath.endsWith('core/network/http_connection_pool.dart')) {
      continue;
    }

    final lines = await file.readAsLines();
    for (var i = 0; i < lines.length; i++) {
      final raw = lines[i];
      final trimmed = raw.trim();
      if (trimmed.startsWith('//') ||
          trimmed.startsWith('/*') ||
          trimmed.startsWith('*')) {
        continue;
      }
      final codeOnly = raw.split('//').first;
      if (codeOnly.contains('HttpClient()') || codeOnly.contains('Dio(')) {
        errors.add(
          '${file.path}:${i + 1} — прямое создание HttpClient/Dio запрещено. '
          'Используйте HttpConnectionPool.instance.client.',
        );
      }
    }
  }
  return errors;
}

String? _extractFeatureName(String importLine) {
  final match = RegExp('features/([^/]+)/').firstMatch(importLine);
  return match?.group(1);
}
