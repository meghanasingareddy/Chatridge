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
  server.sendHeader("Access-Control-Max-Age", "86400"); // 24 hours
  server.send(200, "text/plain", "");
}

// Root endpoint - Serve web interface
void handleRoot() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  // Try to serve index.html from SPIFFS first
  if (SPIFFS.exists("/index.html")) {
    File f = SPIFFS.open("/index.html", FILE_READ);
    if (f) {
      server.streamFile(f, "text/html");
      f.close();
      return;
    }
  }
  
  // If index.html doesn't exist, serve simple embedded HTML (lightweight version)
  // For full interface, upload web_interface.html to SPIFFS as index.html
  String html = getWebInterfaceHTML();
  server.send(200, "text/html", html);
}

// Get web interface HTML - Lightweight version to save code space
// For full interface, upload web_interface.html to SPIFFS as /index.html
String getWebInterfaceHTML() {
  String html = "<!DOCTYPE html><html lang=\"en\"><head>";
  html += "<meta charset=\"UTF-8\"><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\">";
  html += "<title>Chatridge - Web Interface</title>";
  html += "<style>";
  html += "* { margin: 0; padding: 0; box-sizing: border-box; }";
  html += "body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; ";
  html += "background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); min-height: 100vh; padding: 20px; }";
  html += ".container { max-width: 800px; margin: 0 auto; background: white; border-radius: 16px; ";
  html += "box-shadow: 0 10px 40px rgba(0,0,0,0.2); overflow: hidden; }";
  html += ".header { background: linear-gradient(135deg, #3498db 0%, #2980b9 100%); color: white; ";
  html += "padding: 30px; text-align: center; }";
  html += ".header h1 { font-size: 32px; margin-bottom: 10px; }";
  html += ".status-bar { padding: 15px 30px; background: #f8f9fa; border-bottom: 1px solid #e9ecef; ";
  html += "display: flex; justify-content: space-between; align-items: center; }";
  html += ".status-dot { width: 10px; height: 10px; border-radius: 50%; background: #28a745; ";
  html += "display: inline-block; margin-right: 8px; }";
  html += ".content { padding: 30px; }";
  html += ".input-group { margin-bottom: 15px; }";
  html += ".input-group label { display: block; margin-bottom: 5px; font-weight: 600; color: #495057; }";
  html += "input, textarea, select { width: 100%; padding: 12px; border: 2px solid #e9ecef; ";
  html += "border-radius: 8px; font-size: 14px; font-family: inherit; }";
  html += "input:focus, textarea:focus, select:focus { outline: none; border-color: #3498db; }";
  html += "textarea { resize: vertical; min-height: 80px; }";
  html += "button { background: #3498db; color: white; border: none; padding: 12px 24px; ";
  html += "border-radius: 8px; cursor: pointer; font-size: 14px; font-weight: 600; }";
  html += "button:hover { background: #2980b9; }";
  html += "button:disabled { background: #95a5a6; cursor: not-allowed; }";
  html += ".messages-container { max-height: 400px; overflow-y: auto; border: 2px solid #e9ecef; ";
  html += "border-radius: 8px; padding: 15px; background: #f8f9fa; }";
  html += ".message { background: white; padding: 15px; border-radius: 8px; margin-bottom: 10px; ";
  html += "box-shadow: 0 2px 4px rgba(0,0,0,0.1); }";
  html += ".message-header { display: flex; justify-content: space-between; margin-bottom: 8px; }";
  html += ".message-username { font-weight: 600; color: #3498db; }";
  html += ".error { background: #f8d7da; color: #721c24; padding: 12px; border-radius: 6px; ";
  html += "margin-bottom: 15px; }";
  html += "</style></head><body>";
  html += "<div class=\"container\">";
  html += "<div class=\"header\"><h1>💬 Chatridge</h1><p>Offline Local WiFi Messaging</p></div>";
  html += "<div class=\"status-bar\">";
  html += "<div><span class=\"status-dot\"></span><span id=\"statusText\">Connected</span></div>";
  html += "<div><span id=\"deviceCount\">0</span> devices online</div>";
  html += "</div>";
  html += "<div class=\"content\">";
  html += "<div id=\"errorContainer\"></div>";
  html += "<div class=\"input-group\"><label>Your Username</label>";
  html += "<input type=\"text\" id=\"username\" placeholder=\"Enter your name\" required></div>";
  html += "<div class=\"input-group\"><label>Target (Optional)</label>";
  html += "<select id=\"target\"><option value=\"\">Group Chat</option></select></div>";
  html += "<div class=\"input-group\"><label>Message</label>";
  html += "<textarea id=\"messageText\" placeholder=\"Type your message...\"></textarea></div>";
  html += "<button onclick=\"sendMessage()\" style=\"width:100%;margin-bottom:10px;\">Send Message</button>";
  html += "<button onclick=\"refreshAll()\" style=\"width:100%;background:#27ae60;\">Refresh</button>";
  html += "<div style=\"margin-top:20px;\">";
  html += "<label>📎 Attach File</label>";
  html += "<input type=\"file\" id=\"fileInput\" onchange=\"handleFileSelect(event)\" style=\"padding:8px;\">";
  html += "<div id=\"fileName\" style=\"font-size:12px;color:#6c757d;margin-top:5px;\"></div>";
  html += "</div>";
  html += "<div style=\"margin-top:30px;\"><h2>Messages</h2>";
  html += "<div class=\"messages-container\" id=\"messagesContainer\">Loading...</div></div>";
  html += "<div style=\"margin-top:30px;padding-top:20px;border-top:2px solid #e9ecef;\">";
  html += "<h2>Connected Devices</h2><div id=\"devicesList\">Loading...</div></div>";
  html += "</div></div>";
  html += "<script>";
  html += "const BASE_URL = 'http://192.168.4.1';";
  html += "let selectedFile = null;";
  html += "function showError(msg) {";
  html += "document.getElementById('errorContainer').innerHTML = '<div class=\"error\">' + msg + '</div>';";
  html += "setTimeout(() => document.getElementById('errorContainer').innerHTML = '', 5000);";
  html += "}";
  html += "async function loadMessages() {";
  html += "try {";
  html += "const res = await fetch(BASE_URL + '/messages');";
  html += "const msgs = await res.json();";
  html += "const container = document.getElementById('messagesContainer');";
  html += "if (msgs.length === 0) {";
  html += "container.innerHTML = '<div style=\"text-align:center;padding:40px;color:#6c757d;\">No messages yet</div>';";
  html += "return;";
  html += "}";
  html += "msgs.sort((a,b) => a.timestamp - b.timestamp);";
  html += "container.innerHTML = msgs.map(m => {";
  html += "const time = new Date(m.timestamp).toLocaleTimeString();";
  html += "const txt = (m.text || '').replace(/(https?:\\/\\/[^\\s]+)/g, '<a href=\"$1\" target=\"_blank\">$1</a>');";
  html += "const att = m.attachment_url ? '<div style=\"margin-top:10px;padding:10px;background:#e9ecef;border-radius:6px;\"><a href=\"' + BASE_URL + m.attachment_url + '\" target=\"_blank\">📎 ' + (m.attachment_name || 'File') + '</a></div>' : '';";
  html += "return '<div class=\"message\"><div class=\"message-header\"><span class=\"message-username\">' + ";
  html += "(m.username || 'Unknown') + '</span><span style=\"font-size:12px;color:#6c757d;\">' + time + ";
  html += "'</span></div><div class=\"message-text\">' + txt + '</div>' + att + '</div>';";
  html += "}).join('');";
  html += "container.scrollTop = container.scrollHeight;";
  html += "} catch(e) {";
  html += "showError('Failed to load messages');";
  html += "}";
  html += "}";
  html += "async function loadDevices() {";
  html += "try {";
  html += "const res = await fetch(BASE_URL + '/devices');";
  html += "const devices = await res.json();";
  html += "const select = document.getElementById('target');";
  html += "select.innerHTML = '<option value=\"\">Group Chat</option>';";
  html += "devices.forEach(d => {";
  html += "if(d.name) {";
  html += "const opt = document.createElement('option');";
  html += "opt.value = d.name;";
  html += "opt.textContent = d.name + (d.online ? ' 🟢' : '');";
  html += "select.appendChild(opt);";
  html += "}";
  html += "});";
  html += "document.getElementById('deviceCount').textContent = devices.filter(d => d.online).length;";
  html += "document.getElementById('devicesList').innerHTML = devices.map(d => ";
  html += "'<span style=\"background:#e9ecef;padding:8px 16px;border-radius:20px;margin-right:10px;margin-bottom:10px;display:inline-block;font-size:12px;\">' + ";
  html += "(d.online ? '🟢' : '🔴') + ' ' + d.name + '</span>'";
  html += ").join('');";
  html += "} catch(e) {";
  html += "showError('Failed to load devices');";
  html += "}";
  html += "}";
  html += "async function sendMessage() {";
  html += "const username = document.getElementById('username').value.trim();";
  html += "const text = document.getElementById('messageText').value.trim();";
  html += "const target = document.getElementById('target').value.trim();";
  html += "if(!username) { showError('Please enter username'); return; }";
  html += "if(!text && !selectedFile) { showError('Please enter message or select file'); return; }";
  html += "try {";
  html += "await fetch(BASE_URL + '/register?name=' + encodeURIComponent(username));";
  html += "if(selectedFile) {";
  html += "const fd = new FormData();";
  html += "fd.append('file', selectedFile);";
  html += "fd.append('username', username);";
  html += "if(target) fd.append('target', target);";
  html += "await fetch(BASE_URL + '/upload', {method:'POST', body:fd});";
  html += "document.getElementById('fileInput').value = '';";
  html += "document.getElementById('fileName').textContent = '';";
  html += "selectedFile = null;";
  html += "} else {";
  html += "let url = BASE_URL + '/send?username=' + encodeURIComponent(username) + '&text=' + encodeURIComponent(text);";
  html += "if(target) url += '&target=' + encodeURIComponent(target);";
  html += "await fetch(url);";
  html += "}";
  html += "document.getElementById('messageText').value = '';";
  html += "setTimeout(() => { loadMessages(); loadDevices(); }, 500);";
  html += "} catch(e) {";
  html += "showError('Failed to send: ' + e.message);";
  html += "}";
  html += "}";
  html += "function handleFileSelect(e) {";
  html += "const file = e.target.files[0];";
  html += "if(file) {";
  html += "selectedFile = file;";
  html += "document.getElementById('fileName').textContent = 'Selected: ' + file.name + ' (' + (file.size/1024).toFixed(1) + ' KB)';";
  html += "}";
  html += "}";
  html += "function refreshAll() { loadMessages(); loadDevices(); }";
  html += "window.onload = function() { loadMessages(); loadDevices(); setInterval(() => { loadMessages(); loadDevices(); }, 3000); };";
  html += "</script></body></html>";
  
  return html;
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

// Sanitize filename for SPIFFS (remove invalid characters)
// This ensures filenames are stored consistently and can be matched when requested
// IMPORTANT: Preserves file extension so files can be opened correctly on Windows/PC
String sanitizeFilename(String filename) {
  // Extract file extension first to preserve it
  String extension = "";
  int lastDot = filename.lastIndexOf('.');
  if (lastDot > 0 && lastDot < filename.length() - 1) {
    // There's a dot and it's not the first or last character
    extension = filename.substring(lastDot); // Include the dot, e.g., ".pdf"
    filename = filename.substring(0, lastDot); // Get filename without extension
  }
  
  // Sanitize the base filename
  String sanitized = "/";
  for (unsigned int i = 0; i < filename.length(); i++) {
    char c = filename.charAt(i);
    // Allow alphanumeric, dots, hyphens, underscores, and spaces
    // Replace commas, parentheses, and other special chars with underscore
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || 
        (c >= '0' && c <= '9') || c == '.' || c == '-' || c == '_' || c == ' ') {
      sanitized += c;
    } else {
      // Replace invalid characters (comma, parentheses, etc.) with underscore
      sanitized += '_';
    }
  }
  
  // Reattach extension
  sanitized += extension;
  
  return sanitized;
}

// File upload handler (called during upload process)
void handleFileUpload() {
  HTTPUpload &upload = server.upload();
  if (upload.status == UPLOAD_FILE_START) {
    // Sanitize filename to handle Windows paths and special characters
    String originalFilename = upload.filename;
    
    // Extract just the filename from path (handle Windows backslashes)
    int lastSlash = originalFilename.lastIndexOf('/');
    int lastBackslash = originalFilename.lastIndexOf('\\');
    int lastSeparator = (lastSlash > lastBackslash) ? lastSlash : lastBackslash;
    if (lastSeparator >= 0) {
      originalFilename = originalFilename.substring(lastSeparator + 1);
    }
    
    // Sanitize and create full path
    String filename = sanitizeFilename(originalFilename);
    lastUploadedFileName = filename;
    
    Serial.println("Upload START: Original=" + upload.filename + ", Sanitized=" + filename);
    
    // Remove existing file if it exists
    if (SPIFFS.exists(filename)) {
      SPIFFS.remove(filename);
      Serial.println("Removed existing file: " + filename);
    }
    
    uploadFile = SPIFFS.open(filename, FILE_WRITE);
    if (!uploadFile) {
      Serial.println("ERROR: Failed to open file for writing: " + filename);
    } else {
      Serial.println("File opened successfully: " + filename);
    }
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (uploadFile) {
      size_t written = uploadFile.write(upload.buf, upload.currentSize);
      if (written != upload.currentSize) {
        Serial.println("WARNING: Partial write: expected " + String(upload.currentSize) + ", wrote " + String(written));
      }
    }
  } else if (upload.status == UPLOAD_FILE_END) {
    if (uploadFile) {
      uploadFile.close();
      Serial.println("Upload END: " + lastUploadedFileName + " (" + String(upload.totalSize) + " bytes)");
      
      // Verify file was created
      if (SPIFFS.exists(lastUploadedFileName)) {
        File verify = SPIFFS.open(lastUploadedFileName, FILE_READ);
        if (verify) {
          Serial.println("File verified: " + String(verify.size()) + " bytes");
          verify.close();
        }
      } else {
        Serial.println("ERROR: File not found after upload: " + lastUploadedFileName);
      }
    } else {
      Serial.println("ERROR: Upload file was not open at END");
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

  String url = lastUploadedFileName; // e.g. /image.jpg (already sanitized)
  String fname = lastUploadedFileName.substring(1); // strip leading '/' to get display name
  String ctype = detectContentType(lastUploadedFileName);
  
  // Store the sanitized filename in the message (this is what's actually on SPIFFS)
  // The attachmentName keeps the original display name for the user

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

// URL decode helper
String urlDecode(String str) {
  String decoded = "";
  for (unsigned int i = 0; i < str.length(); i++) {
    char c = str.charAt(i);
    if (c == '%' && i + 2 < str.length()) {
      char hex[3] = {str.charAt(i + 1), str.charAt(i + 2), '\0'};
      int value = strtol(hex, NULL, 16);
      decoded += (char)value;
      i += 2;
    } else if (c == '+') {
      decoded += ' ';
    } else {
      decoded += c;
    }
  }
  return decoded;
}

// Serve uploaded files
void handleFileGet() {
  String path = server.uri();
  
  // Debug logging
  Serial.println("File request (raw): " + path);
  
  if (path == "/") {
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(404, "text/plain", "Not found");
    return;
  }
  
  // URL decode the path
  path = urlDecode(path);
  Serial.println("File request (decoded): " + path);
  
  // Normalize path - ensure it starts with /
  if (!path.startsWith("/")) {
    path = "/" + path;
  }
  
  // Extract filename from path
  int lastSlash = path.lastIndexOf('/');
  String filenameOnly = (lastSlash >= 0) ? path.substring(lastSlash + 1) : path;
  
  // Sanitize the filename to match how files are stored in SPIFFS
  // Files are stored with sanitized names (commas/parentheses replaced with underscores)
  String sanitizedPath = sanitizeFilename(filenameOnly);
  Serial.println("File request (sanitized): " + sanitizedPath);
  
  // Try sanitized path first (how files are stored)
  String filePath = sanitizedPath;
  
  // Also try with the original decoded path (in case it matches a file exactly)
  String originalPath = path;
  
  // Check if file exists
  if (!SPIFFS.exists(filePath)) {
    // Try original decoded path (some files might not have been sanitized)
    if (originalPath != filePath && SPIFFS.exists(originalPath)) {
      filePath = originalPath;
      Serial.println("Using original decoded path: " + filePath);
    } else {
      Serial.println("File not found in SPIFFS: " + filePath);
      
      // Try to list all files for debugging
      Serial.println("Available files in SPIFFS:");
      File root = SPIFFS.open("/");
      File file = root.openNextFile();
      while (file) {
        Serial.println("  - " + String(file.name()));
        file = root.openNextFile();
      }
      root.close();
      
    server.sendHeader("Access-Control-Allow-Origin", "*");
      server.send(404, "application/json", "{\"error\":\"File not found\",\"requested\":\"" + path + "\",\"sanitized\":\"" + sanitizedPath + "\"}");
    return;
    }
  } else {
    Serial.println("File found with sanitized path: " + filePath);
  }
  
  // Open and serve file
  File f = SPIFFS.open(filePath, FILE_READ);
  if (!f) {
    Serial.println("Error opening file: " + filePath);
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(500, "application/json", "{\"error\":\"Error opening file\"}");
    return;
  }
  
  Serial.println("Serving file: " + filePath + " (" + String(f.size()) + " bytes)");
  
  String ct = detectContentType(filePath);
  
  // Extract filename for Content-Disposition header
  int lastSlashForName = filePath.lastIndexOf('/');
  String displayFilename = (lastSlashForName >= 0) ? filePath.substring(lastSlashForName + 1) : filePath;
  
  // Send headers - CORS and Content-Disposition for proper file handling
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.sendHeader("Access-Control-Allow-Methods", "GET, POST, OPTIONS");
  server.sendHeader("Access-Control-Allow-Headers", "Content-Type");
  // Content-Disposition ensures browsers download/save file with correct name
  server.sendHeader("Content-Disposition", "inline; filename=\"" + displayFilename + "\"");
  // Content-Type helps browsers/open appropriate applications
  server.sendHeader("Content-Type", ct);
  
  // Use streamFile which properly handles chunked transfer
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
  
  // Setup routes with CORS support
  // Note: server.enableCORS(true) may not work - we manually add CORS headers in each handler
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