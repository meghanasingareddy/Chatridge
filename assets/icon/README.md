# App Icon Setup

To update the app icon:

1. Export your icon from icon.kitchen as a PNG file (1024x1024 recommended)
2. Save it as `app_icon.png` in this directory (`assets/icon/app_icon.png`)
3. Run the following command to generate all platform icons:
   ```
   flutter pub get
   flutter pub run flutter_launcher_icons
   ```

The icon will be automatically generated for:
- Android (all densities)
- iOS (all sizes)
- Web (favicon and manifest icons)
- Windows (app icon)
- macOS (all sizes)

## Current Icon Source
The icon design URL from icon.kitchen:
https://icon.kitchen/i/H4sIAAAAAAAAAx2NsQ7DIBBD%2F8UzQ2e%2BokO2qsNFdxBUyEVAGkUR%2Fx7IYtlPln3hT3GXAnuBKf%2BmRZLAOopFDJyfzq1HhEReMMCbmMPqR7%2FqBvsyyMEv9XGz1qrpsVHcYK0ZJOU9josPaOWsgftS0NL1kBnfdgOKsk1KhQAAAA%3D%3D

