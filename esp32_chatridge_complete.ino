#include <WiFi.h>
#include <WebServer.h>
#include <SPIFFS.h>

// AP credentials
const char* ssid = "Chatridge";
const char* password = "12345678";

WebServer server(80);

// Simple in-memory storage
struct Message {
  String id;
  String username;
  String text;
  String target; // empty for public
  unsigned long ts;
  String attachmentUrl;
  String attachmentName;
  String attachmentType;
};

struct DeviceInfo {
  String name;
  String ip;
  unsigned long lastSeen;
};

Message messages[200];
int messageCount = 0;

DeviceInfo devices[50];
int deviceCount = 0;

// Upload state
File uploadFile;
String lastUploadedFileName;

String genId() {
  return String(millis());
}

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

// CORS handler
void handleCORS() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  server.send(200, "text/plain", "");
}

void handleRoot() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(200, "text/plain", "Chatridge ESP32 Server");
}

void handleRegister() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String name = server.hasArg("name") ? server.arg("name") : "";
  if (name.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"name required\"}");
    return;
  }
  addOrUpdateDevice(name, server.client().remoteIP().toString());
  Serial.println("Device registered: " + name + " (" + server.client().remoteIP().toString() + ")");
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleDevices() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  unsigned long now = millis();
  String json = "[";
  for (int i = 0; i < deviceCount; i++) {
    if (i > 0) json += ",";
    bool isOnline = (now - devices[i].lastSeen) < 15000; // 15s
    json += "{\"name\":\"" + devices[i].name + "\",";
    json += "\"ip\":\"" + devices[i].ip + "\",";
    json += "\"last_seen\":" + String(devices[i].lastSeen) + ",";
    json += "\"online\":" + String(isOnline ? "true" : "false") + "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleMessages() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String json = "[";
  for (int i = 0; i < messageCount; i++) {
    if (i > 0) json += ",";
    json += "{\"id\":\"" + messages[i].id + "\",";
    json += "\"username\":\"" + escapeJson(messages[i].username) + "\",";
    json += "\"text\":\"" + escapeJson(messages[i].text) + "\",";
    if (messages[i].target.length() > 0) {
      json += "\"target\":\"" + escapeJson(messages[i].target) + "\",";
    }
    json += "\"timestamp\":" + String(messages[i].ts);
    if (messages[i].attachmentUrl.length() > 0) {
      json += ",\"attachment_url\":\"" + messages[i].attachmentUrl + "\",";
      json += "\"attachment_name\":\"" + escapeJson(messages[i].attachmentName) + "\",";
      json += "\"attachment_type\":\"" + messages[i].attachmentType + "\"";
    }
    json += "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleSend() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String username = server.hasArg("username") ? server.arg("username") : "";
  String text = server.hasArg("text") ? server.arg("text") : "";
  String target = server.hasArg("target") ? server.arg("target") : "";

  if (username.length() == 0 || text.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"username and text required\"}");
    return;
  }

  if (messageCount >= 200) {
    // simple ring buffer
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

  // Mark sender device active
  addOrUpdateDevice(username, server.client().remoteIP().toString());

  Serial.println("Message from " + username + ": " + text);

  // Echo response
  String json = "{\"status\":\"ok\",\"id\":\"" + m.id + "\"}";
  server.send(200, "application/json", json);
}

// ===== Upload handlers =====
void handleFileUpload() {
  HTTPUpload &upload = server.upload();
  if (upload.status == UPLOAD_FILE_START) {
    String filename = "/" + upload.filename;
    lastUploadedFileName = filename;
    Serial.println("File upload started: " + filename);
    
    // Delete existing file if it exists
    if (SPIFFS.exists(filename)) {
      SPIFFS.remove(filename);
      Serial.println("Deleted existing file: " + filename);
    }
    
    uploadFile = SPIFFS.open(filename, FILE_WRITE);
    if (!uploadFile) {
      Serial.println("Failed to create file: " + filename);
      return;
    }
    Serial.println("File opened for writing: " + filename);
    
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (uploadFile) {
      size_t bytesWritten = uploadFile.write(upload.buf, upload.currentSize);
      if (bytesWritten != upload.currentSize) {
        Serial.println("Write error: expected " + String(upload.currentSize) + " bytes, wrote " + String(bytesWritten));
      }
    }
    
  } else if (upload.status == UPLOAD_FILE_END) {
    if (uploadFile) {
      uploadFile.close();
      Serial.println("File upload completed: " + lastUploadedFileName + " (" + String(upload.totalSize) + " bytes)");
    } else {
      Serial.println("File upload failed: file not open");
      lastUploadedFileName = "";
    }
  }
}

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
  if (f.endsWith(".rtf")) return "application/rtf";
  return "application/octet-stream";
}

void handleUploadRespond() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  // Build response and also append a message so others see the attachment
  if (lastUploadedFileName.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"no file uploaded\"}");
    return;
  }

  String url = lastUploadedFileName; // e.g. /image.jpg
  String fname = lastUploadedFileName.substring(1); // strip leading '/'
  String ctype = detectContentType(lastUploadedFileName);

  // Append a message representing this file upload
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

  addOrUpdateDevice(m.username, server.client().remoteIP().toString());

  Serial.println("File shared by " + m.username + ": " + fname);

  String json = String("{\"status\":\"ok\",\"url\":\"") + url + "\"}";
  server.send(200, "application/json", json);
}

// Serve uploaded files
void handleFileGet() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  String path = server.uri();
  
  if (path == "/") { 
    server.send(404, "text/plain", "Not found"); 
    return; 
  }
  
  if (!SPIFFS.exists(path)) { 
    Serial.println("File not found: " + path);
    server.send(404, "text/plain", "Not found"); 
    return; 
  }
  
  File f = SPIFFS.open(path, FILE_READ);
  if (!f) {
    Serial.println("Failed to open file: " + path);
    server.send(500, "text/plain", "Server error");
    return;
  }
  
  String ct = detectContentType(path);
  server.sendHeader("Content-Type", ct);
  server.streamFile(f, ct);
  f.close();
  Serial.println("Served file: " + path);
}

// Helper function to escape JSON strings
String escapeJson(String input) {
  String output = "";
  for (unsigned int i = 0; i < input.length(); i++) {
    char c = input.charAt(i);
    if (c == '"') {
      output += "\\\"";
    } else if (c == '\\') {
      output += "\\\\";
    } else if (c == '\n') {
      output += "\\n";
    } else if (c == '\r') {
      output += "\\r";
    } else if (c == '\t') {
      output += "\\t";
    } else {
      output += c;
    }
  }
  return output;
}

void setup() {
  Serial.begin(115200);
  delay(1000);
  
  Serial.println("\n\n=== Chatridge ESP32 Server ===");
  
  // Initialize SPIFFS for file storage
  if (!SPIFFS.begin(true)) {
    Serial.println("SPIFFS initialization failed!");
    while (1) delay(1000); // Halt if SPIFFS fails
  }
  
  Serial.println("SPIFFS initialized");
  
  // Get SPIFFS info
  size_t totalBytes = SPIFFS.totalBytes();
  size_t usedBytes = SPIFFS.usedBytes();
  Serial.printf("SPIFFS Total: %d bytes (%.2f KB), Used: %d bytes (%.2f KB), Free: %d bytes (%.2f KB)\n",
               totalBytes, totalBytes / 1024.0,
               usedBytes, usedBytes / 1024.0,
               totalBytes - usedBytes, (totalBytes - usedBytes) / 1024.0);

  // Create Access Point
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();
  
  Serial.println("\n=== WiFi Access Point Created ===");
  Serial.print("SSID: ");
  Serial.println(ssid);
  Serial.print("Password: ");
  Serial.println(password);
  Serial.print("IP Address: ");
  Serial.println(IP);
  Serial.println("===============================\n");

  // Setup server with CORS support
  server.enableCORS(true);
  
  // Route handlers with CORS
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
  
  // File serving (catch-all for uploaded files)
  server.onNotFound(handleFileGet);
  
  server.begin();
  Serial.println("HTTP Server started on port 80");
  Serial.println("Chatridge Server Ready!\n");
}

void loop() {
  server.handleClient();
}

