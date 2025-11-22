@echo off
echo Building Chatridge APK...
echo.

flutter clean
flutter pub get
flutter build apk --release

echo.
echo APK build complete!
echo APK location: build\app\outputs\flutter-apk\app-release.apk
echo.
pause

