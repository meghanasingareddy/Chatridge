# MicroSD Card Migration - App Code Analysis

## Current Implementation

### ESP32 (Current - SPIFFS)
- Files stored in SPIFFS using paths like `/image.jpg`
- Upload endpoint `/upload` returns: `{"status":"ok","url":"/image.jpg"}`
- Files served via `handleFileGet()` which reads from SPIFFS

### Flutter App (Current)
- Uploads files via multipart POST to `/upload`
- Receives URL from upload response (e.g., `/image.jpg`)
- Constructs full URL: `http://192.168.4.1/image.jpg`
- Downloads/displays files using this URL

## App Code Compatibility

✅ **GOOD NEWS: No app code changes required** for basic microSD migration!

The app code is already **storage-agnostic** - it doesn't care where ESP32 stores files. As long as:
1. Upload endpoint returns a URL (e.g., `/filename.jpg`)
2. Files are accessible via GET request to that URL
3. Same URL format is maintained

The app will continue to work.

## What ESP32 Code Should Maintain

### 1. Upload Response Format
The app expects this format from `/upload` endpoint:
```json
{"status":"ok","url":"/filename.jpg"}
```

The app tries multiple fields: `url`, `filename`, `file_url`, `attachment_url` (in `api_service.dart:226-229`)

### 2. File Serving
Files must be accessible via GET request to the URL returned from upload.

Current implementation: `handleFileGet()` serves files from SPIFFS

With microSD: Same handler, but read from SD card instead:
```cpp
// Instead of: File f = SPIFFS.open(path, FILE_READ);
// Use: File f = SD.open(path, FILE_READ);
```

### 3. File Paths
Keep the same path format: `/filename.jpg` (leading slash)

## Potential Considerations

### 1. Error Handling
If SD card fails to initialize or write, ESP32 should return proper error responses:
- `400` for invalid requests
- `500` for server/storage errors

The app already handles these (see `api_service.dart:263-271`)

### 2. Timeouts
With microSD, file operations might be slightly slower. Current timeouts:
- Upload: 60 seconds (`sendTimeout`)
- Download: 10 seconds (`receiveTimeout`)

These should be sufficient, but can be increased in `constants.dart` if needed.

### 3. File Size Limits
Current limit: 10MB (`Constants.maxFileSizeMB`)

MicroSD allows much larger files. Consider:
- Increasing `maxFileSizeMB` if you want to support larger files
- Or keeping the limit for performance reasons

### 4. Concurrent File Access
If multiple users upload simultaneously, ESP32 code needs to handle:
- Unique filenames (already done: uses original filename)
- Thread-safe file operations
- Proper file locking

## Recommended ESP32 Changes

### Minimal Changes Needed:
```cpp
// In setup()
#include <SD.h>
#include <SPI.h>

void setup() {
  // ... existing WiFi setup ...
  
  // Initialize SD card instead of SPIFFS
  if (!SD.begin()) {
    Serial.println("SD Card initialization failed!");
    // Handle error - maybe fallback to SPIFFS?
    return;
  }
  Serial.println("SD Card initialized.");
}

// In handleFileUpload() - change:
uploadFile = SD.open(filename, FILE_WRITE);  // Instead of SPIFFS.open()

// In handleFileGet() - change:
File f = SD.open(path, FILE_READ);  // Instead of SPIFFS.open(path, FILE_READ)
```

### Optional Enhancements:
1. **Hybrid Storage**: Use SPIFFS for small files, SD for large files
2. **Better Error Messages**: Return more descriptive errors for SD failures
3. **File Management**: Add endpoint to list/delete files
4. **File Size Reporting**: Include file size in upload response

## Testing Checklist

After implementing microSD support on ESP32:

1. ✅ File upload works (images, documents)
2. ✅ Files can be downloaded/viewed in app
3. ✅ Image preview works in message bubbles
4. ✅ Document open/download works
5. ✅ Multiple files can be uploaded
6. ✅ Large files (>5MB) work correctly
7. ✅ Error handling when SD card is removed
8. ✅ File serving works for all users simultaneously

## No App Code Changes Needed

The Flutter app code in these files does **NOT** need changes:
- `lib/services/api_service.dart` - Already handles different response formats
- `lib/services/file_service.dart` - Just picks files, doesn't care about storage
- `lib/providers/chat_provider.dart` - Just passes URLs around
- `lib/widgets/message_item.dart` - Just downloads/displays files via URL
- `lib/utils/constants.dart` - All settings still valid

## Optional App Improvements (Future)

If you want to enhance the app after microSD migration:

1. **Better Error Messages**: Add more specific error messages for storage issues
2. **File Size Limits**: Make configurable or increase for SD card support
3. **Upload Progress**: Already implemented, works fine
4. **File Management UI**: Allow users to view uploaded files list
5. **Storage Usage**: Show how much space is used on SD card

## Summary

**Answer: No app code changes required!**

The app is designed to work with any backend that:
- Accepts file uploads at `/upload`
- Returns a URL in the response
- Serves files via GET requests to that URL

As long as your ESP32 microSD implementation maintains these interfaces, the app will work seamlessly.


