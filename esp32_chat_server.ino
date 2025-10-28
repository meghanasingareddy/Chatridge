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

void handleRoot() {
  server.send(200, "text/plain", "Chatridge ESP32 Server");
}

void handleRegister() {
  String name = server.hasArg("name") ? server.arg("name") : "";
  if (name.length() == 0) {
    server.send(400, "application/json", "{\"error\":\"name required\"}");
    return;
  }
  addOrUpdateDevice(name, server.client().remoteIP().toString());
  server.send(200, "application/json", "{\"status\":\"ok\"}");
}

void handleDevices() {
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
  String json = "[";
  for (int i = 0; i < messageCount; i++) {
    if (i > 0) json += ",";
    json += "{\"id\":\"" + messages[i].id + "\",";
    json += "\"username\":\"" + messages[i].username + "\",";
    json += "\"text\":\"" + messages[i].text + "\",";
    if (messages[i].target.length() > 0) {
      json += "\"target\":\"" + messages[i].target + "\",";
    }
    json += "\"timestamp\":" + String(messages[i].ts);
    if (messages[i].attachmentUrl.length() > 0) {
      json += ",\"attachment_url\":\"" + messages[i].attachmentUrl + "\",";
      json += "\"attachment_name\":\"" + messages[i].attachmentName + "\",";
      json += "\"attachment_type\":\"" + messages[i].attachmentType + "\"";
    }
    json += "}";
  }
  json += "]";
  server.send(200, "application/json", json);
}

void handleSend() {
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
  messages[messageCount++] = m;

  // Mark sender device active
  addOrUpdateDevice(username, server.client().remoteIP().toString());

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
    if (SPIFFS.exists(filename)) {
      SPIFFS.remove(filename);
    }
    uploadFile = SPIFFS.open(filename, FILE_WRITE);
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (uploadFile) {
      uploadFile.write(upload.buf, upload.currentSize);
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (uploadFile) {
      uploadFile.close();
    }
  }
}

String detectContentType(const String &fname) {
  String f = fname;
  if (f.endsWith(".png")) return "image/png";
  if (f.endsWith(".jpg") || f.endsWith(".jpeg")) return "image/jpeg";
  if (f.endsWith(".gif")) return "image/gif";
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

void handleUploadRespond() {
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

  String json = String("{\"status\":\"ok\",\"url\":\"") + url + "\"}";
  server.send(200, "application/json", json);
}

// Serve uploaded files (fallback)
void handleFileGet() {
  String path = server.uri();
  if (path == "/") { server.send(404, "text/plain", "Not found"); return; }
  if (!SPIFFS.exists(path)) { server.send(404, "text/plain", "Not found"); return; }
  File f = SPIFFS.open(path, FILE_READ);
  String ct = detectContentType(path);
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.streamFile(f, ct);
  f.close();
}

void setup() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();

  // Init filesystem for uploads
  SPIFFS.begin(true);

  server.enableCORS(true);
  server.on("/", HTTP_GET, handleRoot);
  server.on("/register", HTTP_GET, handleRegister);
  server.on("/devices", HTTP_GET, handleDevices);
  server.on("/messages", HTTP_GET, handleMessages);
  server.on("/send", HTTP_GET, handleSend);
  server.on("/upload", HTTP_POST, handleUploadRespond, handleFileUpload);
  server.onNotFound(handleFileGet);
  server.begin();
}

void loop() {
  server.handleClient();
}



