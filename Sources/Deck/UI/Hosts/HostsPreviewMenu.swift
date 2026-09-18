import AppKit

/// A native submenu opens on hover without activating Deck's settings window.
/// Read again on every opening so external edits are visible too.
final class HostsPreviewMenu: NSMenu, NSMenuDelegate {
    private let hostsURL: URL
    private(set) var displayedContent: String?

    init(hostsURL: URL = URL(fileURLWithPath: "/etc/hosts")) {
        self.hostsURL = hostsURL
        super.init(title: loc(.menuViewHosts))
        autoenablesItems = false
        delegate = self
        // Keep a placeholder so AppKit treats this as an openable submenu.
        addItem(NSMenuItem(title: "/etc/hosts", action: nil, keyEquivalent: ""))
    }

    required init(coder: NSCoder) { fatalError("Use init(hostsURL:)") }

    func menuWillOpen(_ menu: NSMenu) {
        refreshContent()
    }

    func refreshContent() {
        removeAllItems()
        displayedContent = try? String(contentsOf: hostsURL, encoding: .utf8)
        let text: String
        if let content = displayedContent {
            text = content.isEmpty ? loc(.hostsEmptyContent) : content
        } else {
            text = loc(.hostsReadFailed)
        }

        let preview = NSMenuItem()
        preview.view = HostsPreviewView(content: text, isError: displayedContent == nil)
        addItem(preview)
        addItem(.separator())
        let copy = NSMenuItem(title: loc(.hostsCopy), action: #selector(copyContent), keyEquivalent: "")
        copy.target = self
        copy.isEnabled = displayedContent != nil
        addItem(copy)
    }

    @objc private func copyContent() {
        guard let displayedContent else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(displayedContent, forType: .string)
    }
}

final class HostsPreviewView: NSView {
    let textView = NSTextView()
    let scrollView = NSScrollView()

    init(content: String, isError: Bool) {
        let screenSize = (NSScreen.main?.visibleFrame.size ?? NSSize(width: 1024, height: 768))
        let width = min(560, screenSize.width - 80)
        let maxHeight = min(400, screenSize.height - 160)
        let font = NSFont.monospacedSystemFont(ofSize: 12, weight: .regular)
        let lines = content.components(separatedBy: .newlines)
        let lineHeight: CGFloat = 18
        let bodyHeight = min(maxHeight, max(72, CGFloat(lines.count) * lineHeight + 24))
        super.init(frame: NSRect(x: 0, y: 0, width: width, height: bodyHeight + 40))

        let heading = NSTextField(labelWithString: loc(.hostsSystemActiveTitle))
        heading.font = .systemFont(ofSize: 12, weight: .semibold)
        heading.frame = NSRect(x: 14, y: bodyHeight + 14, width: width - 28, height: 18)
        addSubview(heading)

        scrollView.frame = NSRect(x: 10, y: 8, width: width - 20, height: bodyHeight)
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = true
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder
        scrollView.drawsBackground = false

        textView.isEditable = false
        textView.isSelectable = true
        textView.drawsBackground = false
        textView.font = font
        textView.textColor = isError ? .secondaryLabelColor : .labelColor
        textView.textContainerInset = NSSize(width: 4, height: 4)
        textView.string = content
        textView.isHorizontallyResizable = true
        textView.isVerticallyResizable = true
        textView.textContainer?.widthTracksTextView = false
        textView.textContainer?.containerSize = NSSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude)
        // Let TextKit measure tabs, long lines and Unicode instead of truncating them.
        if let layout = textView.layoutManager, let container = textView.textContainer {
            layout.ensureLayout(for: container)
            let used = layout.usedRect(for: container)
            textView.setFrameSize(NSSize(width: max(width - 20, ceil(used.maxX) + 16),
                                         height: max(bodyHeight, ceil(used.maxY) + 16)))
        }
        scrollView.documentView = textView
        addSubview(scrollView)
    }

    required init?(coder: NSCoder) { return nil }
}
