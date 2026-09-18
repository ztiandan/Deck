# Changelog

All notable changes to **Deck** will be documented in this file.

---

## [v1.1.2] - 2026-09-18

### Added
- **Haptic Feedback**: Taptic Engine tactile click on Mac trackpads upon gesture trigger, with toggle in Gesture settings.
- **Comprehensive Unit Testing Suite**: 22 automated tests covering Multitouch bridge layout, gestures engine, palette key matching, hosts exclusivity, and localization parity.
- **Expanded Presets**: Added `⌘ T` (New Tab), `⌘ ⇧ [` (Previous Tab), `⌘ ⇧ ]` (Next Tab) buttons in Gesture Details.

### Changed
- **Trackpad Gestures Algorithm**:
  - Expanded tap duration window to `0.04s ~ 0.38s` (up to `0.42s` for 4-finger taps).
  - Increased movement tolerance to `0.08` to accommodate fingertip flattening.
  - Reduced cooldown debounce to `160ms` for rapid successive operations (e.g. closing multiple tabs with `⌘ W`).
  - Added support for both 2-resting/1-tapping and 1-resting/2-tapping in TipTap 3F.
  - Redesigned 4-Finger Tap detection with session-based tracking and strict swipe rejection (< 0.08 displacement).
- **UI & Layout**:
  - Widened Gesture List column to eliminate text truncation (`TipTap Right (3 Fingers Fi...`).
  - Cleaned up naming (removed awkward `"Fix"` suffix).
  - Enhanced list rows with notes subtitle and keycap badges.
  - Added dynamic glowing pulse feedback on gesture trigger.

### Fixed
- **Browser CMD+Click**: Fixed `kCGMouseEventClickState = 1` and button numbers in `ActionExecutor` to properly open links in background tabs across Chrome, Safari, Firefox, Edge, and Arc.
- **Multi-Monitor Mouse Coordinates**: Accurately queried global Quartz screen coordinates.

---

## [v1.1.1] - 2026-09-18

### Added
- **Menu Bar Brand Icon**: Vector-drawn native Deck logo `| )` supporting Light and Dark modes.
- **Palette Space Shortcut**: Space key support to activate last application or mapped targets.

### Fixed
- **Multitouch Memory Layout**: Fixed `MTTouch` struct stride from 48 bytes to 96 bytes, resolving 3-finger and 4-finger gesture failures.
- **Gesture List/Detail Sync**: Converted detail view to use `@Binding` and `.id(gesture.id)`.
- **Accessibility Permissions**: Added designated requirement codesigning and foreground polling to prevent permission loss across rebuilds.

---

## [v1.1.0] - 2026-09-18

### Initial Production Release
- Native macOS status bar application with Hosts Management, Palette App Switcher, and Trackpad Gestures.
