# Chatridge Release Changelog

## Version 1.0.0+1 (Latest Build)

### ✨ New Features

#### Theme Toggle
- **Location:** Settings → Appearance → Theme
- **Options:**
  - System Default (initial) - Follows device theme automatically
  - Light Theme - Always use light theme
  - Dark Theme - Always use dark theme
- **Persistence:** Theme preference is saved and persists across app restarts
- **Implementation:** New ThemeProvider with system-level integration

#### Enhanced Settings
- **Storage Information:** Shows message count and device count
- **Clear Message History:** Removes local messages (ESP32 data remains)
- **Clear Local Cache:** Clears cache and re-fetches from ESP32
- **Clear All Data:** Complete data wipe and logout

### 🐛 Bug Fixes

#### File Upload
- ✅ Fixed Windows file path handling (backslash support)
- ✅ Improved cross-platform file upload compatibility
- ✅ Better error messages for file upload failures
- ✅ Fixed file upload from laptop/desktop

#### Message Duplication
- ✅ Enhanced deduplication logic
- ✅ Immediate UI updates to prevent duplicate display
- ✅ Better message ID matching

#### Navigation
- ✅ Back button now goes to Conversations screen (not login)
- ✅ Proper navigation flow maintained
- ✅ Conversations screen shows all previous chats

### 🎨 UI Improvements

- ✅ Enhanced dark mode support across all screens
- ✅ Better theme-aware colors
- ✅ Improved conversation list with cards
- ✅ Better visual indicators for unread messages
- ✅ Enhanced input area with theme support
- ✅ Improved empty state messages

### 📱 Platform Support

- ✅ **Android APK:** Fully functional with all features
- ✅ **Windows Release:** Complete desktop support
- ✅ **Cross-Platform:** Mobile ↔ Desktop communication works
- ✅ **File Sharing:** Works between all platforms

### 🔧 Technical Improvements

#### ESP32 Compatibility
- ✅ Full CORS support for cross-platform communication
- ✅ Enhanced error handling
- ✅ Better file type detection
- ✅ Improved JSON escaping for special characters

#### Code Quality
- ✅ New ThemeProvider for theme management
- ✅ Enhanced StorageService with theme persistence
- ✅ Better error handling throughout
- ✅ Improved code organization

### 📦 Build Information

**Android APK:**
- Location: `build/app/outputs/flutter-apk/app-release.apk`
- Size: ~49 MB
- Includes all features and fixes

**Windows Release:**
- Location: `build/windows/x64/runner/Release/`
- Executable: `chatridge.exe`
- Includes all required DLLs and resources

### 🚀 ESP32 Code

**File:** `ESP32_CHATRIDGE_FINAL.ino`

**Features:**
- Full CORS support
- Cross-platform file upload
- Message persistence (200 messages)
- Device tracking (50 devices)
- SPIFFS file storage

**Compatibility:**
- ✅ Mobile ↔ Mobile
- ✅ Desktop ↔ Desktop  
- ✅ Mobile ↔ Desktop

### 📝 Upgrade Notes

1. **ESP32:** Upload `ESP32_CHATRIDGE_FINAL.ino` to your ESP32
2. **Android:** Install new APK (uninstall old version first)
3. **Windows:** Replace old executable with new one
4. **Theme:** Default is System Default; change in Settings if needed

### 🔄 Migration

- All existing data is compatible
- Theme preference will default to System Default on first launch
- No data loss during upgrade
- Settings are preserved

---

## Previous Features (Still Included)

- ✅ Offline local WiFi messaging
- ✅ Private and group messaging
- ✅ File and image sharing
- ✅ Device discovery
- ✅ Message history
- ✅ Conversation list
- ✅ Refresh functionality
- ✅ Auto-polling for new messages
- ✅ Customizable polling intervals

