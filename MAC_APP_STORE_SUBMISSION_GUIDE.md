# Guide: Submitting a macOS Application to the Mac App Store

This guide outlines the step-by-step process of preparing, signing, and submitting your macOS application (such as EzTrash) to the Mac App Store.

---

## ⚠️ CRITICAL WARNING FOR EZTRASH

Before you begin, please note a major security constraint enforced by Apple:
> **Apple requires all applications distributed via the Mac App Store to have the App Sandbox enabled.**

For **EzTrash**, the App Sandbox is currently disabled (`com.apple.security.app-sandbox = false`) because the app needs to scan `/Applications` and write to `~/Library` (Caches, Application Support, etc.) to clean leftover files.
* If you enable the App Sandbox, the app will lose access to these system directories and fail to function.
* If you keep the App Sandbox disabled, Apple **will reject** the app during the App Store review process.

### Possible Workarounds:
1. **Developer ID Distribution (Recommended)**: Distribute your app outside the App Store (e.g., via GitHub or your website) using Developer ID signing and Apple Notarization (already configured in your CI/CD). This allows the app to run without Gatekeeper warnings while retaining system-level access.
2. **Temporary Exception Entitlements**: You can request temporary sandbox exceptions in your `.entitlements` file. However, Apple strictly reviews these exceptions, and you must provide a strong justification (which may still be rejected).

If you still wish to proceed with submitting a Mac app to the App Store, follow the steps below.

---

## Step 1: App Store Connect Setup

1. Go to [App Store Connect](https://appstoreconnect.apple.com/) and sign in with your Apple Developer Account.
2. Navigate to **Apps** and click the **+ (Add)** button -> select **New App**.
3. Fill in the required fields:
   * **Platforms**: Select **macOS**.
   * **Name**: The name of your app as it will appear in the App Store.
   * **Primary Language**: English (or your preferred language).
   * **Bundle ID**: Select the explicit Bundle ID matching your Xcode project.
   * **SKU**: A unique identifier for your app (internal use only, e.g., `com.cinny.eztrash.sku`).
   * **User Access**: Set permissions (usually "Full Access").
4. Click **Create**.

---

## Step 2: Configure App Store Metadata

On the App Store Connect page for your app, fill in the following details:
1. **Screenshots**: Upload at least one high-resolution screenshot of your app running on macOS (dimensions like `2880 x 1800` or `2560 x 1600`).
2. **Description & Keywords**: Explain what your app does and add relevant search terms.
3. **Support URL & Marketing URL**: Links to your support page or website.
4. **App Privacy Policy**: Link to your privacy policy page (required for App Store distribution).
5. **General Information**: Select app categories and set age rating.

---

## Step 3: Configure Xcode for App Store Distribution

1. Open `EzTrash.xcodeproj` in Xcode.
2. Select the **EzTrash** project in the sidebar, select the target, and go to the **Signing & Capabilities** tab.
3. Check **Automatically manage signing**.
4. Set the **Team** to your Apple Developer Account Team.
5. In **Signing Certificate**, ensure it resolves to **Apple Distribution** (for App Store releases).
6. (If submitting to the App Store) Under **Capabilities**, ensure **App Sandbox** is added and configured.

---

## Step 4: Archive and Upload the Build

1. In Xcode, set the active scheme to **EzTrash** and the run destination to **Any Mac (Apple Silicon, Intel)**.
2. Go to the menu bar and select **Product > Archive**.
3. Once the archive process completes, the **Organizer** window will open.
4. Select the latest archive and click **Distribute App** on the right side.
5. Choose **App Store Connect** as the distribution method and click **Next**.
6. Select **Upload** (to upload the app directly to App Store Connect) and click **Next**.
7. Keep the default options for strip Swift symbols and compiler options, and click **Next**.
8. Let Xcode automatically manage certificates and signing. Xcode will communicate with Apple servers to create the App Store Distribution provisioning profiles.
9. Review the summary page and click **Upload**. Xcode will notify you once the upload is successful.

---

## Step 5: Submit for Review in App Store Connect

1. Go back to App Store Connect and navigate to your app's dashboard.
2. Scroll down to the **Build** section. It may take 10-15 minutes for the uploaded build to process.
3. Click the **+** icon next to **Build** and select the version you uploaded from Xcode.
4. Complete the **App Review Information**:
   * Provide contact details.
   * Add review notes (e.g., explaining why specific system permissions or entitlements are used).
5. Set the **Version Release** method (e.g., release immediately after approval, or manually release).
6. Click **Save** in the top right corner.
7. Click **Submit for Review** (or **Add for Review**).

Your app status will change to **Waiting for Review**. Apple's review process for Mac apps typically takes 24 to 48 hours.
