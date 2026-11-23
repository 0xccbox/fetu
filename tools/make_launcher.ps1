# ============================================================================
#  Генератор лаунчера сборки (run_app.bat)
# ----------------------------------------------------------------------------
#  Зачем нужен этот скрипт:
#
#  Файлы .bat для cmd.exe НЕЛЬЗЯ сохранять в UTF-8. cmd.exe читает батник
#  побайтово в OEM-кодировке системы (для русской Windows это CP866) и при
#  этом отслеживает позицию в файле. Два классических источника поломок:
#
#   1. UTF-8 BOM (байты EF BB BF в начале) - cmd.exe воспринимает их как часть
#      первой команды, из-за чего "@echo off" не срабатывает и весь батник
#      начинает выводить сам себя, а затем ломается парсинг.
#
#   2. Вызов "chcp 65001" внутри батника - смена кодовой страницы ПОСЛЕ того,
#      как cmd уже открыл файл, сбивает его внутренний байтовый указатель.
#      В итоге строки читаются со смещением и появляются ошибки вида
#      "'ho.' is not recognized as an internal or external command".
#
#   3. Переводы строк только LF (Unix) - cmd.exe требует CRLF. На LF он тоже
#      теряет смещение и "съедает" первые символы строк.
#
#  Правильный рецепт: текст храним в удобном UTF-8 (run_app_template.txt),
#  а этот скрипт пересохраняет его в CP866, БЕЗ BOM и С переносами CRLF.
#
#  Использование (из корня проекта или из tools):
#      powershell -ExecutionPolicy Bypass -File tools\make_launcher.ps1
# ============================================================================

$ErrorActionPreference = 'Stop'

# Пути: скрипт лежит в tools/, батник - в корне проекта
$toolsDir   = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectDir = Split-Path -Parent $toolsDir

$templatePath = Join-Path $toolsDir 'run_app_template.txt'
$outputPath   = Join-Path $projectDir 'run_app.bat'

if (-not (Test-Path $templatePath)) {
    throw "Не найден шаблон: $templatePath"
}

# 1. Читаем исходник как UTF-8 (шаблон удобно править в любом редакторе)
$text = [System.IO.File]::ReadAllText($templatePath, [System.Text.Encoding]::UTF8)

# 2. Нормализуем переводы строк строго в CRLF
$LF   = [string][char]10
$CRLF = [string][char]13 + [string][char]10
$text = $text.Replace($CRLF, $LF).Replace($LF, $CRLF)

# 3. Пишем в CP866 (OEM-кодировка русской Windows).
#    GetEncoding(866) не добавляет BOM - это ровно то, что нужно для .bat
$cp866 = [System.Text.Encoding]::GetEncoding(866)
[System.IO.File]::WriteAllText($outputPath, $text, $cp866)

# 4. Самопроверка результата, чтобы регрессия не ушла незамеченной
$bytes = [System.IO.File]::ReadAllBytes($outputPath)

$hasBom      = ($bytes.Length -ge 3 -and $bytes[0] -eq 239 -and $bytes[1] -eq 187 -and $bytes[2] -eq 191)
$crCount     = @($bytes | Where-Object { $_ -eq 13 }).Count
$lfCount     = @($bytes | Where-Object { $_ -eq 10 }).Count
$decoded     = [System.IO.File]::ReadAllText($outputPath, $cp866)
$hasChcp     = $decoded.Contains('chcp')

$failed = $false
if ($hasBom)              { Write-Host '  [ОШИБКА] Обнаружен UTF-8 BOM' -ForegroundColor Red;    $failed = $true }
if ($crCount -ne $lfCount) { Write-Host '  [ОШИБКА] Переводы строк не CRLF' -ForegroundColor Red; $failed = $true }
if ($hasChcp)             { Write-Host '  [ОШИБКА] В батнике есть chcp' -ForegroundColor Red;    $failed = $true }
if (-not $decoded.Contains('СБОРКА И ЗАПУСК')) {
    Write-Host '  [ОШИБКА] Кириллица не читается в CP866' -ForegroundColor Red
    $failed = $true
}

if ($failed) { throw 'Сгенерированный run_app.bat не прошёл самопроверку' }

Write-Host ''
Write-Host '  run_app.bat успешно сгенерирован:' -ForegroundColor Green
Write-Host "    путь        : $outputPath"
Write-Host "    кодировка   : CP866 (без BOM)"
Write-Host "    переводы    : CRLF ($crCount строк)"
Write-Host "    размер      : $($bytes.Length) байт"
Write-Host ''
