## Deck v1.1.4

### Hosts preview in the menu bar

- Hover over **View Hosts** to open a scrollable preview of the current `/etc/hosts`, with a Copy action.
- Each opening reads the system file again, including changes made outside Deck.
- Long lines and large previews support horizontal and vertical scrolling. Read failures clear stale content and disable copying.
- Removed the **Active Hosts** page from the main window; profile editing remains available under **Profiles**.

### Fixes and polish

- Removed the bright vertical divider between the sidebar and content area for a cleaner dark appearance.
- Hosts profile switching now reports a configuration-save failure instead of returning success.
- Resetting app mappings preserves the selected theme, trigger key, and palette position.

### Validation

- 70 automated tests cover the existing features plus preview refresh, empty/unreadable files, scrolling, persistence errors, and mapping reset behavior.
- Release builds verify the application signature. Main-window changes were checked in the native app; real pointer-hover behavior remains an environment-specific manual check.

### Installation

1. Download `Deck-macOS.zip` below and unzip it.
2. Quit Deck, then replace `Deck.app` in `/Applications`.
3. Open Deck. Existing profiles, mappings, gestures, and preferences are retained.
