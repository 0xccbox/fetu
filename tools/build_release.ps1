# ============================================================================
# Релизная сборка Fetu (ФАЗА 10, hardening).
#
# AGENTS.md, правило 33: релизная сборка компилируется с обфускацией
# Flutter (--obfuscate --split-debug-info) и, после интеграции libbox
# (ФАЗА 6), Go-часть собирается через garble.
#
# Правило 24: store-сборка — только arm64-v8a (минимальный размер APK).
#
# Использование (PowerShell, из корня проекта):
#   ./tools/build_release.ps1            # сборка + obfuscate
#   ./tools/build_release.ps1 -Universal # все ABI (для тестов на эмуляторах)
# ============================================================================
param(
    # Собирать universal APK (все ABI) вместо только arm64-v8a.
    [switch]$Universal
)

$ErrorActionPreference = 'Stop'

# Конфигурация обфускации (правило 12: константы, не magic numbers).
$SymbolsDir = 'build/symbols'
$TargetPlatforms = if ($Universal) { 'android-arm,android-arm64,android-x64' } else { 'android-arm64' }

Write-Host '==> Проверка flutter analyze (0 issues — обязательное условие)...' -ForegroundColor Cyan
flutter analyze
if ($LASTEXITCODE -ne 0) {
    Write-Host '❌ flutter analyze упал — релизная сборка отменена.' -ForegroundColor Red
    exit 1
}

Write-Host '==> Запуск тестов (все зелёные — обязательное условие)...' -ForegroundColor Cyan
flutter test
if ($LASTEXITCODE -ne 0) {
    Write-Host '❌ flutter test упал — релизная сборка отменена.' -ForegroundColor Red
    exit 1
}

Write-Host '==> Релизная сборка APK с обфускацией...' -ForegroundColor Cyan
Write-Host "    target-platform: $TargetPlatforms"
Write-Host "    split-debug-info: $SymbolsDir (хранить для декодирования стектрейсов!)"

flutter build apk --release `
    --obfuscate `
    --split-debug-info=$SymbolsDir `
    --target-platform $TargetPlatforms

if ($LASTEXITCODE -ne 0) {
    Write-Host '❌ Сборка не удалась.' -ForegroundColor Red
    exit 1
}

Write-Host ''
Write-Host '✅ Релизная сборка готова: build/app/outputs/flutter-apk/' -ForegroundColor Green
Write-Host ''
Write-Host 'ВАЖНО (ФАЗА 10, hardening):' -ForegroundColor Yellow
Write-Host '  1. Символы отладки сохранены в build/symbols — не публиковать,' -ForegroundColor Yellow
Write-Host '     но хранить для декодирования крашей (symbolize).'
Write-Host '  2. Конфиг sing-box передаётся в ядро только в памяти' -ForegroundColor Yellow
Write-Host '     (Platform Channel -> Intent extra, без config.json на диске).'
Write-Host '  3. После интеграции libbox (ФАЗА 6): собирать Go-часть через garble:'
Write-Host '       gomobile bind -target=android -garble ...'
Write-Host '     (garble обфусцирует Go-символы в libbox.aar).'
Write-Host '  4. Подпись релиза настроить в android/key.properties' -ForegroundColor Yellow
Write-Host '     (сейчас release подписан debug-ключом — для store нужен свой).'
