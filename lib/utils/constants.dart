class Constants {
  // ESP32 Configuration
  static const String esp32SSID = 'Chatridge';
  static const String esp32Password = '12345678';
  static const String baseUrl = 'http://192.168.4.1';

  // API Endpoints
  static const String messagesEndpoint = '/messages';
  static const String devicesEndpoint = '/devices';
  static const String sendEndpoint = '/send';
  static const String uploadEndpoint = '/upload';
  static const String registerEndpoint = '/register';

  // Polling Intervals (in seconds)
  static const int messagePollingInterval = 2;
  static const int devicePollingInterval = 5;

  // File Upload Limits
  static const int maxFileSizeMB = 10;
  static const List<String> allowedImageTypes = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'webp',
  ];
  static const List<String> allowedDocumentTypes = [
    'pdf',
    'doc',
    'docx',
    'ppt',
    'pptx',
    'xls',
    'xlsx',
    'csv',
    'txt',
    'rtf',
  ];

  // Storage Keys
  static const String usernameKey = 'username';
  static const String deviceNameKey = 'device_name';
  static const String autoPollingKey = 'auto_polling';
  static const String pollingIntervalKey = 'polling_interval';

  // UI Constants
  static const double borderRadius = 8.0;
  static const double messageBubbleRadius = 16.0;
  static const double avatarSize = 32.0;

  // Colors
  static const int primaryColorValue = 0xFF3498DB;
  static const int secondaryColorValue = 0xFF2C3E50;
  static const int successColorValue = 0xFF27AE60;
  static const int errorColorValue = 0xFFE74C3C;
  static const int warningColorValue = 0xFFF39C12;
}
