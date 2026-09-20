## Deck v1.1.5

### Global Timezone Switcher & Major Economies

- **Major Economies Quick Switch**: Real-time display of local times for leading global economies (China, US East/West/Central, UK, EU/Germany/France, Japan, Singapore, Hong Kong, Australia, India, UAE, Canada) with one-click switching.
- **Global IANA Timezone Support**: Search and switch across 400+ world timezones with real-time UTC offsets and relative difference indicators.
- **Menu Bar Integration**: Dedicated status bar section displaying current timezone and live local time, with an instant-switch submenu.
- **Optional Passwordless Switching**: One-time authorization allows instant timezone changes without repetitive password prompts.

### Startup & Background Experience

- **Silent Launch by Default**: Deck now starts quietly in the macOS menu bar without automatically popping up the settings window.
- **Launch at Login (SMAppService)**: Native macOS 13+ launch-at-login support configurable in General Settings.
- **Streamlined Preferences**: Removed redundant settings cards for a cleaner, faster workflow.

### Validation

- 79 automated unit tests covering all modules: Timezone management, Launch at Login, Hosts, Palette, Trackpad gestures, and bilingual localization coverage.
- Code signed with Apple Developer ID.

### Installation

1. Download `Deck-macOS.zip` below and unzip it.
2. Replace `Deck.app` in `/Applications`.
3. Launch Deck. All your configurations, profiles, and key mappings are preserved.
