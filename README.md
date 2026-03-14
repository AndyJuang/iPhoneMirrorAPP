# iPhoneMirrorAPP 📱🖥️

A native, lightweight macOS application built with Swift and SwiftUI that allows you to mirror your iPhone or iPad screen directly to your Mac via USB at near-zero latency. Perfect for presentations, recording, and live streaming.

## ✨ Features

- **USB Plug & Play**: Simply connect your iPhone/iPad to your Mac via USB to start mirroring.
- **Dynamic Aspect Ratio & Auto-Resizing**: 
  - The window automatically adapts to the exact aspect ratio of your device's screen.
  - No letterboxing (black bars).
  - Instantly responds to device rotation (portrait to landscape).
- **Presentation Highlights**:
  - Show visual effects when you click your mouse to highlight actions on the screen during a presentation or tutorial.
  - Choose between: **Giant Cursor**, **Giant Hand**, **Giant Circle**, or **None (Off)**.
- **Menu Bar Integration**: Easily switch between your iPhone, iPad, or any other camera directly from the macOS Menu Bar.
- **Borderless Draggable Window**: Drag the app window seamlessly from anywhere on its background without a clunky title bar.

## 🚀 How to Use

1. **Connect** your iPhone or iPad to your Mac using a Lightning or USB-C cable.
2. **Launch** `iPhoneMirror.app`.
3. If this is your first time, you may need to unlock your iOS device and tap **"Trust This Computer"**.
4. The app will automatically detect your device and display its screen.
5. If you have multiple devices connected (or want to select a camera), navigate to the top macOS Menu Bar and click on **Device** to select your input.

### Using Highlights
To toggle the click highlight effect:
- Go to the top macOS Menu Bar -> **Highlight** -> Select your preferred animation style or turn it off.

## 🛠️ How to Build from Source

This app is a standalone Swift file designed for rapid compilation without needing Xcode.

**Requirements:**
- macOS 11.0+
- Swift Compiler (`swiftc`) installed (usually via Xcode Command Line Tools)

**Compilation Command:**

```bash
# 1. Compile the app package
swiftc MirrorApp.swift -parse-as-library -o iPhoneMirror.app/Contents/MacOS/iPhoneMirror

# 2. Re-sign the app so macOS allows it to access cameras/hardware
codesign --sign - --force --deep iPhoneMirror.app
```

*Note: The project director must contain the standard `.app` bundle structure (e.g., `iPhoneMirror.app/Contents/MacOS/`, `iPhoneMirror.app/Contents/Info.plist`).*

## 💡 How it Works (Under the Hood)
- By default, macOS does not treat USB-connected iOS devices as standard webcams.
- This app uses the low-level `CoreMediaIO` API to enable `kCMIOHardwarePropertyAllowScreenCaptureDevices`.
- Once enabled, the generic `AVCaptureDevice` system can natively read the uncompressed video stream from your iPhone's screen.

## 📝 License
Feel free to fork, modify, and use this code for any personal or commercial presentation use cases.
