<div align="center">

# 💬 Chatridge

### Offline Local WiFi Messaging

![Flutter](https://img.shields.io/badge/Flutter-3.35.5-blue?style=flat-square&logo=flutter)
![ESP32](https://img.shields.io/badge/ESP32-Compatible-green?style=flat-square&logo=arduino)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux-lightgrey?style=flat-square)
![License](https://img.shields.io/badge/License-MIT-yellow?style=flat-square)

*A cross-platform offline messaging system powered by ESP32 WiFi — no internet required.*

</div>

---

## 📋 Table of Contents

- [Abstract](#abstract)
- [Introduction](#introduction)
- [System Components](#system-components)
- [Screenshots](#screenshots)
- [Working Principle](#working-principle)
- [Use Cases](#use-cases)
- [Results](#results)
- [Future Scope](#future-scope)
- [Setup Guide](#setup-guide)
- [Conclusion](#conclusion)

---

## 📄 Abstract

In situations where internet access is unavailable or restricted, communicating through regular messaging applications becomes difficult. This creates a need for a simple offline method that allows nearby mobile phones, laptops, desktops, and other devices to exchange messages without relying on online networks.

This problem is addressed by creating a **local wireless network using a microcontroller** and enabling connected devices — across multiple platforms — to communicate through a **browser-based interface** and an **application**. This method supports basic text messaging through the web and extended features through the app, all functioning **completely offline**.

---

## 📖 Introduction

This project proposes an **offline communication system** that allows multiple devices to exchange messages without the need for internet connectivity. The system works by creating a private wireless network using a microcontroller, allowing nearby devices such as mobile phones, laptops, desktops, and Linux-based systems to connect and communicate.

Users can access the system in two ways:
- Through a **simple web interface** for basic text messaging
- Through an **application** that provides extended features such as sending images and various file types

The goal of this solution is to offer an easy, reliable, and platform-independent way for people to communicate locally in places where internet access is limited or unavailable.

---

## 🔧 System Components

The Chatridge system consists of three major parts that work together to enable offline communication:

### 3.1 — ESP32 Module (Server Unit)

<div align="center">
<img src="images/esp32_hardware.jpg" alt="ESP32 Module" width="400"/>

*ESP32 microcontroller powering the Chatridge network*
</div>

- Acts as a **WiFi Access Point** (Hotspot)
- Creates the private network named **Chatridge**
- Stores uploaded files using **SPIFFS**
- Routes incoming and outgoing messages
- Hosts the offline web interface accessible at `http://192.168.4.1/`

---

### 3.2 — Flutter Application (Client Application)

This is the main communication interface for users. It provides:

- ✅ **Real-time messaging**
- ✅ **File sharing** (images, PDFs, Word files, Excel sheets, PPTs, and more)
- ✅ **Chat history storage**
- ✅ **Device discovery**
- ✅ **Private messaging**
- ✅ **Cross-platform support** (Android, Windows, Linux, and laptops)

<div align="center">

| Connection Screen | Chat List | Group Chat |
|:-:|:-:|:-:|
| <img src="images/app_connect_screen.jpg" alt="Connection Screen" width="250"/> | <img src="images/app_chat_list.jpg" alt="Chat List" width="250"/> | <img src="images/app_group_chat.jpg" alt="Group Chat with File Sharing" width="250"/> |
| *Connect to Chatridge network* | *View conversations & contacts* | *Messaging with file sharing* |

</div>

---

### 3.3 — Web Interface (Browser-Based Messaging)

<div align="center">
<img src="images/web_interface.jpg" alt="Web Interface" width="300"/>

*Browser-based messaging at `http://192.168.4.1/`*
</div>

- Accessible from **any device** by visiting `http://192.168.4.1/`
- Allows users to send and receive **text messages only**
- Does **not** support image or file sharing
- Works on mobiles, laptops, desktops, Linux systems, and any browser-enabled device

---

## 📸 Screenshots

<div align="center">

| Web Interface | ESP32 Hardware | App – Connect |
|:-:|:-:|:-:|
| <img src="images/web_interface.jpg" alt="Web Interface" width="250"/> | <img src="images/esp32_hardware.jpg" alt="ESP32 Module" width="250"/> | <img src="images/app_connect_screen.jpg" alt="App Connect" width="250"/> |

| App – Chat List | App – Group Chat |
|:-:|:-:|
| <img src="images/app_chat_list.jpg" alt="Chat List" width="250"/> | <img src="images/app_group_chat.jpg" alt="Group Chat" width="250"/> |

</div>

---

## ⚙️ Working Principle

Chatridge works by creating a small, local communication environment where devices connect and interact without using the internet.

### Step 1 — Network Creation

The ESP32 module powers on and creates a **WiFi hotspot** called **Chatridge**. Any nearby device can connect to this hotspot using the password configured in the ESP32.

> **Default Credentials:**
> - SSID: `Chatridge`
> - Password: `12345678`

### Step 2 — Device Access

Users can communicate through:
- The **mobile/desktop app**, or
- The **browser interface** at `http://192.168.4.1/`

### Step 3 — Message Handling

- When a message is sent, the ESP32 receives it through **HTTP requests**
- The ESP32 stores the message temporarily and **forwards it to all connected devices**
- In the app, the message appears instantly due to **continuous polling and updates**
- In the web interface, users can view or send **text messages only**

### Step 4 — File Sharing (App Only)

Through the Flutter app, users can share:

| File Type | Supported |
|:-|:-:|
| Images (JPG, PNG, etc.) | ✅ |
| PDF Documents | ✅ |
| Word Documents (.docx) | ✅ |
| Excel Spreadsheets (.xlsx) | ✅ |
| PowerPoint Presentations (.pptx) | ✅ |
| Other Files | ✅ |

Files are uploaded to the ESP32 and then shared across the local network.

### Block Diagram

```
┌──────────────────────────────────────────────────────────┐
│                    ESP32 Module                          │
│              (WiFi Access Point + Server)                │
│          SSID: Chatridge | IP: 192.168.4.1              │
│                  SPIFFS File Storage                     │
└──────────┬──────────────────────┬────────────────────────┘
           │                      │
     ┌─────▼──────┐        ┌─────▼──────┐
     │  Flutter    │        │    Web     │
     │    App      │        │ Interface  │
     │             │        │            │
     │ • Messages  │        │ • Text     │
     │ • Files     │        │   Messages │
     │ • Images    │        │   Only     │
     │ • Private   │        │            │
     │   Chat      │        │            │
     └─────────────┘        └────────────┘
      Android, Windows,      Any Browser
      Linux, Laptops         (Mobile/Desktop)
```

---

## 🎯 Use Cases

Chatridge is useful in many scenarios, especially where internet is absent:

- 🏔️ **Remote areas** with limited connectivity
- 🎓 **College campuses** for offline demonstrations
- 🎪 **Events or workshops** requiring group communication
- 🆘 **Disaster management** where networks fail
- 🔒 **Secure environments** where internet is restricted
- 👥 **Small teams** needing quick local communication

---

## 📊 Results

After testing the system across multiple devices, the following results were observed:

| Metric | Result |
|:-|:-|
| **Max Simultaneous Devices** | 40–50 devices |
| **Message Delivery** | Instant (via app on Android, Windows, Linux) |
| **Max File Size** | Up to 10 MB |
| **Usable SPIFFS Storage** | ~1.5–1.9 MB |
| **Small Images Capacity** | 15–20 images |
| **Medium Images Capacity** | 3–4 images |
| **Document Capacity** | 1–2 documents |
| **Effective Range** | 15–20 meters |
| **Browser Text Messaging** | Smooth across all browsers |

> **Overall**, the system demonstrated stable offline communication, practical storage handling, and high usability in real-world conditions.

---

## 🔮 Future Scope

### Multi-ESP32 Mesh-Like Network
The system can be extended by connecting **multiple ESP32 units** together to form a mesh-like network. Each ESP32 acts as a relay node, allowing messages to travel from one node to another. This increases the coverage area and enables communication even when users are far from the main ESP32 access point. Such an approach is helpful for large campuses, remote areas, and emergency communication.

### External Storage Support
Since the internal SPIFFS memory is limited, the system can be upgraded using **SD card modules or external flash storage**. This will significantly increase file-sharing capacity and allow users to store and transfer larger files without running out of space.

### Offline Location-Based Services
Future versions can include **location broadcasting** within the local network. ESP32 nodes can send small location or identification signals to help users identify nearby devices offline, which is useful during rescue operations, campus coordination, or group activities.

---

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

### Flutter App Setup

```bash
# Clone the repository
git clone https://github.com/meghanasingareddy/Chatridge.git
cd Chatridge

# Install dependencies
flutter pub get

# Run on mobile
flutter run

# Run on Windows
flutter run -d windows

# Run on Linux
flutter run -d linux
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Windows
flutter build windows --release

# Linux
flutter build linux --release
```

---

## ✅ Conclusion

Chatridge provides a **practical and efficient offline communication platform** that works without internet connectivity. By combining an ESP32-based WiFi network with a cross-platform Flutter application, the system enables nearby devices to exchange text messages and share files in a secure and local environment.

The project is **simple to use, platform-independent**, and suitable for remote communication, emergency situations, and educational demonstrations. Future improvements may include encrypted messaging, group chat support, extended storage, and a richer web interface.

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

<div align="center">

**Built with ❤️ using Flutter & ESP32**

[Report Bug](https://github.com/meghanasingareddy/Chatridge/issues) · [Request Feature](https://github.com/meghanasingareddy/Chatridge/issues) · [GitHub Repository](https://github.com/meghanasingareddy/Chatridge)

</div>
