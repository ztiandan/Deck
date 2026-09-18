import Foundation
import SwiftUI
import Combine

public enum AppLanguage: String, CaseIterable, Identifiable, Codable {
    case english = "en"
    case chinese = "zh-Hans"

    public var id: String { self.rawValue }

    public var displayName: String {
        switch self {
        case .english: return "English (Default)"
        case .chinese: return "简体中文 (Chinese)"
        }
    }
}

public enum L10nKey: String, CaseIterable {
    // Brand & Navigation
    case appName
    case appSubtitle
    case navHostsManagement
    case navProfiles
    case navQuickSwitch
    case navPaletteMappings
    case navTouchGestures
    case navTrackpadGestures
    case navPreferences
    case navGeneralSettings
    case serviceRunning
    case serviceNeedsAttention
    case configIssueTitle
    case paletteKeyInvalid
    case paletteKeyDuplicate
    case hostsDeleteFolder

    // Tab Titles
    case tabEditHosts
    case tabAppSwitcher
    case tabTrackpad
    case tabGeneral

    // Menubar & System Menu
    case menuTooltip
    case menuEditHosts
    case menuViewHosts
    case menuTogglePalette
    case menuTouchGestures
    case menuGesturesActive
    case menuGesturesPaused
    case menuGestureSettings
    case menuPreferences
    case menuQuit
    case menuAbout
    case menuFile
    case menuCloseWindow
    case menuEdit
    case menuUndo
    case menuRedo
    case menuCut
    case menuCopy
    case menuPaste
    case menuSelectAll
    case menuWindow
    case menuMinimize

    // Hosts Section
    case hostsProfilesHeader
    case hostsProfilesCountSuffix
    case hostsNewProfile
    case hostsNewFolder
    case hostsActiveStatus
    case hostsDisabledStatus
    case hostsUnsaved
    case hostsRevert
    case hostsApply
    case hostsSelectPrompt
    case hostsApplySuccess
    case hostsApplyFailed
    case hostsProfileName
    case hostsFolder
    case hostsFolderTopLevel
    case hostsNewProfileTitle
    case hostsNewFolderTitle
    case hostsFolderName
    case hostsCancel
    case hostsCreate
    case hostsSystemActiveTitle
    case hostsRefresh
    case hostsCopy
    case hostsCopied
    case hostsEnabledPending
    case hostsAlreadyApplied
    case hostsVerificationFailed
    case hostsPermissionFailed
    case hostsRestoreFailed
    case hostsAuthorizationPrompt
    case hostsAuthorizationCancelled
    case hostsReadFailed
    case hostsCheckResolution
    case hostsCheckingResolution
    case hostsResolutionMatches
    case hostsResolutionMixed
    case hostsResolutionMismatch
    case hostsResolutionMissing
    case hostsNoCustomDomain
    case hostsFileOnlyHint
    case hostsEmptyContent

    // General Preferences
    case prefAppearanceSection
    case prefAppearanceLabel
    case prefThemeLight
    case prefThemeDark
    case prefThemeSystem
    case prefLanguageSection
    case prefLanguageLabel
    case prefHostsSection
    case prefHoverPreview
    case prefGroupExclusive
    case prefPrivilegesSection
    case prefPasswordlessActive
    case prefPasswordlessInactive
    case prefPasswordlessActiveDesc
    case prefPasswordlessInactiveDesc
    case prefEnablePasswordless
    case prefPasswordlessSuccess
    case prefVersionLabel

    // Touchpad Gestures
    case gestureListHeader
    case gestureReset
    case gestureTriggerActionHeader
    case gesturePropertiesHeader
    case gestureTypeLabel
    case gestureEnableToggle
    case gestureActionTypeLabel
    case gestureShortcutLabel
    case gesturePresetsLabel
    case gestureNotesLabel
    case gestureNotesPlaceholder
    case gestureSelectPrompt
    case gestureAddTitle
    case gestureAddAction
    case gestureActionShortcut
    case gestureActionCmdClick
    case gestureActionMiddleClick
    case gestureTipTapRight2F
    case gestureTipTapLeft2F
    case gestureTipTapLeft3F
    case gestureTipTapRight3F
    case gestureFourFingerTap
    case gestureThreeFingerTap
    case gestureTipTapRight2FDesc
    case gestureTipTapLeft2FDesc
    case gestureTipTapLeft3FDesc
    case gestureTipTapRight3FDesc
    case gestureFourFingerTapDesc
    case gestureThreeFingerTapDesc
    case gestureHapticFeedbackToggle
    case gestureHapticFeedbackDesc
    case gestureIllustrationHeader
    case gestureIllustrationBadge
    case gestureShortcutInvalid
    case gestureDemoPrepare
    case gestureDemoReady
    case gestureDemoTouch
    case gestureDemoLift
    case gestureDemoHoldShort
    case gestureDemoTapShort
    case gestureDemoLiftShort
    case gestureDemoHint
    case gestureDemoMultiHint
    case gestureDemoHoldFinger
    case gestureDemoTapFinger
    case gestureDemoSimultaneousTap
    case gestureDemoTipTapRight2F
    case gestureDemoTipTapLeft2F
    case gestureDemoTipTapLeft3F
    case gestureDemoTipTapRight3F
    case gestureDemoFourFingerTap
    case gestureDemoThreeFingerTap

    // Palette & App Switcher
    case paletteAccessibilityPrompt
    case paletteAuthorize
    case paletteTriggerKeyLabel
    case palettePositionLabel
    case paletteCenterScreen
    case paletteFollowCursor
    case paletteTriggerSection
    case paletteCurrentKey
    case paletteRecordButton
    case paletteRecordingPrompt
    case paletteShowAtCursor
    case paletteShowAtCursorDesc
    case paletteMappingsHeader
    case paletteSearchPlaceholder
    case paletteAddMapping
    case paletteAddMappingTitle
    case paletteEditMappingTitle
    case paletteKeyFieldPlaceholder
    case paletteAppNameLabel
    case paletteBrowseButton
    case paletteDisplayNameLabel
    case paletteSaveButton
    case paletteKeyCol
    case paletteActionCol
    case paletteTargetCol
    case paletteResetDefaults
    case paletteActionActivateLast
    case paletteActionActivateApp
    case paletteHudPrompt
}

public class LocalizationManager: ObservableObject {
    public static let shared = LocalizationManager()

    private let prefKey = "deck_app_language_preference"

    @Published public var currentLanguage: AppLanguage {
        didSet {
            UserDefaults.standard.set(currentLanguage.rawValue, forKey: prefKey)
            onLanguageChanged?()
        }
    }

    public var onLanguageChanged: (() -> Void)?

    private init() {
        if let saved = UserDefaults.standard.string(forKey: prefKey),
           let lang = AppLanguage(rawValue: saved) {
            self.currentLanguage = lang
        } else {
            // Default to English as requested
            self.currentLanguage = .english
        }
    }

    public func setLanguage(_ language: AppLanguage) {
        self.currentLanguage = language
    }

    public func t(_ key: L10nKey) -> String {
        switch currentLanguage {
        case .english:
            return englishStrings[key] ?? key.rawValue
        case .chinese:
            return chineseStrings[key] ?? key.rawValue
        }
    }

    private let englishStrings: [L10nKey: String] = [
        .appName: "Deck",
        .appSubtitle: "Speed Console",
        .navHostsManagement: "HOSTS MANAGEMENT",
        .navProfiles: "Profiles",
        .navQuickSwitch: "QUICK SWITCH",
        .navPaletteMappings: "Palette Mappings",
        .navTouchGestures: "TOUCH GESTURES",
        .navTrackpadGestures: "Trackpad Gestures",
        .navPreferences: "PREFERENCES",
        .navGeneralSettings: "General Settings",
        .serviceRunning: "Service Running",
        .serviceNeedsAttention: "Check service permissions",
        .configIssueTitle: "Configuration could not be loaded or saved",
        .paletteKeyInvalid: "Enter one character or Space.",
        .paletteKeyDuplicate: "This key is already assigned to another action.",
        .hostsDeleteFolder: "Remove folder and keep profiles",

        .tabEditHosts: "Edit Hosts Profiles",
        .tabAppSwitcher: "App Switcher & Palette",
        .tabTrackpad: "Trackpad Gestures",
        .tabGeneral: "General Preferences",

        .menuTooltip: "Deck: Trackpad Gestures / Hosts / App Switcher",
        .menuEditHosts: "Edit Hosts...",
        .menuViewHosts: "View Hosts",
        .menuTogglePalette: "Trigger App Palette",
        .menuTouchGestures: "Trackpad Gestures",
        .menuGesturesActive: "✓ Gestures Active (Click to Pause)",
        .menuGesturesPaused: "Gestures Paused (Click to Enable)",
        .menuGestureSettings: "Gestures & Actions Settings...",
        .menuPreferences: "Preferences & Settings...",
        .menuQuit: "Quit Deck",
        .menuAbout: "About Deck",
        .menuFile: "File",
        .menuCloseWindow: "Close Window",
        .menuEdit: "Edit",
        .menuUndo: "Undo",
        .menuRedo: "Redo",
        .menuCut: "Cut",
        .menuCopy: "Copy",
        .menuPaste: "Paste",
        .menuSelectAll: "Select All",
        .menuWindow: "Window",
        .menuMinimize: "Minimize",

        .hostsProfilesHeader: "Profiles & Groups",
        .hostsProfilesCountSuffix: "items",
        .hostsNewProfile: "New Hosts Profile...",
        .hostsNewFolder: "New Folder...",
        .hostsActiveStatus: "Applied",
        .hostsDisabledStatus: "Disabled",
        .hostsUnsaved: "● Unsaved",
        .hostsRevert: "Revert",
        .hostsEnabledPending: "Pending apply",
        .hostsAlreadyApplied: "Already matches /etc/hosts; verified.",
        .hostsVerificationFailed: "The content read back from /etc/hosts did not match. Please retry.",
        .hostsPermissionFailed: "Could not grant write access to /etc/hosts.",
        .hostsRestoreFailed: "Writing hosts and restoring the previous content failed. Check /etc/hosts before continuing.",
        .hostsAuthorizationPrompt: "Allow your current account to write /etc/hosts. Future changes from this account will not need an administrator password.",
        .hostsAuthorizationCancelled: "Authorization cancelled. Changes have not been applied.",
        .hostsReadFailed: "Could not read /etc/hosts. The preview only shows the actual system file.",
        .hostsCheckResolution: "Check resolution",
        .hostsCheckingResolution: "Checking the first custom domain…",
        .hostsResolutionMatches: "%@: expected %@; resolved %@. Matches.",
        .hostsResolutionMixed: "%@: expected %@; resolved %@. The expected address is present, but extra addresses may still be used. Check IPv6 and VPN/proxy DNS.",
        .hostsResolutionMismatch: "%@: expected %@; resolved %@. The hosts file is written, but DNS differs. Check VPN/proxy DNS and application caches.",
        .hostsResolutionMissing: "No address returned",
        .hostsNoCustomDomain: "No custom domain to check.",
        .hostsFileOnlyHint: "Applied verifies the system file. Check resolution to see whether DNS follows it.",
        .hostsApply: "Apply",
        .hostsSelectPrompt: "Select a Hosts profile on the left to edit",
        .hostsApplySuccess: "Written to /etc/hosts and verified.",
        .hostsApplyFailed: "⚠️ Requires authorization or failed",
        .hostsProfileName: "Profile Name:",
        .hostsFolder: "Folder:",
        .hostsFolderTopLevel: "None (Top Level)",
        .hostsNewProfileTitle: "New Hosts Profile",
        .hostsNewFolderTitle: "New Folder",
        .hostsFolderName: "Folder Name:",
        .hostsCancel: "Cancel",
        .hostsCreate: "Create",
        .hostsSystemActiveTitle: "Current /etc/hosts",
        .hostsRefresh: "Refresh",
        .hostsCopy: "Copy",
        .hostsCopied: "Copied",
        .hostsEmptyContent: "# No active hosts entries",

        .prefAppearanceSection: "Appearance",
        .prefAppearanceLabel: "Theme Mode:",
        .prefThemeLight: "Light (Fresh)",
        .prefThemeDark: "Dark",
        .prefThemeSystem: "System Default",
        .prefLanguageSection: "Language",
        .prefLanguageLabel: "Interface Language:",
        .prefHostsSection: "Hosts Preferences",
        .prefHoverPreview: "Preview content on hover",
        .prefGroupExclusive: "Only activate one item in a group (Mutual Exclusion)",
        .prefPrivilegesSection: "Permissions & Privileges",
        .prefPasswordlessActive: "Passwordless Mode Enabled",
        .prefPasswordlessInactive: "Passwordless Mode Disabled",
        .prefPasswordlessActiveDesc: "Your current account can write hosts directly; Apply verifies the saved contents.",
        .prefPasswordlessInactiveDesc: "Authorize once to let your current account write hosts without repeated password prompts.",
        .prefEnablePasswordless: "Enable Passwordless",
        .prefPasswordlessSuccess: "Passwordless mode successfully enabled",
        .prefVersionLabel: "Deck Version:",

        .gestureListHeader: "Gesture List",
        .gestureReset: "Reset",
        .gestureTriggerActionHeader: "Trigger Action",
        .gesturePropertiesHeader: "Gesture Properties",
        .gestureTypeLabel: "Trackpad Gesture:",
        .gestureEnableToggle: "Enable this gesture",
        .gestureActionTypeLabel: "Action Type:",
        .gestureShortcutLabel: "Shortcut:",
        .gesturePresetsLabel: "Presets:",
        .gestureNotesLabel: "Notes:",
        .gestureNotesPlaceholder: "Optional description",
        .gestureSelectPrompt: "Select a gesture on the left to configure",
        .gestureAddTitle: "Add Trackpad Gesture",
        .gestureAddAction: "Add",
        .gestureActionShortcut: "Keyboard Shortcut",
        .gestureActionCmdClick: "CMD(⌘) + Click",
        .gestureActionMiddleClick: "Middle Click",
        .gestureTipTapRight2F: "TipTap Right (2 Fingers)",
        .gestureTipTapLeft2F: "TipTap Left (2 Fingers)",
        .gestureTipTapLeft3F: "TipTap Left (3 Fingers)",
        .gestureTipTapRight3F: "TipTap Right (3 Fingers)",
        .gestureFourFingerTap: "4-Finger Tap",
        .gestureThreeFingerTap: "3-Finger Tap",
        .gestureTipTapRight2FDesc: "Hold 1 finger left, tap 1 finger right (e.g. Close Tab)",
        .gestureTipTapLeft2FDesc: "Hold 1 finger right, tap 1 finger left (e.g. Reload Page)",
        .gestureTipTapLeft3FDesc: "Hold 2 fingers, tap leftmost finger (Previous Tab/Desktop)",
        .gestureTipTapRight3FDesc: "Hold 2 fingers, tap rightmost finger (Next Tab/Desktop)",
        .gestureFourFingerTapDesc: "Tap with 4 fingers simultaneously (Open link in background)",
        .gestureThreeFingerTapDesc: "Tap with 3 fingers simultaneously",
        .gestureHapticFeedbackToggle: "Haptic Feedback on Trackpad",
        .gestureHapticFeedbackDesc: "Provide subtle tactile click feedback when gesture triggers",
        .gestureIllustrationHeader: "How it Works (Gesture Demonstration)",
        .gestureIllustrationBadge: "Gesture Demo",
        .gestureShortcutInvalid: "Enter a shortcut such as ⌘ W or ctrl+left.",
        .gestureDemoPrepare: "1 · Rest fingers",
        .gestureDemoReady: "1 · Position fingers",
        .gestureDemoTouch: "2 · Touch down",
        .gestureDemoLift: "3 · Lift to trigger",
        .gestureDemoHoldShort: "Hold",
        .gestureDemoTapShort: "Tap",
        .gestureDemoLiftShort: "Lift",
        .gestureDemoHint: "Keep blue fingers resting. Touch and lift orange fingers; do not press or swipe.",
        .gestureDemoMultiHint: "Touch and lift all fingers together. No click or swipe needed.",
        .gestureDemoHoldFinger: "Resting / Anchored",
        .gestureDemoTapFinger: "Tap once",
        .gestureDemoSimultaneousTap: "Tap simultaneously",
        .gestureDemoTipTapRight2F: "Rest left finger on trackpad, tap right finger once",
        .gestureDemoTipTapLeft2F: "Rest right finger on trackpad, tap left finger once",
        .gestureDemoTipTapLeft3F: "Rest 2 fingers on trackpad, tap leftmost finger once",
        .gestureDemoTipTapRight3F: "Rest 2 fingers on trackpad, tap rightmost finger once",
        .gestureDemoFourFingerTap: "Tap simultaneously with 4 fingers on trackpad",
        .gestureDemoThreeFingerTap: "Tap simultaneously with 3 fingers on trackpad",

        .paletteAccessibilityPrompt: "Accessibility permission is required to listen for global trigger key",
        .paletteAuthorize: "Authorize",
        .paletteTriggerKeyLabel: "Trigger Key:",
        .palettePositionLabel: "Panel Position:",
        .paletteCenterScreen: "Center of Screen",
        .paletteFollowCursor: "Follow Mouse Cursor",
        .paletteTriggerSection: "Palette Trigger Key",
        .paletteCurrentKey: "Current Key:",
        .paletteRecordButton: "Click to Record New Key",
        .paletteRecordingPrompt: "Press any single key (e.g. F18)...",
        .paletteShowAtCursor: "Show at Mouse Cursor",
        .paletteShowAtCursorDesc: "Display HUD popup near mouse pointer instead of screen center.",
        .paletteMappingsHeader: "Configured Mappings",
        .paletteSearchPlaceholder: "Search apps or keys...",
        .paletteAddMapping: "Add Mapping...",
        .paletteAddMappingTitle: "Add Key Mapping",
        .paletteEditMappingTitle: "Edit Mapping",
        .paletteKeyFieldPlaceholder: "Key (e.g. c, v, Space, |):",
        .paletteAppNameLabel: "App Name:",
        .paletteBrowseButton: "Browse...",
        .paletteDisplayNameLabel: "Display Name:",
        .paletteSaveButton: "Save",
        .paletteKeyCol: "Key",
        .paletteActionCol: "Action",
        .paletteTargetCol: "Target Application",
        .paletteResetDefaults: "Reset to Default Mappings",
        .paletteActionActivateLast: "Activate Last Application",
        .paletteActionActivateApp: "Activate Application",
        .paletteHudPrompt: "Press key to switch application"
    ]

    private let chineseStrings: [L10nKey: String] = [
        .appName: "Deck",
        .appSubtitle: "极速控制台",
        .navHostsManagement: "HOSTS 管理",
        .navProfiles: "方案列表",
        .navQuickSwitch: "快捷切换",
        .navPaletteMappings: "快捷映射",
        .navTouchGestures: "触控手势",
        .navTrackpadGestures: "触控板手势",
        .navPreferences: "偏好",
        .navGeneralSettings: "通用设置",
        .serviceRunning: "服务运行中",
        .serviceNeedsAttention: "请检查服务权限",
        .configIssueTitle: "配置读取或保存失败",
        .paletteKeyInvalid: "请输入单个字符或 Space。",
        .paletteKeyDuplicate: "该按键已分配给其他操作。",
        .hostsDeleteFolder: "删除文件夹并保留方案",

        .tabEditHosts: "编辑 Hosts 方案",
        .tabAppSwitcher: "应用切换与调色板",
        .tabTrackpad: "触控板手势增强",
        .tabGeneral: "通用偏好设置",

        .menuTooltip: "Deck: 触控手势 / Hosts / 应用切换",
        .menuEditHosts: "编辑 Hosts...",
        .menuViewHosts: "查看当前 Hosts",
        .menuTogglePalette: "呼出应用调色板",
        .menuTouchGestures: "触控手势",
        .menuGesturesActive: "✓ 手势功能生效中 (点击暂停)",
        .menuGesturesPaused: "手势功能已暂停 (点击启用)",
        .menuGestureSettings: "手势与动作设置...",
        .menuPreferences: "偏好设置与管理...",
        .menuQuit: "退出 Deck",
        .menuAbout: "关于 Deck",
        .menuFile: "文件",
        .menuCloseWindow: "关闭窗口",
        .menuEdit: "编辑",
        .menuUndo: "撤销",
        .menuRedo: "重做",
        .menuCut: "剪切",
        .menuCopy: "复制",
        .menuPaste: "粘贴",
        .menuSelectAll: "全选",
        .menuWindow: "窗口",
        .menuMinimize: "最小化",

        .hostsProfilesHeader: "方案与环境",
        .hostsProfilesCountSuffix: "个",
        .hostsNewProfile: "新建 Hosts 方案...",
        .hostsNewFolder: "新建分组文件夹...",
        .hostsActiveStatus: "已应用",
        .hostsDisabledStatus: "未启用",
        .hostsUnsaved: "● 未保存",
        .hostsRevert: "撤回",
        .hostsEnabledPending: "待应用",
        .hostsAlreadyApplied: "与 /etc/hosts 一致，已核验。",
        .hostsVerificationFailed: "读回的 /etc/hosts 内容不一致，请重试。",
        .hostsPermissionFailed: "未能取得 /etc/hosts 写入权限。",
        .hostsRestoreFailed: "写入失败，且未能恢复原内容，请先检查 /etc/hosts。",
        .hostsAuthorizationPrompt: "允许当前账户写入 /etc/hosts。授权后，此账户后续修改无需再输入管理员密码。",
        .hostsAuthorizationCancelled: "已取消授权，修改尚未应用。",
        .hostsReadFailed: "无法读取 /etc/hosts。预览仅展示真实系统文件。",
        .hostsCheckResolution: "检查解析",
        .hostsCheckingResolution: "正在检查首个自定义域名…",
        .hostsResolutionMatches: "%@：预期 %@；实际 %@。解析匹配。",
        .hostsResolutionMixed: "%@：预期 %@；实际 %@。包含预期地址，但仍可能使用其他返回地址，请检查 IPv6 和 VPN／代理 DNS。",
        .hostsResolutionMismatch: "%@：预期 %@；实际 %@。hosts 已写入，但解析不一致，请检查 VPN／代理 DNS 和应用缓存。",
        .hostsResolutionMissing: "未返回地址",
        .hostsNoCustomDomain: "没有可检查的自定义域名。",
        .hostsFileOnlyHint: "“已应用”表示系统文件已核验；点击“检查解析”确认 DNS 是否使用该映射。",
        .hostsApply: "应用生效",
        .hostsSelectPrompt: "请从左侧选择一个 Hosts 方案进行编辑",
        .hostsApplySuccess: "已写入 /etc/hosts 并读回核验。",
        .hostsApplyFailed: "⚠️ 应用需授权或失败，请检查",
        .hostsProfileName: "方案名称:",
        .hostsFolder: "所属分组:",
        .hostsFolderTopLevel: "无分组 (顶层)",
        .hostsNewProfileTitle: "新建 Hosts 方案",
        .hostsNewFolderTitle: "新建分组文件夹",
        .hostsFolderName: "分组名称:",
        .hostsCancel: "取消",
        .hostsCreate: "创建",
        .hostsSystemActiveTitle: "当前系统 Hosts",
        .hostsRefresh: "刷新",
        .hostsCopy: "复制",
        .hostsCopied: "已复制",
        .hostsEmptyContent: "# 暂无生效 Hosts 内容",

        .prefAppearanceSection: "外观配色",
        .prefAppearanceLabel: "主题模式:",
        .prefThemeLight: "清爽浅色",
        .prefThemeDark: "深色模式",
        .prefThemeSystem: "跟随系统",
        .prefLanguageSection: "语言设置",
        .prefLanguageLabel: "界面语言:",
        .prefHostsSection: "Hosts 偏好",
        .prefHoverPreview: "悬停预览内容",
        .prefGroupExclusive: "分组内单选互斥",
        .prefPrivilegesSection: "权限与提权",
        .prefPasswordlessActive: "免密模式已开启",
        .prefPasswordlessInactive: "未开启免密切换",
        .prefPasswordlessActiveDesc: "当前账户可直接写入 hosts；应用后会读回核验。",
        .prefPasswordlessInactiveDesc: "授权一次，允许当前账户写入 hosts，之后无需重复输入密码。",
        .prefEnablePasswordless: "开启免密",
        .prefPasswordlessSuccess: "已成功开启免密模式",
        .prefVersionLabel: "Deck 版本:",

        .gestureListHeader: "手势列表",
        .gestureReset: "重置",
        .gestureTriggerActionHeader: "触发动作",
        .gesturePropertiesHeader: "手势属性",
        .gestureTypeLabel: "触控板手势:",
        .gestureEnableToggle: "启用此手势",
        .gestureActionTypeLabel: "动作类型:",
        .gestureShortcutLabel: "快捷键:",
        .gesturePresetsLabel: "预设:",
        .gestureNotesLabel: "备注:",
        .gestureNotesPlaceholder: "可选说明",
        .gestureSelectPrompt: "选择左侧手势进行配置",
        .gestureAddTitle: "添加触控板手势",
        .gestureAddAction: "添加",
        .gestureActionShortcut: "键盘快捷键",
        .gestureActionCmdClick: "CMD(⌘) + 点击",
        .gestureActionMiddleClick: "鼠标中键",
        .gestureTipTapRight2F: "TipTap Right (双指·右敲)",
        .gestureTipTapLeft2F: "TipTap Left (双指·左敲)",
        .gestureTipTapLeft3F: "TipTap Left (三指·左敲)",
        .gestureTipTapRight3F: "TipTap Right (三指·右敲)",
        .gestureFourFingerTap: "四指同时轻点",
        .gestureThreeFingerTap: "三指同时轻点",
        .gestureTipTapRight2FDesc: "两指搭板，左指固定，右指轻敲（如关闭标签）",
        .gestureTipTapLeft2FDesc: "两指搭板，右指固定，左指轻敲（如刷新页面）",
        .gestureTipTapLeft3FDesc: "三指搭板，最左侧手指轻敲（前一切换标签/桌面）",
        .gestureTipTapRight3FDesc: "三指搭板，最右侧手指轻敲（后一切换标签/桌面）",
        .gestureFourFingerTapDesc: "四指同时轻点触控板（后台新标签打开网页）",
        .gestureThreeFingerTapDesc: "三根手指同时轻拍触控板",
        .gestureHapticFeedbackToggle: "触控板触觉反馈",
        .gestureHapticFeedbackDesc: "手势触发时通过触控板 Taptic 引擎提供物理敲击感",
        .gestureIllustrationHeader: "操作手势动态示意",
        .gestureIllustrationBadge: "动态演示",
        .gestureShortcutInvalid: "请输入有效快捷键，例如 ⌘ W 或 ctrl+left。",
        .gestureDemoPrepare: "1 · 先放稳手指",
        .gestureDemoReady: "1 · 准备轻点",
        .gestureDemoTouch: "2 · 轻触板面",
        .gestureDemoLift: "3 · 抬起触发",
        .gestureDemoHoldShort: "保持",
        .gestureDemoTapShort: "轻点",
        .gestureDemoLiftShort: "抬起",
        .gestureDemoHint: "蓝色手指保持接触；橙色手指轻触后抬起，无需按下或滑动。",
        .gestureDemoMultiHint: "所有手指同时轻触后抬起，无需按下或滑动。",
        .gestureDemoHoldFinger: "手指平放固定",
        .gestureDemoTapFinger: "单指快速轻敲",
        .gestureDemoSimultaneousTap: "多指同时轻点",
        .gestureDemoTipTapRight2F: "左侧手指平放固定在触控板上，右侧手指快速轻敲一下",
        .gestureDemoTipTapLeft2F: "右侧手指平放固定在触控板上，左侧手指快速轻敲一下",
        .gestureDemoTipTapLeft3F: "右侧两指平放固定在触控板上，最左侧手指快速轻敲一下",
        .gestureDemoTipTapRight3F: "左侧两指平放固定在触控板上，最右侧手指快速轻敲一下",
        .gestureDemoFourFingerTap: "四根手指同时轻拍触控板一次（非滑动）",
        .gestureDemoThreeFingerTap: "三根手指同时轻拍触控板一次（非滑动）",

        .paletteAccessibilityPrompt: "需要辅助功能权限以全局监听按键",
        .paletteAuthorize: "授权",
        .paletteTriggerKeyLabel: "呼出按键:",
        .palettePositionLabel: "面板位置:",
        .paletteCenterScreen: "当前屏幕中央",
        .paletteFollowCursor: "跟随鼠标光标",
        .paletteTriggerSection: "调色板呼出键",
        .paletteCurrentKey: "当前触发键:",
        .paletteRecordButton: "点击录制新按键",
        .paletteRecordingPrompt: "按下任意单键（如 F18）...",
        .paletteShowAtCursor: "在鼠标当前位置弹出",
        .paletteShowAtCursorDesc: "调色板将跟随光标位置显示，而非固定屏幕正中。",
        .paletteMappingsHeader: "已配置映射",
        .paletteSearchPlaceholder: "搜索应用名称或按键...",
        .paletteAddMapping: "添加映射...",
        .paletteAddMappingTitle: "添加快捷映射",
        .paletteEditMappingTitle: "编辑映射",
        .paletteKeyFieldPlaceholder: "按键 (如 c, v, Space, |):",
        .paletteAppNameLabel: "应用名称:",
        .paletteBrowseButton: "浏览...",
        .paletteDisplayNameLabel: "显示名称:",
        .paletteSaveButton: "保存",
        .paletteKeyCol: "按键",
        .paletteActionCol: "执行动作",
        .paletteTargetCol: "目标应用",
        .paletteResetDefaults: "恢复默认映射",
        .paletteActionActivateLast: "切回上一应用",
        .paletteActionActivateApp: "激活应用",
        .paletteHudPrompt: "按下对应单键切换应用"
    ]
}

public func loc(_ key: L10nKey) -> String {
    return LocalizationManager.shared.t(key)
}
