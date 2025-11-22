@echo off
echo ========================================
echo Chatridge - Build All Platforms
echo ========================================
echo.

echo Checking Flutter installation...
where flutter >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Flutter is not in PATH!
    echo Please add Flutter to your PATH or run this from Flutter SDK directory
    echo.
    pause
    exit /b 1
)

echo Flutter found!
echo.

echo ========================================
echo Step 1: Clean and prepare
echo ========================================
flutter clean
flutter pub get
echo.

echo ========================================
echo Step 2: Building Android APK
echo ========================================
flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Android APK build failed!
    pause
    exit /b 1
)
echo.
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.

echo ========================================
echo Step 3: Building Windows Executable
echo ========================================
flutter build windows --release
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Windows build failed!
    pause
    exit /b 1
)
echo.
echo Windows executable location: build\windows\runner\Release\chatridge.exe
echo.

echo ========================================
echo Build Complete!
echo ========================================
echo.
echo Android APK: build\app\outputs\flutter-apk\app-release.apk
echo Windows EXE: build\windows\runner\Release\chatridge.exe
echo.
pause

