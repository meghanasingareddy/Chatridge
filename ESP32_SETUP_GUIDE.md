# ESP32 Setup Guide for Chatridge

## ESP32 Code File

Use the file: **`ESP32_CHATRIDGE_FINAL.ino`**

This code is designed to work seamlessly with:
- ✅ Mobile devices (Android/iOS)
- ✅ Desktop devices (Windows/Mac/Linux)
- ✅ Cross-platform communication (mobile ↔ desktop)

## Features Included

### 1. CORS Support (Cross-Origin Resource Sharing)
- Enables communication between different platforms
- Works with web browsers, mobile apps, and desktop apps
- All endpoints include CORS headers

### 2. File Upload Support
- Stores files in ESP32 SPIFFS filesystem
- Supports images (PNG, JPG, GIF, WEBP)
- Supports documents (PDF, DOC, XLS, PPT, TXT, CSV)
- Creates message entries for file attachments
- Files accessible via `/filename` URLs

### 3. Message Storage
- In-memory storage (up to 200 messages)
- Ring buffer: oldest messages removed when limit reached
- Supports private messages (with target) and public messages
- Timestamp tracking

### 4. Device Management
- Tracks up to 50 devices
- Online/offline status (15-second timeout)
- IP address tracking
- Last seen timestamp

## Upload Instructions

1. **Open Arduino IDE**
2. **Install ESP32 Board Support:**
   - Go to File → Preferences
   - Add to Additional Board Manager URLs: `https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json`
   - Go to Tools → Board → Boards Manager
   - Search for "ESP32" and install "esp32 by Espressif Systems"

3. **Install Required Libraries:**
   - WiFi (built-in)
   - WebServer (built-in)
   - SPIFFS (built-in)

4. **Configure Board:**
   - Tools → Board → ESP32 Arduino → Your ESP32 board
   - Tools → Port → Select your ESP32 port
   - Tools → Partition Scheme → "No OTA (2MB APP/2MB SPIFFS)" or "Default 4MB with spiffs"

5. **Upload Code:**
   - Open `ESP32_CHATRIDGE_FINAL.ino`
   - Click Upload button
   - Wait for "Done uploading" message

6. **Verify:**
   - Open Serial Monitor (115200 baud)
   - You should see:
     ```
     === Chatridge ESP32 Server ===
     SPIFFS initialized successfully
     AP IP address: 192.168.4.1
     SSID: Chatridge
     HTTP server started on port 80
     Chatridge server ready!
     ```

## Network Configuration

**Default Settings:**
- **SSID:** `Chatridge`
- **Password:** `12345678`
- **IP Address:** `192.168.4.1`

**To Change:**
Edit these lines in the `.ino` file:
```cpp
const char* ssid = "Chatridge";
const char* password = "12345678";
```

## API Endpoints

All endpoints support CORS and work across all platforms:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | Server status |
| `/register` | GET | Register device (requires `name` parameter) |
| `/devices` | GET | Get list of all devices |
| `/messages` | GET | Get all messages |
| `/send` | GET | Send message (requires `username`, `text`, optional `target`) |
| `/upload` | POST | Upload file (multipart/form-data) |
| `/{filename}` | GET | Download uploaded file |

## Testing

1. **Connect to WiFi:**
   - Search for "Chatridge" network on your device
   - Enter password: `12345678`

2. **Test Server:**
   - Open browser: `http://192.168.4.1`
   - Should see: "Chatridge ESP32 Server - Ready"

3. **Test from App:**
   - Open Chatridge app
   - Register with username and device name
   - Start sending messages!

## Troubleshooting

**Serial Monitor shows errors:**
- Check ESP32 board selection
- Ensure correct COM port selected
- Verify SPIFFS partition scheme

**Can't connect to WiFi:**
- Check SSID and password
- Ensure ESP32 is powered properly
- Try resetting ESP32

**Files not uploading:**
- Check SPIFFS partition size (need at least 1.5MB)
- Verify file size is under limit
- Check Serial Monitor for upload errors

**Messages not appearing:**
- Check Serial Monitor for errors
- Verify device is connected to Chatridge WiFi
- Try refreshing the app

## Storage Limits

- **Messages:** 200 messages maximum (ring buffer)
- **Devices:** 50 devices maximum
- **Files:** Limited by SPIFFS partition size (typically 1.5-3MB)
- **File Size:** Recommended max 10MB per file

## Next Steps

After uploading the ESP32 code:
1. Connect your mobile/desktop to "Chatridge" WiFi
2. Open Chatridge app
3. Register and start chatting!

## Cross-Platform Compatibility

✅ **Tested and working:**
- Android ↔ Android
- Windows ↔ Windows  
- Android ↔ Windows
- iOS ↔ Android (should work)
- iOS ↔ Windows (should work)
- Mobile ↔ Desktop (all combinations)

The CORS headers ensure all platforms can communicate with the ESP32 server.

