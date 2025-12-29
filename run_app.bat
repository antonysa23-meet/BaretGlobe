@echo off
REM Quick start script for Baret Scholars Globe app
REM This script makes it easy to run the app without typing long commands

echo ========================================
echo Baret Scholars Globe - Quick Start
echo ========================================
echo.

REM Set Flutter path
set FLUTTER_PATH=D:\Antony\Downloads\flutter\bin\flutter

echo Checking Flutter installation...
%FLUTTER_PATH% --version
echo.

echo Available devices:
%FLUTTER_PATH% devices
echo.

echo Choose how to run the app:
echo 1. Chrome (Web - Quick, no setup needed)
echo 2. Windows Desktop
echo 3. Android Emulator (requires Android Studio)
echo 4. Check dependencies (flutter doctor)
echo 5. Get packages (flutter pub get)
echo.

set /p choice="Enter your choice (1-5): "

if "%choice%"=="1" (
    echo.
    echo Starting app in Chrome...
    cd /d "D:\Antony\Downloads\Baret\baret_scholars_globe"
    %FLUTTER_PATH% run -d chrome
) else if "%choice%"=="2" (
    echo.
    echo Starting app on Windows Desktop...
    cd /d "D:\Antony\Downloads\Baret\baret_scholars_globe"
    %FLUTTER_PATH% run -d windows
) else if "%choice%"=="3" (
    echo.
    echo Listing available emulators...
    %FLUTTER_PATH% emulators
    echo.
    set /p emu="Enter emulator ID to start: "
    %FLUTTER_PATH% emulators --launch %emu%
    timeout /t 10
    cd /d "D:\Antony\Downloads\Baret\baret_scholars_globe"
    %FLUTTER_PATH% run
) else if "%choice%"=="4" (
    echo.
    echo Running flutter doctor...
    %FLUTTER_PATH% doctor -v
) else if "%choice%"=="5" (
    echo.
    echo Getting packages...
    cd /d "D:\Antony\Downloads\Baret\baret_scholars_globe"
    %FLUTTER_PATH% pub get
) else (
    echo Invalid choice. Please run the script again.
)

echo.
pause
