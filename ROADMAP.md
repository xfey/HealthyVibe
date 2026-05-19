# HealthyVibe / Vibe延寿指南 Roadmap

日期：2026-05-19  
目标：把 MVP 实现拆成可执行阶段，优先跑通核心体验，再接 hook、relay 和分发。

## 总体原则

- 先做本地闭环，再做外部集成。
- 先把菜单栏体验做轻，再补充 hook 和小队。
- 任何阶段都不保存 prompt、代码路径、diff、命令内容。
- 每个阶段都应能独立运行和验证。
- 菜单栏 popover 是唯一主要 GUI，不做独立设置窗口。

## Phase 0：项目脚手架与设计约束

状态：已完成。

目标：建立可持续开发的 macOS 项目骨架。

任务：

- [x] 创建 SwiftUI + AppKit macOS 项目。
- [x] 最低系统版本设为 macOS 13 Ventura+。
- [x] 接入 `NSStatusItem + NSPopover`。
- [x] 建立基础 Design System：颜色、间距、按钮、进度条、卡片、分页。
- [x] 建立三页 popover 骨架：今日任务、日历、设置。
- [x] 引入 GRDB.swift 或先预留数据库层接口。
- [x] 建立本地目录结构：
  - [x] `~/Library/Application Support/HealthyVibe/`
  - [x] `events/`
  - [x] `hooks/`
- [x] 配置基本日志和错误展示。

验收：

- [x] App 启动后只出现在菜单栏。
- [x] 点击菜单栏图标打开 340px 左右的小 popover。
- [x] 三个页面可以切换。
- [x] 页面白底、温暖、干净，无复杂 dashboard。

实现记录：

- 使用 Swift Package Manager 管理源码，并通过 `Scripts/build_app_bundle.sh` 生成 `.app`。
- `Resources/Info.plist` 设置 `LSUIElement=true` 和 `LSMinimumSystemVersion=13.0`。
- `MenuBarController` 使用 `NSStatusItem + NSPopover + NSHostingController`。
- `AppPaths` 在启动时创建 Application Support、`events/` 和 `hooks/`。
- 数据库层暂以 `DatabaseService` 协议和 `PlaceholderDatabaseService` 预留，Phase 2 接入 GRDB。
- 已验证 `swift build`、`make bundle` 和 `.app` 启动目录创建。

## Phase 1：本地任务引擎

状态：已完成。

目标：不依赖 hook 和后端，先跑通任务和延寿进度。

任务：

- [x] 实现任务模板模型。
- [x] 实现每日固定任务池生成：
  - [x] 喝一杯水 8 次，每次 +2 分钟。
  - [x] 远眺 20 秒 6 次，每次 +2 分钟。
  - [x] 起身活动 30 秒 3 次，每次 +4 分钟。
  - [x] 肩颈活动 30 秒 3 次，每次 +3 分钟。
  - [x] 手腕活动 15 秒 3 次，每次 +2 分钟。
  - [x] 深呼吸 5 次 3 次，每次 +2 分钟。
- [x] 实现当前任务卡状态：
  - [x] pending。
  - [x] completed。
  - [x] empty / waiting。
  - [x] all completed。
- [x] 实现 `完成`。
- [x] 实现 `换一个`，从剩余任务池随机换一项，不打开选择列表。
- [x] 实现今日 30 分钟进度条。
- [x] 实现延寿后缀文案，例如 `累计延寿 2 小时，可以多看一部电影`。
- [x] 完成后显示完成状态，不立即补发新任务。

验收：

- [x] 用户可以手动生成一张任务卡。
- [x] 点击完成后今日进度增长。
- [x] 完成后不会立刻出现下一张任务。
- [x] 换一个只随机刷新任务，不出现选择列表。
- [x] 某项任务次数用完后不会再被随机到。

实现记录：

- 新增 `HealthyVibeCore` target，任务引擎与 UI 解耦，便于 Phase 2 持久化接入。
- 今日页支持 `模拟下发任务`、`完成` 和 `换一个`。
- `换一个` 只在剩余任务池中随机，不展示任务选择列表。
- 当前阶段数据保存在内存中，关闭 app 后不保留，Phase 2 接入 SQLite。
- 已通过 `swift test` 覆盖任务池、完成、换任务、耗尽任务和跨日期重置规则。
- 已验证 `make bundle`。

## Phase 2：SQLite 本地持久化与日历

目标：让个人历史成为本地主账本。

任务：

- 接入 SQLite + GRDB.swift。
- 建表：
  - `task_templates`
  - `daily_task_plan`
  - `task_deliveries`
  - `task_completions`
  - `daily_stats`
  - `hook_events`
  - `team_profile`
  - `team_snapshots_cache`
  - `app_settings`
- 持久化每日任务池和完成次数。
- 持久化每次任务下发和完成记录。
- 持久化每日统计。
- 实现日历页：
  - 当月日历。
  - 有记录 / 达标状态。
  - 今日、连续、累计。
  - 点击某天展示延寿分钟和完成次数。
- 实现清除本地数据。

验收：

- 关闭再打开 app，今日任务和进度不丢。
- 跨日期后自动生成新任务池。
- 日历可以显示历史完成情况。
- 清除本地数据后恢复初始状态。

## Phase 3：通知与活跃时间

目标：在没有真实 hook 的情况下跑通提醒节奏。

任务：

- 接入 `UNUserNotificationCenter`。
- 实现通知权限申请和状态展示。
- 点击通知后打开菜单栏 popover 的今日任务页。
- 实现 30 分钟任务下发冷却。
- 实现 60 分钟活跃无 hook 兜底提醒。
- 实现 active time tracker：
  - 睡眠不累计。
  - 锁屏不累计。
  - 熄屏不累计。
  - 唤醒 / 解锁后继续累计。
- 提供测试按钮或 debug action 模拟 `prompt_submitted`。

验收：

- 通知权限未开启时，设置页能解释原因。
- 模拟 prompt 后，如果超过冷却时间，收到系统通知。
- 点击通知打开 popover。
- 睡眠或锁屏时间不会触发兜底提醒。
- 完成任务后不会立即补发下一张。

## Phase 4：Hook Bridge 与 Agent 连接

目标：接入 Claude Code / Codex 的真实 `UserPromptSubmit`。

任务：

- 生成隐藏 hook bridge：
  - `~/Library/Application Support/HealthyVibe/hooks/agent-event.sh`
- 实现 event inbox：
  - `~/Library/Application Support/HealthyVibe/events/*.json`
- Hook bridge 只写入最小事件：
  - source。
  - event。
  - receivedAt。
- Hook bridge 丢弃 prompt payload，不保存、不上传、不输出。
- 设置页支持 Claude Code：
  - Connect。
  - Disconnect。
  - Test。
  - 状态检测。
- 设置页支持 Codex：
  - Connect。
  - Disconnect。
  - Test。
  - 状态检测。
- 写入配置前备份原配置。
- 合并 HealthyVibe hook，不覆盖用户已有 hook。
- 断开时只删除 HealthyVibe 自己写入的 hook。

验收：

- Claude Code 提交 prompt 后能写入 event inbox。
- Codex 提交 prompt 后能写入 event inbox。
- App 未运行时，hook bridge 能写入事件并尝试启动 app。
- App 启动后能处理积压事件。
- 用户已有 hook 不被覆盖。
- 断开连接后用户配置恢复到没有 HealthyVibe hook 的状态。

## Phase 5：小队 Relay

目标：提供轻量小队当天排行榜。

任务：

- 创建 Cloudflare Workers + D1 项目。
- 实现最小 API：
  - `POST /v1/team/snapshot`
  - `GET /v1/team/ranking?team=...&date=...`
- 本地生成匿名 member id。
- 创建小队时生成高熵 team code。
- 加入小队时保存 team code。
- 完成任务后同步当天 snapshot。
- 菜单栏今日任务页显示 `小队排名 3/10`。
- 设置页显示当日完整小队排行榜。
- 服务端保留当天完整成员结果。
- 服务端保留最近 48-72 小时数据作为容错。

验收：

- 无账号系统也能创建 / 加入小队。
- 多台机器使用同一 team code 能看到同一排行榜。
- 菜单栏只显示最简排名。
- 个人历史仍完全依赖本地数据库。
- Relay 不保存 prompt、代码、diff、路径、hook 原始 payload。

## Phase 6：安装与分发

目标：让程序员能通过 CLI 风格安装，但日常使用仍是 GUI。

任务：

- 配置 app signing。
- 配置 notarization。
- 打包 app。
- 准备 Homebrew Cask。
- 验证：
  - `brew install --cask healthyvibe`
  - 安装后能启动菜单栏 app。
  - App 能创建 Application Support 目录。
  - Hook bridge 能正常生成。
- 可选准备透明安装脚本：
  - `curl -fsSL https://healthyvibe.dev/install | sh`

验收：

- 新机器安装后能打开菜单栏 app。
- 不要求用户手动拖拽 DMG。
- 安装后配置全部在 GUI 中完成。
- 卸载后不会留下无法解释的 hook 配置。

## Phase 7：体验打磨与发布准备

目标：发布前减少粗糙感和误触发。

任务：

- 文案打磨：
  - 通知文案。
  - 延寿后缀文案。
  - 空态文案。
  - 隐私说明。
- 视觉打磨：
  - 白底卡片。
  - 温暖强调色。
  - 进度条。
  - 日历状态点。
- 状态打磨：
  - 全部任务完成。
  - 今日目标达成。
  - 未开启通知。
  - 未连接 agent。
  - 无小队。
  - relay 不可用。
- 增加最小可用 QA 清单。
- 更新 README。

验收：

- 一个新用户能在 5 分钟内完成安装、打开、连接 agent、收到测试提醒。
- 菜单栏页面无明显拥挤和文字溢出。
- 系统通知不会高频打扰。
- 隐私边界在设置页能清楚说明。

## 建议首轮实现范围

首轮开发建议只做到 Phase 0 到 Phase 3：

- 菜单栏 popover。
- 三页结构。
- 本地任务池。
- 本地 SQLite。
- 日历。
- 系统通知。
- 30 分钟冷却。
- 60 分钟活跃兜底。
- 模拟 `prompt_submitted`。

暂不接真实 Claude/Codex hook，暂不接 relay，暂不做 Homebrew 分发。

这样可以先验证核心体验：用户是否愿意在 agent 等待期间完成一张任务卡。
