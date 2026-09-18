import SwiftUI
import AppKit

public struct PaletteView: View {
    @ObservedObject var configStore = ConfigStore.shared
    public var onItemTriggered: ((PaletteItem) -> Void)?
    public var onClose: (() -> Void)?
    public var onOpenSettings: (() -> Void)?

    @State private var hoveredItemId: UUID?

    public init(
        onItemTriggered: ((PaletteItem) -> Void)? = nil,
        onClose: (() -> Void)? = nil,
        onOpenSettings: (() -> Void)? = nil
    ) {
        self.onItemTriggered = onItemTriggered
        self.onClose = onClose
        self.onOpenSettings = onOpenSettings
    }

    public var body: some View {
        VStack(spacing: 0) {
            // 顶栏 Header
            HStack {
                Button(action: {
                    onClose?()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.gray.opacity(0.9))
                }
                .buttonStyle(.plain)

                Spacer()

                Text(configStore.config.triggerKeyName)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.95))

                Spacer()

                Button(action: {
                    onOpenSettings?()
                }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.4))

            Divider()
                .background(Color.white.opacity(0.12))

            // 列表 Items List
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 1) {
                    ForEach(configStore.config.items) { item in
                        PaletteRow(
                            item: item,
                            isHovered: hoveredItemId == item.id
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            onItemTriggered?(item)
                        }
                        .onHover { hovering in
                            if hovering {
                                hoveredItemId = item.id
                            } else if hoveredItemId == item.id {
                                hoveredItemId = nil
                            }
                        }
                    }
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 6)
            }
            .frame(maxHeight: 480)
        }
        .frame(width: 310)
        .background(
            ZStack {
                VisualEffectBlur(material: .hudWindow, blendingMode: .behindWindow)
                Color.black.opacity(0.72)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.white.opacity(0.18), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.55), radius: 24, x: 0, y: 12)
        .preferredColorScheme(.dark)
    }
}

struct PaletteRow: View {
    let item: PaletteItem
    let isHovered: Bool

    var body: some View {
        HStack(spacing: 8) {
            // 图标
            Image(nsImage: item.icon())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 18, height: 18)
                .cornerRadius(4)

            // 按键标识
            Text(item.key)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.white)

            Text(":")
                .font(.system(size: 12, weight: .regular))
                .foregroundColor(.white.opacity(0.6))

            // 动作名称
            Text(item.displayName)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.95))
                .lineLimit(1)
                .truncationMode(.tail)

            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isHovered ? Color.white.opacity(0.18) : Color.clear)
        )
    }
}

/// AppKit NSVisualEffectView 封装，实现原生毛玻璃
public struct VisualEffectBlur: NSViewRepresentable {
    public var material: NSVisualEffectView.Material
    public var blendingMode: NSVisualEffectView.BlendingMode

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = .active
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
    }
}
