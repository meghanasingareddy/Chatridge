#include <WiFi.h>
#include <WebServer.h>

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
    json += "\"timestamp\":" + String(messages[i].ts) + "}";
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

void setup() {
  WiFi.mode(WIFI_AP);
  WiFi.softAP(ssid, password);
  IPAddress IP = WiFi.softAPIP();

  server.enableCORS(true);
  server.on("/", HTTP_GET, handleRoot);
  server.on("/register", HTTP_GET, handleRegister);
  server.on("/devices", HTTP_GET, handleDevices);
  server.on("/messages", HTTP_GET, handleMessages);
  server.on("/send", HTTP_GET, handleSend);
  server.begin();
}

void loop() {
  server.handleClient();
}


