## Phase 2: Feature Plan and Execution Guide

This document lists features to implement next, with technical steps, validation criteria, and known issues. It is written for a coding agent to execute directly.

### 1) Ghost Overlay + Level + Auto‑Snap
- Implement translucent ghost overlay of last captured image in `CameraView` with toggle.
- Add CoreMotion level detection (roll/pitch within ±2° triggers `isLevel = true`).
- If Auto‑Snap enabled and level sustained for 0.8s, trigger capture.
- Persist toggles in `@AppStorage` keys:
  - `capture.enableGhost`, `capture.showGrid`, `capture.rememberZoom`.

Validation:
- Toggle persists across app restarts.
- When level is reached, shutter pulses green; if Auto‑Snap on, photo is captured.

### 2) Ophthalmology Overlays
- Add overlay presets (Frontal, Left/Right Profile, 3/4). Each preset positions alignment lines: pupil line, vertical midline, margins.
- Store selected preset in `@AppStorage("capture.overlayPreset")`.

Validation:
- Switching presets updates overlay immediately; selection persists.

### 3) Virtual Lens / Zoom Presets
- Provide segmented control for 1x/2x/3x (or available). If `rememberZoom` is on, save chosen factor and apply on start.

Validation:
- Zoom factor remains consistent between sessions; respects device capabilities.

### 4) Background Replacement on Export
- DONE: `BackgroundReplaceService` with Vision person segmentation.
- Integrate in `ShareService.watermarked()` controlled by settings.
- Add `Settings` controls: enable/disable and color picker (hex stored in `export.bgColorHex`).

Validation:
- Exported images show chosen background color around subject; disabled state leaves original.

### 5) Tagging
- Model updated: `PhotoAsset.tags: [String]`.
- Repo: `addTag(_:,to:)` added.
- Add simple tag editor in `CaseDetailView` (chip list + add).

Validation:
- Tags persist after app restart; appear on both before/after if tagged.

### 6) Session Workflow (Pending vs Uploaded)
- Create `SessionView` listing captured images not yet assigned to a case as Pending; once attached via repo they are Uploaded.
- Minimal first pass: reuse `PhotoAsset` and flags in memory; stretch goal: persistent queue.

Validation:
- Captures appear under Pending until assigned; moving to case removes from Pending.

### 7) Accessibility & Styling
- Ensure buttons have min tap size, labels readable, consistent spacing per guide.

Validation:
- VoiceOver reads action labels; dynamic type keeps layout stable.

---

## Success Criteria
- No NaN CoreGraphics warnings (fixed in Phase 1).
- Actions never beneath the fold; safe‑area inset bar passes on iPhone 16 simulator.
- Share sheet contains watermarked images when present.
- Reminders can be scheduled and cancelled; notifications authorized on first run.
- Background replacement works and can be toggled.
- Ghost overlay + level + (optional) auto‑snap operate reliably at 60fps without dropped frames.

## Current Known Bugs/Issues
- Share watermark text can overlap bright subjects; future: dynamic contrast or outline.
- Person segmentation quality varies with lighting; add confidence threshold and fallbacks.
- No Canon/DSLR support; plan as separate phase.
- Session queue is not persisted yet.

## Checkpoint (to date)
- Phase 1 complete: NaN fix, sticky actions, share hardening, reminders, Info.plist usage, image editor, camera eye line overlay, library/case styling, iPhone 16 safe areas.
- Phase 2 started: Background replacement integrated, tagging model/repo added, camera ghost/level scaffolding.

## Implementation Notes
- Files to modify next:
  - `CameraView.swift`: add overlay presets UI, virtual lens controls, auto‑snap timer.
  - `CaseDetailView.swift`: tag editor UI for before/after assets.
  - New `SessionView.swift`: pending/uploaded list (optional in Phase 2.1).


