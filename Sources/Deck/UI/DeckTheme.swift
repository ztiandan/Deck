import SwiftUI
import AppKit

/// Deck 现代化原生视觉设计规范（清爽高亮浅色系）
public struct DeckTheme {
    /// 侧边栏背景：极浅瓷白，清爽通透 (Light: #F5F6F8, Dark: #151618)
    public static let sidebarBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.12, green: 0.13, blue: 0.14, alpha: 1.0)
            : NSColor(red: 0.962, green: 0.966, blue: 0.972, alpha: 1.0)
    }))

    /// 右侧主工作区画布背景：超清爽明亮浅白 (Light: #FAFBFC, Dark: #0E0F11)
    public static let canvasBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.08, green: 0.08, blue: 0.09, alpha: 1.0)
            : NSColor(red: 0.980, green: 0.983, blue: 0.988, alpha: 1.0)
    }))

    /// 卡片与内容表面：纯白无暇 (Light: #FFFFFF, Dark: #1A1B1E)
    public static let cardBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.14, green: 0.15, blue: 0.17, alpha: 1.0)
            : NSColor.white
    }))

    /// 次级列表/侧边栏背景 (如手势列表、Hosts 方案列表) (Light: #F7F8FA, Dark: #121315)
    public static let subSidebarBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.10, green: 0.11, blue: 0.12, alpha: 1.0)
            : NSColor(red: 0.968, green: 0.972, blue: 0.978, alpha: 1.0)
    }))

    /// 顶栏与底栏背景 (Light: #FAFAFC, Dark: #16171A)
    public static let barBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.12, green: 0.13, blue: 0.14, alpha: 1.0)
            : NSColor(red: 0.982, green: 0.985, blue: 0.989, alpha: 1.0)
    }))

    /// 代码编辑器/查看器背景 (Light: #FFFFFF, Dark: #101113)
    public static let editorBackground = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(red: 0.09, green: 0.10, blue: 0.11, alpha: 1.0)
            : NSColor.white
    }))

    /// 极细边框描边：微柔边线 (Light: 6% black, Dark: 8% white)
    public static let borderColor = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1.0, alpha: 0.08)
            : NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.06)
    }))

    /// 分割线颜色 (Light: 5% black, Dark: 8% white)
    public static let dividerColor = Color(NSColor(name: nil, dynamicProvider: { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1.0, alpha: 0.08)
            : NSColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 0.05)
    }))

    /// 现代微阴影
    public static let cardShadow = Color.black.opacity(0.025)

    /// 鼠标悬停高光
    public static let hoverBackground = Color.primary.opacity(0.045)

    /// 强调蓝色
    public static let accent = Color(red: 0.08, green: 0.48, blue: 0.98)
}
