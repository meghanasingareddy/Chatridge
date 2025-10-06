# BlueBridge Quick Start Guide

This guide will help you set up and test the BlueBridge system in its current state.

## Current Implementation Status

✅ **Working Features:**
- ESP32 BlueBridge Hub firmware
- Android app with Bluetooth discovery
- Device pairing and connection
- Real-time chat interface
- Message sending and receiving
- Connection status monitoring

⚠️ **Limitations:**
- Currently supports 1 active Android connection per hub
- Multiple device broadcasting requires firmware enhancement

## Hardware Setup

### 1. Prepare ESP32
```bash
# Required: ESP32 Dev Kit C or compatible
# Required: Arduino IDE with ESP32 support
# Required: USB cable
```

### 2. Flash Firmware
1. Open Arduino IDE
2. Install ESP32 board support (File → Preferences → Board Manager URLs):
   ```
   https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
   ```
3. Open `firmware/bluebridge_hub.ino`
4. Select Board: "ESP32 Dev Module"
5. Select correct Port
6. Click Upload

### 3. Verify Hub Operation
1. Open Serial Monitor (115200 baud)
2. You should see:
   ```
   =========================================
         BlueBridge Hub Initializing       
   =========================================
   Bluetooth initialized successfully
   Device is discoverable as: BlueBridge_Hub_XXXX
   BlueBridge Hub ready for connections!
   ```
3. LED should be slowly blinking (ready state)

## Android App Setup

### 1. Install Dependencies
```bash
cd Chatridge
flutter pub get
```

### 2. Run on Android Device
```bash
# Connect Android device via USB
flutter run
```

### 3. Grant Permissions
- Allow Bluetooth permissions when prompted
- Allow Location permissions (required for Bluetooth scanning)

## Testing the System

### Step 1: Device Discovery
1. Open BlueBridge app on Android
2. App should show "BlueBridge" as title
3. Tap "Discovery" tab if not already selected
4. Pull down to refresh or tap refresh icon
5. Your ESP32 should appear as "BlueBridge_Hub_XXXX"

### Step 2: Connection
1. Tap on your BlueBridge Hub device
2. Tap "Connect Device" in the device details sheet
3. Complete Bluetooth pairing if prompted
4. You should see "Connected to BlueBridge_Hub_XXXX" notification
5. ESP32 LED should change to solid on

### Step 3: Chat Testing
1. Tap "Open Chat" in success notification, or
2. Navigate back and tap notification action, or  
3. Use navigation to go to chat interface
4. You should see "BlueBridge Chat" interface
5. Type a test message and hit send
6. Message should appear in chat with "sent" status

### Step 4: Echo Test (Current Firmware)
Current firmware echoes messages back to sender:
1. Send message: "Hello BlueBridge!"  
2. You should receive back: "MSG:Hello BlueBridge!"
3. This confirms bidirectional communication works

## Troubleshooting

### ESP32 Issues
**LED not blinking:**
- Check power connection
- Verify firmware upload successful
- Open Serial Monitor for error messages

**Device not discoverable:**
- Restart ESP32
- Check Serial Monitor for Bluetooth initialization errors
- Ensure no other devices are blocking Bluetooth

**Upload failed:**
- Hold BOOT button during upload
- Check USB cable and port selection
- Install CP2102 or CH340 drivers if needed

### Android App Issues
**No devices found:**
- Ensure Bluetooth is enabled on phone
- Grant location permissions
- Try refresh/rescan
- Check ESP32 is discoverable (LED blinking)

**Connection failed:**
- Restart both devices
- Clear Bluetooth cache: Settings → Apps → Bluetooth → Storage → Clear Cache
- Try forgetting and re-pairing device

**App crashes:**
- Check flutter doctor for setup issues
- Run `flutter clean && flutter pub get`
- Enable USB debugging and check logs

### Connection Issues
**Connected but no messages:**
- Check Serial Monitor for incoming data on ESP32
- Verify message appears in ESP32 log
- Restart both devices and reconnect

**Messages not appearing:**
- Check connection status in app
- Look for error messages in chat interface
- Verify ESP32 is echoing messages (Serial Monitor)

## Serial Console Commands

Connect to ESP32 via Serial Monitor and try these commands:

```bash
status          # Show system status
restart         # Restart the hub
name NewName    # Change device name (restart required)
help           # Show available commands
```

## Expected Behavior

### Normal Operation Flow:
1. ESP32 powers on → LED slow blink → Serial shows "ready"
2. Android scans → Finds "BlueBridge_Hub_XXXX"
3. Android connects → LED solid on → Serial shows "client connected"
4. Send message → ESP32 receives → Serial shows message → ESP32 echoes back
5. Android receives echo → Displays in chat interface

### Status Indicators:
- **ESP32 LED Off**: Power off or error
- **ESP32 LED Slow Blink**: Ready, waiting for connections
- **ESP32 LED Solid On**: Device connected
- **ESP32 LED Fast Blink**: Error state

- **Android Connection Green**: Connected to hub
- **Android Connection Orange**: Connecting/reconnecting
- **Android Connection Red**: Disconnected/error

## Next Development Steps

To implement true multi-device broadcasting:

1. **Modify ESP32 Firmware** to support multiple BLE connections
2. **Test with Multiple Devices** connecting simultaneously  
3. **Verify Message Broadcasting** to all connected devices
4. **Optimize Performance** for target 2-second message delivery

## Getting Help

1. **Check Serial Output**: ESP32 Serial Monitor shows detailed logs
2. **Review Error Messages**: Both app and ESP32 provide error details
3. **Hardware Check**: Verify ESP32 power, connections, and LED status
4. **Software Check**: Ensure permissions granted and Bluetooth enabled

---

**Note**: This system is designed for testing and development. For production use, additional security and optimization features should be implemented.