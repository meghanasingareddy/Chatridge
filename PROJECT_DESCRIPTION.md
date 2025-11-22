# Chatridge - Project Description & Presentation Prompt

## Project Overview

**Chatridge** is an innovative offline messaging system that enables local communication between multiple devices without requiring internet connectivity. Built with Flutter for cross-platform compatibility and powered by an ESP32 microcontroller as a WiFi access point, Chatridge provides a complete communication solution for scenarios where traditional internet-based messaging is unavailable or undesirable.

## Problem Statement

In today's connected world, there are numerous situations where internet connectivity is unavailable, unreliable, or intentionally restricted:
- Remote areas with poor network coverage
- Events and conferences with limited bandwidth
- Secure environments requiring air-gapped networks
- Educational settings for controlled communication
- Emergency situations where infrastructure may be compromised
- Privacy-focused scenarios requiring local-only communication

Chatridge addresses these challenges by creating a self-contained, offline communication network.

## Solution

Chatridge leverages an ESP32 microcontroller to create a local WiFi hotspot, allowing nearby devices to connect and communicate with each other. The system includes:

1. **ESP32 Server**: Creates a WiFi access point and manages message routing
2. **Cross-Platform Client**: Flutter app running on Android, iOS, Windows, and Linux
3. **Real-time Communication**: Instant messaging with automatic synchronization
4. **Rich Media Support**: File sharing, image viewing, and document exchange

## Key Features

### Core Functionality
- ✅ **Offline Messaging**: Complete communication without internet
- ✅ **Real-time Updates**: Automatic polling for new messages and device discovery
- ✅ **File Sharing**: Upload and share images, documents, and files (up to 10MB)
- ✅ **Image Viewing**: Full-screen image viewer with zoom and share capabilities
- ✅ **Device Discovery**: Real-time list of connected devices
- ✅ **Private Messaging**: Direct messages between specific devices
- ✅ **Message History**: Persistent local storage of all conversations

### Advanced Features
- ✅ **Share Functionality**: Share images and files directly from the app
- ✅ **Multi-Platform Support**: Works on Android, iOS, Windows, and Linux
- ✅ **Auto WiFi Connection**: Automatic WiFi connection on mobile devices
- ✅ **Manual WiFi Support**: Desktop platforms with OS-level WiFi management
- ✅ **File Type Support**: Images (JPG, PNG, GIF, WEBP), Documents (PDF, DOC, XLS, PPT), Text files
- ✅ **Upload Progress**: Visual feedback during file uploads
- ✅ **Error Handling**: Robust error handling with user-friendly messages

## Technical Architecture

### Frontend (Flutter)
- **Framework**: Flutter 3.35.5
- **State Management**: Provider pattern
- **Local Storage**: Hive database + SharedPreferences
- **HTTP Client**: Dio with retry logic and timeout handling
- **Platform Support**: Android, iOS, Windows, Linux

### Backend (ESP32)
- **Microcontroller**: ESP32 (WiFi-enabled)
- **Storage**: SPIFFS file system (1-2MB capacity)
- **Communication**: HTTP REST API
- **Protocol**: WiFi Access Point mode

### Key Technical Highlights
- **Cross-Platform**: Single codebase for all platforms
- **Offline-First**: No dependency on external servers
- **Scalable**: Supports up to 50 connected devices
- **Efficient**: Optimized polling with configurable intervals
- **Secure**: Local network only, no external data transmission

## Use Cases

1. **Education**: School projects, campus communication, classroom collaboration
2. **Events**: Conferences, workshops, exhibitions where attendees need to communicate
3. **Emergency**: Disaster relief, field operations, areas with damaged infrastructure
4. **Privacy**: Secure communication without internet exposure
5. **Remote Areas**: Locations with no cellular or internet coverage
6. **Development**: Testing network applications, IoT development

## Platform Support

### Mobile
- **Android**: Full support with APK build (48MB)
- **iOS**: Supported (requires Apple Developer account for distribution)

### Desktop
- **Windows**: Native Windows executable
- **Linux**: Cross-platform Linux support
- **macOS**: Full macOS compatibility

## Project Structure

```
Chatridge/
├── ESP32 Firmware
│   └── esp32_chatridge_complete.ino (Complete server implementation)
├── Flutter App
│   ├── lib/
│   │   ├── models/          # Data models
│   │   ├── providers/        # State management
│   │   ├── services/         # Business logic
│   │   ├── screens/          # UI screens
│   │   ├── widgets/          # Reusable components
│   │   └── utils/            # Utilities
│   └── build/
│       ├── app-release.apk   # Android release
│       └── windows/           # Windows executable
└── Documentation
    ├── README.md
    └── MICROSD_MIGRATION_NOTES.md
```

## Development Highlights

- **Clean Architecture**: Separation of concerns with clear layer boundaries
- **Error Handling**: Comprehensive error handling at all levels
- **Code Organization**: Modular design with reusable components
- **Documentation**: Well-documented codebase with inline comments
- **Version Control**: Git-based development workflow

## Future Enhancements

- MicroSD card support for expanded file storage
- End-to-end encryption for enhanced security
- Message read receipts
- Voice message support
- Group chat functionality
- File browser to view all uploaded files

## Technical Specifications

- **Programming Languages**: Dart (Flutter), C++ (Arduino/ESP32)
- **Communication Protocol**: HTTP REST API
- **Data Format**: JSON
- **Storage**: SPIFFS (ESP32), Hive (Flutter)
- **Network**: WiFi 802.11 b/g/n
- **Maximum File Size**: 10MB (configurable)
- **Maximum Devices**: 50 concurrent connections
- **Message Buffer**: 200 messages in memory

## Presentation Points

1. **Problem-Solution Fit**: Addresses real-world communication challenges
2. **Technical Innovation**: Combination of embedded systems and modern mobile development
3. **Cross-Platform**: Single codebase for multiple platforms
4. **Practical Application**: Real-world use cases and scenarios
5. **Scalability**: Can support multiple devices and expandable architecture
6. **User Experience**: Intuitive interface with modern design principles

## Demonstration Flow

1. **Setup**: Show ESP32 creating WiFi network
2. **Connection**: Multiple devices connecting to network
3. **Messaging**: Real-time message exchange
4. **File Sharing**: Upload and view shared files
5. **Cross-Platform**: Show app running on different platforms
6. **Features**: Demonstrate all key features

## Conclusion

Chatridge represents a practical solution for offline communication needs, combining embedded systems expertise with modern mobile development practices. The project demonstrates full-stack development capabilities, from hardware programming to cross-platform software development, making it an excellent showcase of technical skills and problem-solving abilities.

---

**Version**: 1.0.0+1  
**License**: MIT  
**Status**: Production Ready

