import SwiftUI
import AppKit

public struct EditHostsView: View {
    @ObservedObject var hostsStore = HostsStore.shared
    @ObservedObject var l10n = LocalizationManager.shared

    @State private var selectedProfileId: UUID?
    @State private var editingContent: String = ""
    @State private var hasUnsavedChanges: Bool = false
    @State private var showingAddProfileSheet: Bool = false
    @State private var showingAddGroupSheet: Bool = false
    @State private var newProfileTitle: String = ""
    @State private var newGroupTitle: String = ""
    @State private var statusMessage: String?

    public init() {}

    public var body: some View {
        HSplitView {
            // 左侧侧边栏：方案树与分组
            VStack(spacing: 0) {
                // 顶栏提示
                HStack {
                    Text(loc(.hostsProfilesHeader))
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(hostsStore.config.profiles.count) \(loc(.hostsProfilesCountSuffix))")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(DeckTheme.barBackground)

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)

                // 方案列表
                ScrollView {
                    VStack(alignment: .leading, spacing: 2) {
                        // 独立未分组方案
                        ForEach(hostsStore.config.profiles.filter { $0.groupId == nil }) { profile in
                            ProfileListRow(
                                profile: profile,
                                isSelected: selectedProfileId == profile.id,
                                onSelect: { selectedProfileId = profile.id },
                                onToggle: { hostsStore.toggleProfile(id: profile.id) }
                            )
                        }

                        // 分组
                        ForEach(hostsStore.config.groups) { group in
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 5) {
                                    Image(systemName: "folder.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(.secondary)
                                    Text(group.title)
                                        .font(.system(size: 11, weight: .bold))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                }
                                .padding(.horizontal, 10)
                                .padding(.top, 10)
                                .padding(.bottom, 2)

                                ForEach(hostsStore.config.profiles.filter { $0.groupId == group.id }) { profile in
                                    ProfileListRow(
                                        profile: profile,
                                        isSelected: selectedProfileId == profile.id,
                                        indent: 14,
                                        onSelect: { selectedProfileId = profile.id },
                                        onToggle: { hostsStore.toggleProfile(id: profile.id) }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.vertical, 6)
                    .padding(.horizontal, 6)
                }
                .background(DeckTheme.subSidebarBackground)

                Rectangle()
                    .fill(DeckTheme.dividerColor)
                    .frame(height: 1)

                // 底部工具条 [+ -]
                HStack(spacing: 6) {
                    Menu {
                        Button(loc(.hostsNewProfile)) {
                            newProfileTitle = ""
                            showingAddProfileSheet = true
                        }
                        Button(loc(.hostsNewFolder)) {
                            newGroupTitle = ""
                            showingAddGroupSheet = true
                        }
                    } label: {
                        HStack(spacing: 2) {
                            Image(systemName: "plus")
                                .font(.system(size: 11))
                        }
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 28, height: 26)

                    Button(action: deleteSelected) {
                        Image(systemName: "minus")
                            .font(.system(size: 11))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 26)
                    .disabled(selectedProfileId == nil)

                    Spacer()
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(DeckTheme.barBackground)
            }
            .frame(minWidth: 180, idealWidth: 200, maxWidth: 240)

            // 右侧主代码编辑器区
            VStack(spacing: 0) {
                if let profile = selectedProfile {
                    // 当前方案标题与状态横幅
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 6) {
                                Text(profile.title)
                                    .font(.system(size: 13, weight: .bold))

                                Circle()
                                    .fill(profile.isEnabled ? Color.green : Color.gray.opacity(0.4))
                                    .frame(width: 7, height: 7)

                                Text(profile.isEnabled ? loc(.hostsActiveStatus) : loc(.hostsDisabledStatus))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(profile.isEnabled ? .green : .secondary)
                            }
                        }

                        Spacer()

                        if hasUnsavedChanges {
                            Text(loc(.hostsUnsaved))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(DeckTheme.barBackground)

                    Rectangle()
                        .fill(DeckTheme.dividerColor)
                        .frame(height: 1)

                    // 专业等宽代码编辑器
                    TextEditor(text: $editingContent)
                        .font(.system(size: 13, weight: .regular, design: .monospaced))
                        .lineSpacing(5)
                        .padding(14)
                        .background(DeckTheme.editorBackground)
                        .scrollContentBackground(.hidden)
                        .foregroundColor(Color(NSColor.textColor))
                        .onChange(of: editingContent) { newValue in
                            hasUnsavedChanges = (newValue != profile.content)
                        }

                    Rectangle()
                        .fill(DeckTheme.dividerColor)
                        .frame(height: 1)

                    // 编辑区底栏
                    HStack {
                        if let msg = statusMessage {
                            Text(msg)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.green)
                        }

                        Spacer()

                        Button(loc(.hostsRevert)) {
                            editingContent = profile.content
                            hasUnsavedChanges = false
                        }
                        .disabled(!hasUnsavedChanges)
                        .controlSize(.small)

                        Button(loc(.hostsApply)) {
                            applyChanges()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(DeckTheme.barBackground)
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.4))
                        Text(loc(.hostsSelectPrompt))
                            .font(.system(size: 13))
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(DeckTheme.editorBackground)
                }
            }
            .frame(minWidth: 420)
        }
        .onAppear {
            if selectedProfileId == nil {
                selectedProfileId = hostsStore.config.profiles.first?.id
            }
            loadSelectedContent()
        }
        .onChange(of: selectedProfileId) { _ in
            loadSelectedContent()
        }
        .sheet(isPresented: $showingAddProfileSheet) {
            AddProfileSheet(
                title: $newProfileTitle,
                groups: hostsStore.config.groups,
                onAdd: { title, groupId in
                    let newP = hostsStore.addProfile(title: title, groupId: groupId)
                    selectedProfileId = newP.id
                    showingAddProfileSheet = false
                },
                onCancel: { showingAddProfileSheet = false }
            )
        }
        .sheet(isPresented: $showingAddGroupSheet) {
            AddGroupSheet(
                title: $newGroupTitle,
                onAdd: { title in
                    _ = hostsStore.addGroup(title: title)
                    showingAddGroupSheet = false
                },
                onCancel: { showingAddGroupSheet = false }
            )
        }
    }

    private var selectedProfile: HostsProfile? {
        hostsStore.config.profiles.first(where: { $0.id == selectedProfileId })
    }

    private func loadSelectedContent() {
        if let profile = selectedProfile {
            editingContent = profile.content
            hasUnsavedChanges = false
        }
    }

    private func applyChanges() {
        guard var profile = selectedProfile else { return }
        profile.content = editingContent
        hostsStore.updateProfile(profile)
        hasUnsavedChanges = false

        let ok = HostsManager.shared.applyHostsToSystem()
        if ok {
            statusMessage = loc(.hostsApplySuccess)
        } else {
            statusMessage = loc(.hostsApplyFailed)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            statusMessage = nil
        }
    }

    private func deleteSelected() {
        guard let id = selectedProfileId else { return }
        hostsStore.deleteProfile(id: id)
        selectedProfileId = hostsStore.config.profiles.first?.id
    }
}

/// 方案行组件
struct ProfileListRow: View {
    let profile: HostsProfile
    let isSelected: Bool
    var indent: CGFloat = 0
    let onSelect: () -> Void
    let onToggle: () -> Void

    @State private var isHovered: Bool = false

    var body: some View {
        HStack(spacing: 8) {
            // 开关状态指示点（类似网络状态灯）
            Button(action: onToggle) {
                ZStack {
                    Circle()
                        .fill(profile.isEnabled ? Color.green.opacity(0.2) : Color.clear)
                        .frame(width: 14, height: 14)
                    Circle()
                        .fill(profile.isEnabled ? Color.green : Color.primary.opacity(0.2))
                        .frame(width: 8, height: 8)
                }
            }
            .buttonStyle(.plain)

            Text(profile.title)
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundColor(isSelected ? .white : .primary)
                .lineLimit(1)

            Spacer()

            if profile.isEnabled {
                Text(loc(.hostsActiveStatus))
                    .font(.system(size: 9))
                    .foregroundColor(isSelected ? .white.opacity(0.8) : .green)
            }
        }
        .padding(.leading, 8 + indent)
        .padding(.trailing, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .background(
            RoundedRectangle(cornerRadius: 6, style: .continuous)
                .fill(isSelected ? DeckTheme.accent : (isHovered ? DeckTheme.hoverBackground : Color.clear))
        )
        .onTapGesture {
            onSelect()
        }
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

struct AddProfileSheet: View {
    @Binding var title: String
    let groups: [HostsGroup]
    let onAdd: (String, UUID?) -> Void
    let onCancel: () -> Void

    @State private var selectedGroupId: UUID?

    var body: some View {
        VStack(spacing: 16) {
            Text(loc(.hostsNewProfileTitle))
                .font(.headline)

            Form {
                TextField(loc(.hostsProfileName), text: $title)
                    .frame(width: 260)

                Picker(loc(.hostsFolder), selection: $selectedGroupId) {
                    Text(loc(.hostsFolderTopLevel)).tag(Optional<UUID>.none)
                    ForEach(groups) { group in
                        Text(group.title).tag(Optional(group.id))
                    }
                }
            }

            HStack {
                Spacer()
                Button(loc(.hostsCancel), action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(loc(.hostsCreate)) {
                    let name = title.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        onAdd(name, selectedGroupId)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 360)
    }
}

struct AddGroupSheet: View {
    @Binding var title: String
    let onAdd: (String) -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text(loc(.hostsNewFolderTitle))
                .font(.headline)

            TextField(loc(.hostsFolderName), text: $title)
                .frame(width: 260)

            HStack {
                Spacer()
                Button(loc(.hostsCancel), action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Button(loc(.hostsCreate)) {
                    let name = title.trimmingCharacters(in: .whitespaces)
                    if !name.isEmpty {
                        onAdd(name)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
        }
        .padding(20)
        .frame(width: 340)
    }
}
