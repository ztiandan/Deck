import SwiftUI
import AppKit

public struct ViewHostsView: View {
    @ObservedObject var hostsStore = HostsStore.shared
    @ObservedObject var l10n = LocalizationManager.shared
    @State private var activeContent: String = ""
    @State private var copied: Bool = false

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏状态提示
            HStack {
                Text(loc(.hostsSystemActiveTitle))
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.secondary)

                Spacer()

                Button(action: {
                    refreshContent()
                }) {
                    Label(loc(.hostsRefresh), systemImage: "arrow.clockwise")
                }
                .controlSize(.small)

                Button(action: {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(activeContent, forType: .string)
                    copied = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        copied = false
                    }
                }) {
                    Label(copied ? loc(.hostsCopied) : loc(.hostsCopy), systemImage: copied ? "checkmark" : "doc.on.doc")
                }
                .controlSize(.small)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(DeckTheme.barBackground)

            Rectangle()
                .fill(DeckTheme.dividerColor)
                .frame(height: 1)

            // 只读查看代码视图
            ScrollView {
                Text(activeContent.isEmpty ? loc(.hostsEmptyContent) : activeContent)
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .lineSpacing(5)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .foregroundColor(Color(NSColor.textColor))
                    .textSelection(.enabled)
            }
            .background(DeckTheme.editorBackground)
        }
        .onAppear {
            refreshContent()
        }
        .onChange(of: hostsStore.config.profiles) { _ in
            refreshContent()
        }
    }

    private func refreshContent() {
        if let actual = try? String(contentsOfFile: "/etc/hosts", encoding: .utf8) {
            activeContent = actual
        } else {
            activeContent = HostsManager.shared.generateMergedContent()
        }
    }
}
