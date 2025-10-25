// Improved file upload handler for ESP32
void handleFileUpload() {
  HTTPUpload& upload = server.upload();
  static File file;
  static String filename;
  static String filepath;
  
  if (upload.status == UPLOAD_FILE_START) {
    filename = upload.filename;
    if (filename.length() == 0) {
      filename = "file_" + String(millis()) + ".bin";
    }
    
    // Create file path
    filepath = "/" + filename;
    Serial.println("File upload started: " + filename);
    
    // Open file for writing
    file = SPIFFS.open(filepath, "w");
    if (!file) {
      Serial.println("Failed to create file: " + filepath);
      return;
    }
    Serial.println("File created: " + filepath);
    
  } else if (upload.status == UPLOAD_FILE_WRITE) {
    if (file) {
      size_t bytesWritten = file.write(upload.buf, upload.currentSize);
      if (bytesWritten != upload.currentSize) {
        Serial.println("Write error: expected " + String(upload.currentSize) + " bytes, wrote " + String(bytesWritten));
      }
    }
    
  } else if (upload.status == UPLOAD_FILE_END) {
    if (file) {
      file.close();
      Serial.println("File upload completed: " + filename + " (" + String(upload.totalSize) + " bytes)");
      
      // Send success response
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.send(200, "application/json", "{\"status\":\"ok\",\"filename\":\"" + filename + "\",\"url\":\"" + filepath + "\"}");
    } else {
      Serial.println("File upload failed: file not open");
      server.sendHeader("Access-Control-Allow-Origin", "*");
      server.send(500, "application/json", "{\"status\":\"error\",\"message\":\"File upload failed\"}");
    }
  }
}

// Add this to your setup() function:
void setup() {
  // ... your existing code ...
  
  // Setup server routes with improved file upload
  server.on("/", handleRoot);
  server.on("/send", HTTP_OPTIONS, handleCORS);
  server.on("/send", handleSendMessage);
  server.on("/messages", HTTP_OPTIONS, handleCORS);
  server.on("/messages", handleGetMessages);
  server.on("/devices", HTTP_OPTIONS, handleCORS);
  server.on("/devices", handleGetDevices);
  server.on("/register", HTTP_OPTIONS, handleCORS);
  server.on("/register", handleRegisterDevice);
  server.on("/upload", HTTP_OPTIONS, handleCORS);
  server.on("/upload", HTTP_POST, []() {
    // Handle successful upload
    server.sendHeader("Access-Control-Allow-Origin", "*");
    server.send(200, "application/json", "{\"status\":\"ok\"}");
  }, handleFileUpload);
  server.on("/files", HTTP_OPTIONS, handleCORS);
  server.on("/files", handleServeFile);
  server.on("/style.css", handleCSS);
  
  server.begin();
  Serial.println("HTTP server started");
}

// Add file serving functionality
void handleServeFile() {
  server.sendHeader("Access-Control-Allow-Origin", "*");
  
  // List files in SPIFFS
  File root = SPIFFS.open("/");
  File file = root.openNextFile();
  
  String json = "[";
  bool first = true;
  
  while (file) {
    if (!file.isDirectory()) {
      if (!first) json += ",";
      json += "{";
      json += "\"name\":\"" + String(file.name()) + "\",";
      json += "\"size\":\"" + String(file.size()) + "\"";
      json += "}";
      first = false;
    }
    file = root.openNextFile();
  }
  
  json += "]";
  server.send(200, "application/json", json);
}

// Add file download functionality
void handleDownloadFile() {
  if (server.hasArg("file")) {
    String filename = server.arg("file");
    String filepath = "/" + filename;
    
    if (SPIFFS.exists(filepath)) {
      File file = SPIFFS.open(filepath, "r");
      if (file) {
        server.sendHeader("Access-Control-Allow-Origin", "*");
        server.sendHeader("Content-Disposition", "attachment; filename=" + filename);
        server.streamFile(file, "application/octet-stream");
        file.close();
        return;
      }
    }
  }
  
  server.sendHeader("Access-Control-Allow-Origin", "*");
  server.send(404, "text/plain", "File not found");
}


