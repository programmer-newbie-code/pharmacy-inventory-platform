# 📱 Google Play Store Console Release Guide

This document is the step-by-step guide for releasing **PharmaLoka** (Pharmacy Inventory Platform) on the Google Play Store Console.

---

## 1. Account & Project Overview

| Item | Value |
| --- | --- |
| **Developer Account** | `<your-developer-email>` |
| **Google Cloud Project** | `<your-gcp-project-id>` |
| **Android Package Name** | `com.programmernewbiecode.pharmacy_inventory_platform` |
| **Upload Keystore SHA-1** | `<your-upload-keystore-sha1>` |
| **Upload Keystore SHA-256** | `<your-upload-keystore-sha256>` |

---

## 2. Google Play Console Setup Steps

### Step 1: Create App in Google Play Console
1. Navigate to [Google Play Console](https://play.google.com/console) logged in with your developer account.
2. Click **Create app**:
   - **App name**: `PharmaLoka` (or `PharmaLoka - Pharmacy POS & Inventory`)
   - **Default language**: `Indonesian (id-ID)` or `English (United States)`
   - **App or Game**: `App`
   - **Free or Paid**: `Free`
   - Accept the Developer Program Policies and US export laws checkboxes.
   - Click **Create app**.

### Step 2: Play App Signing & OAuth Configuration
1. Go to **Release** > **Setup** > **App integrity** / **App signing**.
2. When creating your first release, Play Console will prompt you for Play App Signing:
   - Choose **Use Google-generated key** (recommended) or use the upload key.
   - Play Console will show:
     - **App signing key certificate** (SHA-1 & SHA-256)
     - **Upload key certificate** (SHA-1 fingerprint)
3. ⚠️ **Important for Google Drive Sign-In**:
   - If Play App Signing generates a new signing key for user downloads, copy the **App signing key certificate SHA-1 fingerprint** from Play Console and add it as an additional SHA-1 fingerprint in your Google Cloud Console / Firebase Console Credentials for your Android package name. This ensures Google Drive backup works on both developer builds and Play Store installed builds.

### Step 3: Main Store Listing Assets Checklist
Prepare the following graphic assets before submitting:
- [ ] **App Icon**: 512 x 512 px, 32-bit PNG (with alpha channel), max 1 MB. (Use the official PharmaLoka icon).
- [ ] **Feature Graphic**: 1024 x 500 px, JPG or 24-bit PNG (no alpha), max 15 MB.
- [ ] **Phone Screenshots**:
  - Minimum 2 screenshots (recommended 4-8).
  - Minimum dimension: 320 px, Maximum dimension: 3840 px.
  - Recommended: 1080 x 2400 px or 1080 x 1920 px PNG/JPG.
  - Show POS Screen, Catalog/Inventory, Compounding/Racikan, and Reports.
- [ ] **7-inch / 10-inch Tablet Screenshots**: (Optional for phone-only, recommended for POS tablets).
- [ ] **Short Description**: (Up to 80 characters, e.g., `Aplikasi Manajemen Apotek & Kasir POS Lengkap, Akurat, dan Terintegrasi`).
- [ ] **Full Description**: (Up to 4000 characters covering POS, inventory, batch expiry, racikan, BPOM/SIPNAP compliance, and Google Drive cloud backup).

### Step 4: Policy & Store Content Declarations
Complete each section in **Policy and programs** > **App content**:
- [ ] **Privacy Policy**: Link to the privacy policy page (e.g. `https://programmer-newbie-code.github.io/pharmacy-inventory-platform/`).
- [ ] **App access**: Select *All functionality is available without special access* (or provide a test employee PIN e.g. `123456`).
- [ ] **Ads**: Select *No, my app does not contain ads*.
- [ ] **Content rating**: Complete the IARC questionnaire (Utility / Productivity / Medical tools; Rating: 3+ / Everyone).
- [ ] **Target audience and content**: Target age 18+.
- [ ] **Data safety**:
  - Personal info: Name & Email (for Google Drive backup authentication if connected).
  - Financial info: In-app POS transaction records stored locally in SQLite database.
  - Data transfer: All data is stored on-device with optional user-controlled backup to Google Drive.
- [ ] **Financial features**: Select *Internal business accounting / inventory management*, not public banking/lending.

### Step 5: Uploading Release Bundle (AAB)
1. Go to **Release** > **Testing** > **Closed testing** (or **Production**).
2. Click **Create new release**.
3. Upload the `pharmacy-inventory-platform-android-vX.Y.Z.aab` bundle from the GitHub Actions release artifacts.
4. Enter **Release name** (e.g., `1.8.2` or `1.9.0`).
5. Enter **Release notes** (e.g., in Indonesian and English from `CHANGELOG.md`).
6. Click **Save** > **Review release** > **Start rollout**.

---

## 3. GitHub Actions CI Secrets (for automated signing in CI)

To have GitHub Actions sign release builds automatically with the registered upload keystore:

1. In GitHub repo settings > **Secrets and variables** > **Actions**, add:
   - `ANDROID_KEYSTORE_BASE64`: Base64 encoded string of `upload-keystore.jks`.
   - `ANDROID_KEYSTORE_PASSWORD`: Keystore password.
   - `ANDROID_KEY_ALIAS`: Key alias (`upload`).
   - `ANDROID_KEY_PASSWORD`: Key password.
   - `GOOGLE_DRIVE_DESKTOP_CLIENT_ID`: OAuth Client ID for Windows.
   - `GOOGLE_DRIVE_DESKTOP_CLIENT_SECRET`: OAuth Client Secret for Windows.

2. When a release tag `vX.Y.Z` is pushed, CI automatically builds the signed `.aab` ready for direct upload to Google Play Console.
