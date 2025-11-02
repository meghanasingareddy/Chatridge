#include <WiFi.h>
#include <WebServer.h>
#include <SPIFFS.h>

// AP credentials - Change these if needed
const char* ssid = "Chatridge";
const char* password = "12345678";

WebServer server(80);

// Message structure
struct Message {
  String id;
  String username;
  String text;
  String target; // empty for public messages
  unsigned long ts;
  String attachmentUrl;
  String attachmentName;
  String attachmentType;
};

// Device info structure
struct DeviceInfo {
  String name;
  String ip;
  unsigned long lastSeen;
};

// Storage arrays
Message messages[200];
int messageCount = 0;

DeviceInfo devices[50];
int deviceCount = 0;

// File upload state
File uploadFile;
String lastUploadedFileName;

// Generate unique message ID
String genId() {
  return String(millis());
}

// Add or update device info
void addOrUpdateDevice(const String& name, const String& ip) {
  unsigned long now = millis();
  for (int i = 0; i < deviceCount; i++) {
    if (devices[i].name == name) {
      devices[i].ip = ip;
      devices[i].lastSeen = now;
      return;
    }
  }
  if (deviceCount < 50) {
    devices[deviceCount].name = name;
    devices[deviceCount].ip = ip;
    devices[deviceCount].lastSeen = now;
    deviceCount++;
  }
}

// Escape JSON special characters
String escapeJson(const String& str) {
  String escaped = "";
  for (unsigned int i = 0; i < str.length(); i++) {
    char c = str.charAt(i);
    if (c == '"') escaped += "\\\"";
    else if (c == '\\') escaped += "\\\\";
    else if (c == '\n') escaped += "\\n";
    else if (c == '\r') escaped += "\\r";
    else if (c == '\t') escaped += "\\t";
    else escaped += c;
  }
  return escaped;
}

// CORS handler for OPTIONS requests
void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

// Root endpoint
void handleRoot() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", "Chatridge ESP32 Server - Ready");
}

// Register device endpoint
void handleRegister() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String name = server.hasArg("name") ? server.arg("name") : "";
  if (name.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"name required\"}");
    return;
  }
  addOrUpdateDevice(name, server.client().remoteIP().toString());
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

// Get devices endpoint
void handleDevices() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  unsigned long now = millis();
  String json = "[";
  for (int i = 0; i < deviceCount; i++) {
    if (i > 0) json += ",";
    bool isOnline = (now - devices[i].lastSeen) < 15000; // 15 seconds timeout
    json += "{\"name\":\"" + escapeJson(devices[i].name) + "\",";
    json += "\"ip\":\"" + devices[i].ip + "\",";
    json += "\"last_seen\":" + String(devices[i].lastSeen) + ",";
    json += "\"online\":" + String(isOnline ? "true" : "false") + "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

// Get messages endpoint
void handleMessages() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String json = "[";
  for (int i = 0; i < messageCount; i++) {
    if (i > 0) json += ",";
    json += "{\"id\":\"" + escapeJson(messages[i].id) + "\",";
    json += "\"username\":\"" + escapeJson(messages[i].username) + "\",";
    json += "\"text\":\"" + escapeJson(messages[i].text) + "\",";
    if (messages[i].target.length() > 0) {
      json += "\"target\":\"" + escapeJson(messages[i].target) + "\",";
    }
    json += "\"timestamp\":" + String(messages[i].ts);
    if (messages[i].attachmentUrl.length() > 0) {
      json += ",\"attachment_url\":\"" + escapeJson(messages[i].attachmentUrl) + "\",";
      json += "\"attachment_name\":\"" + escapeJson(messages[i].attachmentName) + "\",";
      json += "\"attachment_type\":\"" + escapeJson(messages[i].attachmentType) + "\"";
    }
    json += "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

// Send message endpoint
void handleSend() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String username = server.hasArg("username") ? server.arg("username") : "";
  String text = server.hasArg("text") ? server.arg("text") : "";
  String target = server.hasArg("target") ? server.arg("target") : "";

  if (username.length() == 0 || text.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"username and text required\"}");
    return;
  }

  // Ring buffer: remove oldest message if limit reached
  if (messageCount >= 200) {
    for (int i = 1; i < 200; i++) messages[i - 1] = messages[i];
    messageCount = 199;
  }

  Message m;
  m.id = genId();
  m.username = username;
  m.text = text;
  m.target = target;
  m.ts = millis();
  m.attachmentUrl = "";
  m.attachmentName = "";
  m.attachmentType = "";
  messages[messageCount++] = m;

  // Mark sender device as active
  addOrUpdateDevice(username, server.client().remoteIP().toString());

  // Return success with message ID
  String json = "{\"status\":\"ok\",\"id\":\"" + m.id + "\"}";
  server.send(200, "application/json", json);
}

// File upload handler (called during upload process)
void handleFileUpload() {
  HTTPUpload &upload = server.upload();
  if (upload.status == UPLOAD_FILE_START) {
    String filename = "/" + upload.filename;
    lastUploadedFileName = filename;
    // Remove existing file if it exists
    if (SPIFFS.exists(filename)) {
      SPIFFS.remove(filename);
    }
    uploadFile = SPIFFS.open(filename, FILE_WRITE);
    Serial.println("Upload START: " + filename);
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (uploadFile) {
      uploadFile.write(upload.buf, upload.currentSize);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (uploadFile) {
      uploadFile.close();
      Serial.println("Upload END: " + String(upload.totalSize) + " bytes");
    }
  }
}

// Detect content type from filename
String detectContentType(const String &fname) {
  String f = fname;
  f.toLowerCase();
  if (f.endsWith(".png")) return "image/png";
  if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
  if (f.endsWith(".gif")) return "image/gif";
  if (f.endsWith(".webp")) return "image/webp";
  if (f.endsWith(".pdf")) return "application/pdf";
  if (f.endsWith(".ppt")) return "application/vnd.ms-powerpoint";
  if (f.endsWith(".pptx")) return "application/vnd.openxmlformats-officedocument.presentationml.presentation";
  if (f.endsWith(".doc")) return "application/msword";
  if (f.endsWith(".docx")) return "application/vnd.openxmlformats-officedocument.wordprocessingml.document";
  if (f.endsWith(".xls")) return "application/vnd.ms-excel";
  if (f.endsWith(".xlsx")) return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet";
  if (f.endsWith(".csv")) return "text/csv";
  if (f.endsWith(".txt")) return "text/plain";
  return "application/octet-stream";
}

// Handle upload completion and create message
void handleUploadRespond() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  if (lastUploadedFileName.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"no file uploaded\"}");
    return;
  }

  String url = lastUploadedFileName; // e.g. /image.jpg
  String fname = lastUploadedFileName.substring(1); // strip leading '/'
  String ctype = detectContentType(lastUploadedFileName);

  // Create message for file attachment
  if (messageCount >= 200) {
    for (int i = 1; i < 200; i++) messages[i - 1] = messages[i];
    messageCount = 199;
  }
  
  Message m;
  m.id = genId();
  m.username = server.hasArg("username") ? server.arg("username") : "Unknown";
  m.text = "Shared a file";
  m.target = server.hasArg("target") ? server.arg("target") : "";
  m.ts = millis();
  m.attachmentUrl = url;
  m.attachmentName = fname;
  m.attachmentType = ctype;
  messages[messageCount++] = m;

  // Mark sender device as active
  addOrUpdateDevice(m.username, server.client().remoteIP().toString());

  // Return success with file URL
  String json = "{\"status\":\"ok\",\"url\":\"" + url + "\"}";
  server.send(200, "application/json", json);
}

// Serve uploaded files
void handleFileGet() {
  String path = server.uri();
  if (path == "/") {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(404, "text/plain", "Not found");
    return;
  }
  if (!SPIFFS.exists(path)) {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(404, "text/plain", "File not found");
    return;
  }
  File f = SPIFFS.open(path, FILE_READ);
  if (!f) {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(500, "text/plain", "Error opening file");
    return;
  }
  String ct = detectContentType(path);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Content-Type", ct);
  server.streamFile(f, ct);
  f.close();
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n=== Chatridge ESP32 Server ===");
  
  // Initialize SPIFFS filesystem for file storage
  if (!SPIFFS.begin(true)) {
    Serial.println("SPIFFS initialization failed!");
    return;
  }
  Serial.println("SPIFFS initialized successfully");
  
  // Create Access Point
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);
  
  IPAddress IP = WiFi.softAPIP();
  Serial.print("AP IP address: ");
  Serial.println(IP);
  Serial.print("SSID: ");
  Serial.println(ssid);
  Serial.println("Server starting...");
  
  // Enable CORS for cross-platform support
  server.enableCORS(true);
  
  // Setup routes with CORS support
  server.on("/", HTTP_GET, handleRoot);
  server.on("/", HTTP_OPTIONS, handleCORS);
  
  server.on("/register", HTTP_GET, handleRegister);
  server.on("/register", HTTP_OPTIONS, handleCORS);
  
  server.on("/devices", HTTP_GET, handleDevices);
  server.on("/devices", HTTP_OPTIONS, handleCORS);
  
  server.on("/messages", HTTP_GET, handleMessages);
  server.on("/messages", HTTP_OPTIONS, handleCORS);
  
  server.on("/send", HTTP_GET, handleSend);
  server.on("/send", HTTP_OPTIONS, handleCORS);
  
  server.on("/upload", HTTP_POST, handleUploadRespond, handleFileUpload);
  server.on("/upload", HTTP_OPTIONS, handleCORS);
  
  // Serve files (catch-all for file requests)
  server.onNotFound(handleFileGet);
  
  server.begin();
  Serial.println("HTTP server started on port 80");
  Serial.println("Chatridge server ready!");
  Serial.println("Connect devices to WiFi: " + String(ssid));
  Serial.println("Password: " + String(password));
}

void loop() {
  server.handleClient();
}

