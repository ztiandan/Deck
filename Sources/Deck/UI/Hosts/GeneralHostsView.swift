import SwiftUI

public struct GeneralHostsView: View {
    @ObservedObject var hostsStore = HostsStore.shared
    @ObservedObject var configStore = ConfigStore.shared
    @ObservedObject var l10n = LocalizationManager.shared
    @State private var isPasswordless: Bool = false
    @State private var statusTip: String?

    public init() {}

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 外观主题
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.prefAppearanceSection))
                        .font(.system(size: 13, weight: .bold))

                    HStack {
                        Text(loc(.prefAppearanceLabel))
                            .font(.system(size: 12.5))
                        Spacer()
                        Picker("", selection: Binding(
                            get: { configStore.config.themeMode },
                            set: { newMode in
                                configStore.config.themeMode = newMode
                                configStore.save()
                                MainWindowController.shared.updateAppearance()
                            }
                        )) {
                            ForEach(AppThemeMode.allCases) { mode in
                                Text(mode.title).tag(mode)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
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

                // 语言选择
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.prefLanguageSection))
                        .font(.system(size: 13, weight: .bold))

                    HStack {
                        Text(loc(.prefLanguageLabel))
                            .font(.system(size: 12.5))
                        Spacer()
                        Picker("", selection: $l10n.currentLanguage) {
                            ForEach(AppLanguage.allCases) { lang in
                                Text(lang.displayName).tag(lang)
                            }
                        }
                        .labelsHidden()
                        .frame(width: 190)
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

                // Hosts 偏好
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.prefHostsSection))
                        .font(.system(size: 13, weight: .bold))

                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(loc(.prefHoverPreview), isOn: $hostsStore.config.previewOnHover)
                            .onChange(of: hostsStore.config.previewOnHover) { _ in hostsStore.save() }

                        Divider()

                        Toggle(loc(.prefGroupExclusive), isOn: $hostsStore.config.exclusiveInGroup)
                            .onChange(of: hostsStore.config.exclusiveInGroup) { _ in hostsStore.save() }
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

                // 免密切换提权
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.prefPrivilegesSection))
                        .font(.system(size: 13, weight: .bold))

                    VStack(alignment: .leading, spacing: 10) {
                        HStack(spacing: 14) {
                            Image(systemName: isPasswordless ? "checkmark.shield.fill" : "lock.shield.fill")
                                .foregroundColor(isPasswordless ? .green : .orange)
                                .font(.system(size: 22))

                            VStack(alignment: .leading, spacing: 3) {
                                Text(isPasswordless ? loc(.prefPasswordlessActive) : loc(.prefPasswordlessInactive))
                                    .font(.system(size: 13, weight: .semibold))
                                Text(isPasswordless ? loc(.prefPasswordlessActiveDesc) : loc(.prefPasswordlessInactiveDesc))
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            if !isPasswordless {
                                Button(loc(.prefEnablePasswordless)) {
                                    if HostsManager.shared.enablePasswordlessMode() {
                                        isPasswordless = true
                                        statusTip = loc(.prefPasswordlessSuccess)
                                    }
                                }
                                .controlSize(.regular)
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        if let tip = statusTip {
                            HStack(spacing: 4) {
                                Image(systemName: "checkmark.circle.fill")
                                Text(tip)
                            }
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(.green)
                            .padding(.top, 4)
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

                // 版本信息
                HStack(spacing: 6) {
                    Text(loc(.prefVersionLabel))
                        .foregroundColor(.secondary)
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.1")
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.primary)
                }
                .font(.system(size: 11.5))
                .padding(.top, 4)
            }
            .padding(20)
        }
        .onAppear {
            isPasswordless = HostsManager.shared.isPasswordlessEnabled()
        }
    }
}
