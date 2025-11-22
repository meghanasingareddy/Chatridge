# Build and Test Instructions

## Quick Build Commands

### Android APK
```bash
flutter clean
flutter pub get
flutter build apk --release
```
**Output**: `build/app/outputs/flutter-apk/app-release.apk`

### Windows Executable
```bash
flutter clean
flutter pub get
flutter build windows --release
```
**Output**: `build/windows/runner/Release/chatridge.exe`

### Build Both (Windows)
```bash
build_all.bat
```

## Testing Checklist

### Before Building
- [ ] Flutter is installed and in PATH
- [ ] Android SDK is installed (for APK)
- [ ] Visual Studio with C++ tools installed (for Windows)
- [ ] Run `flutter doctor` to check setup

### Mobile Testing (Android)
1. **ESP32 Network Testing**
   - [ ] Connect to ESP32 WiFi (Chatridge/12345678)
   - [ ] Register username and device
   - [ ] Send text message
   - [ ] Upload image from gallery
   - [ ] Upload file from storage
   - [ ] Download image
   - [ ] Download file
   - [ ] Open document
   - [ ] Share image
   - [ ] Share file

2. **Normal Internet Testing (Cloud Fallback)**
   - [ ] Connect to normal WiFi (not ESP32)
   - [ ] Register username and device
   - [ ] Send text message
   - [ ] Upload image from gallery (should use cloud)
   - [ ] Upload file from storage (should use cloud)
   - [ ] Download image (from cloud URL)
   - [ ] Download file (from cloud URL)
   - [ ] Open document (from cloud URL)
   - [ ] Share image (from cloud URL)
   - [ ] Share file (from cloud URL)

### Windows Testing
1. **ESP32 Network Testing**
   - [ ] Connect to ESP32 WiFi manually
   - [ ] Launch app
   - [ ] Register username and device
   - [ ] Send text message
   - [ ] Upload image
   - [ ] Upload file
   - [ ] Download image
   - [ ] Download file
   - [ ] Open document
   - [ ] Share image
   - [ ] Share file

2. **Normal Internet Testing (Cloud Fallback)**
   - [ ] Connect to normal internet
   - [ ] Launch app
   - [ ] Register username and device
   - [ ] Send text message
   - [ ] Upload image (should use cloud)
   - [ ] Upload file (should use cloud)
   - [ ] Download image (from cloud URL)
   - [ ] Download file (from cloud URL)
   - [ ] Open document (from cloud URL)
   - [ ] Share image (from cloud URL)
   - [ ] Share file (from cloud URL)

## Troubleshooting

### Build Issues

**Flutter not found**
```bash
# Add Flutter to PATH or use full path
# Example: C:\src\flutter\bin\flutter build apk --release
```

**Android build fails**
```bash
cd android
gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk --release
```

**Windows build fails**
```bash
flutter clean
flutter pub get
flutter build windows --release
```

### Runtime Issues

**File upload fails on ESP32**
- Check ESP32 is powered and connected
- Verify WiFi connection to Chatridge network
- Check ESP32 Serial Monitor for errors
- Verify file size is under 10MB

**File upload fails on cloud**
- Check internet connection
- Verify file size is under service limit (512MB)
- Check if cloud service is accessible

**File download fails**
- Check if URL is valid (ESP32 or cloud)
- Verify file still exists on server/cloud
- Check internet/WiFi connection
- Try re-uploading the file

## Features to Test

### Core Features
- ✅ Text messaging
- ✅ Private messaging
- ✅ Device discovery
- ✅ File upload (ESP32)
- ✅ File upload (Cloud fallback)
- ✅ Image upload (ESP32)
- ✅ Image upload (Cloud fallback)
- ✅ File download (ESP32)
- ✅ File download (Cloud)
- ✅ Image viewing
- ✅ Document opening
- ✅ File sharing
- ✅ Image sharing

### Edge Cases
- Large files (>5MB)
- Files with special characters in names
- Files with spaces in names
- Multiple file types (images, PDFs, documents)
- Network switching (ESP32 to internet)
- Network disconnection during upload
- Network disconnection during download

## Performance Testing

- Upload speed on ESP32 network
- Upload speed on cloud (normal internet)
- Download speed on ESP32 network
- Download speed on cloud
- App startup time
- Message polling performance
- File opening speed

## Known Issues

1. **Cloud Service Limitations**
   - Files may expire after some time (service-dependent)
   - No permanent storage guarantee
   - Public URLs (anyone with link can access)

2. **ESP32 Limitations**
   - Limited storage space (SPIFFS)
   - Slower upload/download speeds
   - Requires WiFi connection

## Success Criteria

✅ All file operations work on ESP32 network
✅ All file operations work on normal internet (cloud fallback)
✅ No UI changes visible to user
✅ Backward compatible with existing messages
✅ No crashes or errors during normal use
✅ Files download and open correctly
✅ Sharing works on both platforms

