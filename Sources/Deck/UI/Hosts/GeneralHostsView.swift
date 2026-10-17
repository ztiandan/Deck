import SwiftUI

public struct GeneralHostsView: View {
    @ObservedObject var configStore = ConfigStore.shared
    @ObservedObject var launchAtLoginManager = LaunchAtLoginManager.shared
    @ObservedObject var l10n = LocalizationManager.shared
    @State private var isPasswordless: Bool = false
    @State private var statusTip: String?
    @State private var permissionFailed = false

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


                // 启动偏好
                VStack(alignment: .leading, spacing: 10) {
                    Text(loc(.prefStartupSection))
                        .font(.system(size: 13, weight: .bold))

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc(.prefLaunchAtLogin))
                                    .font(.system(size: 12.5, weight: .medium))
                                Text(loc(.prefLaunchAtLoginDesc))
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { launchAtLoginManager.isEnabled },
                                set: { launchAtLoginManager.setEnabled($0) }
                            ))
                            .labelsHidden()
                        }

                        Divider()

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(loc(.prefShowWindowOnLaunch))
                                    .font(.system(size: 12.5, weight: .medium))
                                Text(loc(.prefShowWindowOnLaunchDesc))
                                    .font(.system(size: 10.5))
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { configStore.config.showWindowOnLaunch },
                                set: { newValue in
                                    configStore.config.showWindowOnLaunch = newValue
                                    configStore.save()
                                }
                            ))
                            .labelsHidden()
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
                                    let manager = HostsManager.shared
                                    permissionFailed = !manager.enablePasswordlessMode()
                                    isPasswordless = manager.isPasswordlessEnabled()
                                    statusTip = permissionFailed ? manager.lastError : loc(.prefPasswordlessSuccess)
                                }
                                .controlSize(.regular)
                                .buttonStyle(.borderedProminent)
                            }
                        }

                        if let tip = statusTip {
                            HStack(spacing: 4) {
                                Image(systemName: permissionFailed ? "exclamationmark.triangle.fill" : "checkmark.circle.fill")
                                Text(tip)
                            }
                            .font(.system(size: 11.5, weight: .medium))
                            .foregroundColor(permissionFailed ? .red : .green)
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
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.1.6")
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
            launchAtLoginManager.refresh()
        }
    }
}
