# Configuring GitHub Secrets for macOS Code Signing and Notarization

To enable GitHub Actions to automatically sign and notarize your macOS application using your Apple Developer Account, you need to configure specific Repository Secrets in your GitHub repository under **Settings -> Secrets and variables -> Actions**.

Here is the step-by-step guide to gathering and setting up these values:

---

## 1. List of Required GitHub Secrets

| Secret Name | Description | Format |
| :--- | :--- | :--- |
| `BUILD_CERTIFICATE_BASE64` | The Developer ID Application signing certificate exported in `.p12` format and encoded as a Base64 string. | Long text string |
| `P12_PASSWORD` | The password you created when exporting the certificate into the `.p12` file. | Text string |
| `APPLE_DEVELOPER_TEAM_ID` | Your 10-character Apple Developer Team ID. | Alphanumeric (e.g., `A1B2C3D4E5`) |
| `APP_STORE_CONNECT_KEY_ID` | The ID of the private API key generated on App Store Connect. | 10-character string |
| `APP_STORE_CONNECT_ISSUER_ID` | The Issuer ID associated with the API key on App Store Connect. | UUID string (e.g., `572465ad-2d32-4d24-8b6b-c74384a2d801`) |
| `APP_STORE_CONNECT_KEY_BASE64` | The contents of the App Store Connect private API key (`.p8` file) encoded in Base64. | Long text string |

---

## 2. Step-by-Step Instructions

### Step A: Export Certificate & Generate `BUILD_CERTIFICATE_BASE64`
1. Log in to [Apple Developer Certificates](https://developer.apple.com/account/resources/certificates/list).
2. Create a new certificate of type **Developer ID Application** (required for distributing outside the App Store). Download the `.cer` file and double-click it to import it into your Mac's Keychain Access.
3. Open **Keychain Access** on your Mac.
4. Locate the imported certificate (starts with `Developer ID Application: Your Name`).
5. Right-click on the certificate and choose **Export "Developer ID Application: ..."**.
6. Save it as a `.p12` file and enter a password. This password will be your `P12_PASSWORD` secret.
7. Open Terminal and run the following command to convert the `.p12` file to a Base64 string:
   ```bash
   base64 -i path/to/exported-certificate.p12 | pbcopy
   ```
   The Base64 string is now copied to your clipboard. Paste it as the value for `BUILD_CERTIFICATE_BASE64` on GitHub.

---

### Step B: Find `APPLE_DEVELOPER_TEAM_ID`
1. Log in to your [Apple Developer Account](https://developer.apple.com/account/).
2. Go to **Membership Details** or look at the top right corner of the page to copy your **Team ID** (10-character alphanumeric string).

---

### Step C: Create App Store Connect API Key for Notarization
To submit your app for automated malware scanning (Notarization) on GitHub Actions, you need an API key:
1. Log in to [App Store Connect](https://appstoreconnect.apple.com/).
2. Go to **Users and Access** -> select the **Integrations** tab at the top -> select **App Store Connect API**.
3. Click the **+** button to generate a new key. Name it (e.g., `GitHub Actions CI`) and set the role to **Developer** or **Admin**.
4. Once generated, note down the following:
   * **Key ID**: Copy it and save it as the `APP_STORE_CONNECT_KEY_ID` secret.
   * **Issuer ID**: Copy it from the top of the table and save it as the `APP_STORE_CONNECT_ISSUER_ID` secret.
5. Click **Download API Key** to download the private key file (`.p8`). Note: This file can only be downloaded once.
6. Open Terminal and run the following command to convert the `.p8` file to Base64:
   ```bash
   base64 -i path/to/AuthKey_XXXXXXXXXX.p8 | pbcopy
   ```
   Paste this value as the `APP_STORE_CONNECT_KEY_BASE64` secret on GitHub.

---

After configuring these 6 Secrets, pushing a tag starting with `v*` (such as `v1.0.0`) will trigger the workflow, which signs, notarizes, staples, and attaches the final notarized `EzTrash.zip` archive to the GitHub Release!
