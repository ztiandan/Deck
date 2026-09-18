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
    case navActiveHosts
    case navQuickSwitch
    case navPaletteMappings
    case navTouchGestures
    case navTrackpadGestures
    case navPreferences
    case navGeneralSettings
    case serviceRunning

    // Tab Titles
    case tabEditHosts
    case tabViewHosts
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
        .navActiveHosts: "Active Hosts",
        .navQuickSwitch: "QUICK SWITCH",
        .navPaletteMappings: "Palette Mappings",
        .navTouchGestures: "TOUCH GESTURES",
        .navTrackpadGestures: "Trackpad Gestures",
        .navPreferences: "PREFERENCES",
        .navGeneralSettings: "General Settings",
        .serviceRunning: "Service Running",

        .tabEditHosts: "Edit Hosts Profiles",
        .tabViewHosts: "Active Hosts Overview",
        .tabAppSwitcher: "App Switcher & Palette",
        .tabTrackpad: "Trackpad Gestures",
        .tabGeneral: "General Preferences",

        .menuTooltip: "Deck: Trackpad Gestures / Hosts / App Switcher",
        .menuEditHosts: "Edit Hosts...",
        .menuViewHosts: "View Hosts...",
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
        .hostsActiveStatus: "Active",
        .hostsDisabledStatus: "Disabled",
        .hostsUnsaved: "● Unsaved",
        .hostsRevert: "Revert",
        .hostsApply: "Apply",
        .hostsSelectPrompt: "Select a Hosts profile on the left to edit",
        .hostsApplySuccess: "✓ Successfully applied to /etc/hosts",
        .hostsApplyFailed: "⚠️ Requires authorization or failed",
        .hostsProfileName: "Profile Name:",
        .hostsFolder: "Folder:",
        .hostsFolderTopLevel: "None (Top Level)",
        .hostsNewProfileTitle: "New Hosts Profile",
        .hostsNewFolderTitle: "New Folder",
        .hostsFolderName: "Folder Name:",
        .hostsCancel: "Cancel",
        .hostsCreate: "Create",
        .hostsSystemActiveTitle: "Active /etc/hosts",
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
        .prefPasswordlessActiveDesc: "Hosts modifications write directly without password prompts.",
        .prefPasswordlessInactiveDesc: "Enable to update hosts instantly without entering admin passwords.",
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
        .navActiveHosts: "生效 Hosts",
        .navQuickSwitch: "快捷切换",
        .navPaletteMappings: "快捷映射",
        .navTouchGestures: "触控手势",
        .navTrackpadGestures: "触控板手势",
        .navPreferences: "偏好",
        .navGeneralSettings: "通用设置",
        .serviceRunning: "服务运行中",

        .tabEditHosts: "编辑 Hosts 方案",
        .tabViewHosts: "生效 Hosts 全览",
        .tabAppSwitcher: "应用切换与调色板",
        .tabTrackpad: "触控板手势增强",
        .tabGeneral: "通用偏好设置",

        .menuTooltip: "Deck: 触控手势 / Hosts / 应用切换",
        .menuEditHosts: "编辑 Hosts...",
        .menuViewHosts: "查看生效 Hosts...",
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
        .hostsActiveStatus: "生效中",
        .hostsDisabledStatus: "未启用",
        .hostsUnsaved: "● 未保存",
        .hostsRevert: "撤回",
        .hostsApply: "应用生效",
        .hostsSelectPrompt: "请从左侧选择一个 Hosts 方案进行编辑",
        .hostsApplySuccess: "✓ 已成功应用至系统 /etc/hosts",
        .hostsApplyFailed: "⚠️ 应用需授权或失败，请检查",
        .hostsProfileName: "方案名称:",
        .hostsFolder: "所属分组:",
        .hostsFolderTopLevel: "无分组 (顶层)",
        .hostsNewProfileTitle: "新建 Hosts 方案",
        .hostsNewFolderTitle: "新建分组文件夹",
        .hostsFolderName: "分组名称:",
        .hostsCancel: "取消",
        .hostsCreate: "创建",
        .hostsSystemActiveTitle: "系统生效 Hosts",
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
        .prefPasswordlessActiveDesc: "修改 Hosts 无需弹窗输入密码，即时写入生效。",
        .prefPasswordlessInactiveDesc: "点击开启后，修改 Hosts 无需重复输入系统密码。",
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
