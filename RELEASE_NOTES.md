## Deck v1.1.6

### Sleep & Wake Recovery

- Restore trackpad gestures and the global app-switcher shortcut after system sleep, display wake, and user-session changes.
- Reconnect the trackpad with bounded retries while the hardware wakes, and clean up previous device registrations.
- Check keyboard listener health and automatically restore disabled or invalid event taps.
- Discard stale input callbacks and incomplete gestures so pre-sleep input cannot trigger actions after waking.
- Preserve your gesture enablement settings during recovery.

### Validation

- 96 automated tests pass, including 17 new recovery regression tests.
- Verified three native trackpad start/stop cycles and a signed release build locally.
- Long-duration hardware sleep still requires manual verification.

### Installation

1. Download `Deck-macOS.zip` below and unzip it.
2. Quit Deck and replace `Deck.app` in `/Applications`.
3. Launch Deck. Your configurations, profiles, and key mappings are preserved.
