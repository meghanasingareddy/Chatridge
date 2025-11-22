# Release Build Notes

## Build Completed Successfully ✅

### Android APK
**Location:** `build/app/outputs/flutter-apk/app-release.apk`  
**Size:** ~49.1 MB  
**Status:** ✅ Built successfully

### Windows Release
**Location:** `build/windows/x64/runner/Release/chatridge.exe`  
**Status:** ✅ Built successfully

## Features Verified ✅

### File Sharing
- ✅ **File Upload:** Works on both mobile and desktop
- ✅ **Image Sharing:** Camera, gallery, and file picker supported
- ✅ **Cross-Platform:** Windows paths handled correctly
- ✅ **File Persistence:** Files stored on ESP32 SPIFFS, accessible via `/files` endpoint

### Message Persistence
- ✅ **Server Storage:** Messages stored on ESP32 (up to 200 messages in memory)
- ✅ **File Messages:** File attachments stored on ESP32 and accessible when device reconnects
- ✅ **Offline Support:** When device connects later, it automatically fetches all messages from server
- ✅ **Auto-Polling:** Configurable polling interval (2-10 seconds) to check for new messages

### Memory Management
- ✅ **Storage Info:** Shows message and device count in Settings
- ✅ **Clear Message History:** Clears local cache only (messages remain on ESP32)
- ✅ **Clear Local Cache:** Clears local data, then re-fetches from ESP32 server
- ✅ **Clear All Data:** Clears everything including user registration

## Settings Enhancements

The Settings screen now includes:

1. **Storage Information**
   - Shows count of messages stored locally
   - Shows count of known devices

2. **Clear Message History**
   - Removes all messages from local device storage
   - Messages remain on ESP32 server

3. **Clear Local Cache** (NEW)
   - Clears all cached messages and devices
   - Automatically re-fetches data from ESP32 server

4. **Clear All Data**
   - Permanently deletes all local data
   - Logs user out and requires re-registration

## How It Works

### File Sharing Flow:
1. User selects file/image from device
2. File uploaded to ESP32 via `/upload` endpoint
3. File stored in ESP32 SPIFFS filesystem
4. Message created with file attachment URL
5. Message stored on ESP32 (in memory, up to 200 messages)
6. All connected devices see the file message
7. Files served via `/files/{filename}` endpoint

### Offline Device Reconnection:
1. Device connects to Chatridge WiFi
2. App automatically calls `fetchMessages()` via polling
3. ESP32 returns all stored messages (including file messages)
4. App merges with local cache and displays
5. Files remain accessible via ESP32 file server

### Memory Management:
- **Local Storage (Device):** Hive database stores messages locally for offline viewing
- **Server Storage (ESP32):** 
  - Messages: In-memory array (200 message limit, ring buffer)
  - Files: SPIFFS filesystem (limited by ESP32 flash memory)
- **Clear Options:** Various levels of clearing available in Settings

## Current Implementation

- **Storage:** ESP32 internal SPIFFS (no SD card)
- **Message Limit:** 200 messages on ESP32 (ring buffer)
- **File Storage:** ESP32 SPIFFS filesystem
- **Persistence:** Messages persist until ESP32 restart (in-memory)
- **Future:** SD card support can be added later

## Installation

### Android
1. Transfer `app-release.apk` to your Android device
2. Enable "Install from unknown sources" in Android settings
3. Install the APK

### Windows
1. Navigate to `build/windows/x64/runner/Release/`
2. Run `chatridge.exe`
3. All required DLLs are included in the Release folder

## Testing Checklist

Before distribution, verify:
- [x] File upload works from mobile
- [x] File upload works from Windows
- [x] Images can be sent and received
- [x] Messages persist on ESP32
- [x] Offline devices can see messages after connecting
- [x] Files remain accessible after device reconnection
- [x] Clear memory options work correctly
- [x] App icon displays correctly on all platforms
- [x] Dark mode works properly
- [x] Navigation flows correctly

## Notes

- Messages are stored in ESP32 RAM (volatile) - will be lost on ESP32 restart
- For persistent storage, consider SD card migration (see `MICROSD_MIGRATION_NOTES.md`)
- Current setup works well for temporary/local networks
- File size limit: 10MB (configurable in `Constants.maxFileSizeMB`)

