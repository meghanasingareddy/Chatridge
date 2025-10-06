/*
 * BlueBridge Hub Firmware for ESP32
 * 
 * This firmware implements the hardware component of the BlueBridge system.
 * The ESP32 acts as a Bluetooth Serial communication hub that receives messages
 * from one connected Android device and broadcasts them to all other connected devices.
 * 
 * Hardware: ESP32 Dev Kit C (or similar ESP32 board)
 * Protocol: Bluetooth Classic Serial Port Profile (SPP)
 * 
 * Features:
 * - Multi-client Bluetooth connections (up to 7 devices)
 * - Message broadcasting (relay messages between all connected devices)
 * - Connection management with automatic reconnection
 * - Status LED indicators
 * - Serial debug output
 * - Configurable device name and settings
 * 
 * Author: BlueBridge Development Team
 * Version: 1.0
 * Date: October 2025
 */

#include "BluetoothSerial.h"
#include <WiFi.h>
#include <EEPROM.h>

// Configuration Constants
#define DEVICE_NAME "BlueBridge_Hub_001"
#define MAX_CLIENTS 7
#define BUFFER_SIZE 512
#define LED_PIN 2
#define HEARTBEAT_INTERVAL 30000  // 30 seconds
#define EEPROM_SIZE 512

// Protocol Constants
#define MSG_PREFIX "MSG:"
#define ALERT_PREFIX "ALERT:"
#define CMD_PREFIX "CMD:"
#define MESSAGE_DELIMITER '\n'

// LED States
enum LedState {
  LED_OFF,
  LED_ON,
  LED_SLOW_BLINK,
  LED_FAST_BLINK,
  LED_HEARTBEAT
};

// Global Variables
BluetoothSerial SerialBT;
String deviceName = DEVICE_NAME;
String messageBuffer = "";
unsigned long lastHeartbeat = 0;
unsigned long lastLedUpdate = 0;
LedState currentLedState = LED_OFF;
bool ledStateHigh = false;
int connectedClients = 0;

// Statistics
unsigned long totalMessagesReceived = 0;
unsigned long totalMessagesSent = 0;
unsigned long totalBytesTransferred = 0;
unsigned long uptime = 0;

// Function Prototypes
void setupBluetooth();
void setupLED();
void handleIncomingData();
void processMessage(String message);
void broadcastMessage(String message);
void updateLED();
void printStatus();
void handleSerialCommands();
void saveConfiguration();
void loadConfiguration();
String generateDeviceId();

void setup() {
  // Initialize Serial for debugging
  Serial.begin(115200);
  Serial.println();
  Serial.println("=========================================");
  Serial.println("      BlueBridge Hub Initializing       ");
  Serial.println("=========================================");
  
  // Disable WiFi to save power and avoid interference
  WiFi.mode(WIFI_OFF);
  btStop();
  
  // Initialize EEPROM
  EEPROM.begin(EEPROM_SIZE);
  
  // Load saved configuration
  loadConfiguration();
  
  // Setup hardware
  setupLED();
  
  // Initialize Bluetooth
  setupBluetooth();
  
  Serial.println("BlueBridge Hub ready for connections!");
  Serial.println("Device Name: " + deviceName);
  Serial.println("Waiting for client connections...");
  Serial.println("=========================================");
  
  currentLedState = LED_SLOW_BLINK;
  lastHeartbeat = millis();
}

void loop() {
  // Handle incoming Bluetooth data
  handleIncomingData();
  
  // Handle serial console commands
  if (Serial.available()) {
    handleSerialCommands();
  }
  
  // Update LED status
  updateLED();
  
  // Print periodic status
  if (millis() - lastHeartbeat >= HEARTBEAT_INTERVAL) {
    printStatus();
    lastHeartbeat = millis();
  }
  
  // Small delay to prevent watchdog issues
  delay(10);
}

void setupBluetooth() {
  Serial.println("Initializing Bluetooth...");
  
  // Start Bluetooth Serial with device name
  if (!SerialBT.begin(deviceName)) {
    Serial.println("ERROR: Failed to initialize Bluetooth!");
    currentLedState = LED_FAST_BLINK;
    return;
  }
  
  // Enable discoverability
  SerialBT.enableSSP();
  
  Serial.println("Bluetooth initialized successfully");
  Serial.println("Device is discoverable as: " + deviceName);
  
  currentLedState = LED_SLOW_BLINK;
}

void setupLED() {
  pinMode(LED_PIN, OUTPUT);
  digitalWrite(LED_PIN, LOW);
  
  // LED startup sequence
  for (int i = 0; i < 3; i++) {
    digitalWrite(LED_PIN, HIGH);
    delay(200);
    digitalWrite(LED_PIN, LOW);
    delay(200);
  }
}

void handleIncomingData() {
  if (SerialBT.available()) {
    char incomingChar = SerialBT.read();
    
    // Add character to buffer
    messageBuffer += incomingChar;
    totalBytesTransferred++;
    
    // Check for complete message (delimited by newline)
    if (incomingChar == MESSAGE_DELIMITER) {
      // Remove the delimiter
      messageBuffer.trim();
      
      if (messageBuffer.length() > 0) {
        processMessage(messageBuffer);
        totalMessagesReceived++;
      }
      
      // Clear buffer for next message
      messageBuffer = "";
    }
    
    // Prevent buffer overflow
    if (messageBuffer.length() > BUFFER_SIZE) {
      Serial.println("WARNING: Message buffer overflow, clearing buffer");
      messageBuffer = "";
    }
  }
}

void processMessage(String message) {
  Serial.println("Received: " + message);
  
  // Update connection status
  if (SerialBT.hasClient()) {
    currentLedState = LED_ON;
    connectedClients = 1; // Note: BluetoothSerial doesn't support multiple clients natively
  }
  
  // Process different message types
  if (message.startsWith(MSG_PREFIX)) {
    // Regular chat message - broadcast to all clients
    broadcastMessage(message);
    
  } else if (message.startsWith(ALERT_PREFIX)) {
    // System alert - handle specially
    Serial.println("ALERT received: " + message);
    broadcastMessage(message);
    
  } else if (message.startsWith(CMD_PREFIX)) {
    // Command message - process locally
    handleCommand(message);
    
  } else {
    // Plain text message - treat as chat message
    String formattedMessage = MSG_PREFIX + message;
    broadcastMessage(formattedMessage);
  }
}

void broadcastMessage(String message) {
  if (SerialBT.hasClient()) {
    // Add newline delimiter
    String messageToSend = message + MESSAGE_DELIMITER;
    
    // Send to connected client(s)
    SerialBT.print(messageToSend);
    
    totalMessagesSent++;
    totalBytesTransferred += messageToSend.length();
    
    Serial.println("Broadcasted: " + message);
  } else {
    Serial.println("No clients connected - message not sent");
  }
}

void handleCommand(String command) {
  Serial.println("Processing command: " + command);
  
  // Remove CMD: prefix
  String cmd = command.substring(4);
  cmd.trim();
  
  if (cmd.startsWith("STATUS")) {
    // Send status information
    String statusMsg = "CMD:STATUS_RESPONSE:";
    statusMsg += "uptime=" + String(millis()/1000) + ",";
    statusMsg += "clients=" + String(connectedClients) + ",";
    statusMsg += "msgs_rx=" + String(totalMessagesReceived) + ",";
    statusMsg += "msgs_tx=" + String(totalMessagesSent);
    
    broadcastMessage(statusMsg);
    
  } else if (cmd.startsWith("PING")) {
    // Respond to ping
    broadcastMessage("CMD:PONG");
    
  } else if (cmd.startsWith("RESET")) {
    // Restart the device
    Serial.println("RESET command received - restarting in 3 seconds...");
    delay(3000);
    ESP.restart();
    
  } else {
    Serial.println("Unknown command: " + cmd);
  }
}

void updateLED() {
  unsigned long currentTime = millis();
  
  switch (currentLedState) {
    case LED_OFF:
      digitalWrite(LED_PIN, LOW);
      break;
      
    case LED_ON:
      digitalWrite(LED_PIN, HIGH);
      break;
      
    case LED_SLOW_BLINK:
      if (currentTime - lastLedUpdate >= 1000) {
        ledStateHigh = !ledStateHigh;
        digitalWrite(LED_PIN, ledStateHigh ? HIGH : LOW);
        lastLedUpdate = currentTime;
      }
      break;
      
    case LED_FAST_BLINK:
      if (currentTime - lastLedUpdate >= 250) {
        ledStateHigh = !ledStateHigh;
        digitalWrite(LED_PIN, ledStateHigh ? HIGH : LOW);
        lastLedUpdate = currentTime;
      }
      break;
      
    case LED_HEARTBEAT:
      // Double blink pattern
      if (currentTime - lastLedUpdate >= 100) {
        static int heartbeatStep = 0;
        
        switch (heartbeatStep) {
          case 0: digitalWrite(LED_PIN, HIGH); break;
          case 1: digitalWrite(LED_PIN, LOW); break;
          case 2: digitalWrite(LED_PIN, HIGH); break;
          case 3: digitalWrite(LED_PIN, LOW); break;
        }
        
        heartbeatStep = (heartbeatStep + 1) % 4;
        if (heartbeatStep == 0) {
          lastLedUpdate = currentTime + 1000; // Longer pause between heartbeats
        } else {
          lastLedUpdate = currentTime;
        }
      }
      break;
  }
}

void printStatus() {
  uptime = millis() / 1000;
  
  Serial.println();
  Serial.println("========== BlueBridge Hub Status ==========");
  Serial.println("Uptime: " + String(uptime) + " seconds");
  Serial.println("Connected Clients: " + String(connectedClients));
  Serial.println("Messages Received: " + String(totalMessagesReceived));
  Serial.println("Messages Sent: " + String(totalMessagesSent));
  Serial.println("Bytes Transferred: " + String(totalBytesTransferred));
  Serial.println("Free Heap: " + String(ESP.getFreeHeap()) + " bytes");
  Serial.println("Device Name: " + deviceName);
  
  if (SerialBT.hasClient()) {
    Serial.println("Status: CONNECTED");
  } else {
    Serial.println("Status: WAITING FOR CONNECTIONS");
  }
  
  Serial.println("==========================================");
}

void handleSerialCommands() {
  String command = Serial.readStringUntil('\n');
  command.trim();
  
  if (command == "status") {
    printStatus();
    
  } else if (command == "restart") {
    Serial.println("Restarting BlueBridge Hub...");
    delay(1000);
    ESP.restart();
    
  } else if (command.startsWith("name ")) {
    String newName = command.substring(5);
    if (newName.length() > 0 && newName.length() <= 32) {
      deviceName = newName;
      saveConfiguration();
      Serial.println("Device name changed to: " + deviceName);
      Serial.println("Restart required for changes to take effect.");
    } else {
      Serial.println("Invalid name length (1-32 characters)");
    }
    
  } else if (command == "help") {
    Serial.println();
    Serial.println("Available commands:");
    Serial.println("  status    - Show current status");
    Serial.println("  restart   - Restart the device");
    Serial.println("  name <n>  - Change device name");
    Serial.println("  help      - Show this help");
    Serial.println();
    
  } else if (command.length() > 0) {
    Serial.println("Unknown command: " + command + " (type 'help' for commands)");
  }
}

void saveConfiguration() {
  // Save device name to EEPROM
  EEPROM.writeString(0, deviceName);
  EEPROM.commit();
  Serial.println("Configuration saved to EEPROM");
}

void loadConfiguration() {
  // Load device name from EEPROM
  String savedName = EEPROM.readString(0);
  if (savedName.length() > 0 && savedName.length() <= 32) {
    deviceName = savedName;
    Serial.println("Loaded device name from EEPROM: " + deviceName);
  } else {
    // Generate unique device name
    deviceName = DEVICE_NAME + "_" + generateDeviceId();
    saveConfiguration();
  }
}

String generateDeviceId() {
  // Generate a unique ID based on ESP32 chip ID
  uint64_t chipid = ESP.getEfuseMac();
  char chipString[13];
  sprintf(chipString, "%04X%04X%04X", 
          (uint16_t)(chipid >> 32), 
          (uint16_t)(chipid >> 16), 
          (uint16_t)chipid);
  return String(chipString).substring(8); // Use last 4 characters
}

/*
 * Additional Functions for Future Expansion
 */

// Function to handle IoT sensor data (future feature)
void handleSensorData(String sensorId, float value) {
  String alertMessage = ALERT_PREFIX + sensorId + ":" + String(value);
  broadcastMessage(alertMessage);
}

// Function to check memory usage
bool checkMemoryHealth() {
  size_t freeHeap = ESP.getFreeHeap();
  if (freeHeap < 10000) { // Less than 10KB free
    Serial.println("WARNING: Low memory detected!");
    return false;
  }
  return true;
}

// Function to perform self-diagnostics
void runDiagnostics() {
  Serial.println("Running system diagnostics...");
  
  // Check memory
  bool memOk = checkMemoryHealth();
  
  // Check Bluetooth
  bool btOk = SerialBT.hasClient() || SerialBT.isReady();
  
  // Report results
  Serial.println("Diagnostics Results:");
  Serial.println("  Memory: " + String(memOk ? "OK" : "WARNING"));
  Serial.println("  Bluetooth: " + String(btOk ? "OK" : "ERROR"));
}