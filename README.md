# Chatridge - Offline Local WiFi Messaging

Chatridge is a Flutter mobile app that enables offline messaging between devices connected to an ESP32 WiFi access point. Perfect for situations where internet connectivity is not available but local communication is needed.

## Features

- **Offline Messaging**: Send and receive messages without internet connection
- **Real-time Updates**: Automatic polling for new messages and device discovery
- **File Sharing**: Share photos, documents, and other files with upload progress
- **Device Discovery**: See all connected devices in real-time
- **Private Messaging**: Send private messages to specific devices
- **Message History**: Persistent local storage of all messages
- **Modern UI**: Clean, intuitive interface with Material Design

## ESP32 Setup

### Hardware Requirements
- ESP32 development board
- MicroSD card (optional, for file storage)

### Software Setup
1. Flash the ESP32 with the Chatridge server firmware
2. Configure the ESP32 to create a WiFi access point:
   - SSID: `Chatridge`
   - Password: `12345678`
   - IP Address: `192.168.4.1`

### ESP32 API Endpoints
The ESP32 server should implement the following endpoints:

- `GET /` - Serves the chat interface
- `GET /messages` - Returns all messages as JSON
- `GET /devices` - Returns connected devices as JSON
- `GET /send?username=X&text=Y&target=Z` - Sends a message
- `POST /upload` - Handles file uploads
- `GET /register?name=X` - Registers a device

## Flutter App Setup

### Prerequisites
- Flutter SDK (stable channel)
- Android Studio / VS Code
- Android device or emulator

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd chatridge
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate Hive adapters**
   ```bash
   flutter packages pub run build_runner build
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration

The app is pre-configured to connect to the ESP32 access point:
- Base URL: `http://192.168.4.1`
- Network: `Chatridge`
- Password: `12345678`

You can modify these settings in `lib/utils/constants.dart`.

## Usage

### First Time Setup

1. **Connect to Chatridge Network**
   - Go to your device's WiFi settings
   - Connect to network "Chatridge" (password: 12345678)

2. **Launch the App**
   - Open the Chatridge app
   - The app will detect your connection status

3. **Register Your Device**
   - Enter a username and device name
   - Tap "Register & Start Chatting"

### Using the App

1. **Send Messages**
   - Type your message in the input field
   - Tap the send button or press Enter

2. **Share Files**
   - Tap the attachment button
   - Choose from camera, gallery, or file picker
   - Files are automatically uploaded and shared

3. **View Connected Devices**
   - Tap the people icon in the top bar
   - See all devices connected to the network

4. **Private Messaging**
   - Select a device from the device list
   - Send private messages to that specific device

5. **Settings**
   - Tap the settings icon to configure:
     - Change username/device name
     - Adjust polling intervals
     - Clear message history
     - Manage storage

## Technical Details

### Architecture
- **State Management**: Provider pattern
- **Local Storage**: Hive database for messages, SharedPreferences for settings
- **Network**: Dio HTTP client with retry logic
- **File Handling**: File picker with validation and progress tracking

### Key Components

- **Models**: Message, Device data structures
- **Services**: API, Storage, File handling
- **Providers**: Connectivity, Chat, Device state management
- **Screens**: Login, Chat, Settings
- **Widgets**: Reusable UI components

### Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  provider: ^6.0.0
  dio: ^5.0.0
  shared_preferences: ^2.0.0
  hive: ^2.0.0
  hive_flutter: ^1.1.0
  file_picker: ^5.0.0
  image_picker: ^0.8.7
  path_provider: ^2.0.0
  permission_handler: ^10.0.0
  connectivity_plus: ^3.0.0
  open_file: ^3.2.1
```

## Permissions

The app requires the following permissions:

- **Internet**: For network communication
- **Storage**: For file access and sharing
- **Camera**: For taking photos
- **Network State**: For connectivity monitoring

## Troubleshooting

### Common Issues

1. **Cannot connect to ESP32**
   - Ensure ESP32 is powered on and broadcasting
   - Check WiFi credentials (Chatridge/12345678)
   - Verify ESP32 IP address (192.168.4.1)

2. **Messages not sending**
   - Check network connection
   - Verify ESP32 server is running
   - Try refreshing the connection

3. **File upload fails**
   - Check file size (max 10MB)
   - Ensure file type is supported
   - Verify storage permissions

4. **App crashes on startup**
   - Run `flutter clean` and `flutter pub get`
   - Check Flutter version compatibility
   - Verify all dependencies are installed

### Debug Mode

Enable debug logging by setting `debugPrint` in the app. Check the console for:
- Network request/response logs
- Error messages and stack traces
- State change notifications

## Development

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
│   └── file_service.dart
├── screens/                  # UI screens
│   ├── login_screen.dart
│   ├── chat_screen.dart
│   └── settings_screen.dart
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

### Building for Release

1. **Android APK**
   ```bash
   flutter build apk --release
   ```

2. **Android App Bundle**
   ```bash
   flutter build appbundle --release
   ```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
1. Check the troubleshooting section
2. Search existing issues
3. Create a new issue with detailed information

## Changelog

### Version 1.0.0
- Initial release
- Basic messaging functionality
- File sharing support
- Device discovery
- Private messaging
- Local message storage
- Settings and configuration
