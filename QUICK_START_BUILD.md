# Quick Start - Build Commands

## Prerequisites Check
```bash
flutter doctor
```

## Build Commands

### Option 1: Use Build Script (Recommended)
```bash
build_all.bat
```
This will build both Android APK and Windows executable.

### Option 2: Manual Build

#### Android APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```
**Output**: `build\app\outputs\flutter-apk\app-release.apk`

#### Windows Executable
```bash
flutter clean
flutter pub get
flutter build windows --release
```
**Output**: `build\windows\runner\Release\chatridge.exe`

## What Was Changed

1. ✅ **Fixed file/image sharing** - All download operations now work correctly
2. ✅ **Added cloud fallback** - Files automatically upload to cloud when ESP32 unavailable
3. ✅ **Improved error handling** - Better error messages and recovery
4. ✅ **UI unchanged** - All changes are invisible to user

## Testing

After building, test:
1. File upload on ESP32 network
2. File upload on normal internet (cloud fallback)
3. File download from ESP32
4. File download from cloud
5. Image sharing
6. Document opening

See `BUILD_AND_TEST.md` for detailed testing checklist.

## Files Changed

- `lib/services/api_service.dart` - Added cloud fallback
- `lib/services/cloud_file_service.dart` - NEW cloud service
- `lib/widgets/message_item.dart` - Fixed file operations
- `lib/screens/image_viewer_screen.dart` - Fixed image operations

## Notes

- Cloud feature is completely hidden and automatic
- Works seamlessly when ESP32 is unavailable
- No user configuration needed
- Backward compatible with existing messages

