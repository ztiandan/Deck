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
                        selectedGestureId = gestureStore.gestures.first?.id
                    }
                    .controlSize(.small)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DeckTheme.barBackground)
            }
            .frame(minWidth: 240, idealWidth: 260, maxWidth: 300)

            // 右侧：动作与配置区
            if let selected = gestureStore.gestures.first(where: { $0.id == selectedGestureId }) {
                GestureDetailView(gesture: Binding(
                    get: { gestureStore.gestures.first(where: { $0.id == selected.id }) ?? selected },
                    set: { gestureStore.updateGesture($0) }
                ))
                    .id(selected.id)
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
            // 状态指示条（启用绿色，触发时高亮橙色）
            RoundedRectangle(cornerRadius: 1.5)
                .fill(isJustTriggered ? Color.orange : (gesture.isEnabled ? Color.green : Color.clear))
                .frame(width: 3, height: 32)
                .animation(.easeInOut(duration: 0.2), value: isJustTriggered)

            VStack(alignment: .leading, spacing: 2) {
                Text(gesture.gestureType.displayName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(isSelected ? .white : .primary)
                    .lineLimit(1)

                if !gesture.notes.isEmpty {
                    Text(gesture.notes)
                        .font(.system(size: 10))
                        .foregroundColor(isSelected ? .white.opacity(0.8) : .secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            // 快捷键键帽样式
            Text(gesture.shortcutDisplay)
                .font(.system(size: 10, weight: .semibold, design: .monospaced))
                .foregroundColor(isSelected ? .white : .secondary)
                .padding(.horizontal, 6)
                .padding(.vertical, 2.5)
                .background(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .fill(isSelected ? Color.white.opacity(0.2) : Color.primary.opacity(0.06))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .stroke(isSelected ? Color.white.opacity(0.3) : DeckTheme.borderColor, lineWidth: 0.5)
                )

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
                .fill(isSelected ? DeckTheme.accent : (isJustTriggered ? Color.orange.opacity(0.15) : Color.clear))
        )
        .onTapGesture {
            onSelect()
        }
    }
}

/// 手势配置详情
struct GestureDetailView: View {
    @Binding var gesture: TouchpadGesture
    @ObservedObject var gestureStore = GestureStore.shared
    @ObservedObject var touchpadManager = TouchpadManager.shared
    @ObservedObject var l10n = LocalizationManager.shared

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
                            Text(gesture.shortcutDisplay)
                                .font(.system(size: 15, weight: .bold, design: .monospaced))
                                .foregroundColor(.primary)

                            Text(gesture.actionType.title)
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
                            .stroke(touchpadManager.lastTriggeredGesture == gesture.gestureType ? Color.orange : Color.primary.opacity(0.06), lineWidth: touchpadManager.lastTriggeredGesture == gesture.gestureType ? 1.5 : 1)
                    )
                    .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 1)
                }

                // 2. 手势操作动态示意图
                TrackpadGestureIllustrationView(gestureType: gesture.gestureType)
                    .id(gesture.gestureType)

                // 3. 参数设置卡片
                VStack(alignment: .leading, spacing: 14) {
                    Text(loc(.gesturePropertiesHeader))
                        .font(.system(size: 13, weight: .bold))

                    // 触控手势选择
                    VStack(alignment: .leading, spacing: 6) {
                        Text(loc(.gestureTypeLabel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $gesture.gestureType) {
                            ForEach(GestureType.allCases) { type in
                                Text(type.displayName).tag(type)
                            }
                        }
                        .labelsHidden()

                        Text(gesture.gestureType.description)
                            .font(.system(size: 11))
                            .foregroundColor(.secondary.opacity(0.85))
                    }

                    Divider()

                    Toggle(loc(.gestureEnableToggle), isOn: $gesture.isEnabled)

                    Divider()

                    // 动作类型
                    VStack(alignment: .leading, spacing: 8) {
                        Text(loc(.gestureActionTypeLabel))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.secondary)

                        Picker("", selection: $gesture.actionType) {
                            ForEach(GestureActionType.allCases, id: \.self) { type in
                                Text(type.title).tag(type)
                            }
                        }
                        .pickerStyle(.segmented)
                        .onChange(of: gesture.actionType) { newType in
                            if newType == .cmdClick {
                                gesture.shortcutDisplay = "CMD(⌘)+Click"
                            } else if newType == .middleClick {
                                gesture.shortcutDisplay = "Middle Click"
                            } else {
                                gesture.shortcutDisplay = ShortcutDefinition(keyCode: gesture.keyCode, modifiers: gesture.modifiers).display
                            }
                        }

                        if gesture.actionType == .shortcut {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(loc(.gestureShortcutLabel))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.secondary)

                                TextField("⌘ W", text: $gesture.shortcutDisplay)
                                    .textFieldStyle(.roundedBorder)
                                    .frame(width: 200)
                                    .onChange(of: gesture.shortcutDisplay) { text in
                                        if let shortcut = ShortcutDefinition.parse(text) {
                                            gesture.keyCode = shortcut.keyCode
                                            gesture.modifiers = shortcut.modifiers
                                        }
                                    }
                                if ShortcutDefinition.parse(gesture.shortcutDisplay) == nil {
                                    Text(loc(.gestureShortcutInvalid))
                                        .font(.caption)
                                        .foregroundColor(.orange)
                                }

                                LazyVGrid(columns: [GridItem(.adaptive(minimum: 56), spacing: 6)], alignment: .leading, spacing: 6) {
                                    Text(loc(.gesturePresetsLabel))
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)

                                    PresetButton(title: "⌘ W") {
                                        gesture.shortcutDisplay = "⌘ W"
                                        gesture.keyCode = 13
                                        gesture.modifiers = ["cmd"]
                                    }
                                    PresetButton(title: "⌘ R") {
                                        gesture.shortcutDisplay = "⌘ R"
                                        gesture.keyCode = 15
                                        gesture.modifiers = ["cmd"]
                                    }
                                    PresetButton(title: "⌘ T") {
                                        gesture.shortcutDisplay = "⌘ T"
                                        gesture.keyCode = 17
                                        gesture.modifiers = ["cmd"]
                                    }
                                    PresetButton(title: "^ ←") {
                                        gesture.shortcutDisplay = "^ ←"
                                        gesture.keyCode = 123
                                        gesture.modifiers = ["ctrl"]
                                    }
                                    PresetButton(title: "^ →") {
                                        gesture.shortcutDisplay = "^ →"
                                        gesture.keyCode = 124
                                        gesture.modifiers = ["ctrl"]
                                    }
                                    PresetButton(title: "⌘ ⇧ [") {
                                        gesture.shortcutDisplay = "⌘ ⇧ ["
                                        gesture.keyCode = 33
                                        gesture.modifiers = ["cmd", "shift"]
                                    }
                                    PresetButton(title: "⌘ ⇧ ]") {
                                        gesture.shortcutDisplay = "⌘ ⇧ ]"
                                        gesture.keyCode = 30
                                        gesture.modifiers = ["cmd", "shift"]
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

                        TextField(loc(.gestureNotesPlaceholder), text: $gesture.notes)
                            .textFieldStyle(.roundedBorder)
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

                // 3. 触控板触觉反馈设置
                VStack(alignment: .leading, spacing: 6) {
                    Toggle(loc(.gestureHapticFeedbackToggle), isOn: $gestureStore.isHapticFeedbackEnabled)
                        .font(.system(size: 12, weight: .semibold))

                    Text(loc(.gestureHapticFeedbackDesc))
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
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

    private var actionIconName: String {
        switch gesture.actionType {
        case .shortcut: return "keyboard"
        case .cmdClick, .middleClick: return "cursorarrow.click.2"
        }
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
                    guard let shortcut = ShortcutDefinition.parse(shortcutText) else { return }
                    let newG = TouchpadGesture(
                        gestureType: selectedType,
                        shortcutDisplay: shortcutText,
                        keyCode: shortcut.keyCode,
                        modifiers: shortcut.modifiers
                    )
                    onAdd(newG)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(ShortcutDefinition.parse(shortcutText) == nil)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

/// 触控板手势操作动态示意图
struct TrackpadGestureIllustrationView: View {
    let gestureType: GestureType
    @ObservedObject var l10n = LocalizationManager.shared
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var demoStart = Date()

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(loc(.gestureIllustrationHeader))
                    .font(.system(size: 11.5, weight: .bold))
                    .foregroundColor(.secondary)
                Spacer()
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                    Text(loc(.gestureIllustrationBadge))
                        .font(.system(size: 9.5, weight: .semibold))
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal, 7)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(Color.primary.opacity(0.06))
                )
            }

            ViewThatFits(in: .horizontal) {
                HStack(spacing: 16) {
                    demoCanvas
                    instructions.frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
                }
                VStack(alignment: .leading, spacing: 12) {
                    demoCanvas.frame(maxWidth: .infinity)
                    instructions
                }
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
    }

    private var demoCanvas: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0, paused: reduceMotion)) { context in
            TrackpadCanvas(gestureType: gestureType,
                           elapsed: reduceMotion ? 1.2 : context.date.timeIntervalSince(demoStart))
        }
        .frame(width: 190, height: 148)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(stepDescription)
    }

    private var instructions: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(stepDescription)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 12) {
                if showsRestingFingerLegend {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.blue.gradient)
                            .frame(width: 9, height: 9)
                        Text(loc(.gestureDemoHoldFinger))
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                HStack(spacing: 5) {
                    Circle()
                        .fill(Color.orange.gradient)
                        .frame(width: 9, height: 9)
                    Text(isSimultaneousTap ? loc(.gestureDemoSimultaneousTap) : loc(.gestureDemoTapFinger))
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
            }

            Text(loc(isSimultaneousTap ? .gestureDemoMultiHint : .gestureDemoHint))
                .font(.system(size: 10.5))
                .foregroundColor(.secondary.opacity(0.85))
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var showsRestingFingerLegend: Bool {
        switch gestureType {
        case .tipTapRight2F, .tipTapLeft2F, .tipTapLeft3F, .tipTapRight3F:
            return true
        case .fourFingerTap, .threeFingerTap:
            return false
        }
    }

    private var isSimultaneousTap: Bool {
        switch gestureType {
        case .fourFingerTap, .threeFingerTap:
            return true
        default:
            return false
        }
    }

    private var stepDescription: String {
        switch gestureType {
        case .tipTapRight2F: return loc(.gestureDemoTipTapRight2F)
        case .tipTapLeft2F: return loc(.gestureDemoTipTapLeft2F)
        case .tipTapLeft3F: return loc(.gestureDemoTipTapLeft3F)
        case .tipTapRight3F: return loc(.gestureDemoTipTapRight3F)
        case .fourFingerTap: return loc(.gestureDemoFourFingerTap)
        case .threeFingerTap: return loc(.gestureDemoThreeFingerTap)
        }
    }
}

/// The surface contact stays in place. Only the fingertip rises and falls,
/// making a tap visibly different from dragging across the trackpad.
struct TrackpadCanvas: View {
    let gestureType: GestureType
    let elapsed: TimeInterval

    private var phase: Double { max(0, elapsed).truncatingRemainder(dividingBy: 2.8) }
    private var touching: Bool { phase >= 0.95 && phase < 1.20 }
    private var lifted: Bool { phase >= 1.20 }
    private var height: CGFloat {
        if phase < 0.75 { return 15 }
        if phase < 0.95 { return 15 * (0.95 - phase) / 0.20 }
        if phase < 1.20 { return 0 }
        if phase < 1.45 { return 15 * (phase - 1.20) / 0.25 }
        return 15
    }
    private var hasAnchors: Bool {
        gestureType != .threeFingerTap && gestureType != .fourFingerTap
    }

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(LinearGradient(colors: [Color.primary.opacity(0.07), Color.primary.opacity(0.02)],
                                         startPoint: .top, endPoint: .bottom))
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primary.opacity(0.14), lineWidth: 1)
                GeometryReader { geometry in
                    ForEach(fingers, id: \.id) { finger in
                        fingertip(resting: finger.resting)
                            .position(x: geometry.size.width * finger.x, y: 57)
                    }
                }
            }
            .frame(height: 114)

            HStack(spacing: 5) {
                Image(systemName: lifted ? "checkmark.circle.fill" : (touching ? "hand.tap.fill" : "hand.point.up"))
                Text(loc(lifted ? .gestureDemoLift : (touching ? .gestureDemoTouch :
                            (hasAnchors ? .gestureDemoPrepare : .gestureDemoReady))))
            }
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(lifted ? .green : .secondary)
            .frame(maxWidth: .infinity)
        }
    }

    private func fingertip(resting: Bool) -> some View {
        let color: Color = resting ? .blue : .orange
        let down = resting || touching
        return ZStack {
            // Dashed outline marks the unchanged landing point while hovering.
            Ellipse()
                .stroke(color.opacity(down ? 0.65 : 0.30), style: StrokeStyle(lineWidth: 1, dash: down ? [] : [2, 2]))
                .frame(width: 27, height: 12)
                .offset(y: 13)
            if down {
                Ellipse().fill(color.opacity(0.20))
                    .frame(width: 33, height: 16)
                    .offset(y: 13)
            }
            if !resting && touching {
                let progress = (phase - 0.95) / 0.25
                Ellipse().stroke(color.opacity(0.8 * (1 - progress)), lineWidth: 1.5)
                    .frame(width: 28 + 18 * progress, height: 14 + 10 * progress)
                    .offset(y: 13)
            }
            // A fingertip silhouette, with a nail, replaces the ambiguous moving dot.
            Capsule()
                .fill(color.opacity(down ? 0.92 : 0.30).gradient)
                .frame(width: down ? 24 : 22, height: down ? 35 : 38)
                .overlay(alignment: .top) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.65))
                        .frame(width: 12, height: 14)
                        .padding(.top, 4)
                }
                .offset(y: resting ? -3 : -3 - height)
                .shadow(color: color.opacity(0.18), radius: down ? 1 : 3, y: down ? 1 : 6)
            if !resting && !touching {
                Image(systemName: lifted ? "arrow.up" : "arrow.down")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(color)
                    .offset(x: 17, y: -8)
            }
            Text(loc(resting ? .gestureDemoHoldShort : (lifted ? .gestureDemoLiftShort : .gestureDemoTapShort)))
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(color)
                .offset(y: 35)
        }
    }

    private struct Finger: Identifiable {
        let id: Int
        let x: CGFloat
        let resting: Bool
    }

    private var fingers: [Finger] {
        let anchors: [Bool]
        switch gestureType {
        case .tipTapRight2F: anchors = [true, false]
        case .tipTapLeft2F: anchors = [false, true]
        case .tipTapLeft3F: anchors = [false, true, true]
        case .tipTapRight3F: anchors = [true, true, false]
        case .threeFingerTap: anchors = [false, false, false]
        case .fourFingerTap: anchors = [false, false, false, false]
        }
        return anchors.enumerated().map { index, resting in
            Finger(id: index, x: 0.5 + (CGFloat(index) - CGFloat(anchors.count - 1) / 2) * 0.21, resting: resting)
        }
    }
}
