# BlueBridge ESP32 Setup Guide

## 🚨 CRITICAL: Hardware Requirements

### Required Components:
1. **ESP32 Development Board** (ESP32-WROOM-32 or similar)
2. **USB Cable** (USB-A to Micro-USB or USB-C depending on your ESP32)
3. **LED** (optional, for status indication)
4. **Resistor** 220Ω (optional, for LED)
5. **Breadboard and jumper wires** (optional, for LED connection)

## 📋 Step 1: Install Arduino IDE

1. Download Arduino IDE from: https://www.arduino.cc/en/software
2. Install the ESP32 board package:
   - Open Arduino IDE
   - Go to File → Preferences
   - Add this URL to "Additional Boards Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to Tools → Board → Boards Manager
   - Search for "ESP32" and install "esp32 by Espressif Systems"

## 📋 Step 2: Hardware Setup (Optional LED)

If you want status LEDs (recommended for debugging):

```
ESP32 Pin  →  Component
GPIO 2     →  LED (Built-in LED, usually blue)
GPIO 4     →  External Status LED (through 220Ω resistor to ground)
GND        →  LED cathode (negative)
```

## 📋 Step 3: Flash the Firmware

1. **Connect ESP32** to your computer via USB
2. **Open Arduino IDE**
3. **Copy the firmware code** from `firmware/bluebridge_hub.ino` 
4. **Select Board**: Tools → Board → ESP32 Dev Module
5. **Select Port**: Tools → Port → (select your ESP32's COM port)
6. **Upload**: Click the Upload button (→)

### Firmware Code Location:
```
Project 3/Chatridge/firmware/bluebridge_hub.ino
```

## 📋 Step 4: Verify Operation

After flashing:

1. **Open Serial Monitor** (Tools → Serial Monitor)
2. **Set baud rate** to 115200
3. **Reset ESP32** (press EN button)
4. **Look for output**:
   ```
   [BLUEBRIDGE] BlueBridge Hub v1.0 Starting...
   [BLUETOOTH] Initializing Bluetooth...
   [BLUETOOTH] Hub ready as 'BlueBridge-Hub-XXXX'
   [STATUS] Ready for connections
   ```

## 📋 Step 5: Test Connection

1. **Enable Bluetooth** on your Android device
2. **Open BlueBridge app**
3. **Look for "BlueBridge-Hub-XXXX"** in device list
4. **Connect** and start messaging

## 🔧 Troubleshooting

### ESP32 Not Detected:
- Install ESP32 drivers: https://www.silabs.com/developers/usb-to-uart-bridge-vcp-drivers
- Try different USB cable
- Press and hold BOOT button while connecting

### Upload Errors:
- Check board selection (ESP32 Dev Module)
- Verify correct port selection
- Try pressing BOOT button during upload
- Reduce upload speed: Tools → Upload Speed → 115200

### Bluetooth Issues:
- Ensure ESP32 has Bluetooth capability (not ESP32-S2)
- Check power supply (use powered USB hub if needed)
- Verify firmware uploaded successfully

### Serial Monitor Issues:
- Set correct baud rate (115200)
- Check if ESP32 is properly reset after upload
- Try different USB cable/port

## 🎯 Expected Behavior

### Status LEDs:
- **Solid Blue**: ESP32 powered on
- **Blinking**: Waiting for connections
- **Solid**: Device connected

### Serial Output:
```
[BLUEBRIDGE] BlueBridge Hub v1.0 Starting...
[BLUETOOTH] Initializing Bluetooth...
[BLUETOOTH] Hub ready as 'BlueBridge-Hub-1234'
[STATUS] Ready for connections
[CONNECTION] Device connected: XX:XX:XX:XX:XX:XX
[MESSAGE] Relaying: Hello from Android!
```

## 📱 App Testing Workflow

1. **Flash ESP32** with BlueBridge firmware
2. **Run Android app** on emulator or device
3. **Enable Bluetooth** and location permissions
4. **Scan for devices** in BlueBridge app
5. **Connect to ESP32 hub**
6. **Send test messages**
7. **Verify message relay** in Serial Monitor

## 🚀 Next Steps

Once both ESP32 and Android are working:
- Test multi-device connections
- Verify message broadcasting
- Test offline message storage
- Experiment with mesh networking (multiple ESP32s)

## 📞 Support

If you encounter issues:
1. Check Serial Monitor output
2. Verify hardware connections
3. Ensure correct board/port selection
4. Try different ESP32 board if available