# Chatridge - Offline Local WiFi Messaging System

<div align="center">

![Chatridge Logo](https://img.shields.io/badge/Chatridge-Offline%20Messaging-blue?style=for-the-badge)
![Flutter](https://img.shields.io/badge/Flutter-3.35.5-blue?style=flat-square&logo=flutter)
![ESP32](https://img.shields.io/badge/ESP32-Compatible-green?style=flat-square&logo=arduino)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Windows%20%7C%20Linux-lightgrey?style=flat-square)

**A cross-platform offline messaging system powered by ESP32 WiFi access point**

</div>

## 📋 Table of Contents

- [Overview](#overview)
- [Features](#features)
- [Screenshots](#screenshots)
- [Architecture](#architecture)
- [Setup Guide](#setup-guide)
- [Usage](#usage)
- [Platform Support](#platform-support)
- [API Documentation](#api-documentation)
- [Development](#development)
- [Contributing](#contributing)

## 🌟 Overview

Chatridge is a complete offline messaging solution that enables local communication between multiple devices without requiring internet connectivity. Perfect for remote areas, events, secure environments, or any scenario where traditional internet-based messaging is unavailable.

### Key Highlights

- ✅ **100% Offline** - No internet connection required
- ✅ **Cross-Platform** - Android, iOS, Windows, Linux support
- ✅ **Real-time Messaging** - Instant message delivery
- ✅ **File Sharing** - Upload and share images, documents, and files
- ✅ **Multi-Device** - Support for up to 50 concurrent devices
- ✅ **Privacy-Focused** - All data stays on local network

## ✨ Features

### Core Messaging
- **Real-time Chat**: Send and receive messages instantly
- **Private Messaging**: Direct messages to specific devices
- **Message History**: Persistent local storage of all conversations
- **Device Discovery**: See all connected devices in real-time
- **Online Status**: Visual indicators for device connectivity

### File Sharing
- **Image Sharing**: Upload and view images with full-screen viewer
- **Document Support**: Share PDFs, Word docs, Excel sheets, and more
- **File Upload**: Progress tracking during file uploads
- **Share Functionality**: Share files directly from the app
- **Multiple Sources**: Choose from camera, gallery, or file picker

### User Experience
- **Modern UI**: Clean, intuitive Material Design interface
- **Auto WiFi Connection**: Automatic connection on mobile devices
- **Manual WiFi Support**: Desktop platforms with OS-level management
- **Error Handling**: User-friendly error messages and retry mechanisms
- **Settings**: Customizable polling intervals and user preferences

### Platform Features
- **Mobile**: Full Android/iOS support with native features
- **Desktop**: Windows and Linux native applications
- **Responsive**: Adapts to different screen sizes and orientations

## 🏗️ Architecture

### System Components

```
┌─────────────────┐         ┌─────────────────┐
│  Flutter App    │ ◄─────► │   ESP32 Server  │
│  (Multi-Platform)│         │  (WiFi AP + API)│
└─────────────────┘         └─────────────────┘
         │                           │
         │                           │
    ┌────▼────┐                ┌────▼────┐
    │  Mobile │                │ SPIFFS  │
    │Desktop  │                │ Storage │
    └─────────┘                └─────────┘
```

### Technology Stack

**Frontend (Flutter)**
- Framework: Flutter 3.35.5
- State Management: Provider
- Local Storage: Hive + SharedPreferences
- HTTP Client: Dio
- File Handling: file_picker, image_picker
- Sharing: share_plus

**Backend (ESP32)**
- Microcontroller: ESP32
- Storage: SPIFFS (1-2MB)
- Communication: WiFi Access Point
- Protocol: HTTP REST API

## 🚀 Setup Guide

### Prerequisites

- **ESP32 Development Board**
- **Arduino IDE** with ESP32 board support
- **Flutter SDK** (3.0.0 or higher)
- **Android Studio / VS Code** (for development)

### ESP32 Setup

1. **Install ESP32 Board Support**
   - Open Arduino IDE
   - Go to `File` → `Preferences`
   - Add to Additional Board Manager URLs:
     ```
     https://raw.githubusercontent.com/espressif/arduino-esp32/gh-pages/package_esp32_index.json
     ```
   - Go to `Tools` → `Board` → `Boards Manager`
   - Search for "ESP32" and install

2. **Upload Firmware**
   - Open `esp32_chatridge_complete.ino` in Arduino IDE
   - Select your ESP32 board from `Tools` → `Board`
   - Select COM port from `Tools` → `Port`
   - Click `Upload`

3. **Verify Setup**
   - Open Serial Monitor (115200 baud)
   - You should see:
     ```
     === Chatridge ESP32 Server ===
     SPIFFS initialized
     === WiFi Access Point Created ===
     SSID: Chatridge
     IP Address: 192.168.4.1
     HTTP Server started on port 80
     ```

**Default WiFi Credentials:**
- SSID: `Chatridge`
- Password: `12345678`
- IP Address: `192.168.4.1`

### Flutter App Setup

1. **Clone Repository**
   ```bash
   git clone <repository-url>
   cd Chatridge
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Code**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the App**
   ```bash
   # Mobile
   flutter run
   
   # Desktop (Windows)
   flutter run -d windows
   
   # Desktop (Linux)
   flutter run -d linux
   ```

### Building for Release

**Android APK:**
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

**Windows Executable:**
```bash
flutter build windows --release
# Output: build/windows/x64/runner/Release/chatridge.exe
```

**Linux App:**
```bash
flutter build linux --release
# Output: build/linux/x64/release/bundle/
```

## 📱 Usage

### First Time Setup

1. **Connect to Network**
   - **Mobile**: App will automatically connect to "Chatridge" WiFi
   - **Desktop**: Manually connect to "Chatridge" WiFi via OS settings
   - Password: `12345678`

2. **Launch App**
   - Open Chatridge app
   - Enter your username and device name
   - Tap "Register & Start Chatting"

3. **Start Messaging**
   - Type messages in the input field
   - Tap send or press Enter
   - Messages appear in real-time

### Using Features

**Send Files:**
1. Tap the attachment button (📎)
2. Choose from:
   - 📷 Take Photo
   - 🖼️ Choose from Gallery
   - 📁 Choose File
3. File uploads automatically and appears in chat

**View Images:**
- Tap any image to view full-screen
- Use pinch to zoom
- Share or download using toolbar buttons

**Private Messages:**
1. Tap the people icon (👥)
2. Select a device from the list
3. Messages sent will be private to that device

**Share Files:**
- Tap share button (📤) on images
- Choose sharing method (WhatsApp, Email, etc.)
- File is downloaded and shared

### Settings

Access settings via the gear icon (⚙️):
- Change username/device name
- Adjust message polling interval
- Clear message history
- View storage information

## 💻 Platform Support

### Android
- ✅ Full support
- ✅ Auto WiFi connection
- ✅ All features available
- **Build**: `flutter build apk --release`

### iOS
- ✅ Full support
- ✅ Auto WiFi connection
- ✅ App Store ready (with developer account)
- **Build**: `flutter build ios --release`

### Windows
- ✅ Native Windows app
- ⚠️ Manual WiFi connection required
- ✅ All messaging features
- **Build**: `flutter build windows --release`

### Linux
- ✅ Native Linux app
- ⚠️ Manual WiFi connection required
- ✅ All messaging features
- **Build**: `flutter build linux --release`

## 🔌 API Documentation

### ESP32 Endpoints

**Base URL**: `http://192.168.4.1`

#### Get Messages
```
GET /messages
Response: JSON array of messages
```

#### Send Message
```
GET /send?username=<username>&text=<message>&target=<target>
Response: {"status":"ok","id":"<message_id>"}
```

#### Upload File
```
POST /upload
Body: multipart/form-data
  - file: <file_data>
  - username: <username>
  - target: <target> (optional)
Response: {"status":"ok","url":"/<filename>"}
```

#### Get Devices
```
GET /devices
Response: JSON array of connected devices
```

#### Register Device
```
GET /register?name=<device_name>
Response: {"status":"ok"}
```

#### Serve Files
```
GET /<filename>
Response: File content with appropriate MIME type
```

## 🛠️ Development

### Project Structure

```
lib/
├── main.dart                 # App entry point
├── app.dart                  # Main app widget
├── models/                   # Data models
│   ├── message.dart
│   └── device.dart
├── providers/                # State management
│   ├── connectivity_provider.dart
│   ├── chat_provider.dart
│   └── device_provider.dart
├── services/                 # Business logic
│   ├── api_service.dart
│   ├── storage_service.dart
│   ├── file_service.dart
│   └── wifi_service.dart    # Platform-aware WiFi
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── connect_screen.dart
│   ├── chat_screen.dart
│   ├── settings_screen.dart
│   └── image_viewer_screen.dart
├── widgets/                  # Reusable components
│   ├── message_item.dart
│   ├── device_list.dart
│   ├── input_area.dart
│   └── file_attachment_button.dart
└── utils/                    # Utilities
    ├── constants.dart
    ├── helpers.dart
    └── permissions.dart
```

### Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0           # State management
  dio: ^5.0.0                # HTTP client
  wifi_iot: ^0.3.19          # WiFi control (mobile only)
  shared_preferences: ^2.0.0  # Settings storage
  hive: ^2.0.0                # Local database
  hive_flutter: ^1.1.0
  file_picker: ^8.0.0         # File selection
  image_picker: ^1.0.0        # Image selection
  path_provider: ^2.1.0       # File paths
  permission_handler: ^11.0.0 # Permissions
  connectivity_plus: ^6.0.0   # Network status
  open_file: ^3.2.1           # File opening
  photo_view: ^0.14.0         # Image viewer
  share_plus: ^7.2.2           # File sharing
  cupertino_icons: ^1.0.2
```

### Configuration

Edit `lib/utils/constants.dart` to customize:
- ESP32 WiFi SSID and password
- Base URL (default: http://192.168.4.1)
- Message polling intervals
- File size limits
- Allowed file types

## 🐛 Troubleshooting

### Common Issues

**Cannot connect to ESP32**
- Verify ESP32 is powered on and broadcasting
- Check WiFi credentials (Chatridge/12345678)
- Ensure ESP32 IP is 192.168.4.1
- Try restarting ESP32

**Messages not sending**
- Check network connection status
- Verify ESP32 server is running (check Serial Monitor)
- Try refreshing the connection

**File upload fails**
- Check file size (max 10MB default)
- Verify file type is supported
- Ensure storage permissions are granted
- Check SPIFFS space on ESP32

**Desktop WiFi connection**
- Connect manually via OS WiFi settings first
- Then launch the app
- App will detect you're on desktop and skip auto-connect

**Build errors**
- Run `flutter clean`
- Run `flutter pub get`
- Verify Flutter version: `flutter --version`
- Check platform-specific requirements

## 🔐 Permissions

**Android/iOS:**
- Internet (for local network)
- Storage (file access)
- Camera (photo capture)
- Network State (connectivity)

**Desktop:**
- Network access
- File system access

## 📊 Technical Specifications

- **Programming Languages**: Dart (Flutter), C++ (Arduino/ESP32)
- **Communication**: HTTP REST API over WiFi
- **Data Format**: JSON
- **Storage**: SPIFFS (ESP32), Hive (Flutter)
- **Network**: WiFi 802.11 b/g/n
- **Max File Size**: 10MB (configurable)
- **Max Devices**: 50 concurrent
- **Message Buffer**: 200 messages in memory
- **SPIFFS Capacity**: 1-2MB (typical ESP32)

## 🔮 Future Enhancements

- [ ] MicroSD card support for expanded storage
- [ ] End-to-end encryption
- [ ] Message read receipts
- [ ] Voice message support
- [ ] Group chat functionality
- [ ] File browser (view all uploaded files)
- [ ] Message search functionality
- [ ] User avatars and profiles
- [ ] Message reactions
- [ ] Push notifications (when online)

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- ESP32 community for excellent documentation
- Flutter team for the amazing framework
- All contributors and testers

## 📞 Support

For issues, questions, or suggestions:
1. Check the [Troubleshooting](#-troubleshooting) section
2. Search existing issues
3. Create a new issue with detailed information

## 📝 Changelog

### Version 1.0.0+1 (Current)
- ✅ Initial release
- ✅ Basic messaging functionality
- ✅ File sharing with upload progress
- ✅ Image viewer with zoom and share
- ✅ Cross-platform support (Android, iOS, Windows, Linux)
- ✅ Device discovery and private messaging
- ✅ Local message storage
- ✅ Settings and configuration
- ✅ Share functionality for images and files
- ✅ Desktop platform support with manual WiFi
- ✅ Auto WiFi connection on mobile platforms

---

<div align="center">

**Built with ❤️ using Flutter & ESP32**

[Report Bug](https://github.com/yourusername/chatridge/issues) · [Request Feature](https://github.com/yourusername/chatridge/issues) · [Documentation](README.md)

</div>
