### Deck v1.1.2 🚀

Release build for **Deck** macOS native efficiency platform.

---

### 🌟 What's New in v1.1.2 (本次更新内容)

#### 1. 🖐️ 触控板手势算法与灵敏度全面升级 (Trackpad Gestures Recognition Optimization)
- **放宽轻敲判定窗口**：由原来苛刻的 `< 0.28s` 优化为 `0.04s ~ 0.38s`（四指轻点支持到 `0.42s`），位移容差提升至 `0.08`，更符合真实人手在触控板上的自然敲击习惯，告别手势难触发问题。
- **防抖冷却缩短至 160ms**：支持连续快速双指敲击连关多个网页标签（`⌘ W`）或切换桌面（`^ →`），操作流畅不吞键。
- **TipTap 3F 双向支持**：同时支持“2指按住 + 1指轻敲”与“1指按住 + 2指轻敲”。
- **4指轻点精准防误触**：采用接触会话追踪最大指尖数与滑动位移，彻底杜绝与系统 4指滑动切换桌面（Mission Control）发生冲突误触。

#### 2. 🔗 浏览器后台打开标签失效修复 (Browser Background Tab Opening Fix)
- 补齐底层 CoreGraphics `kCGMouseEventClickState = 1` 与精确全局光标坐标，并合成 Command 按键状态，彻底解决 Chrome、Safari、Arc、Firefox、Edge 等浏览器此前无法识别后台打开新标签的问题。

#### 3. 📳 新增 Taptic Engine 触控板触觉反馈 (Haptic Feedback)
- 手势成功触发时，通过 `NSHapticFeedbackManager` 驱动触控板发出清脆的物理轻微震动反馈，给手指即时的成功确认感。
- 详情设置页提供“触控板触觉反馈”开关控制（默认开启）。

#### 4. 🎨 界面视觉与排版优化 (UI Layout & Naming Polish)
- **消除文字截断**：去除不自然的 `"Fix"` 英文后缀，调宽左侧手势栏，彻底消除原截断为 `"TipTap Right (3 Fingers Fi..."` 的排版问题。
- **视觉层级提升**：列表行展示“手势名 + 功能说明 + 右侧独立键帽徽标胶囊”，手势触发时增加动态微光动效。
- **常用预设扩展**：预设按钮新增 `⌘ T`（新建标签）、`⌘ ⇧ [`（上一标签）、`⌘ ⇧ ]`（下一标签）。

#### 5. 🧪 全功能单元测试套件覆盖 (Comprehensive Unit Test Suite)
- 新增 22 项自动化单元测试，覆盖触控引擎、调色板按键匹配、Hosts 环境分组互斥逻辑、中英文本地化字典覆盖率，通过率 100%。

---

#### 📥 Installation
1. Download `Deck-macOS.zip` below.
2. Unzip to obtain `Deck.app`.
3. Drag `Deck.app` into your `/Applications` folder.
4. If macOS displays a Gatekeeper prompt on first launch, right-click (or Control-click) `Deck.app` and choose **Open**, or run:
   ```bash
   xattr -cr /Applications/Deck.app
   ```
