# ESP32 Storage Information

## Current Storage Configuration

### SPIFFS (SPI Flash File System)

The ESP32 uses **SPIFFS** for file storage, which is part of the ESP32's flash memory.

#### Storage Capacity

**Typical ESP32 Models:**
- **ESP32 (4MB Flash)**: ~1.5-3MB available for SPIFFS
- **ESP32 (8MB Flash)**: ~3-6MB available for SPIFFS  
- **ESP32 (16MB Flash)**: ~6-12MB available for SPIFFS

**Current Partition Scheme (Recommended):**
```
- App Code: 2MB
- SPIFFS: 2MB
- Total: 4MB Flash
```

#### Actual Available Storage

**Current Setup:**
- **SPIFFS Size**: 2MB (default partition scheme)
- **Usable Space**: ~1.9MB (after filesystem overhead)
- **Recommended File Size Limit**: 10MB per file (enforced in app)
- **Practical Limit**: Files are limited by available SPIFFS space

#### Storage Breakdown

| Item | Size Limit | Notes |
|------|-----------|-------|
| **SPIFFS Total** | 2MB | Depends on partition scheme |
| **Individual File** | 10MB max | App limit (larger than SPIFFS) |
| **Total Files** | Limited by 2MB | Sum of all files |
| **Messages** | 200 | In RAM (not stored in SPIFFS) |
| **Devices** | 50 | In RAM (not stored in SPIFFS) |

### Current Limits in Code

```cpp
// Messages: In-memory array
Message messages[200];  // ~50KB RAM

// Devices: In-memory array  
DeviceInfo devices[50];  // ~2KB RAM

// Files: SPIFFS storage
// Limited by partition size (typically 2MB)
```

```dart
// Flutter App Limit
static const int maxFileSizeMB = 10;  // Per file
```

## How to Check Available Storage

### Via Serial Monitor

Add this to your ESP32 code to check storage:

```cpp
void checkStorage() {
  size_t totalBytes = SPIFFS.totalBytes();
  size_t usedBytes = SPIFFS.usedBytes();
  size_t freeBytes = totalBytes - usedBytes;
  
  Serial.println("=== Storage Info ===");
  Serial.printf("Total: %d bytes (%.2f MB)\n", totalBytes, totalBytes / 1024.0 / 1024.0);
  Serial.printf("Used: %d bytes (%.2f MB)\n", usedBytes, usedBytes / 1024.0 / 1024.0);
  Serial.printf("Free: %d bytes (%.2f MB)\n", freeBytes, freeBytes / 1024.0 / 1024.0);
}
```

### Via API Endpoint (Optional)

You could add an endpoint to check storage:

```cpp
void handleStorageInfo() {
  size_t totalBytes = SPIFFS.totalBytes();
  size_t usedBytes = SPIFFS.usedBytes();
  size_t freeBytes = totalBytes - usedBytes;
  
  String json = "{";
  json += "\"total_bytes\":" + String(totalBytes) + ",";
  json += "\"used_bytes\":" + String(usedBytes) + ",";
  json += "\"free_bytes\":" + String(freeBytes);
  json += "}";
  
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "application/json", json);
}
```

## Increasing Storage

### Option 1: Change Partition Scheme (More SPIFFS)

In Arduino IDE:
1. Tools → Partition Scheme
2. Select: **"No OTA (2MB APP/2MB SPIFFS)"** ← Current
3. Or: **"Huge APP (3MB No OTA/1MB SPIFFS)"** (less SPIFFS)
4. Or: **"Minimal SPIFFS (1.9MB APP with OTA/190KB SPIFFS)"** (minimal SPIFFS)

**Better Options:**
- Custom partition scheme (create your own)
- Use 8MB or 16MB ESP32 for more storage

### Option 2: Use External Storage (SD Card)

See `MICROSD_MIGRATION_NOTES.md` for SD card support:
- **Capacity**: Up to 32GB+ (typical SD card)
- **Advantages**: Much more storage, removable
- **Disadvantages**: Requires hardware modification

### Option 3: Use ESP32 with More Flash

- **ESP32-S2** (4-8MB flash)
- **ESP32-S3** (4-8MB flash)
- **ESP32 with 8MB/16MB flash** (custom boards)

## Practical Usage Recommendations

### For Current Setup (2MB SPIFFS):

**Recommended File Sizes:**
- Images: < 500KB each
- PDFs: < 1MB each
- Documents: < 500KB each
- **Total storage**: Keep under 1.5MB for safety

**Number of Files:**
- Small images (100KB): ~15-20 files
- Medium images (500KB): ~3-4 files
- Documents (1MB): ~1-2 files

### Storage Management

**Current Behavior:**
- Old files are **NOT automatically deleted**
- Files accumulate until SPIFFS is full
- When full, new uploads will fail

**Recommendations:**
1. Monitor storage usage
2. Manually delete old files when needed
3. Or implement auto-cleanup (delete oldest files)

## Storage Status

**Current Configuration:**
- ✅ **SPIFFS Size**: 2MB (default partition)
- ✅ **File Size Limit**: 10MB (app limit, but SPIFFS is smaller)
- ⚠️ **Actual Limit**: Limited by available SPIFFS space (~1.9MB total)
- ⚠️ **No Auto-Cleanup**: Files persist until manually deleted or ESP32 reset

## Summary

**Maximum Storage:**
- **Total SPIFFS**: ~2MB (current partition scheme)
- **Per File**: 10MB (app limit, but files can't exceed available SPIFFS)
- **Practical**: ~1.5-1.9MB usable after overhead

**For More Storage:**
1. Change partition scheme (more SPIFFS, less app space)
2. Use ESP32 with larger flash memory (8MB/16MB)
3. Add external SD card (see migration notes)

**Current Status:**
- Works well for small files (images, small documents)
- Limited for large files or many files
- Suitable for temporary/local network use


