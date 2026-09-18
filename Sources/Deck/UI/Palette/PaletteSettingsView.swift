import SwiftUI
import AppKit

public struct PaletteSettingsView: View {
    @ObservedObject var configStore = ConfigStore.shared
    @ObservedObject var hotKeyManager = HotKeyManager.shared
    @ObservedObject var l10n = LocalizationManager.shared

    @State private var showingAddSheet = false
    @State private var editingItem: PaletteItem?
    @State private var hoveredItemId: UUID?
    @State private var searchText = ""

    let commonFKeys: [(name: String, code: Int)] = [
        ("F13", 105),
        ("F14", 107),
        ("F15", 113),
        ("F16", 106),
        ("F17", 64),
        ("F18", 79),
        ("F19", 80),
        ("F20", 90)
    ]

    var filteredItems: [PaletteItem] {
        let cleanSearch = searchText.trimmingCharacters(in: .whitespaces)
        if cleanSearch.isEmpty {
            return configStore.config.items
        }
        return configStore.config.items.filter {
            $0.displayName.localizedCaseInsensitiveContains(cleanSearch) ||
            $0.key.localizedCaseInsensitiveContains(cleanSearch) ||
            ($0.bundleIdentifier?.localizedCaseInsensitiveContains(cleanSearch) == true)
        }
    }

    public init() {}

    public var body: some View {
        VStack(spacing: 0) {
            // 权限提示（未授权时显现）
            if !hotKeyManager.isAccessibilityGranted {
                HStack(spacing: 10) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.orange)
                        .font(.system(size: 14))
                    Text(loc(.paletteAccessibilityPrompt))
                        .font(.system(size: 12, weight: .medium))
                    Spacer()

                    Button(action: {
                        hotKeyManager.checkAccessibility(prompt: false)
                    }) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 11))
                    }
                    .controlSize(.small)
                    .buttonStyle(.bordered)
                    .help("重新检测权限状态")

                    Button(loc(.paletteAuthorize)) {
                        hotKeyManager.openAccessibilityPreferences()
                    }
                    .controlSize(.small)
                    .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.orange.opacity(0.12))
                Divider()
            }

            ScrollView {
                VStack(spacing: 16) {
                    // 顶部触发配置卡片
                    HStack(spacing: 24) {
                        HStack(spacing: 8) {
                            Text(loc(.paletteTriggerKeyLabel))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            Picker("", selection: Binding(
                                get: { configStore.config.triggerKeyCode },
                                set: { newCode in
                                    configStore.config.triggerKeyCode = newCode
                                    if let found = commonFKeys.first(where: { $0.code == newCode }) {
                                        configStore.config.triggerKeyName = found.name
                                    }
                                    configStore.save()
                                    hotKeyManager.restartListening()
                                }
                            )) {
                                ForEach(commonFKeys, id: \.code) { item in
                                    Text(item.name).tag(item.code)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        Divider()
                            .frame(height: 20)

                        HStack(spacing: 8) {
                            Text(loc(.palettePositionLabel))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.secondary)

                            Picker("", selection: Binding(
                                get: { configStore.config.showAtCursor },
                                set: {
                                    configStore.config.showAtCursor = $0
                                    configStore.save()
                                }
                            )) {
                                Text(loc(.paletteCenterScreen)).tag(false)
                                Text(loc(.paletteFollowCursor)).tag(true)
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DeckTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DeckTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: DeckTheme.cardShadow, radius: 4, x: 0, y: 1)

                    // 映射列表卡片
                    VStack(spacing: 12) {
                        // 工具栏：标题、搜索框与操作
                        HStack(spacing: 12) {
                            HStack(spacing: 6) {
                                Text(loc(.paletteMappingsHeader))
                                    .font(.system(size: 13, weight: .bold))
                                Text("(\(configStore.config.items.count))")
                                    .font(.system(size: 11, weight: .bold, design: .monospaced))
                                    .foregroundColor(.secondary)
                            }

                            // 搜索框
                            HStack(spacing: 6) {
                                Image(systemName: "magnifyingglass")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                                TextField(loc(.paletteSearchPlaceholder), text: $searchText)
                                    .textFieldStyle(.plain)
                                    .font(.system(size: 11.5))
                                if !searchText.isEmpty {
                                    Button(action: { searchText = "" }) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(.secondary)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 5)
                            .background(DeckTheme.subSidebarBackground)
                            .cornerRadius(6)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(DeckTheme.borderColor, lineWidth: 1)
                            )
                            .frame(width: 180)

                            Spacer()

                            Button(loc(.gestureReset)) {
                                configStore.resetToDefault()
                            }
                            .controlSize(.small)

                            Button(action: { showingAddSheet = true }) {
                                Label(loc(.paletteAddMapping), systemImage: "plus")
                            }
                            .buttonStyle(.borderedProminent)
                            .controlSize(.small)
                        }

                        // 列表内容
                        VStack(spacing: 3) {
                            ForEach(filteredItems) { item in
                                PaletteItemCard(
                                    item: item,
                                    isHovered: hoveredItemId == item.id,
                                    onEdit: { editingItem = item },
                                    onDelete: { configStore.removeItem(id: item.id) }
                                )
                                .onHover { hovering in
                                    hoveredItemId = hovering ? item.id : (hoveredItemId == item.id ? nil : hoveredItemId)
                                }
                            }
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(DeckTheme.cardBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(DeckTheme.borderColor, lineWidth: 1)
                    )
                    .shadow(color: DeckTheme.cardShadow, radius: 4, x: 0, y: 1)
                }
                .padding(16)
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            ItemEditSheet(item: nil) { newItem in
                configStore.addItem(newItem)
                showingAddSheet = false
            } onCancel: {
                showingAddSheet = false
            }
        }
        .sheet(item: $editingItem) { item in
            ItemEditSheet(item: item) { updatedItem in
                configStore.updateItem(updatedItem)
                editingItem = nil
            } onCancel: {
                editingItem = nil
            }
        }
        .onAppear {
            hotKeyManager.checkAccessibility(prompt: false)
            if !hotKeyManager.isAccessibilityGranted {
                hotKeyManager.startPollingAccessibility()
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in
            hotKeyManager.checkAccessibility(prompt: false)
        }
    }
}

/// 物理键帽 2.0 (Keycap 2.0)
struct PaletteItemCard: View {
    let item: PaletteItem
    let isHovered: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            // 实体微浮雕键帽
            Text(item.displayKey)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(.primary)
                .frame(minWidth: 28, minHeight: 26)
                .padding(.horizontal, 6)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(DeckTheme.cardBackground)
                        .shadow(color: Color.black.opacity(0.06), radius: 1.5, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(DeckTheme.borderColor, lineWidth: 1)
                )

            // 图标
            Image(nsImage: item.icon())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 22, height: 22)
                .cornerRadius(5)
                .overlay(
                    RoundedRectangle(cornerRadius: 5)
                        .stroke(Color.primary.opacity(0.08), lineWidth: 0.5)
                )

            // 动作名称与信息
            VStack(alignment: .leading, spacing: 1) {
                Text(item.displayName)
                    .font(.system(size: 12.5, weight: .medium))
                    .foregroundColor(.primary)

                if item.actionType == .activateLastApp {
                    Text(loc(.paletteActionActivateLast))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                } else if let bundleId = item.bundleIdentifier {
                    Text(bundleId)
                        .font(.system(size: 9.5, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                        .lineLimit(1)
                }
            }

            Spacer()

            // 悬停操作按钮
            HStack(spacing: 6) {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color.accentColor)
                        .frame(width: 22, height: 22)
                        .background(Color.accentColor.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)

                Button(action: onDelete) {
                    Image(systemName: "trash")
                        .font(.system(size: 10.5))
                        .foregroundColor(Color.red.opacity(0.8))
                        .frame(width: 22, height: 22)
                        .background(Color.red.opacity(0.12))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
            }
            .opacity(isHovered ? 1.0 : 0.25)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(isHovered ? DeckTheme.hoverBackground : Color.clear)
        )
    }
}

/// 添加与编辑弹窗
struct ItemEditSheet: View {
    let initialItem: PaletteItem?
    let onSave: (PaletteItem) -> Void
    let onCancel: () -> Void

    @State private var key: String = ""
    @State private var displayName: String = ""
    @State private var isLastApp: Bool = false
    @State private var appPath: String = ""
    @State private var bundleId: String = ""
    @ObservedObject var l10n = LocalizationManager.shared

    init(item: PaletteItem?, onSave: @escaping (PaletteItem) -> Void, onCancel: @escaping () -> Void) {
        self.initialItem = item
        self.onSave = onSave
        self.onCancel = onCancel
        _key = State(initialValue: item?.key ?? "")
        _displayName = State(initialValue: item?.displayName ?? "")
        _isLastApp = State(initialValue: item?.actionType == .activateLastApp)
        _appPath = State(initialValue: item?.appPath ?? "")
        _bundleId = State(initialValue: item?.bundleIdentifier ?? "")
    }

    private var isKeyValid: Bool {
        let trimmed = key.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty || key == " " || trimmed.lowercased() == "space"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(initialItem == nil ? loc(.paletteAddMappingTitle) : loc(.paletteEditMappingTitle))
                .font(.headline)

            Form {
                HStack(spacing: 8) {
                    TextField(loc(.paletteKeyFieldPlaceholder), text: $key)
                        .frame(width: 220)
                        .onChange(of: key) { newKey in
                            if newKey == " " {
                                key = "Space"
                            }
                        }

                    Button(action: { key = "Space" }) {
                        Text("Space (空格)")
                            .font(.system(size: 11))
                    }
                    .controlSize(.small)
                }

                Picker(loc(.paletteActionCol) + ":", selection: $isLastApp) {
                    Text(loc(.paletteActionActivateApp)).tag(false)
                    Text(loc(.paletteActionActivateLast)).tag(true)
                }

                if !isLastApp {
                    HStack {
                        TextField(loc(.paletteAppNameLabel), text: $displayName)
                        Button(loc(.paletteBrowseButton)) { chooseApp() }
                    }

                    if !bundleId.isEmpty {
                        Text(bundleId)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                } else {
                    TextField(loc(.paletteDisplayNameLabel), text: $displayName)
                }
            }

            HStack {
                Spacer()
                Button(loc(.hostsCancel), action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(loc(.paletteSaveButton)) {
                    let trimmed = key.trimmingCharacters(in: .whitespaces)
                    let cleanedKey: String
                    if key == " " || trimmed.lowercased() == "space" || trimmed == "␣" || trimmed == "空格" {
                        cleanedKey = "Space"
                    } else {
                        cleanedKey = trimmed
                    }

                    let name = displayName.isEmpty ? "Activate Application" : displayName
                    let item = PaletteItem(
                        id: initialItem?.id ?? UUID(),
                        key: cleanedKey,
                        displayName: name,
                        actionType: isLastApp ? .activateLastApp : .activateApp,
                        bundleIdentifier: isLastApp ? nil : (bundleId.isEmpty ? nil : bundleId),
                        appPath: isLastApp ? nil : (appPath.isEmpty ? nil : appPath)
                    )
                    onSave(item)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isKeyValid)
            }
        }
        .padding(20)
        .frame(width: 420)
        .onAppear {
            if isLastApp && displayName.isEmpty {
                displayName = loc(.paletteActionActivateLast)
            }
        }
    }

    private func chooseApp() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.application]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.directoryURL = URL(fileURLWithPath: "/Applications")

        if panel.runModal() == .OK, let url = panel.url {
            let bundle = Bundle(url: url)
            let appName = (bundle?.infoDictionary?["CFBundleDisplayName"] as? String)
                ?? (bundle?.infoDictionary?["CFBundleName"] as? String)
                ?? url.deletingPathExtension().lastPathComponent

            self.appPath = url.path
            self.bundleId = bundle?.bundleIdentifier ?? ""
            self.displayName = "Activate \(appName)"
        }
    }
}

public typealias SettingsView = PaletteSettingsView
