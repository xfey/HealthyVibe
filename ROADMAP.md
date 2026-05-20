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
- [x] 建立 popover 骨架：今日任务、日历、设置、关于。
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

状态：已完成。

目标：让个人历史成为本地主账本。

任务：

- [x] 接入 SQLite + GRDB.swift。
- [x] 建表：
  - [x] `task_templates`
  - [x] `daily_task_plan`
  - [x] `task_deliveries`
  - [x] `task_completions`
  - [x] `daily_stats`
  - [x] `hook_events`
  - [x] `team_profile`
  - [x] `team_snapshots_cache`
  - [x] `app_settings`
- [x] 持久化每日任务池和完成次数。
- [x] 持久化每次任务下发和完成记录。
- [x] 持久化每日统计。
- [x] 实现日历页：
  - [x] 当月日历。
  - [x] 有记录 / 达标状态。
  - [x] 今日、连续、累计。
  - [x] 点击某天展示延寿分钟和完成次数。
- [x] 实现清除本地数据。

验收：

- [x] 关闭再打开 app，今日任务和进度不丢。
- [x] 跨日期后自动生成新任务池。
- [x] 日历可以显示历史完成情况。
- [x] 清除本地数据后恢复初始状态。

实现记录：

- 新增 `HealthyVibeStorage` target，使用 GRDB 7.10.0。
- SQLite 文件路径为 `~/Library/Application Support/HealthyVibe/HealthyVibe.sqlite`。
- 存储层负责 migrations、默认任务模板、每日计划、下发记录、完成记录、日报统计、月历摘要和清除数据。
- 日历页显示当月记录点，达到 30 分钟目标时使用深色点；点击日期展示当日延寿分钟和完成次数。
- 设置页提供二次确认式 `清除本地数据`。
- 已通过 `swift test` 覆盖建表、跨重启恢复、跨日期新计划、月历摘要和清除数据。
- 已验证 `make bundle` 和真实 app 启动后创建 SQLite。

## Phase 3：通知与活跃时间

状态：已完成。

目标：在没有真实 hook 的情况下跑通提醒节奏。

任务：

- [x] 接入 `UNUserNotificationCenter`。
- [x] 实现通知权限申请和状态展示。
- [x] 点击通知后打开菜单栏 popover 的今日任务页。
- [x] 实现完成任务后的 30 分钟冷却。
- [x] 实现通知 action：已完成、30 分钟后提醒、两小时后提醒。
- [x] 实现 60 分钟活跃无 hook 兜底提醒。
- [x] 实现 active time tracker：
  - [x] 睡眠不累计。
  - [x] 锁屏不累计。
  - [x] 熄屏不累计。
  - [x] 唤醒 / 解锁后继续累计。
- [x] 提供测试按钮或 debug action 模拟 `prompt_submitted`。

验收：

- [x] 通知权限未开启时，设置页能解释原因。
- [x] 模拟 prompt 后，如果超过冷却时间，收到系统通知。
- [x] 点击通知打开 popover。
- [x] 睡眠或锁屏时间不会触发兜底提醒。
- [x] 完成任务后不会立即补发下一张。

实现记录：

- 新增 `NotificationService`，使用系统通知，不做自定义弹窗和通知按钮。
- 设置页展示通知权限状态，支持申请权限、打开系统设置、模拟 `prompt_submitted`。
- 模拟 prompt 会记录最小 hook event、按完成冷却和稍后提醒状态下发任务，并在权限允许时发送系统通知。
- 通知内的 `已完成` 会直接完成当前任务并启动 30 分钟冷却；`30分钟后提醒` 和 `两小时后提醒` 会安排延迟系统通知。
- 点击通知通过 `UNUserNotificationCenterDelegate` 打开菜单栏 popover 的今日任务页。
- 新增 `ActiveTimeTracker`，监听睡眠、屏幕睡眠、会话失活，以及唤醒、屏幕唤醒、会话恢复。
- 新增 `ActiveTimeAccumulator` 单测，确保非活跃时间不累计，hook event 会重置 60 分钟兜底计时。
- 已通过 `swift test` 和 `make bundle`，并验证真实 app 可启动。

## Phase 4：Hook Bridge 与 Agent 连接

状态：已完成。

目标：接入 Claude Code / Codex 的真实 `UserPromptSubmit`。

任务：

- [x] 生成隐藏 hook bridge：
  - [x] `~/Library/Application Support/HealthyVibe/hooks/agent-event.sh`
- [x] 实现 event inbox：
  - [x] `~/Library/Application Support/HealthyVibe/events/*.json`
- [x] Hook bridge 只写入最小事件：
  - [x] source。
  - [x] event。
  - [x] receivedAt。
- [x] Hook bridge 丢弃 prompt payload，不保存、不上传、不输出。
- [x] 设置页支持 Claude Code：
  - [x] Connect。
  - [x] Disconnect。
  - [x] Test。
  - [x] 状态检测。
- [x] 设置页支持 Codex：
  - [x] Connect。
  - [x] Disconnect。
  - [x] Test。
  - [x] 状态检测。
- [x] 写入配置前备份原配置。
- [x] 合并 HealthyVibe hook，不覆盖用户已有 hook。
- [x] 断开时只删除 HealthyVibe 自己写入的 hook。

验收：

- [x] Claude Code 提交 prompt 后能写入 event inbox。
- [x] Codex 提交 prompt 后能写入 event inbox。
- [x] App 未运行时，hook bridge 能写入事件并尝试启动 app。
- [x] App 启动后能处理积压事件。
- [x] 用户已有 hook 不被覆盖。
- [x] 断开连接后用户配置恢复到没有 HealthyVibe hook 的状态。

实现记录：

- 新增 `HealthyVibeAgents` target，负责 hook bridge、event inbox、Claude/Codex 配置合并和状态检测。
- Claude Code 写入用户级 `~/.claude/settings.json` 的 `hooks.UserPromptSubmit`。
- Codex 写入用户级 `~/.codex/hooks.json` 的 `hooks.UserPromptSubmit`。
- Hook command 使用 shell form 调用本地 `agent-event.sh`，兼容 Claude/Codex 当前 command hook 格式。
- `agent-event.sh` 会读取 stdin 后立即丢弃，只写入 `source`、`event`、`receivedAt`，并尝试 `open -gj -a HealthyVibe`。
- App 启动时和运行期间轮询 `events/*.json`，处理后删除，解析失败改名为 `.failed`。
- 已通过 `swift test` 覆盖配置合并、备份、断开、无效 JSON 保护、bridge 写入最小事件和 prompt 丢弃。
- 已验证 `make bundle`，真实 app 启动后会生成可执行 bridge script。

## Phase 5：小队 Relay

状态：已完成，生产 relay 已上线。

目标：提供轻量小队当天排行榜。

任务：

- [x] 创建 Cloudflare Workers + D1 项目。
- [x] 实现最小 API：
  - [x] `POST /v1/team/snapshot`
  - [x] `GET /v1/team/ranking?team=...&date=...`
- [x] 本地生成匿名 member id。
- [x] 创建小队时生成高熵 team code。
- [x] 加入小队时保存 team code。
- [x] 完成任务后同步当天 snapshot。
- [x] 菜单栏今日任务页显示 `小队排名 3/10`。
- [x] 设置页显示当日完整小队排行榜。
- [x] 服务端保留当天完整成员结果。
- [x] 服务端保留最近 48-72 小时数据作为容错。

验收：

- [x] 无账号系统也能创建 / 加入小队。
- [x] 多台机器使用同一 team code 能看到同一排行榜。
- [x] 菜单栏只显示最简排名。
- [x] 个人历史仍完全依赖本地数据库。
- [x] Relay 不保存 prompt、代码、diff、路径、hook 原始 payload。

实现记录：

- 新增 `relay/`，使用 Cloudflare Workers + D1，提供 snapshot upsert 和当日 ranking 查询。
- 生产 relay 已由服务器侧以 Node.js + SQLite 实现并上线，地址为 `https://healthyvibe.owlib.ai`。
- 服务通过 nginx 反向代理到 `127.0.0.1:8787`，systemd 服务名为 `healthyvibe-relay`。
- Relay 只保存 `team_code_hash`、`member_id_hash`、可选 display name、日期、延寿分钟、完成次数和更新时间。
- Relay 每次 snapshot 写入时清理 3 天前数据，满足 48-72 小时容错。
- 新增 `HealthyVibeTeam` target，负责 team code、匿名 member id hash、Relay client 和 ranking model。
- 小队码本地保存明文用于用户复制/查看，上传时只传 SHA-256 hash。
- MVP 没有昵称设置项，因此默认不上传 macOS 用户名。
- `team_profile` 增加本地 `team_code` 和 `member_id`，`team_snapshots_cache` 增加 `rank`，个人历史仍由 SQLite 本地账本负责。
- 今日页仅在已加入小队且有排名缓存时显示一行简洁排名。
- 设置页支持创建小队、加入小队、同步、退出，并展示当日榜单。
- 已通过 `swift test`、`npm run typecheck`、`npm test` 和 `make bundle`。

## Phase 6：安装与分发

状态：已完成（本地打包、Developer ID 签名、notarization 和安装链路已验证）。

目标：让程序员能通过 CLI 风格安装，但日常使用仍是 GUI。

任务：

- [x] 配置 app signing。
- [x] 配置 notarization。
- [x] 打包 app。
- [x] 准备 Homebrew Cask。
- [x] 验证：
  - [x] `brew install --cask healthyvibe` 等价链路（本地临时 tap：`healthyvibe/local/healthyvibe`）。
  - [x] 安装后 app bundle 存在于目标 appdir。
  - [x] App 能创建 Application Support 目录。
  - [x] Hook bridge 能正常生成。
- [x] 可选准备透明安装脚本：
  - [x] `curl -fsSL https://healthyvibe.dev/install | sh`

验收：

- [x] 新机器安装后能打开菜单栏 app。
- [x] 不要求用户手动拖拽 DMG。
- [x] 安装后配置全部在 GUI 中完成。
- [x] 卸载后不会留下无法解释的 hook 配置。

实现记录：

- 新增 `Scripts/package_release.sh`，生成 release `.app`、zip、sha256 和 cask。
- 新增 `Scripts/generate_homebrew_cask.sh`，根据 zip 自动计算 SHA-256 并生成 `healthyvibe.rb`。
- 新增 `Scripts/install.sh`，支持 `HEALTHYVIBE_ZIP_URL` 在线安装或 `HEALTHYVIBE_ZIP_PATH` 本地安装。
- `make package` 作为统一打包入口。
- 签名通过 `HEALTHYVIBE_SIGN_IDENTITY` 启用，使用 hardened runtime 和 timestamp。
- Notarization 通过 `HEALTHYVIBE_NOTARY_PROFILE` 启用，使用 `xcrun notarytool` 和 `stapler`。
- Homebrew Cask uninstall preflight 会移除 HealthyVibe 自己写入的 Claude Code / Codex hook handler，不删除用户其他 hook。
- 已用临时 Homebrew tap、临时 `HOME` 和临时 `--appdir` 验证 cask 安装/卸载链路。
- 已验证透明安装脚本可从本地 zip 安装到指定目录。
- 已使用 Developer ID Application 证书和 `healthyvibe-notary` keychain profile 完成真实 Apple notarization；release app 已通过 staple 和 Gatekeeper 验证。

## Phase 7：体验打磨与发布准备

状态：已完成。

目标：发布前减少粗糙感和误触发。

任务：

- [x] 文案打磨：
  - [x] 通知文案。
  - [x] 延寿后缀文案。
  - [x] 空态文案。
  - [x] 隐私说明。
- [x] 视觉打磨：
  - [x] 白底卡片。
  - [x] 温暖强调色。
  - [x] 进度条。
  - [x] 日历状态点。
- [x] 状态打磨：
  - [x] 全部任务完成。
  - [x] 今日目标达成。
  - [x] 未开启通知。
  - [x] 未连接 agent。
  - [x] 无小队。
  - [x] relay 不可用。
- [x] 增加最小可用 QA 清单。
- [x] 更新 README。

验收：

- [x] 一个新用户能在 5 分钟内完成安装、打开、连接 agent、收到提醒。
- [x] 菜单栏页面无明显拥挤和文字溢出。
- [x] 系统通知不会高频打扰。
- [x] 隐私边界在设置页能清楚说明。

实现记录：

- 今日页移除开发期手动下发入口，保留真实等待、完成、全部完成、目标达成状态。
- 未连接 Agent 时，今日页提供进入设置页的明确入口。
- 设置页状态文案统一中文化，并补充 hook 隐私边界说明。
- 进度条在达成目标后切换为温暖强调色，并显示 `目标达成` 标签。
- 日历累计文案允许两行展示，降低小 popover 内文字溢出风险。
- 新增 `README.md`，说明产品、开发、打包、Relay 和隐私边界。
- 新增 `QA.md`，覆盖新用户路径、页面状态、隐私卸载和分发验证。
- 已通过 `swift test`、`make bundle`、`npm run typecheck` 和 `npm test`。

## 历史备注：首轮实现范围建议

早期讨论中，首轮开发曾建议只做到 Phase 0 到 Phase 3：

- 菜单栏 popover。
- 菜单栏分页结构。
- 本地任务池。
- 本地 SQLite。
- 日历。
- 系统通知。
- 30 分钟冷却。
- 60 分钟活跃兜底。
- 模拟 `prompt_submitted`。

当时暂不接真实 Claude/Codex hook，暂不接 relay，暂不做 Homebrew 分发。

当前 roadmap 已推进到 Phase 7，保留此段仅用于记录产品收敛过程。
