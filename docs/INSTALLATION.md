# Installation & Troubleshooting Guide

This document describes how to install, update, and troubleshoot **PharmaLoka — Pharmacy Inventory Platform** on Windows Desktop and Android devices.

---

## 💻 Windows Desktop Installation

### Option A: Standard MSIX Installer (Recommended)

1. Download `pharmacy-inventory-platform-windows-vX.Y.Z.msix` from the [Latest GitHub Release](https://github.com/programmer-newbie-code/pharmacy-inventory-platform/releases/latest).
2. **Double-click** the `.msix` file.
3. Windows App Installer will open automatically showing the app title, version, and publisher.
4. Click **Install**.
5. Once installed, launch the app directly from your **Start Menu** or **Desktop Shortcut**.

---

### 🚨 Fixing Windows MSIX Certificate Error `0x800B010A`

If Windows displays the following error when opening the `.msix` package:
> *"This app package’s publisher certificate could not be verified. Contact your system administrator or the app developer to obtain a new app package with verified certificates (0x800B010A)"*

Follow these steps to trust the self-signed publisher certificate:

1. **Right-click** the downloaded `.msix` file and select **Properties**.
2. Click the **Digital Signatures** tab.
3. Click on the listed signature (`ApotekMedikaDev` or `programmer-newbie-code`) and click **Details**.
4. In the Digital Signature Details dialog, click **View Certificate**.
5. Click **Install Certificate...**.
6. Store Location: Select **Local Machine** (requires Administrator access) and click **Next**.
7. Select **Place all certificates in the following store** and click **Browse...**.
8. Select **Trusted People** (or **Trusted Root Certification Authorities**) and click **OK**.
9. Click **Next** -> **Finish**. You will see a prompt saying *"The import was successful."*
10. **Re-open** the `.msix` installer. The **Install** button will now be enabled!

---

### Option B: Portable ZIP Package (No Certificate Required)

If you prefer not to install certificates:
1. Download `pharmacy-inventory-platform-windows-vX.Y.Z.zip` from GitHub Releases.
2. Extract the ZIP archive to a local folder (e.g., `C:\Apps\PharmacyInventory`).
3. Run `pharmacy_inventory_platform.exe` directly.

---

## 📱 Android Mobile Installation

1. Download `pharmacy-inventory-platform-android-vX.Y.Z.apk` to your Android device.
2. Open the file manager on your Android device and tap the `.apk` file.
3. If prompted, allow installation from **Unknown Sources** / **This Source**.
4. Tap **Install** or **Update**.
