@echo off
setlocal enabledelayedexpansion
title Fetu - Меню сборки

set "JAVA_HOME=C:\Users\79878\jdk17\jdk17.0.21_1"
set "PATH=%JAVA_HOME%\bin;C:\flutter\bin;C:\Users\79878\AppData\Local\Android\Sdk\platform-tools;C:\Users\79878\AppData\Local\Android\Sdk\emulator;%PATH%"

cd /d "%~dp0"

:MENU
cls
echo ========================================================
echo            FETU - СБОРКА И ЗАПУСК
echo ========================================================
echo.
echo   [1] Запустить на Android эмуляторе
echo   [2] Собрать и установить на телефон (USB)
echo   [3] Очистка и запуск на Windows (clean + pub get + run)
echo   [4] Только flutter clean и flutter pub get
echo   [5] Запустить на Windows (без очистки)
echo   [6] Показать подключенные устройства
echo   [0] Выход
echo.
echo ========================================================
set "CHOICE="
set /p "CHOICE=Выберите пункт (0-6) и нажмите Enter: "

if "%CHOICE%"=="1" goto RUN_EMULATOR
if "%CHOICE%"=="2" goto RUN_PHONE
if "%CHOICE%"=="3" goto CLEAN_RUN_WINDOWS
if "%CHOICE%"=="4" goto CLEAN_PUB_GET
if "%CHOICE%"=="5" goto RUN_WINDOWS
if "%CHOICE%"=="6" goto SHOW_DEVICES
if "%CHOICE%"=="0" goto EXIT_SCRIPT

echo.
echo Неверный выбор. Попробуйте еще раз.
timeout /t 2 /nobreak > nul
goto MENU

:RUN_EMULATOR
cls
echo ========================================================
echo   [1] Запуск на Android эмуляторе
echo ========================================================
echo.
call :DETECT_DEVICES

if defined EMU_ID (
    echo Эмулятор уже запущен: !EMU_ID!
    echo.
    echo Собираю и запускаю приложение...
    call flutter run -d !EMU_ID!
    echo.
    pause
    goto MENU
)

set "AVD_NAME="
for /f "delims=" %%a in ('emulator -list-avds 2^>nul') do (
    if not defined AVD_NAME set "AVD_NAME=%%a"
)
if not defined AVD_NAME set "AVD_NAME=Medium_Phone_API_37.0"

echo Запускаю эмулятор: !AVD_NAME!
start "" emulator -avd !AVD_NAME!

echo Жду подключения ADB...
adb wait-for-device

echo Жду полной загрузки Android...
:WAIT_BOOT
timeout /t 3 /nobreak > nul
set "BOOT_STATE=0"
for /f "delims=" %%i in ('adb shell getprop sys.boot_completed 2^>nul') do set "BOOT_STATE=%%i"
if not "!BOOT_STATE!"=="1" (
    echo   ...эмулятор еще грузится...
    goto WAIT_BOOT
)

call :DETECT_DEVICES
echo.
echo Эмулятор готов. Запускаю приложение...
echo.
if defined EMU_ID (
    call flutter run -d !EMU_ID!
) else (
    call flutter run -d android
)
echo.
pause
goto MENU

:RUN_PHONE
cls
echo ========================================================
echo   [2] Сборка и установка на телефон
echo ========================================================
echo.
call :DETECT_DEVICES

if not defined PHONE_ID (
    echo Телефон не найден. Проверьте:
    echo   1. Кабель USB подключен.
    echo   2. Включена "Отладка по USB" в режиме разработчика.
    echo   3. На экране телефона подтвержден запрос на отладку.
    echo.
    echo Текущий список устройств ADB:
    adb devices
    echo.
    pause
    goto MENU
)

echo Найден телефон: !PHONE_ID!
echo.
echo Собираю и устанавливаю приложение...
echo.
call flutter run -d !PHONE_ID!
if errorlevel 1 (
    echo.
    echo [ОШИБКА] Не удалось запустить приложение на телефоне.
)
echo.
pause
goto MENU

:CLEAN_RUN_WINDOWS
cls
echo ========================================================
echo   [3] Очистка и запуск на Windows
echo ========================================================
echo.
echo Шаг 1/3: flutter clean
call flutter clean
echo.
echo Шаг 2/3: flutter pub get
call flutter pub get
echo.
echo Шаг 3/3: flutter run -d windows
echo.
call flutter run -d windows
echo.
pause
goto MENU

:CLEAN_PUB_GET
cls
echo ========================================================
echo   [4] flutter clean и flutter pub get
echo ========================================================
echo.
echo Шаг 1/2: flutter clean
call flutter clean
echo.
echo Шаг 2/2: flutter pub get
call flutter pub get
echo.
echo Готово: проект очищен и зависимости обновлены.
echo.
pause
goto MENU

:RUN_WINDOWS
cls
echo ========================================================
echo   [5] Запуск на Windows (Desktop)
echo ========================================================
echo.
call flutter run -d windows
echo.
pause
goto MENU

:SHOW_DEVICES
cls
echo ========================================================
echo   [6] Подключенные устройства и эмуляторы
echo ========================================================
echo.
echo --- flutter devices ---
call flutter devices
echo.
echo --- flutter emulators ---
call flutter emulators
echo.
echo --- adb devices ---
adb devices
echo.
pause
goto MENU

:EXIT_SCRIPT
exit /b 0

:DETECT_DEVICES
set "EMU_ID="
set "PHONE_ID="
for /f "tokens=1,2" %%a in ('adb devices 2^>nul') do (
    if "%%b"=="device" (
        set "DEV_ID=%%a"
        if "!DEV_ID:~0,9!"=="emulator-" (
            if not defined EMU_ID set "EMU_ID=!DEV_ID!"
        ) else (
            if not defined PHONE_ID set "PHONE_ID=!DEV_ID!"
        )
    )
)
goto :eof
