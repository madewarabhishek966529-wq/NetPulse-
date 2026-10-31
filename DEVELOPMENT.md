# NetPulse Developer Guide

This guide provides instructions for setting up your development workspace, running tests, extending features, and creating release builds for **NetPulse**.

---

## 🛠️ Development Setup

### 1. Prerequisites
- **Flutter SDK**: 3.24+ (Dart 3.5+)
- **Windows 10/11 x64** with Developer Mode enabled (for symlink support)
- **Visual Studio 2022** with "Desktop development with C++" workload
- **Inno Setup 6** (for compiling `.exe` installers)

### 2. Verify Your Toolchain
Check that Flutter recognizes your Windows desktop toolchain:
```powershell
flutter doctor -v
```

Ensure `Windows (desktop)` is listed under connected devices:
```powershell
flutter devices
```

---

## 🚀 Running the Application in Development

To start the application during development:
```powershell
flutter run -d windows
```

### Hot Reload & Hot Restart
- Press `r` in the terminal for Hot Reload.
- Press `R` in the terminal for Hot Restart.

---

## 🧪 Running Automated Tests

Run the complete test suite:
```powershell
flutter test
```

Run specific test groups:
```powershell
# Unit tests
flutter test test/unit/

# Live Aria2 RPC Engine Integration Test
flutter test test/integration/aria2_live_engine_test.dart

# Widget tests
flutter test test/widget_test.dart
```

---

## 🔍 Code Quality & Static Analysis

Analyze the codebase for lint issues, type safety, and formatting:
```powershell
flutter analyze
```

---

## 📦 Building the Windows Release & Installer

### Step 1: Compile Flutter Windows Executable
```powershell
flutter build windows --release
```
The compiled binaries, DLLs, and assets will be output to:
`build\windows\x64\runner\Release\`

### Step 2: Compile Inno Setup Installer
Run the Inno Setup compiler (`iscc.exe`):
```powershell
& "C:\Users\<User>\AppData\Local\Programs\Inno Setup 6\ISCC.exe" installer\netpulse.iss
```
The final standalone installer will be created at:
`dist\NetPulse-Setup.exe`

---

## 🔌 Testing the Browser Extension

1. Build or run the NetPulse desktop app.
2. Open Chrome: navigate to `chrome://extensions`.
3. Enable **Developer mode**.
4. Click **Load unpacked** and select `browser_extension\chrome`.
5. Run `browser_extension\native_host\register_host.bat` (or use the 1-Click register button in the NetPulse GUI).
6. Try clicking a download link or right-clicking on an image/media URL and selecting **Download with NetPulse**.

