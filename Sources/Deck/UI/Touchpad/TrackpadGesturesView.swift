import SwiftUI
import AppKit

public struct TrackpadGesturesView: View {
    @ObservedObject var gestureStore = GestureStore.shared
    @ObservedObject var touchpadManager = TouchpadManager.shared
    @ObservedObject var l10n = LocalizationManager.shared

    @State private var selectedGestureId: UUID?
    @State private var showingAddSheet = false

    public init() {}

    public var body: some View {
        HSplitView {
            // 左侧：手势列表栏
            VStack(spacing: 0) {
                // 顶栏 Header
                HStack {
                    Text(loc(.gestureListHeader))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()

                    // 全局总开关
                    Toggle("", isOn: $gestureStore.isGlobalEnabled)
                        .toggleStyle(.switch)
                        .controlSize(.mini)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DeckTheme.barBackground)

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)

                // 手势卡片列表
                ScrollView {
                    VStack(spacing: 3) {
                        ForEach(gestureStore.gestures) { gesture in
                            GestureListRow(
                                gesture: gesture,
                                isSelected: selectedGestureId == gesture.id,
                                isJustTriggered: touchpadManager.lastTriggeredGesture == gesture.gestureType,
                                onSelect: { selectedGestureId = gesture.id },
                                onToggle: { gestureStore.toggleGesture(id: gesture.id) }
                            )
                        }
                    }
                    .padding(8)
                }
                .background(DeckTheme.subSidebarBackground)

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)

                // 底部操作栏
                HStack(spacing: 6) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)

                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                    .disabled(selectedGestureId == nil)

                    Spacer()

                    Button(loc(.gestureReset)) {
                        gestureStore.resetToDefault()
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DeckTheme.barBackground)
            }
            .frame(minWidth: 220, idealWidth: 240, maxWidth: 280)

            // 右侧：动作与配置区
            if let gesture = selectedGesture {
                GestureDetailView(
                    gesture: gesture,
                    onUpdate: { updated in
                        gestureStore.updateGesture(updated)
                    }
                )
                .frame(minWidth: 420)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "hand.tap")
                        .font(.system(size: 36))
                        .foregroundColor(.secondary.opacity(0.4))
                    Text(loc(.gestureSelectPrompt))
                        .font(.system(size: 12.5))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            if selectedGestureId == nil {
                selectedGestureId = gestureStore.gestures.first?.id
            }
            TouchpadManager.shared.start()
        }
        .sheet(isPresented: $showingAddSheet) {
            AddGestureSheet(
                onAdd: { newG in
                    gestureStore.addGesture(newG)
                    selectedGestureId = newG.id
                    showingAddSheet = false
                },
                onCancel: { showingAddSheet = false }
            )
        }
    }

    private var selectedGesture: TouchpadGesture? {
        gestureStore.gestures.first(where: { $0.id == selectedGestureId })
    }

    private func deleteSelected() {
        guard let id = selectedGestureId else { return }
        gestureStore.removeGesture(id: id)
        selectedGestureId = gestureStore.gestures.first?.id
    }
}

/// 纯粹优雅的手势条目行
struct GestureListRow: View {
    let gesture: TouchpadGesture
    let isSelected: Bool
    let isJustTriggered: Bool
    let onSelect: () -> Void
    let onToggle: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            // 状态指示条
            Rectangle()
                .fill(gesture.isEnabled ? Color.green : Color.clear)
                .frame(width: 3)
                .cornerRadius(1.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(gesture.gestureType.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                Text(gesture.shortcutDisplay)
                    .font(.system(size: 10.5, weight: .medium, design: .monospaced))
                    .foregroundColor(isSelected ? .white.opacity(0.85) : .secondary)
            }

            Spacer()

            if isJustTriggered {
                Circle()
                    .fill(Color.orange)
                    .frame(width: 6, height: 6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? DeckTheme.accent : Color.clear)
        )
        .onTapGesture {
            onSelect()
        }
    }
}

/// 手势配置详情
struct GestureDetailView: View {
    let gesture: TouchpadGesture
    let onUpdate: (TouchpadGesture) -> Void

    @State private var currentGesture: TouchpadGesture
    @ObservedObject var l10n = LocalizationManager.shared

    init(gesture: TouchpadGesture, onUpdate: @escaping (TouchpadGesture) -> Void) {
        self.gesture = gesture
        self.onUpdate = onUpdate
        _currentGesture = State(initialValue: gesture)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // 1. 触发动作卡片
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.gestureTriggerActionHeader))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 12) {
                        Image(systemName: actionIconName)
                            .font(.system(size: 16))
                            .foregroundColor(.accentColor)
                            .frame(width: 36, height: 36)
                            .background(Color.accentColor.opacity(0.12))
                            .cornerRadius(8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(currentGesture.shortcutDisplay)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)

                            Text(currentGesture.actionType.title)
                                .font(.system(size: 11))
                                .foregroundColor(.secondary)
                        }

                        Spacer()
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(Color(NSColor.controlBackgroundColor))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .stroke(Color.primary.opacity(0.06), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                }

                // 2. 参数设置卡片
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc(.gesturePropertiesHeader))
                        .font(.system(size: 13, weight: .bold))

                    // 触控手势选择
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc(.gestureTypeLabel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $currentGesture.gestureType) {
                            ForEach(GestureType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .labelsHidden()
                        .onChange(of: currentGesture.gestureType) { _ in save() }

                        Text(currentGesture.gestureType.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.85))
                    }

                    Divider()

                    Toggle(loc(.gestureEnableToggle), isOn: $currentGesture.isEnabled)
                        .onChange(of: currentGesture.isEnabled) { _ in save() }

                    Divider()

                    // 动作类型
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc(.gestureActionTypeLabel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $currentGesture.actionType) {
                            ForEach(GestureActionType.allCases, id: \.self) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: currentGesture.actionType) { newType in
                            if newType == .cmdClick {
                                currentGesture.shortcutDisplay = "CMD(⌘)+Click"
                            } else if newType == .middleClick {
                                currentGesture.shortcutDisplay = "Middle Click"
                            }
                            save()
                        }

                        if currentGesture.actionType == .shortcut {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(loc(.gestureShortcutLabel))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                TextField("⌘ W", text: $currentGesture.shortcutDisplay)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                    .onChange(of: currentGesture.shortcutDisplay) { _ in save() }

                                HStack(spacing: 6) {
                                    Text(loc(.gesturePresetsLabel))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    PresetButton(title: "⌘ W") {
                                        currentGesture.shortcutDisplay = "⌘ W"
                                        currentGesture.keyCode = 13
                                        currentGesture.modifiers = ["cmd"]
                                        save()
                                    }
                                    PresetButton(title: "⌘ R") {
                                        currentGesture.shortcutDisplay = "⌘ R"
                                        currentGesture.keyCode = 15
                                        currentGesture.modifiers = ["cmd"]
                                        save()
                                    }
                                    PresetButton(title: "^ ⇧ →") {
                                        currentGesture.shortcutDisplay = "^ ⇧ →"
                                        currentGesture.keyCode = 124
                                        currentGesture.modifiers = ["ctrl", "shift"]
                                        save()
                                    }
                                    PresetButton(title: "^ →") {
                                        currentGesture.shortcutDisplay = "^ →"
                                        currentGesture.keyCode = 124
                                        currentGesture.modifiers = ["ctrl"]
                                        save()
                                    }
                                }
                            }
                        }
                    }

                    Divider()

                    // 备注
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc(.gestureNotesLabel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        TextField(loc(.gestureNotesPlaceholder), text: $currentGesture.notes)
                            .textFieldStyle(.roundedBorder)
                            .onChange(of: currentGesture.notes) { _ in save() }
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
        .onChange(of: gesture.id) { _ in
            currentGesture = gesture
        }
    }

    private var actionIconName: String {
        switch currentGesture.actionType {
        case .shortcut: return "keyboard"
        case .cmdClick, .middleClick: return "cursorarrow.click.2"
        }
    }

    private func save() {
        onUpdate(currentGesture)
    }
}

struct PresetButton: View {
    let title: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10.5, weight: .semibold, design: .monospaced))
        }
        .buttonStyle(.bordered)
        .controlSize(.small)
    }
}

struct AddGestureSheet: View {
    let onAdd: (TouchpadGesture) -> Void
    let onCancel: () -> Void

    @State private var selectedType: GestureType = .tipTapRight2F
    @State private var shortcutText: String = "⌘ W"
    @ObservedObject var l10n = LocalizationManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text(loc(.gestureAddTitle))
                .font(.headline)

            Form {
                Picker(loc(.gestureTypeLabel), selection: $selectedType) {
                    ForEach(GestureType.allCases) { type in
                        Text(type.displayName).tag(type)
                    }
                }

                TextField(loc(.gestureShortcutLabel), text: $shortcutText)
            }

            HStack {
                Spacer()
                Button(loc(.hostsCancel), action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button(loc(.gestureAddAction)) {
                    let newG = TouchpadGesture(
                        gestureType: selectedType,
                        shortcutDisplay: shortcutText,
                        keyCode: 13,
                        modifiers: ["cmd"]
                    )
                    onAdd(newG)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}
