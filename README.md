# EzTrash — macOS Application Cleaner

EzTrash is a lightweight, native macOS application designed to completely uninstall applications and scan for associated leftover files (caches, application support, preferences, logs, launch agents). The UI is built entirely in compliance with the **Apple Human Interface Guidelines (HIG)** to provide a smooth, premium, and safe user experience.

---

## 🚀 Key Features

* **Premium Native UI**: Built using 100% native macOS components (`NavigationSplitView`, `Inset List`, standard toolbars, and segmented pickers) with modern aesthetics.
* **Smart & Efficient Scanning**: 
  * Instantly scans the `/Applications` folder.
  * Deep scans for leftovers in system and user library directories under `~/Library` (including *Application Support, Caches, Preferences, Logs, Launch Agents, Saved Application State, HTTPStorages, Containers, Group Containers*).
* **Privacy-Friendly TCC Behavior**: Uses a unified, cached sequential pre-scan on startup to prevent repeated macOS privacy and system access prompts.
* **Biometric & Password Authentication**: 
  * Integrates **LocalAuthentication** to request Touch ID or the system password before moving files to the Trash.
  * Displays a smooth, real-time sequential progress sheet during the uninstallation process.
* **System Safeguards**: 
  * Categorizes applications into **User Applications** and **System / App Store** groups in the sidebar.
  * Automatically detects system-protected or App Store-managed applications owned by `root` (UID = 0), marking them with a **lock icon** and disabling the uninstall button to prevent accidental system damage.
* **Bilingual Support**: Instant toggle between **English (EN)** and **Vietnamese (VI)** directly from the toolbar.
* **Default Window Geometry**: Launches centered on the screen at 70% width and 60% height of the visible frame (respecting the menu bar and Dock).

---

## 🛠️ Technology Stack

* **Swift & SwiftUI**: Core layout and application state management.
* **AppKit**: System integration (`NSWorkspace`, `NSWindow`, `NSScreen`, `NSImage`).
* **LocalAuthentication**: Biometric and system passcode verification.
* **Xcode 15+ & Swift 5.10+**: Requires macOS 14.0 (Sonoma) or newer.

---

## 🏗️ Setup & Compile Instructions

### System Requirements:
* macOS 14.0+ (Sonoma)
* Xcode 15.0+

### How to Compile:
1. Open the project file `EzTrash.xcodeproj` in Xcode.
2. Select the **EzTrash** target and set the run destination to **My Mac**.
3. Press `Cmd + R` to build and run in Debug mode, or go to **Product > Archive** to bundle the application.

> [!IMPORTANT]  
> Because the application reads and cleans files inside system directories (`~/Library`), the **App Sandbox** is disabled in the entitlements file `EzTrash.entitlements` (`com.apple.security.app-sandbox = false`).

---

## 🛡️ CI/CD & Code Signing

The project is equipped with a **GitHub Actions CI/CD workflow** that automatically builds, signs using your Apple Developer certificate, notarizes with Apple, and uploads a zipped release asset when a tag starting with `v*` is pushed:
* Workflow file: `.github/workflows/release.yml`
* Configuration Guide: See **[CI_CD_GUIDE.md](file:///Volumes/Cinny/Cinny/Project/EzTrash/CI_CD_GUIDE.md)** for detailed instructions on setting up GitHub Secrets.
# ez-trash
