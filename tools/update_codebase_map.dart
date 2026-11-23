// ignore_for_file: avoid_print

import 'dart:io';

/// Автоматически генерирует docs/CODEBASE_MAP.md на основе структуры lib/
void main() {
  final libDir = Directory('lib');

  if (!libDir.existsSync()) {
    print('❌ Папка lib/ не найдена. Запусти скрипт из корня проекта.');
    exit(1);
  }

  final map = StringBuffer();

  // Заголовок
  map.writeln('# 🗺️ КАРТА КОДОВОЙ БАЗЫ');
  map.writeln();
  map.writeln(
    '> **Автоматически сгенерировано:** ${DateTime.now().toIso8601String()}',
  );
  map.writeln('>');
  map.writeln(
    '> ⚠️ Не редактируй этот файл вручную! Он генерируется автоматически.',
  );
  map.writeln('>');
  map.writeln(
    '> Для обновления запусти: `dart run tools/update_codebase_map.dart`',
  );
  map.writeln();

  map.writeln('---');
  map.writeln();

  // Структура папок
  map.writeln('## 📂 СТРУКТУРА ПАПОК');
  map.writeln();
  map.writeln('```');
  _printTree(libDir, map, prefix: '');
  map.writeln('```');
  map.writeln();

  // Реестр модулей
  map.writeln('---');
  map.writeln();
  map.writeln('## 📦 РЕЕСТР МОДУЛЕЙ');
  map.writeln();
  _printModules(libDir, map);

  // Правила обновления
  map.writeln('---');
  map.writeln();
  map.writeln('## 🔄 ПРАВИЛА ОБНОВЛЕНИЯ');
  map.writeln();
  map.writeln(
    'Этот файл обновляется **автоматически** при каждом изменении структуры `lib/`.',
  );
  map.writeln();
  map.writeln('### Вручную (если забыл):');
  map.writeln('```bash');
  map.writeln('dart run tools/update_codebase_map.dart');
  map.writeln('git add docs/CODEBASE_MAP.md');
  map.writeln('git commit -m "docs: обновить CODEBASE_MAP"');
  map.writeln('```');
  map.writeln();
  map.writeln('### Автоматически (pre-commit hook):');
  map.writeln('```bash');
  map.writeln('# .git/hooks/pre-commit');
  map.writeln('#!/bin/bash');
  map.writeln('if git diff --cached --name-only | grep -q "^lib/"; then');
  map.writeln('  dart run tools/update_codebase_map.dart');
  map.writeln('  git add docs/CODEBASE_MAP.md');
  map.writeln('fi');
  map.writeln('```');
  map.writeln();
  map.writeln('---');
  map.writeln();
  map.writeln(
    '_Документ обновлён: ${DateTime.now().toIso8601String().split('T')[0]}_  ',
  );
  map.writeln('_Версия: Автоматическая_');

  // Сохранить файл
  final docsDir = Directory('docs');
  if (!docsDir.existsSync()) {
    docsDir.createSync();
  }

  File('docs/CODEBASE_MAP.md').writeAsStringSync(map.toString());

  print('✅ docs/CODEBASE_MAP.md успешно обновлён!');
}

/// Печатает дерево файлов в виде ASCII-арта
void _printTree(Directory dir, StringBuffer buffer, {required String prefix}) {
  final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (var i = 0; i < entries.length; i++) {
    final entry = entries[i];
    final isLast = i == entries.length - 1;
    final connector = isLast ? '└── ' : '├── ';
    final childPrefix = prefix + (isLast ? '    ' : '│   ');

    if (entry is Directory) {
      final name = entry.path.split(Platform.pathSeparator).last;

      // Пропускаем скрытые папки
      if (name.startsWith('.')) continue;

      buffer.writeln('$prefix$connector$name/');
      _printTree(entry, buffer, prefix: childPrefix);
    } else if (entry is File && entry.path.endsWith('.dart')) {
      final name = entry.path.split(Platform.pathSeparator).last;
      buffer.writeln('$prefix$connector$name');
    }
  }
}

/// Печатает список модулей с описаниями
void _printModules(Directory dir, StringBuffer buffer) {
  final modules = <String, String>{};

  // Сканируем lib/ и извлекаем doc-комментарии из первых строк файлов
  _scanModules(dir, modules);

  if (modules.isEmpty) {
    buffer.writeln('_Модули ещё не созданы._');
    return;
  }

  final sortedKeys = modules.keys.toList()..sort();

  for (final path in sortedKeys) {
    final description = modules[path] ?? 'Описание отсутствует';
    buffer.writeln('- **`$path`** — $description');
  }

  buffer.writeln();
}

/// Сканирует директорию и извлекает первый doc-комментарий из файлов
void _scanModules(Directory dir, Map<String, String> modules) {
  final entries = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));

  for (final entry in entries) {
    if (entry is Directory) {
      final name = entry.path.split(Platform.pathSeparator).last;
      if (name.startsWith('.')) continue;
      _scanModules(entry, modules);
    } else if (entry is File && entry.path.endsWith('.dart')) {
      final relativePath = entry.path.replaceFirst('lib/', '');
      final description = _extractDescription(entry);
      modules[relativePath] = description;
    }
  }
}

/// Извлекает первый doc-комментарий из файла (строки начинающиеся с ///)
String _extractDescription(File file) {
  try {
    final lines = file.readAsLinesSync();
    final docLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('///')) {
        docLines.add(trimmed.replaceFirst('///', '').trim());
      } else if (docLines.isNotEmpty) {
        // Первый не-doc комментарий — останавливаемся
        break;
      }
    }

    if (docLines.isEmpty) {
      return 'Описание отсутствует';
    }

    return docLines.join(' ').replaceAll('  ', ' ').trim();
  } catch (e) {
    return 'Ошибка чтения файла';
  }
}
