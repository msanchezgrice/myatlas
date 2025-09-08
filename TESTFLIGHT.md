## TestFlight Upload Guide

Follow these steps to sign, archive, and upload the app to TestFlight.

### Prerequisites
- Apple Developer account with access to App Store Connect
- Xcode signed in (Xcode → Settings → Accounts)
- Bundle ID: `com.miguel.AtlasBeforeAfter`

### 1) Configure signing in Xcode
1. Open `iOS/AtlasBeforeAfter.xcodeproj` in Xcode.
2. Select target `AtlasBeforeAfter` → Signing & Capabilities.
3. Set Team to your developer team.
4. Check “Automatically manage signing”.
5. Version is set to 0.2.0; increment Build (e.g., 2) for re-uploads.

### 2) Archive and Upload (Xcode UI)
1. Product → Archive (Scheme: AtlasBeforeAfter; Destination: Any iOS Device).
2. In Organizer, select the archive → Distribute App → App Store Connect → Upload.
3. Complete the prompts (signing automatic, include symbols) → Upload.
4. In App Store Connect, add testers under TestFlight (internal is immediate; external requires beta review).

### 3) CLI (optional)
From the `iOS/` directory:
```bash
xcodebuild -scheme AtlasBeforeAfter -configuration Release -archivePath build/Atlas.xcarchive -destination 'generic/platform=iOS' -allowProvisioningUpdates archive
xcodebuild -exportArchive -archivePath build/Atlas.xcarchive -exportPath build/export -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates
```
This produces `build/export/AtlasBeforeAfter.ipa`. Upload with Xcode Organizer or Transporter.

### Notes
- If you see “requires a development team”, set the Team on the target as above.
- If upload stalls on processing, wait ~15–30 minutes, then refresh TestFlight.
- Screenshots and App Privacy must be filled out in App Store Connect before external testing.


