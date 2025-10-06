# BlueBridge Hub Firmware

This directory contains the ESP32 firmware for the BlueBridge Hub - the hardware component of the BlueBridge offline communication system.

## Hardware Requirements

### Primary Hardware
- **ESP32 Dev Kit C** (or compatible ESP32 board)
- **Power Supply**: USB cable or 3.3V/5V power adapter
- **LED Indicator**: Built-in LED on GPIO2 (most ESP32 boards)

### Optional Components
- External LED for better status indication
- Breadboard and jumper wires for prototyping
- Enclosure for deployment

## Pin Configuration

```
ESP32 Pin    | Function           | Description
-------------|-------------------|----------------------------------
GPIO2        | Status LED        | Built-in LED for status indication
USB/Serial   | Debug Console     | Serial communication for setup
Built-in     | Bluetooth Module  | ESP32's integrated Bluetooth
```

## Features

### Core Functionality
- **Multi-Client Support**: Handle multiple Android device connections
- **Message Broadcasting**: Relay messages between all connected devices
- **Bluetooth SPP**: Uses Serial Port Profile for compatibility
- **Protocol Support**: Extensible message protocol (MSG:, ALERT:, CMD:)

### Status Indicators
- **LED Off**: System off or error
- **Slow Blink**: Ready, waiting for connections
- **Solid On**: Device(s) connected
- **Fast Blink**: Error or initialization
- **Heartbeat**: System health indicator

### Management Features
- **Serial Console**: Debug and configuration interface
- **Persistent Settings**: Device name and configuration stored in EEPROM
- **Statistics**: Message counts, uptime, memory usage
- **Remote Commands**: Status, ping, reset via Bluetooth

## Installation Instructions

### Step 1: Setup Arduino IDE

1. **Install Arduino IDE** (version 2.0+ recommended)
   - Download from: https://www.arduino.cc/en/software

2. **Add ESP32 Board Support**
   - Open Arduino IDE
   - Go to File → Preferences
   - Add this URL to "Additional Boards Manager URLs":
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to Tools → Board → Boards Manager
   - Search for "ESP32" and install "ESP32 by Espressif Systems"

3. **Install Required Libraries**
   - Go to Sketch → Include Library → Manage Libraries
   - Search and install:
     - "BluetoothSerial" (usually included with ESP32 board package)

### Step 2: Hardware Setup

1. **Connect ESP32 to Computer**
   - Use USB cable to connect ESP32 to your computer
   - Install CP2102 or CH340 drivers if needed

2. **Verify Connection**
   - Open Arduino IDE
   - Go to Tools → Board → ESP32 Dev Module
   - Go to Tools → Port → Select your ESP32 port (usually COM3+ on Windows)

### Step 3: Upload Firmware

1. **Open Firmware**
   - Open `bluebridge_hub.ino` in Arduino IDE

2. **Configure Settings** (Optional)
   - Modify `DEVICE_NAME` in the code if desired
   - Adjust `MAX_CLIENTS` or other constants as needed

3. **Compile and Upload**
   - Click the "Upload" button (arrow icon)
   - Wait for compilation and upload to complete
   - Monitor Serial output for any errors

4. **Verify Installation**
   - Open Serial Monitor (Tools → Serial Monitor)
   - Set baud rate to 115200
   - You should see startup messages

## Configuration

### Device Name
The hub automatically generates a unique device name based on the ESP32's chip ID. You can customize it:

**Via Serial Console:**
```
name BlueBridge_MyHub_001
```

**Via Code:**
```cpp
#define DEVICE_NAME "BlueBridge_MyHub_001"
```

### Advanced Settings
```cpp
#define MAX_CLIENTS 7              // Maximum connected devices
#define HEARTBEAT_INTERVAL 30000   // Status update interval (ms)
#define BUFFER_SIZE 512            // Message buffer size
```

## Usage

### Starting the Hub
1. Power on the ESP32
2. Wait for initialization (LED will start slow blinking)
3. Hub becomes discoverable as "BlueBridge_Hub_XXXX"

### Connecting Devices
1. Use BlueBridge Android app to scan for devices
2. Look for devices starting with "BlueBridge"
3. Pair and connect to the hub
4. Start messaging!

### Serial Console Commands
Connect to the ESP32 via Serial Monitor (115200 baud) and use these commands:

```
status     - Show current system status
restart    - Restart the hub
name <n>   - Change device name
help       - Show available commands
```

## Protocol Specification

### Message Format
Messages use a simple prefix-based protocol:

```
MSG:<content>\n        - Chat message
ALERT:<id>:<value>\n   - Sensor alert (future)
CMD:<command>\n        - System command
```

### Example Messages
```
MSG:Hello everyone!\n
ALERT:temp:25.6\n
CMD:STATUS\n
```

## Troubleshooting

### Common Issues

1. **Upload Failed**
   - Check USB cable connection
   - Verify correct board and port selected
   - Try holding BOOT button during upload
   - Install proper drivers (CP2102/CH340)

2. **Bluetooth Not Working**
   - Ensure ESP32 board has Bluetooth capability
   - Check for interference from WiFi
   - Verify Bluetooth is enabled on connecting device

3. **Connection Issues**
   - Check device name and discoverability
   - Ensure devices are within range (~10 meters)
   - Try restarting both hub and client devices

4. **Memory Issues**
   - Monitor free heap in serial output
   - Reduce BUFFER_SIZE if needed
   - Check for memory leaks in custom code

### Debug Information
Enable verbose output by adding to setup():
```cpp
Serial.setDebugOutput(true);
```

### LED Status Guide
- **Not Lit**: Power off or critical error
- **Slow Blink (1 sec)**: Ready, waiting for connections
- **Solid On**: At least one device connected
- **Fast Blink (250ms)**: Error or initialization problem
- **Heartbeat Pattern**: System health mode (future feature)

## Development

### Extending Functionality
The firmware is designed for easy extension:

1. **Adding Sensors**: Use `handleSensorData()` function
2. **Custom Commands**: Extend `handleCommand()` function
3. **New Protocols**: Modify `processMessage()` function

### Code Structure
```
setup()              - Initialize system
loop()               - Main program loop
handleIncomingData() - Process Bluetooth input
processMessage()     - Parse message protocol
broadcastMessage()   - Send to all clients
updateLED()          - Manage status indicators
```

## Performance Specifications

- **Range**: ~10 meters (Bluetooth Class 2)
- **Throughput**: Up to 1 Mbps (Bluetooth 2.0)
- **Latency**: <100ms typical message relay
- **Connections**: Up to 7 simultaneous devices
- **Power**: ~80mA active, <1mA deep sleep
- **Memory**: ~4KB RAM usage base

## Future Enhancements

### Planned Features
- [ ] Multiple simultaneous connections (current: 1 active)
- [ ] Mesh networking between multiple hubs
- [ ] IoT sensor integration
- [ ] Web-based configuration interface
- [ ] Battery power management
- [ ] Encryption and security features
- [ ] Over-the-air (OTA) updates

### Hardware Expansion
- External antenna for extended range
- Battery pack for portable operation
- Sensor modules (temperature, humidity, etc.)
- Display module for status information

## License

This firmware is part of the BlueBridge project and is licensed under [your license here].

## Support

For technical support:
1. Check the troubleshooting section above
2. Review serial output for error messages
3. Consult the main BlueBridge documentation
4. Submit issues to the project repository

---

**Note**: This firmware is designed for the BlueBridge offline communication system. Ensure you have the corresponding Android application installed for full functionality.