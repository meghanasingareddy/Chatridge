# Chatridge Build Instructions

This guide explains how to build APK files for Android and release builds for all platforms.

## Prerequisites

1. **Flutter SDK**: Install Flutter from [flutter.dev](https://flutter.dev)
2. **Android Studio**: For Android builds
3. **Xcode** (macOS only): For iOS builds
4. **Visual Studio** (Windows): For Windows desktop builds
5. **Xcode Command Line Tools** (macOS): For macOS builds

## Building Android APK

### Release APK (for distribution)

```bash
# Build release APK
flutter build apk --release

# APK will be located at:
# build/app/outputs/flutter-apk/app-release.apk
```

### Split APKs by ABI (smaller size)

```bash
# Build split APKs (one per architecture)
flutter build apk --split-per-abi

# APKs will be located at:
# build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk (32-bit)
# build/app/outputs/flutter-apk/app-arm64-v8a-release.apk (64-bit)
# build/app/outputs/flutter-apk/app-x86_64-release.apk (Intel)
```

### App Bundle (for Google Play Store)

```bash
# Build App Bundle for Play Store
flutter build appbundle

# Bundle will be located at:
# build/app/outputs/bundle/release/app-release.aab
```

### Install APK on Device

```bash
# Connect Android device via USB and enable USB debugging
# Then install the APK:
flutter install

# Or manually:
adb install build/app/outputs/flutter-apk/app-release.apk
```

## Building iOS App

### Requirements
- macOS with Xcode installed
- Apple Developer account (for device testing and App Store)

```bash
# Build iOS release
flutter build ios --release

# For App Store distribution
flutter build ipa

# IPA will be located at:
# build/ios/ipa/chatridge.ipa
```

## Building Windows Desktop

```bash
# Build Windows release
flutter build windows --release

# Executable will be located at:
# build/windows/runner/Release/chatridge.exe
```

## Building macOS Desktop

```bash
# Build macOS release
flutter build macos --release

# App bundle will be located at:
# build/macos/Build/Products/Release/chatridge.app
```

## Building Linux Desktop

```bash
# Build Linux release
flutter build linux --release

# Executables will be located at:
# build/linux/x64/release/bundle/
```

## Building Web Version

```bash
# Build web release
flutter build web --release

# Web files will be located at:
# build/web/
```

### Deploy Web Version

You can serve the web build using any web server:

```bash
# Using Python
cd build/web
python -m http.server 8000

# Then access at http://localhost:8000
```

## Release Checklist

Before building for release:

- [ ] Update version in `pubspec.yaml`
- [ ] Update app icon and splash screen
- [ ] Test on target platforms
- [ ] Review and update permissions in platform-specific configs
- [ ] Check Android signing configuration (for Play Store)
- [ ] Test file upload/download functionality
- [ ] Test URL link opening
- [ ] Verify WiFi connection functionality

## Android Signing Configuration

For Play Store releases, configure signing in `android/app/build.gradle.kts`:

```kotlin
android {
    signingConfigs {
        create("release") {
            storeFile = file("path/to/keystore.jks")
            storePassword = System.getenv("KEYSTORE_PASSWORD")
            keyAlias = System.getenv("KEY_ALIAS")
            keyPassword = System.getenv("KEY_PASSWORD")
        }
    }
    buildTypes {
        getByName("release") {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}
```

## Building All Platforms

You can build for all platforms using scripts:

### Windows (PowerShell)
```powershell
# Build all platforms
flutter build apk --release
flutter build windows --release
flutter build web --release
```

### macOS/Linux
```bash
# Build all platforms
flutter build apk --release
flutter build ios --release  # macOS only
flutter build macos --release  # macOS only
flutter build linux --release
flutter build web --release
```

## Troubleshooting

### Android Build Issues

1. **Gradle errors**: 
   ```bash
   cd android
   ./gradlew clean
   cd ..
   flutter clean
   flutter pub get
   flutter build apk --release
   ```

2. **SDK version issues**: Update `android/app/build.gradle.kts` with correct min/max SDK versions

### iOS Build Issues

1. **Code signing**: Ensure you have valid signing certificates in Xcode
2. **Pod issues**:
   ```bash
   cd ios
   pod deintegrate
   pod install
   cd ..
   ```

### General Issues

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter pub upgrade
flutter build [platform] --release
```

## Distribution

### Android APK Distribution

1. **Direct Install**: Share the APK file directly
2. **Google Play Store**: Upload the `.aab` bundle
3. **Other Stores**: Upload the APK file

### iOS Distribution

1. **TestFlight**: Upload `.ipa` via Xcode or App Store Connect
2. **App Store**: Submit via App Store Connect

### Desktop Distribution

1. **Windows**: Share the `.exe` file or create an installer
2. **macOS**: Share the `.app` bundle or create a DMG
3. **Linux**: Share the release bundle or create a package (.deb, .rpm)

## Web Interface Alternative

If users don't have the app installed, they can access Chatridge via web browser:

1. Connect to ESP32 WiFi network "Chatridge" (password: 12345678)
2. Open browser and navigate to: `http://192.168.4.1`
3. Use the web interface (no installation needed)

The web interface is automatically served by the ESP32 and works on any device with a web browser (laptop, mobile, tablet).

## Additional Notes

- The ESP32 serves a web interface at `http://192.168.4.1` (or `http://chatridge.local` if mDNS is enabled)
- Users can use either the native app or the web interface
- Web interface requires no installation and works immediately
- All features (messaging, file sharing, URLs) work in both app and web interface


