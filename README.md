# Atlas Before & After (iOS)

A native SwiftUI iPhone app for physicians to capture, standardize, and manage surgical before/after photos with local, encrypted storage.

## Features (MVP)
- Face ID/passcode app lock with auto-lock on background
- Onboarding (provider, biometrics)
- Camera capture using AVFoundation
- Encrypted storage (CryptoKit AES-GCM, key in Keychain)
- Case library with patient/case models
- Before/After comparison slider in case detail
- Local reminders (UserNotifications)

## Security & Compliance
- All PHI stored locally in Application Support and excluded from iCloud/iTunes backups
- Symmetric AES-256 key generated and stored in Keychain; images and JSON are encrypted at rest
- Face ID/app lock required by default
- Next steps for HIPAA readiness: consent capture/signature, audit logs for access/exports, configurable retention, auto-redaction, emergency lockout, screenshot/recording detection messaging

## Requirements
- Xcode 16+ (iOS 16 target)
- Command line: XcodeGen (optional if you use the generated project already in `iOS/`)

## Build & Run (Xcode)
1. Open the project: `iOS/AtlasBeforeAfter.xcodeproj`
2. Select an iPhone Simulator (e.g., iPhone 15)
3. Run (Cmd+R)

First-run tips:
- Approve Camera and Notification permissions in the simulator
- Use Library tab (+) to create a sample case, then Camera to capture and attach photos

## Build & Run (CLI)
```bash
cd iOS
xcodebuild -project AtlasBeforeAfter.xcodeproj -scheme AtlasBeforeAfter -destination 'generic/platform=iOS Simulator' -configuration Debug build
```

## Repository Layout
- `iOS/project.yml`: XcodeGen config
- `iOS/AtlasBeforeAfter/`:
  - `AtlasBeforeAfterApp.swift`: App entry
  - `ContentView.swift`: Tabs and environment wiring
  - `Features/`: UI modules (Library, Camera, Reminders, Settings, Lock, Onboarding)
  - `Models/`: Domain models
  - `Services/`: AppLock, Security, Storage, Repository
  - `Assets.xcassets/`: Assets and app icon

## Roadmap
- Alignment overlays, gridlines, and pose guidance
- Vision-based face/eye alignment and standardization
- Consent capture with signature and versioned policy storage
- HIPAA-safe share flow with templated consent, watermarking, and audit trail
- Case tagging, search, and export bundles

## License
Private, all rights reserved.
