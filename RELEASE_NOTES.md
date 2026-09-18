## Deck v1.1.3

This release improves reliability across trackpad gestures, the app switcher, and Hosts management, and adds animated gesture demonstrations.

### Trackpad gestures

- Added animated instructions that distinguish resting fingers, tapping, and lifting.
- Improved TipTap and simultaneous three/four-finger tap recognition, including swipe rejection, staggered releases, repeated taps, and malformed-frame handling.
- Editing a shortcut now executes the displayed shortcut instead of a stale saved key code.
- Enabling a new rule for the same gesture automatically disables conflicting rules.
- Improved settings layout and shortcut preset wrapping.
- Three-finger TipTap uses two resting fingers and one tapping finger; see the in-app demonstration for the supported gesture.

### Hosts management

- Updates preserve the existing hosts file's ownership and permissions, verify the written contents, and attempt to restore the original content on write failure.
- One-time authorization grants write access to the current account. Unchanged content does not require another write or authorization.
- Applying an inactive profile enables it; failed system updates do not commit the proposed profile selection.
- Drafts survive switching profiles and restarting the app, and are retained if saving an applied profile fails.
- Added resolution checks that distinguish file success from DNS overrides, including valid IPv4/IPv6 combinations.
- Fixed the global group-exclusivity switch and hover previews. Folders can be collapsed or removed while retaining their profiles.
- Example profiles are disabled for new installations.

### App switcher and settings

- Fixed build errors in global hotkey handling and service-status localization.
- Added invalid/duplicate key validation and fixed modified Space shortcuts accidentally triggering the previous app.
- Explicit app identities no longer fall back to similarly named running applications.
- Improved permission monitoring, palette dismissal, configuration recovery, and window sizing.

### Validation

- 63 automated tests cover gesture recognition, action events, key matching, Hosts writes and failure recovery, persistence, and English/Chinese localization.
- The release workflow runs tests before building and publishing, and the build script verifies the application signature.
- Real trackpad interaction, multi-display/full-screen shortcuts, fresh permission prompts, and older macOS versions still require environment-specific verification. See [QA_REPORT.md](https://github.com/ztiandan/Deck/blob/v1.1.3/QA_REPORT.md) for scope and limitations.

### Installation

1. Download `Deck-macOS.zip` below and unzip it.
2. Quit the previous version of Deck, then replace `Deck.app` in `/Applications`.
3. Open Deck and check Accessibility permission in System Settings if prompted.

Existing configurations in `~/Library/Application Support/Deck` are retained.
