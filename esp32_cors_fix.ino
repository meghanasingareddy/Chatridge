// Add this function to your ESP32 code to handle CORS
void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

// Update your setup() function to include CORS handling
void setup() {
  Serial.begin(115200);
  
  // Initialize SPIFFS for message storage
  if (!SPIFFS.begin(true)) {
    Serial.println("SPIFFS initialization failed!");
    return;
  }
  Serial.println("SPIFFS initialized");
  
  // Load previous messages
  loadMessages();
  
  // Create Access Point
  WiFi.softAP(ssid, password);
  
  IPAddress myIP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(myIP);
  Serial.println("Chatridge Enhanced v3.0 Ready!");
  
  // Setup server routes
  server.on("/", handleRoot);
  server.on("/send", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/send", handleSendMessage);
  server.on("/messages", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/messages", handleGetMessages);
  server.on("/devices", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/devices", handleGetDevices);
  server.on("/register", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/register", handleRegisterDevice);
  server.on("/upload", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/upload", HTTP_POST, []() {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", "{\"status\":\"ok\"}");
  }, handleFileUpload);
  server.on("/files", HTTP_OPTIONS, handleCORS);  // Add CORS for OPTIONS
  server.on("/files", handleServeFile);
  server.on("/style.css", handleCSS);
  
  server.begin();
  Serial.println("HTTP server started");
}

// Update your existing handler functions to include CORS headers
void handleSendMessage() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  if (server.hasArg("username") && server.hasArg("text") && server.hasArg("target")) {
    String username = server.arg("username");
    String text = server.arg("text");
    String target = server.arg("target");
    
    if (messageCount < MAX_MESSAGES && text.length() > 0) {
      // Create new message with timestamp
      Message newMsg;
      newMsg.username = username;
      newMsg.text = text;
      newMsg.timestamp = getTimestamp();
      newMsg.targetDevice = target;
      
      messages[messageCount] = newMsg;
      messageCount++;
      
      // Save to storage
      saveMessages();
      
      Serial.println("New message from " + username + " to " + target + ": " + text);
    }
  }
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleGetMessages() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  String json = "[";
  for (int i = 0; i < messageCount; i++) {
    if (i > 0) json += ",";
    json += "{";
    json += "\"username\":\"" + escapeJson(messages[i].username) + "\",";
    json += "\"text\":\"" + escapeJson(messages[i].text) + "\",";
    json += "\"timestamp\":\"" + messages[i].timestamp + "\",";
    json += "\"targetDevice\":\"" + escapeJson(messages[i].targetDevice) + "\"";
    json += "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleGetDevices() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  cleanupDevices();
  
  String json = "[";
  for (int i = 0; i < deviceCount; i++) {
    if (i > 0) json += ",";
    json += "{";
    json += "\"name\":\"" + escapeJson(devices[i].deviceName) + "\",";
    json += "\"ip\":\"" + devices[i].ipAddress + "\"";
    json += "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleRegisterDevice() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  if (server.hasArg("name")) {
    String deviceName = server.arg("name");
    String clientIP = server.client().remoteIP().toString();
    
    addOrUpdateDevice(deviceName, clientIP);
    Serial.println("Device registered: " + deviceName + " (" + clientIP + ")");
  }
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleServeFile() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  // For now, return empty array - implement file listing later
  server.send(200, "application/json", "[]");
}


