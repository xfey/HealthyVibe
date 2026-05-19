# HealthyVibe / Vibe延寿指南 PRD

日期：2026-05-19  
阶段：MVP 需求定稿前  
状态：实现中，Phase 0-5 已完成

## 1. 产品定位

HealthyVibe，中文名暂定为「Vibe延寿指南」，是一款面向程序员在 AI coding / vibe coding 等待期间使用的轻量健康等待室。

当用户向 Claude Code、Codex、Cursor Agent、Copilot Agent 等 AI 编程工具提交 prompt 后，HealthyVibe 在 agent 开始工作时提醒用户完成一个短、低成本、无器械的健康微动作，例如站起来、喝水、远眺、活动手腕、深呼吸。

它不是严肃健身软件，不是医疗建议工具，也不是普通番茄钟或企业健康平台。它的核心价值是：把 AI 写代码时自然产生的等待时间，转化为轻量、好玩、低打扰的健康休息。

一句话：

> AI 写代码的时候，你去续命。

## 2. 目标用户

核心用户：

- 高频使用 Claude Code、Codex、Cursor Agent、Copilot Agent 等 AI 编程工具的程序员。
- 长时间坐在电脑前工作，容易盯终端、刷手机、忘记休息。
- 喜欢轻量、有梗、低打扰工具，不愿意安装复杂健身或健康管理软件。

次级用户：

- 小团队、独立开发者、开源项目维护者。
- 希望用轻松方式做健康挑战的远程团队。

## 3. 核心问题

AI coding 工作流中存在大量碎片等待时间：

- 用户提交 prompt 后，agent 读代码、改文件、跑命令。
- 用户等待期间容易盯屏幕、刷新终端、刷手机。
- 这些等待时间不适合进入复杂任务，但适合做 20-60 秒的健康微动作。

HealthyVibe 的目标不是创造新的休息时间，而是接管这些已经存在的等待时间。

## 4. MVP 目标

第一版只实现最终核心形态，不追求重功能扩展：

- 支持通过 CLI 方式完成安装，避免用户必须手动下载和拖拽 DMG。
- 安装后的配置和日常使用通过 GUI 完成。
- 提供一个 macOS 菜单栏 popover，内部支持左右切换分页。
- 支持 Claude Code / Codex 的 `UserPromptSubmit` hook 事件接入。
- 用户提交 prompt 后，通过系统通知触发健康任务。
- 支持 30 分钟冷却和 60 分钟活跃无 hook 兜底提醒。
- 每天生成固定任务池，每次只下发一张任务卡。
- 任务完成后展示完成状态或空态，不立即补发新任务。
- 提供今日延寿进度、历史日历、基础设置和小队排名。
- 远端只做轻量 relay，同步当天小队榜单。

## 5. 交互形态

### 5.1 单一菜单栏 Popover

HealthyVibe 不做独立设置窗口。所有日常操作、历史查看和设置都放在菜单栏 popover 内。

建议尺寸：

```text
宽 340px
高 300-360px
白底
8px 圆角
轻边框
无复杂阴影
```

Popover 内部三页左右切换：

```text
[ 今日任务 ]  [ 日历 ]  [ 设置 ]
```

交互方式：

- 顶部分段控制或分页指示，保证用户知道可以切换。
- 支持 trackpad 左右滑动。
- 支持左右箭头键切换。
- 不做复杂 dashboard，不做信息流。

视觉方向：

- Apple / macOS：白底、留白、系统感、清晰层级。
- Linear：安静、克制、精确的工具感。
- Claude：温暖、轻松，有一点人味。
- Raycast：小面板密度、快捷、工程师友好。

### 5.2 今日任务页

今日任务页是默认页。它只展示当前下发任务、完成反馈、今日进度和小队简要信息。

有待完成任务：

```text
Vibe延寿指南

远眺 20 秒
让眼睛从 diff 里撤退一下

延寿 +2 分钟，可以多听一首歌的前奏

[完成]   [换一个]

今日 18 / 30 分钟
████████░░░░

小队排名 3/10
```

完成后状态：

```text
本轮已续命
+3 分钟

今日 21 / 30 分钟
█████████░░░

下一次 agent 开工后再提醒
```

空态：

```text
等待下一次 agent 开工
超过 30 分钟后，新的 prompt 会触发一次提醒

今日 21 / 30 分钟
█████████░░░
```

显示规则：

- 未加入小队时，不显示小队排名。
- 没有当前任务时，显示完成状态或等待状态。
- 不提供 `Snooze`。
- `换一个` 是随机刷新，从当天剩余任务池中换一项，不打开选择列表。
- 当某类任务今日次数用完后，不再被随机选中。

### 5.3 日历页

日历页用于查看本地历史，不做复杂报表。

第一版建议：

```text
2026 年 5 月

一 二 三 四 五 六 日
        1  2  3
4  5  6  7  8  9 10
...

今日：21 分钟
连续：4 天
累计：186 分钟，可以多看一部电影
```

日历显示：

- 空白：当天无记录。
- 浅色点：当天有完成。
- 深色点：当天达到 30 分钟目标。

点击某天后显示：

```text
5 月 18 日
延寿 34 分钟
完成 9 次任务
```

### 5.4 设置页

设置页也在 popover 内，使用简单列表布局。

内容建议：

```text
Agents
Claude Code       Connected
Codex             Not Connected

Notifications
System Notification   Enabled

Team
未加入小队        [加入]

Preferences
每日目标          30 分钟
冷却时间          30 分钟

Privacy
延寿分钟说明
清除本地数据
```

设置页承担：

- 通知权限说明和状态。
- Claude Code / Codex 连接、断开、测试。
- 创建小队 / 加入小队。
- 查看当日小队排行榜。
- 每日目标和冷却时间。
- 隐私说明。
- 删除本地数据。

免责声明放在设置页：

```text
延寿分钟是 HealthyVibe 内的娱乐积分，用于鼓励短暂休息和轻量活动，不构成医学建议。
```

## 6. 任务系统

### 6.1 每日固定任务池

每天生成固定任务池，用户完成的是池子里的次数，不是无限随机任务。

示例任务池：

```text
喝一杯水       8 次   每次 +2 分钟
远眺 20 秒     6 次   每次 +2 分钟
起身活动 30 秒 3 次   每次 +4 分钟
肩颈活动 30 秒 3 次   每次 +3 分钟
手腕活动 15 秒 3 次   每次 +2 分钟
深呼吸 5 次    3 次   每次 +2 分钟
```

任务池总延寿值可以超过每日目标 30 分钟。用户不需要全部完成，只需要完成自己力所能及的一部分。

规则：

- 每次只下发一张任务卡。
- 完成任务后不立即补发新任务。
- `换一个` 从剩余可完成任务中随机换一项。
- 某项任务今日次数完成后，该任务不再被下发。
- 当天任务池全部完成后，显示今日全部完成状态。

### 6.2 任务下发

任务只在合适时机下发，避免用户连续刷任务。

触发规则：

- 用户提交 prompt 后触发 `UserPromptSubmit`。
- 如果距离上一次任务下发已经超过 30 分钟，则下发一个任务。
- 如果 30 分钟内已经下发过任务，不提醒。
- 如果连续 60 分钟活跃使用但没有收到 hook，则兜底下发一张任务。
- 完成任务后等待下一次触发，不自动补发。

活跃时间规则：

- 60 分钟兜底使用活跃时间，不是纯 wall clock。
- 电脑睡眠、锁屏、熄屏期间不累计活跃时间。
- 唤醒或解锁后继续累计活跃时间。
- 如果 app 未运行，hook bridge 会写入 event inbox 并尝试启动 app；兜底提醒依赖 app 运行。

### 6.3 延寿值

延寿分钟是产品内娱乐积分，不表达真实医学结论。

默认目标：

```text
每日 30 分钟延寿值
```

延寿展示应增加直观后缀：

```text
累计延寿 2 小时，可以多看一部电影
累计延寿 30 分钟，可以多散一次步
本次延寿 +3 分钟，可以认真伸个懒腰
```

这些后缀用于帮助用户直观理解进度，不构成医学建议。

## 7. Hook 集成

HealthyVibe 不做用户可感知的 CLI 产品，但需要一个隐藏 hook bridge 来接收 Claude Code / Codex 的 hook 调用。

推荐路径：

```text
~/Library/Application Support/HealthyVibe/hooks/agent-event.sh
```

事件链路：

```text
Claude/Codex UserPromptSubmit hook
  -> agent-event.sh
  -> 写入本地 event inbox
  -> open -gj -a HealthyVibe
  -> HealthyVibe 读取事件
  -> 判断是否应下发任务
  -> macOS 系统通知
  -> 用户点击通知打开菜单栏 popover
```

设计原则：

- 用户不需要知道 hook bridge 的存在。
- GUI 中点击 `Connect Claude Code` / `Connect Codex` 后，app 自动写入 hook 配置。
- hook bridge 只记录最小必要事件，例如来源、事件类型、接收时间。
- `UserPromptSubmit` 可能收到 prompt 字段；bridge 必须读取后立即丢弃，不保存、不上传、不输出。
- MVP 阶段不保存 prompt、代码路径、diff、命令内容等敏感信息。
- App 未运行时，hook bridge 先写入本地队列，再尝试启动 app。

第一版只写用户级配置，不碰项目级配置：

```text
Claude Code: ~/.claude/settings.json
Codex:      ~/.codex/hooks.json
```

连接流程：

- 备份原配置。
- 合并 HealthyVibe hook，不覆盖用户已有 hook。
- 写入 `UserPromptSubmit` hook。
- 发送测试事件，确认菜单栏 app 能收到。

断开流程：

- 只删除 HealthyVibe 自己写入的 hook。
- 通过固定脚本路径和唯一 marker 识别 HealthyVibe hook。
- 不修改用户其他 hook。

## 8. 通知

优先使用 macOS 系统级通知，不做自定义浮层弹窗。

通知策略：

- 触发条件满足后发系统通知。
- 通知不需要操作按钮。
- 用户点击通知后打开菜单栏 popover 的今日任务页。
- 通知文案生动有趣，但不制造压力。

通知文案示例：

- `Codex 开始干活了。你先远眺 20 秒，别盯着它想。`
- `Claude 接单了。活动一下手腕，等它交差。`
- `Prompt 已投喂。站起来 30 秒，让身体也参与一下异步。`
- `没等到新的 agent，也该给身体发个 keepalive 了。`

通知权限未开启：

- 菜单栏仍可手动使用。
- hook event 仍记录。
- 不弹系统通知。
- 设置页显示 `Notification Disabled`，并解释开启通知的价值。

## 9. 统计、小队与 Relay

### 9.1 本地统计

本地数据库是个人历史主账本。

本地保存：

- 今日延寿总量。
- 今日完成任务数。
- 当天任务池和完成次数。
- 每次任务下发记录。
- 每次任务完成记录。
- 连续完成天数。
- 累计延寿总量。
- 历史每日统计。
- 小队配置。
- 最近 hook 事件摘要。
- 设置项。

### 9.2 小队

小队功能保持轻量：

- 创建小队。
- 加入邀请码。
- 今日小队延寿总量。
- 按当日个人延寿总量排名。
- 菜单栏只展示最简排名，例如 `小队排名 3/10`。
- 设置页可查看当日完整小队排行榜和成员结果。
- 每日重置。

团队玩法基调：

- 比参与，不比运动强度。
- 不做严肃健身比赛。
- 不制造强压力。
- 允许信任制自报。

### 9.3 Relay Server

HealthyVibe 第一版不做账号系统，后端只作为轻量 relay / 当日排行榜服务。

本地保存个人完整历史，relay server 只保存小队当天需要共享的数据，但当天数据应包含完整成员结果，而不是只返回一个排名数字。

Relay server 保存：

- team code 或其 hash。
- anonymous member id 或其 hash。
- display name，可选。
- date。
- today longevity minutes。
- today completed task count。
- updated at。

Relay server 不保存：

- 用户账号。
- 邮箱、手机号等身份信息。
- prompt、代码、diff、文件路径。
- hook 原始 payload。
- 个人长期历史报表。

数据保留策略：

- 当天小队数据需要保留完整成员结果，用于排行榜和结果页。
- 可保留最近 48-72 小时作为容错窗口。
- 个人历史由本地数据库持久保存，不依赖 server。

最小 API：

```text
POST /v1/team/snapshot
GET  /v1/team/ranking?team=...&date=...
```

## 10. 技术选型

### 10.1 macOS 客户端

第一版选择 SwiftUI + AppKit 原生 macOS。

推荐结构：

```text
HealthyVibe.app
  - AppKit NSStatusItem + NSPopover
  - SwiftUI 菜单栏 popover
  - SwiftUI 分页视图
  - UNUserNotificationCenter 系统通知
  - SQLite 本地数据
  - Hook 配置写入器
  - Event Inbox 读取器
  - Active Time Tracker

Hook Bridge
  - 本地隐藏 shell script
  - 被 Claude/Codex hook 调用
  - 用户不可见
```

选择理由：

- 菜单栏、popover、系统通知、开机启动、app bundle、notarization 都是 macOS 原生能力。
- `NSStatusItem + NSPopover + SwiftUI view` 比纯 `MenuBarExtra` 更适合程序化打开菜单栏小浮窗。
- 第一版只面向 macOS，不需要 Electron/Tauri 的跨平台成本。

最低系统版本建议：

```text
macOS 13 Ventura+
```

### 10.2 本地数据

第一版选择 SQLite + GRDB.swift。

本地文件：

```text
~/Library/Application Support/HealthyVibe/HealthyVibe.sqlite
~/Library/Application Support/HealthyVibe/events/*.json
~/Library/Application Support/HealthyVibe/hooks/agent-event.sh
```

建议数据表：

- `task_templates`
- `daily_task_plan`
- `task_deliveries`
- `task_completions`
- `daily_stats`
- `hook_events`
- `team_profile`
- `team_snapshots_cache`
- `app_settings`

数据原则：

- `events/*.json` 是 hook bridge 写入的 event inbox，只保存最小事件。
- SQLite 是个人历史主账本，保存日历、日报、累计统计和设置。
- `hook_events` 只保留最近少量记录用于排障，不保存原始 payload。

### 10.3 Relay Server

第一版选择 Cloudflare Workers + D1。

选择理由：

- API 极简。
- 无账号系统。
- 成本低。
- 适合只保存小队当天排行榜快照。

如果后续需要更强管理后台、实时能力或更快搭建速度，可再评估 Supabase。

## 11. 非目标

第一版明确不做：

- 独立设置窗口。
- 严肃健身计划。
- 医疗建议、诊断、治疗、药物、补剂建议。
- 摄像头姿态检测。
- Apple Watch / HealthKit 深度集成。
- 企业 HR wellness 平台。
- 复杂社交和聊天。
- 大型新闻流或 RSS 阅读器。
- 段子 / 轻资讯内容模块。
- 复杂插件市场分发。
- 跨平台完整适配。
- 过度游戏化。
- 任务选择列表。
- 通知按钮操作。

## 12. 隐私与安全

默认本地优先：

- hook 事件先进入本地 app。
- 不上传代码、prompt、diff、文件路径等敏感内容。
- 远端只存匿名小队当天榜单快照。
- 用户可关闭团队功能。
- 用户可查看最近收到的 hook 事件摘要。

需要明确说明：

- HealthyVibe 不读取代码内容。
- HealthyVibe 不保存 prompt。
- HealthyVibe 不提供医疗建议。
- 延寿分钟是产品内娱乐积分，不构成医学建议。
- hook 配置变更会备份。
- 用户可以一键断开 Claude/Codex 集成。
- 用户可以删除本地历史数据。

## 13. 成功指标

MVP 阶段关注：

- CLI 安装到首次打开 GUI 的完成率。
- GUI 中完成 Claude/Codex 连接配置的完成率。
- 首次成功触发 hook 的完成率。
- 系统通知触发后用户打开面板比例。
- 任务完成率。
- `换一个` 使用比例。
- 每日延寿总量。
- 每日健康任务完成次数。
- 7 日留存。
- 小队创建和加入比例。
- 小队用户的次日回访率。
- 用户是否觉得提醒打扰。

## 14. 待讨论问题

- Homebrew Cask 和 notarized app 的具体分发流程。
- Claude Code 与 Codex 的 `UserPromptSubmit` hook 写入格式细节。
- 今日默认延寿目标是否固定为 30 分钟，还是允许首次引导时选择。
- 延寿收益数值是否完全自定义，还是参考「程序员延寿指南」做一版可解释规则。
- 累计延寿后缀文案的映射规则。
- 小队 relay 的保留窗口最终设为 48 小时还是 72 小时。
- 产品正式名使用 HealthyVibe，还是 Vibe延寿指南优先。
