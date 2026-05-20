# HealthyVibe Development

日期：2026-05-19

## 本地构建

项目当前使用 Swift Package Manager 管理源码，并通过脚本生成 macOS `.app` bundle。

```bash
make build
make bundle
make run
```

生成的应用位于：

```text
.build/HealthyVibe.app
```

## Phase 0 验证

已验证：

```bash
swift build
make bundle
open -n .build/HealthyVibe.app
```

启动后会创建：

```text
~/Library/Application Support/HealthyVibe/
~/Library/Application Support/HealthyVibe/events/
~/Library/Application Support/HealthyVibe/hooks/
```

## Phase 1 验证

已验证：

```bash
swift test
make bundle
```

Phase 1 的任务引擎目前只保存内存状态，Phase 2 会把每日任务池、完成记录和日历统计接入 SQLite。

## Phase 2 验证

已验证：

```bash
swift test
make bundle
open -n .build/HealthyVibe.app
```

当前 SQLite 位置：

```text
~/Library/Application Support/HealthyVibe/HealthyVibe.sqlite
```

GRDB 当前解析版本记录在 `Package.resolved`：`7.10.0`。

## Phase 3 验证

已验证：

```bash
swift test
make bundle
open -n .build/HealthyVibe.app
```

当前通知和活跃时间实现：

- `NotificationService`：通知权限、系统通知、点击通知打开今日任务页。
- `ActiveTimeTracker`：监听睡眠、屏幕睡眠、会话失活/恢复，兜底计时只累计活跃时间。
- `ActiveTimeAccumulator`：纯逻辑计时器，已单测覆盖。
- 设置页提供 `模拟 prompt_submitted` debug action。

## Phase 4 验证

已验证：

```bash
swift test
make bundle
open -n .build/HealthyVibe.app
```

当前 hook bridge：

```text
~/Library/Application Support/HealthyVibe/hooks/agent-event.sh
~/Library/Application Support/HealthyVibe/events/*.json
```

Agent 配置路径：

```text
Claude Code: ~/.claude/settings.json
Codex:      ~/.codex/hooks.json
```

`agent-event.sh` 会丢弃 stdin，仅写入 `source`、`event`、`receivedAt`。

## Phase 5 验证

已验证：

```bash
swift test
make bundle
cd relay && npm run typecheck
cd relay && npm test
```

当前小队 Relay：

```text
relay/src/index.ts
relay/migrations/0001_team_snapshots.sql
```

Relay API：

```text
POST /v1/team/snapshot
GET  /v1/team/ranking?team=<team_code_hash>&date=<YYYY-MM-DD>
```

Swift 客户端：

```text
Sources/HealthyVibeTeam/
```

小队数据边界：

- 本地保存小队码和匿名 member id，便于用户查看小队码和稳定识别自己。
- 上传 Relay 时只传 `team_code_hash`、`member_id_hash`、可选 display name、日期、延寿分钟和完成次数。
- Relay 不接收、不保存 prompt、代码、diff、路径或 hook 原始 payload。
- Relay 保留最近 3 天数据，个人长期历史仍由本地 SQLite 保存。

## Phase 6 验证

已验证：

```bash
make package
ruby -c dist/healthyvibe.rb
```

并使用临时 Homebrew tap、临时 `HOME` 和临时 `--appdir` 验证过 cask 安装/卸载：

```bash
brew install --cask healthyvibe/local/healthyvibe
brew uninstall --cask healthyvibe/local/healthyvibe
```

透明安装脚本本地验证：

```bash
HEALTHYVIBE_ZIP_PATH="$PWD/dist/HealthyVibe-0.1.0.zip" \
HEALTHYVIBE_INSTALL_DIR="$(mktemp -d)/apps" \
HEALTHYVIBE_SKIP_OPEN=1 \
./Scripts/install.sh
```

当前发布脚本：

- `Scripts/package_release.sh`：release build、可选签名、可选 notarization、zip、sha256、cask。
- `Scripts/generate_homebrew_cask.sh`：根据 zip 生成 Homebrew Cask。
- `Scripts/install.sh`：透明安装脚本，支持 URL 或本地 zip。

发布凭据：

- `HEALTHYVIBE_SIGN_IDENTITY`：Developer ID Application 证书名称。
- `HEALTHYVIBE_NOTARY_PROFILE`：`xcrun notarytool store-credentials` 保存的 keychain profile。
- `HEALTHYVIBE_RELEASE_URL`：生成线上 cask 时写入的 release artifact URL。

已验证真实 Apple notarization：使用 Developer ID Application 证书和 `healthyvibe-notary` keychain profile 生成的 release app 可通过 notarization、staple 和 Gatekeeper 验证。

## Phase 7 验证

已验证：

```bash
swift test
make bundle
cd relay && npm run typecheck
cd relay && npm test
```

Phase 7 调整：

- 今日页移除开发期手动下发入口。
- 今日页增加未连接 Agent 入口和目标达成标签。
- 通知状态、Agent 状态和设置页操作中文化。
- 设置页隐私说明覆盖 hook payload、本地历史和 Relay 上传边界。
- 日历累计文案允许两行展示，避免小 popover 内长文案溢出。
- 新增 `README.md` 和 `QA.md`。

## 当前架构

```text
Sources/HealthyVibe/
  App/              AppDelegate、菜单栏控制器、全局状态
  App/              通知服务、活跃时间 tracker
  Design/           颜色、间距、按钮、进度条等基础设计系统
  Infrastructure/   本地目录、日志、数据库接口预留
  Models/           轻量 UI/domain model
  Views/            Popover 三页视图
Sources/HealthyVibeCore/
  ActiveTime        活跃时间累计规则
  TaskEngine        本地任务池、随机下发、完成状态
  HistoryModels     日历摘要和历史总览模型
Sources/HealthyVibeAgents/
  HookBridge        bridge script、event inbox、Agent 配置合并
Sources/HealthyVibeStorage/
  AppDatabase       GRDB migrations、任务状态持久化、日历统计
Sources/HealthyVibeTeam/
  TeamIdentity      小队码、匿名 member id、hash
  TeamRelayClient   Relay API 客户端
  TeamModels        小队 profile、snapshot、ranking
relay/
  src/              Cloudflare Worker API、校验、排行逻辑
  migrations/       D1 表结构
Tests/HealthyVibeCoreTests/
  TaskEngineTests   Phase 1 核心规则测试
  ActiveTimeTests   Phase 3 活跃时间规则测试
Tests/HealthyVibeStorageTests/
  AppDatabaseTests  Phase 2 持久化规则测试
Tests/HealthyVibeAgentsTests/
  HookBridgeTests   Phase 4 hook bridge 和配置合并测试
Tests/HealthyVibeTeamTests/
  TeamTests         Phase 5 小队身份和 Relay client 测试
Resources/
  Info.plist        app bundle 元信息，包含 LSUIElement
README.md           项目说明和本地开发入口
QA.md               MVP 发布前 QA 清单
Scripts/
  build_app_bundle.sh
  package_release.sh
  generate_homebrew_cask.sh
  install.sh
DISTRIBUTION.md     签名、公证、Homebrew Cask 和安装脚本说明
```

## Phase 0 范围

Phase 0 只建立菜单栏应用骨架：

- `NSStatusItem + NSPopover`
- SwiftUI 三页结构
- 白底、温暖、克制的小面板视觉
- `~/Library/Application Support/HealthyVibe/`
- `events/`
- `hooks/`
- 数据库层接口预留

任务引擎、SQLite、通知、hook bridge 和 relay 按 roadmap 后续阶段实现。
