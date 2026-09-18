### Deck v1.1.2 🚀

Release build for **Deck** macOS native efficiency platform.

---

### 🌟 What's New in v1.1.2

#### 1. 🖐️ Trackpad Gestures Engine & Sensitivity Upgrade
- **Relaxed Tap Duration Window**: Broadened the tap detection window from `< 0.28s` to `0.04s ~ 0.38s` (up to `0.42s` for 4-finger taps), accommodating natural human finger pacing and eliminating missed triggers.
- **Improved Displacement Tolerance**: Increased movement threshold to `0.08` to account for natural fingertip flattening and subtle contact rotation without misidentifying as drags or swipes.
- **Reduced Debounce Cooldown**: Shortened cooldown from `300ms` to `160ms`, enabling users to rapidly close multiple tabs (`⌘ W`) or navigate desktops (`^ →`) in quick succession.
- **TipTap 3F Flexibility**: Supported both `2 resting fingers + 1 tapping finger` and `1 resting finger + 2 tapping fingers` on both left and right sides.
- **4-Finger Tap Swipe Rejection**: Rebuilt multi-finger session tracking to reliably capture 4-finger taps while strictly rejecting 4-finger swipes (Mission Control / workspace switching).

#### 2. 🔗 Browser Background Tab Opening Fix (CMD + Click)
- Added `kCGMouseEventClickState = 1`, proper button numbers, and synthetic Command key states in `ActionExecutor`, ensuring Chrome, Safari, Arc, Firefox, and Edge 100% reliably open links in background tabs.
- Corrected mouse cursor coordinate mapping for multi-monitor and Retina display setups.

#### 3. 📳 Taptic Engine Haptic Feedback
- Added crisp physical vibration feedback powered by `NSHapticFeedbackManager` whenever a trackpad gesture triggers.
- Added a dedicated "Haptic Feedback on Trackpad" toggle in Gesture Details (enabled by default).

#### 4. 🎨 UI Polish & Layout Enhancements
- **No More Text Truncation**: Removed the awkward `"Fix"` suffix from English names (`"TipTap Right (2 Fingers)"`, `"TipTap Left (2 Fingers)"`, etc.) and widened the sidebar column, eliminating truncated text like `"TipTap Right (3 Fingers Fi..."`.
- **Enhanced Gesture List Rows**: Rows now display the gesture title, functional note description, and a clear keycap badge, with dynamic glowing pulse feedback upon gesture activation.
- **Expanded Preset Shortcuts**: Added quick preset buttons for `⌘ T` (New Tab), `⌘ ⇧ [` (Previous Tab), and `⌘ ⇧ ]` (Next Tab).

#### 5. 🧪 Comprehensive Automated Unit Test Suite
- Added 22 automated unit tests covering the Multitouch bridge memory layout, gesture recognition engine, action executor, palette key matching, Hosts mutual exclusivity, and full localization parity (100% pass rate).

---

#### 📥 Installation
1. Download `Deck-macOS.zip` below.
2. Unzip to obtain `Deck.app`.
3. Drag `Deck.app` into your `/Applications` folder.
4. If macOS displays a Gatekeeper prompt on first launch, right-click (or Control-click) `Deck.app` and choose **Open**, or run:
   ```bash
   xattr -cr /Applications/Deck.app
   ```
