# App Icon Setup Guide

This guide will help you set up your new app icon from icon.kitchen.

## Quick Setup Steps

### Step 1: Download Your Icon

1. **Open the icon design in your browser:**
   ```
   https://icon.kitchen/i/H4sIAAAAAAAAAx2NsQ7DIBBD%2F8UzQ2e%2BokO2qsNFdxBUyEVAGkUR%2Fx7IYtlPln3hT3GXAnuBKf%2BmRZLAOopFDJyfzq1HhEReMMCbmMPqR7%2FqBvsyyMEv9XGz1qrpsVHcYK0ZJOU9josPaOWsgftS0NL1kBnfdgOKsk1KhQAAAA%3D%3D
   ```

2. **On the icon.kitchen page:**
   - Look for an "Export" or "Download" button
   - Click it and choose PNG format
   - Select size: **1024x1024 pixels** (or larger)
   - Download the file

3. **Save the icon:**
   - Rename the downloaded file to: `app_icon.png`
   - Move it to: `assets/icon/app_icon.png` (create the folder if needed)

### Step 2: Generate All Platform Icons

Once you have `app_icon.png` in the `assets/icon/` folder, run:

```bash
flutter pub get
flutter pub run flutter_launcher_icons
```

This will automatically generate icons for:
- ✅ Android (all screen densities)
- ✅ iOS (all device sizes)
- ✅ Web (favicon and manifest icons)
- ✅ Windows (app icon)
- ✅ macOS (all sizes)

### Step 3: Verify

After running the commands, you should see:
- Icons generated in `android/app/src/main/res/mipmap-*/`
- Icons generated in `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- Icons generated in `web/icons/`
- Icons updated in `macos/Runner/Assets.xcassets/AppIcon.appiconset/`
- Icons updated in `windows/runner/resources/`

## Troubleshooting

**If the icon doesn't appear:**
1. Make sure `app_icon.png` exists in `assets/icon/`
2. Run `flutter clean` then `flutter pub get`
3. Run `flutter pub run flutter_launcher_icons` again
4. Rebuild your app: `flutter run`

**If you get errors:**
- Ensure the icon file is a valid PNG
- Check that the file size is at least 1024x1024 pixels
- Verify the file path in `pubspec.yaml` matches your file location

## Alternative: Manual Icon Placement

If you prefer to manually place icons, you'll need to generate multiple sizes:

### Android:
- `mipmap-mdpi/ic_launcher.png` - 48x48
- `mipmap-hdpi/ic_launcher.png` - 72x72
- `mipmap-xhdpi/ic_launcher.png` - 96x96
- `mipmap-xxhdpi/ic_launcher.png` - 144x144
- `mipmap-xxxhdpi/ic_launcher.png` - 192x192

### iOS:
- Various sizes from 20x20 to 1024x1024 (see `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json`)

### Web:
- `icons/Icon-192.png` - 192x192
- `icons/Icon-512.png` - 512x512
- `icons/Icon-maskable-192.png` - 192x192
- `icons/Icon-maskable-512.png` - 512x512

The automated approach with `flutter_launcher_icons` is recommended as it handles all sizes automatically.

