# iPhoneMirrorAPP 📱🖥️

[English](#english) | [繁體中文](#繁體中文)

---

## English

A native, lightweight macOS application built with Swift and SwiftUI that allows you to mirror your iPhone or iPad screen directly to your Mac via USB at near-zero latency. Perfect for presentations, recording, and live streaming.

### ✨ Features

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

### 🚀 How to Use

1. **Download the app** from the [Releases page](https://github.com/AndyJuang/iPhoneMirrorAPP/releases) or build it yourself.
2. **Connect** your iPhone or iPad to your Mac using a Lightning or USB-C cable.
3. **Launch** `iPhoneMirror.app`.
4. If this is your first time, you may need to unlock your iOS device and tap **"Trust This Computer"**.
5. The app will automatically detect your device and display its screen.
6. If you have multiple devices connected (or want to select a camera), navigate to the top macOS Menu Bar and click on **Device** to select your input.

**Using Highlights**
To toggle the click highlight effect:
- Go to the top macOS Menu Bar -> **Highlight** -> Select your preferred animation style or turn it off.

### 🛠️ Build from Source

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

### 💡 How it Works (Under the Hood)
- By default, macOS does not treat USB-connected iOS devices as standard webcams.
- This app uses the low-level `CoreMediaIO` API to enable `kCMIOHardwarePropertyAllowScreenCaptureDevices`.
- Once enabled, the generic `AVCaptureDevice` system can natively read the uncompressed video stream from your iPhone's screen.

---

## 繁體中文

這是一款使用原生 Swift 與 SwiftUI 打造的輕量級 macOS 應用程式，它能讓你透過 USB 線以「接近零延遲」的速度，將 iPhone 或 iPad 的螢幕直接投射到你的 Mac 畫面上。非常適合用於教學簡報、螢幕錄影或是直播實況。

### ✨ 核心功能

- **隨插即用**: 只需要將 iOS 設備接上 Mac 的 USB，開啟 App 就能自動連接。
- **動態比例自動縮放**: 
  - 視窗會自動死死扣住你的手機螢幕比例，永遠不會出現黑邊（Letterboxing）。
  - 對手機畫面的直向或橫向旋轉，能做到瞬間無縫變形。
- **點擊特效與輔助指示**:
  - 專為教學與簡報設計，用滑鼠點擊 App 中展示的手機畫面時會跳出特殊動畫，讓觀眾知道你點哪裡！
  - 可從選單列選擇：**巨型游標**、**點擊的巨手**、**巨大紅圈** 或是 **關閉 (None)**。
- **選單列無縫切換裝置**: 如果有其他攝影機或多台 iOS 設備，你可以直接從 Mac 的系統頂部工具列（Menu Bar）隨時自由切換輸入來源。
- **無邊框全區拖曳**: 我們拔掉了笨重的應用程式標題列。想要移動畫面，點擊畫面上任何一處（或是三指）都能輕鬆把整個視窗拖著走。

### 🚀 如何使用

1. 到本專案的 [Releases 頁面](https://github.com/AndyJuang/iPhoneMirrorAPP/releases) 下載最新的 `.dmg` 檔案，或是從原始碼自己編譯。
2. 使用傳輸線將 iPhone / iPad **連上 Mac**。
3. **開啟** `iPhoneMirror.app`。
4. 第一次使用時，請解鎖手機畫面並點選 **「信任這部電腦」**。
5. App 打開後，就會自動抓取你的手機實時螢幕。
6. 前往 Mac 螢幕頂部的「Menu Bar」，你可以：
   - 到 **Device** 欄位切換你要觀看的設備。
   - 到 **Highlight** 指定你要點擊的滑鼠動畫效果！

### 🛠️ 如何從原始碼編譯打包

本專案只有一支 SwiftUI 程式碼，不依賴龐大的 Xcode 專案即可獨立編譯。確保 Mac 有安裝 Xcode 指令列工具後執行：

```bash
# 1. 編譯二進位執行檔到 bundle 中
swiftc MirrorApp.swift -parse-as-library -o iPhoneMirror.app/Contents/MacOS/iPhoneMirror

# 2. 重新給予本機簽名（非常重要，不簽名 macOS 不會放行其讀取攝影機）
codesign --sign - --force --deep iPhoneMirror.app
```

### 💡 原理解析
基於蘋果對於隱私的限制，macOS 內建並不把透過 USB 連接的手機視為普通的網路攝影機（Webcam）。
這支 App 在背後利用了極底層的 `CoreMediaIO` API 強制啟用 `kCMIOHardwarePropertyAllowScreenCaptureDevices` 硬體標記參數。將隱藏在底層的 USB 螢幕視窗釋放後，我們才得以用非常標準的 `AVCaptureDevice` 把 iOS 極高速的無損視訊串流拉出來播放！
