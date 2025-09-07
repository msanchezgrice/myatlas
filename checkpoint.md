### Checkpoint

Date: 2025-09-07

#### Progress summary
- Completed:
  - Scaffolded native iOS app with SwiftUI and XcodeGen
  - Security stack: Keychain, AES-GCM encryption, encrypted file/JSON stores; iCloud backup excluded
  - Domain models and local repository; encrypted image persistence
  - Onboarding and Face ID app lock with auto-lock on background
  - Camera preview and capture pipeline with readiness guards; grid overlay control
  - Library and Case detail with before/after compare slider
  - Initial Vision-based standardization service (align eyes, scale, crop) wired to Case toolbar
  - README and .gitignore
  - Xcode project generated and builds for Simulator

- In progress:
  - Simulator/device camera stability and NaN guards
  - Styling and theme improvements

- Notes:
  - Some simulator logs (eligibility.plist, CA Events) are simulator-specific and benign
  - Replaced unsupported SF Symbol; using supported toggles for grid overlay

#### Remaining TODOs (not completed)
- camera-capture: Implement camera capture with alignment overlays and consistent settings [pending]
- image-processing: Add image processing for alignment/standardization using Vision [pending]
- reminders: Add reminders and local notifications for follow-ups [pending]
- consent-capture: Implement consent capture/signature and storage [pending]
- sharing-hipaa: Implement sharing flow with HIPAA safeguards and audit logs [pending]
- settings-hipaa: Implement settings and HIPAA safeguards (backup exclusion, capture detection) [pending]
- fix-sim-errors: Fix simulator crash and NaN (camera connection, CompareView) [in_progress]
- alignment-overlays: Add alignment overlays and camera UI controls [pending]
- vision-standardization: Implement Vision-based standardization service and wire to CaseDetail [in_progress]
- consent-signature: Add consent capture with signature and storage [pending]
- hipaa-share-audit: Add HIPAA-safe sharing with watermark and audit logs [pending]
- audit-log-view: Create audit log view in settings [pending]
- styling: Improve styling and theme across views [in_progress]
