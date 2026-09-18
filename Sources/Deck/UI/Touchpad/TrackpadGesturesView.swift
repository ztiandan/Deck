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
            .frame(minWidth: 240, idealWidth: 260, maxWidth: 300)

            // 右侧：动作与配置区
            if let index = gestureStore.gestures.firstIndex(where: { $0.id == selectedGestureId }) {
                GestureDetailView(gesture: $gestureStore.gestures[index])
                    .id(gestureStore.gestures[index].id)
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

                                HStack(spacing: 6) {
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

/// 触控板手势操作动态示意图
struct TrackpadGestureIllustrationView: View {
    let gestureType: GestureType
    @ObservedObject var l10n = LocalizationManager.shared

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

            HStack(spacing: 16) {
                // 模拟触控板动画画布
                TimelineView(.periodic(from: .now, by: 1.0 / 30.0)) { context in
                    TrackpadCanvas(gestureType: gestureType, date: context.date)
                }
                .frame(width: 170, height: 100)

                // 详细操作步骤与图例
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

                    Text(gestureType.description)
                        .font(.system(size: 10.5))
                        .foregroundColor(.secondary.opacity(0.85))
                        .lineLimit(2)
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

/// 模拟触控板图形与手指运动
struct TrackpadCanvas: View {
    let gestureType: GestureType
    let date: Date

    var body: some View {
        let time = date.timeIntervalSinceReferenceDate
        let cycle = (time.truncatingRemainder(dividingBy: 1.5)) / 1.5 // 0.0 ... 1.0

        // 敲击动态阶段计算
        let tapProgress: (offset: CGFloat, scale: CGFloat, rippleScale: CGFloat, rippleOpacity: Double) = {
            if cycle < 0.20 {
                // 悬停准备阶段
                return (offset: -7, scale: 0.9, rippleScale: 0, rippleOpacity: 0)
            } else if cycle < 0.38 {
                // 触板敲击瞬间
                let p = (cycle - 0.20) / 0.18
                return (offset: -7 * (1.0 - p), scale: 0.9 + 0.25 * p, rippleScale: 1.0 + p * 1.5, rippleOpacity: 1.0 - p)
            } else if cycle < 0.55 {
                // 短暂停留接触
                let p = (cycle - 0.38) / 0.17
                return (offset: 0, scale: 1.15 - 0.05 * p, rippleScale: 2.5, rippleOpacity: 0)
            } else if cycle < 0.75 {
                // 抬起阶段
                let p = (cycle - 0.55) / 0.20
                return (offset: -7 * p, scale: 1.1 - 0.2 * p, rippleScale: 0, rippleOpacity: 0)
            } else {
                // 静止间隙等待下一次循环
                return (offset: -7, scale: 0.9, rippleScale: 0, rippleOpacity: 0)
            }
        }()

        ZStack {
            // 触控板外框底板
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.08), Color.primary.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color.primary.opacity(0.12), lineWidth: 1)
                )

            // 顶部微质感边缘
            VStack {
                Rectangle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(height: 1)
                    .padding(.horizontal, 16)
                    .padding(.top, 4)
                Spacer()
            }

            // 手指接触点呈现
            GeometryReader { geo in
                let w = geo.size.width
                let h = geo.size.height
                let centerY = h * 0.48

                ZStack {
                    ForEach(fingerConfigs(for: gestureType, width: w), id: \.id) { config in
                        if config.isResting {
                            // 固定按压手指（平稳静止）
                            VStack(spacing: 2) {
                                ZStack {
                                    Circle()
                                        .fill(Color.blue.opacity(0.2))
                                        .frame(width: 26, height: 26)

                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.blue, Color.blue.opacity(0.8)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 19, height: 19)
                                        .shadow(color: Color.blue.opacity(0.4), radius: 3, x: 0, y: 1)

                                    Circle()
                                        .fill(Color.white.opacity(0.7))
                                        .frame(width: 5, height: 5)
                                }

                                Text("Hold")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.blue.opacity(0.85))
                            }
                            .position(x: config.x, y: centerY)
                        } else {
                            // 动态轻敲手指（带悬停、触板冲击波、抬起动效）
                            VStack(spacing: 2) {
                                ZStack {
                                    // 触板冲击扩散涟漪波
                                    if tapProgress.rippleOpacity > 0.05 {
                                        Circle()
                                            .stroke(Color.orange.opacity(tapProgress.rippleOpacity), lineWidth: 1.8)
                                            .frame(width: 19 * tapProgress.rippleScale, height: 19 * tapProgress.rippleScale)
                                    }

                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [Color.orange, Color.orange.opacity(0.85)],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: 19, height: 19)
                                        .scaleEffect(tapProgress.scale)
                                        .offset(y: tapProgress.offset)
                                        .shadow(color: Color.orange.opacity(tapProgress.offset == 0 ? 0.45 : 0.15), radius: tapProgress.offset == 0 ? 4 : 2, x: 0, y: tapProgress.offset == 0 ? 1 : 4)

                                    Circle()
                                        .fill(Color.white.opacity(0.8))
                                        .frame(width: 5, height: 5)
                                        .scaleEffect(tapProgress.scale)
                                        .offset(y: tapProgress.offset)
                                }

                                Text("Tap")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.orange)
                            }
                            .position(x: config.x, y: centerY)
                        }
                    }
                }
            }
        }
    }

    private struct FingerConfig: Identifiable {
        let id: Int
        let x: CGFloat
        let isResting: Bool
    }

    private func fingerConfigs(for type: GestureType, width: CGFloat) -> [FingerConfig] {
        switch type {
        case .tipTapRight2F:
            return [
                FingerConfig(id: 1, x: width * 0.36, isResting: true),
                FingerConfig(id: 2, x: width * 0.64, isResting: false)
            ]
        case .tipTapLeft2F:
            return [
                FingerConfig(id: 1, x: width * 0.36, isResting: false),
                FingerConfig(id: 2, x: width * 0.64, isResting: true)
            ]
        case .tipTapLeft3F:
            return [
                FingerConfig(id: 1, x: width * 0.28, isResting: false),
                FingerConfig(id: 2, x: width * 0.50, isResting: true),
                FingerConfig(id: 3, x: width * 0.72, isResting: true)
            ]
        case .tipTapRight3F:
            return [
                FingerConfig(id: 1, x: width * 0.28, isResting: true),
                FingerConfig(id: 2, x: width * 0.50, isResting: true),
                FingerConfig(id: 3, x: width * 0.72, isResting: false)
            ]
        case .fourFingerTap:
            return [
                FingerConfig(id: 1, x: width * 0.22, isResting: false),
                FingerConfig(id: 2, x: width * 0.41, isResting: false),
                FingerConfig(id: 3, x: width * 0.59, isResting: false),
                FingerConfig(id: 4, x: width * 0.78, isResting: false)
            ]
        case .threeFingerTap:
            return [
                FingerConfig(id: 1, x: width * 0.28, isResting: false),
                FingerConfig(id: 2, x: width * 0.50, isResting: false),
                FingerConfig(id: 3, x: width * 0.72, isResting: false)
            ]
        }
    }
}

