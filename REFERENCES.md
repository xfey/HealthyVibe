# HealthyVibe Reference Notes

日期：2026-05-19  
用途：记录产品、设计、技术实现相关参考资料，供后续实现和讨论使用。

## 1. 设计参考

### 1.1 design-md / awesome-design-md

- VoltAgent awesome-design-md: https://github.com/VoltAgent/awesome-design-md
- Google DESIGN.md spec: https://github.com/google-labs-code/design.md

参考价值：

- 用 Markdown + YAML 结构化描述视觉设计，便于 AI agent 和工程实现共同理解。
- 适合后续为 HealthyVibe 创建 `DESIGN.md`，固化颜色、字体、组件、布局、文案风格和交互禁忌。
- 不建议直接复制某个品牌模板，应吸收风格原则后做自己的小工具设计系统。

### 1.2 Apple / macOS

- Apple design-md: https://getdesign.md/apple/design-md
- Apple Human Interface Guidelines: https://developer.apple.com/design/human-interface-guidelines/

对 HealthyVibe 的启发：

- 白底、留白、清晰层级。
- 系统通知、菜单栏、popover、分页、小设置项应尽量符合 macOS 用户习惯。
- MVP 应避免营销页式 UI、复杂 dashboard 和过重视觉装饰。

### 1.3 Linear

- Linear design-md: https://getdesign.md/linear.app/design-md

对 HealthyVibe 的启发：

- 安静、克制、精确的工具感。
- 适合程序员工具，不应使用过多插画、夸张渐变或复杂动效。
- 信息密度可以高一点，但必须保持可扫读。

### 1.4 Claude

- Claude design-md: https://getdesign.md/claude/design-md

对 HealthyVibe 的启发：

- 温暖、轻松、有一点人味。
- 可以承载「Vibe延寿指南」的幽默文案，但不能吵。
- 适合用温暖的强调色，而不是高饱和健康 app 风格。

### 1.5 Raycast

- Raycast: https://www.raycast.com/

对 HealthyVibe 的启发：

- 小面板、高效率、工程师友好。
- 菜单栏小浮窗应一眼完成动作，不承载复杂 dashboard。

## 2. Hook 与 Agent 集成

### 2.1 Claude Code Hooks

- Claude Code hooks: https://code.claude.com/docs/en/hooks
- Claude Code plugins: https://code.claude.com/docs/en/plugins

当前方案：

- MVP 优先使用 `UserPromptSubmit`，即用户提交 prompt 后触发。
- 菜单栏设置页一键写入用户级配置。
- 不做用户可感知的 Claude 插件产品。
- 不通过插件 marketplace 作为第一版主路径。

实现注意：

- `UserPromptSubmit` 可能包含用户 prompt。HealthyVibe hook bridge 必须读取后丢弃，不保存、不上传、不输出。
- Claude Code `UserPromptSubmit` 会在 input 中提供 `prompt` 字段；hook 返回 stdout 可能影响上下文，因此 HealthyVibe bridge 不输出任何内容。
- 用户级配置路径为 `~/.claude/settings.json`，配置形态为 `hooks.UserPromptSubmit[].hooks[]`。
- 写入配置前必须备份。
- 断开连接时只删除 HealthyVibe 自己写入的 hook，不影响用户已有 hook。

### 2.2 Codex Hooks

- Codex hooks: https://developers.openai.com/codex/hooks
- Codex plugins: https://developers.openai.com/codex/plugins
- Codex build plugins: https://developers.openai.com/codex/plugins/build

当前方案：

- MVP 优先使用 command hook。
- 目标事件为 `UserPromptSubmit`。
- 菜单栏设置页一键写入用户级 `~/.codex/hooks.json`。
- Codex plugin hooks 当前不作为 MVP 的主分发依赖。

实现注意：

- Codex hooks 当前更适合调用本地 command/script。
- Codex `UserPromptSubmit` 会在 input 中提供 `prompt` 字段；hook 返回 stdout 可能加入上下文，因此 HealthyVibe bridge 不输出任何内容。
- 用户级 hook 配置使用 `~/.codex/hooks.json`，配置形态为 `hooks.UserPromptSubmit[].hooks[]`。
- Hook bridge 要快速退出，避免影响 agent 开始工作。
- MVP 不读取命令内容、文件路径、diff、prompt 等敏感信息。

### 2.3 Hook Bridge

推荐路径：

```text
~/Library/Application Support/HealthyVibe/hooks/agent-event.sh
```

推荐 event inbox：

```text
~/Library/Application Support/HealthyVibe/events/*.json
```

最小事件：

```json
{
  "source": "claude",
  "event": "prompt_submitted",
  "receivedAt": "2026-05-19T10:00:00Z"
}
```

原则：

- 用户不可见。
- 菜单栏设置页负责安装和配置。
- 不需要本地端口。
- App 未运行时也能先写入事件，再尝试启动 app。
- 不保存原始 hook payload。

## 3. 安装与分发

### 3.1 Homebrew Cask

- Homebrew Cask: https://docs.brew.sh/Cask-Cookbook

当前方案：

```bash
brew install --cask healthyvibe
```

产品原因：

- 降低程序员对“下载 DMG、拖进 Applications”的心理阻力。
- 安装后配置和使用仍然回到 GUI。
- CLI 安装不代表 CLI 产品。

实现注意：

- App 需要签名和 notarization。
- 安装后要确保菜单栏 app 能被用户顺利打开。
- 可选提供透明安装脚本，但 Homebrew 应作为推荐路径。
- Homebrew 5.1 起本地 cask 验证需要放入 tap；直接传任意路径会被拒绝。
- Cask 由 `Scripts/generate_homebrew_cask.sh` 根据 release zip 自动生成 sha256。
- Cask uninstall preflight 会清理 HealthyVibe 自己写入的 Claude Code / Codex hook handler。

### 3.2 macOS App Distribution

- Notarizing macOS software: https://developer.apple.com/documentation/security/notarizing_macos_software_before_distribution
- Developer ID Application signing: https://developer.apple.com/developer-id/

后续需要确认：

- 是否进入 Mac App Store。
- 是否只做直接分发 + Homebrew Cask。
- 开机启动和通知权限在非 App Store 分发下的具体实现细节。

实现记录：

- `Scripts/package_release.sh` 支持 `HEALTHYVIBE_SIGN_IDENTITY`。
- `Scripts/package_release.sh` 支持 `HEALTHYVIBE_NOTARY_PROFILE`，使用 `xcrun notarytool` 和 `xcrun stapler`。
- `Scripts/install.sh` 支持 `HEALTHYVIBE_ZIP_URL` 和 `HEALTHYVIBE_ZIP_PATH`。

## 4. 本地数据

当前方案：SQLite + GRDB.swift。

实现记录：

- Swift Package 依赖：`https://github.com/groue/GRDB.swift.git`
- 当前解析版本：`7.10.0`

本地保存：

- 任务模板。
- 每日固定任务池。
- 每次任务下发记录。
- 每次任务完成记录。
- 每日延寿总量。
- 连续完成天数。
- 累计延寿总量。
- 历史日历数据。
- 小队配置。
- 最近 hook 事件摘要。
- 设置项。

推荐文件：

```text
~/Library/Application Support/HealthyVibe/HealthyVibe.sqlite
~/Library/Application Support/HealthyVibe/events/*.json
~/Library/Application Support/HealthyVibe/hooks/agent-event.sh
```

推荐表：

- `task_templates`
- `daily_task_plan`
- `task_deliveries`
- `task_completions`
- `daily_stats`
- `hook_events`
- `team_profile`
- `team_snapshots_cache`
- `app_settings`

隐私原则：

- 本地是个人历史主账本。
- 用户可删除本地历史。
- `hook_events` 只保留最近少量摘要用于排障。
- 不保存 prompt、代码路径、diff、命令内容。

## 5. 小队 Relay

当前方案：Cloudflare Workers + D1。

参考资料：

- Cloudflare Workers: https://developers.cloudflare.com/workers/
- Cloudflare D1: https://developers.cloudflare.com/d1/

实现记录：

- Relay 目录：`relay/`
- Worker 入口：`relay/src/index.ts`
- D1 migration：`relay/migrations/0001_team_snapshots.sql`
- Swift 客户端：`Sources/HealthyVibeTeam/TeamRelayClient.swift`

API：

```text
POST /v1/team/snapshot
GET  /v1/team/ranking?team=<team_code_hash>&date=<YYYY-MM-DD>
```

服务端保存：

- `team_code_hash`
- `member_id_hash`
- `display_name`（可选；MVP 默认不上传 macOS 用户名）
- `date`
- `longevity_minutes`
- `completed_task_count`
- `updated_at`

服务端不保存：

- 小队码明文。
- member id 明文。
- prompt。
- 代码路径。
- diff。
- 命令内容。
- hook 原始 payload。

保留策略：

- 每次 snapshot 写入时清理 3 天前的 date 数据。
- Relay 只承担当天/近几天排行榜同步，不作为个人历史账本。
- 个人历史、日历和长期统计仍以本地 SQLite 为准。

## 6. 任务与提醒

### 6.1 每日固定任务池

MVP 任务池草案：

```text
喝一杯水       8 次   每次 +2 分钟
远眺 20 秒     6 次   每次 +2 分钟
起身活动 30 秒 3 次   每次 +4 分钟
肩颈活动 30 秒 3 次   每次 +3 分钟
手腕活动 15 秒 3 次   每次 +2 分钟
深呼吸 5 次    3 次   每次 +2 分钟
```

规则：

- 每天任务池固定。
- 任务池总延寿值可以超过每日目标 30 分钟。
- 每次只下发一张任务卡。
- 完成后不立即补发新任务。
- `换一个` 是随机刷新，从剩余任务池中选一项，不打开选择列表。
- 某项任务次数完成后，从随机候选中移除。

### 6.2 提醒节奏

触发规则：

- 用户提交 prompt 后触发 `UserPromptSubmit`。
- 距离上次任务下发超过 30 分钟才发新任务。
- 连续 60 分钟活跃使用但没有收到 hook 时，兜底下发一张任务。
- 电脑睡眠、锁屏、熄屏期间不累计活跃时间。
- 唤醒或解锁后继续累计活跃时间。

## 7. 健康与延寿值参考

### 7.1 程序员延寿指南

- HowToLiveLonger / 程序员延寿指南: https://github.com/geekan/HowToLiveLonger

参考价值：

- 可参考其表达方式和健康条目类型。
- 不应把 HealthyVibe 的延寿分钟表达为真实医学结论。
- MVP 中延寿分钟是产品内娱乐积分。

### 7.2 延寿后缀文案

延寿分钟建议附加半句话，帮助用户直观理解累计成果。

示例：

```text
本次延寿 +3 分钟，可以认真伸个懒腰
累计延寿 30 分钟，可以多散一次步
累计延寿 2 小时，可以多看一部电影
累计延寿 8 小时，可以睡一个完整觉
```

设置页声明：

```text
延寿分钟是 HealthyVibe 内的娱乐积分，用于鼓励短暂休息和轻量活动，不构成医学建议。
```

## 8. 竞品与邻近产品

### 8.1 休息提醒

- Stretchly: https://github.com/hovancik/stretchly
- Time Out: https://www.dejal.com/timeout/
- Pebl: https://www.peblapp.com/
- Workrave: https://workrave.org/

区别：

- 这些产品主要是定时休息提醒。
- HealthyVibe 的触发点是 AI coding prompt 提交后的自然等待期。

### 8.2 AI coding 等待 / 通知

- CodeBreak: https://thecodebreak.com/
- Claude Code Notifier: https://claudecodenotifier.com/

区别：

- 邻近产品更偏 agent 通知、远程响应或等待陪伴。
- HealthyVibe 的核心反馈是健康微任务、延寿进度和小队当日排名。

### 8.3 团队健康挑战

- Count.It: https://count.it/
- MoveSpring: https://movespring.com/
- Wellable: https://www.wellable.co/wellness-platform
- YuMuuv: https://yumuuv.com/

区别：

- 这些产品更偏企业 wellness。
- HealthyVibe 不做账号系统、HR 平台、复杂挑战和严肃运动强度。

## 9. 后续待查

- 非 App Store 分发下开机启动的推荐实现。
- Homebrew Cask 初版发布流程和自动更新策略。
- Cloudflare D1 生产数据库绑定、migration 部署和域名配置。
