import SwiftUI
import AppKit

public enum DeckTab: String, CaseIterable, Identifiable {
    case appSwitcher = "appSwitcher"
    case trackpad = "trackpad"
    case editHosts = "editHosts"
    case viewHosts = "viewHosts"
    case general = "general"

    public var id: String { self.rawValue }

    public var title: String {
        switch self {
        case .appSwitcher: return loc(.tabAppSwitcher)
        case .trackpad: return loc(.tabTrackpad)
        case .editHosts: return loc(.tabEditHosts)
        case .viewHosts: return loc(.tabViewHosts)
        case .general: return loc(.tabGeneral)
        }
    }

    public var iconName: String {
        switch self {
        case .appSwitcher: return "square.grid.2x2.fill"
        case .trackpad: return "hand.tap.fill"
        case .editHosts: return "pencil.and.outline"
        case .viewHosts: return "eye.fill"
        case .general: return "gearshape.fill"
        }
    }
}

public struct MainContainerView: View {
    @State public var selectedTab: DeckTab = .appSwitcher
    @ObservedObject var hostsStore = HostsStore.shared
    @ObservedObject var configStore = ConfigStore.shared
    @ObservedObject var gestureStore = GestureStore.shared
    @ObservedObject var l10n = LocalizationManager.shared

    public init(initialTab: DeckTab = .appSwitcher) {
        _selectedTab = State(initialValue: initialTab)
    }

    public var body: some View {
        HStack(spacing: 0) {
            // 左侧现代纯净极简侧边栏
            VStack(alignment: .leading, spacing: 0) {
                // 顶部品牌区（保留交通灯间隙）
                HStack(spacing: 10) {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .cornerRadius(6)
                        .shadow(color: Color.black.opacity(0.12), radius: 2, x: 0, y: 1)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Deck")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text(loc(.appSubtitle))
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 38)
                .padding(.bottom, 14)

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)
                    .padding(.horizontal, 12)
                    .padding(.bottom, 10)

                // 侧边栏导航分组
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        // 板块一：应用切换调色板
                        VStack(alignment: .leading, spacing: 3) {
                            SidebarSectionHeader(title: loc(.navQuickSwitch), icon: "bolt.fill")

                            SidebarItemButton(
                                title: loc(.navPaletteMappings),
                                icon: "square.grid.2x2.fill",
                                isSelected: selectedTab == .appSwitcher,
                                badgeText: configStore.config.triggerKeyName,
                                badgeColor: DeckTheme.accent,
                                action: { selectedTab = .appSwitcher }
                            )
                        }

                        // 板块二：触控板手势增强
                        VStack(alignment: .leading, spacing: 3) {
                            SidebarSectionHeader(title: loc(.navTouchGestures), icon: "hand.tap.fill")

                            SidebarItemButton(
                                title: loc(.navTrackpadGestures),
                                icon: "hand.draw.fill",
                                isSelected: selectedTab == .trackpad,
                                badgeText: "\(gestureStore.gestures.filter { $0.isEnabled }.count)",
                                badgeColor: .blue,
                                action: { selectedTab = .trackpad }
                            )
                        }

                        // 板块三：Hosts 域名管理 (置于偏好设置上方)
                        VStack(alignment: .leading, spacing: 3) {
                            SidebarSectionHeader(title: loc(.navHostsManagement), icon: "network")

                            SidebarItemButton(
                                title: loc(.navProfiles),
                                icon: "pencil.line",
                                isSelected: selectedTab == .editHosts,
                                badgeText: nil,
                                action: { selectedTab = .editHosts }
                            )

                            SidebarItemButton(
                                title: loc(.navActiveHosts),
                                icon: "eye.fill",
                                isSelected: selectedTab == .viewHosts,
                                badgeText: "\(hostsStore.config.profiles.filter { $0.isEnabled }.count)",
                                badgeColor: .green,
                                action: { selectedTab = .viewHosts }
                            )
                        }

                        // 板块四：系统偏好
                        VStack(alignment: .leading, spacing: 3) {
                            SidebarSectionHeader(title: loc(.navPreferences), icon: "slider.horizontal.3")

                            SidebarItemButton(
                                title: loc(.navGeneralSettings),
                                icon: "gearshape.fill",
                                isSelected: selectedTab == .general,
                                badgeText: nil,
                                action: { selectedTab = .general }
                            )
                        }
                    }
                    .padding(.horizontal, 10)
                }

                Spacer()

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)

                // 底部状态提示
                HStack(spacing: 8) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 6, height: 6)
                        .shadow(color: Color.green.opacity(0.4), radius: 2)
                    Text(loc(.serviceRunning))
                        .font(.system(size: 10.5, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("v" + (Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.1"))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.7))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(DeckTheme.sidebarBackground)
            }
            .frame(width: 220)
            .background(DeckTheme.sidebarBackground)

            // 侧栏与主画布间的清晰微质感分割线
            Rectangle()
                .fill(DeckTheme.dividerColor)
                .frame(width: 1)
                .ignoresSafeArea()

            // 右侧主工作区
            Group {
                switch selectedTab {
                case .appSwitcher:
                    PaletteSettingsView()
                case .trackpad:
                    TrackpadGesturesView()
                case .editHosts:
                    EditHostsView()
                case .viewHosts:
                    ViewHostsView()
                case .general:
                    GeneralHostsView()
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(DeckTheme.canvasBackground)
        }
        .frame(minWidth: 800, minHeight: 560)
    }
}

/// 侧边栏分段标题
struct SidebarSectionHeader: View {
    let title: String
    let icon: String

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 9, weight: .bold))
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
            Spacer()
        }
        .foregroundColor(.secondary.opacity(0.8))
        .padding(.horizontal, 8)
        .padding(.bottom, 2)
    }
}

/// 极简大热区侧边栏按钮
struct SidebarItemButton: View {
    let title: String
    let icon: String
    let isSelected: Bool
    var badgeText: String? = nil
    var badgeColor: Color = .accentColor
    let action: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(isSelected ? .white : (isHovered ? .primary : .secondary))
                .frame(width: 18, height: 18)

            Text(title)
                .font(.system(size: 12.5, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)

            Spacer()

            if let badge = badgeText {
                Text(badge)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(
                        isSelected ? Color.white.opacity(0.25) : badgeColor.opacity(0.15)
                    )
                    .foregroundColor(isSelected ? .white : badgeColor)
                    .cornerRadius(5)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .contentShape(Rectangle()) // 保证整行任何位置点击均能触发！
        .background(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(
                    isSelected ? DeckTheme.accent : (isHovered ? DeckTheme.hoverBackground : Color.clear)
                )
        )
        .onTapGesture {
            action()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
