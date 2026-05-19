# Vibe Healthy 产品想法记录

日期：2026-05-19  
阶段：概念确认 / MVP 前  
说明：本文件保留产品背景和讨论脉络。当前实现口径以 `PRD.md` 和 `ROADMAP.md` 为准。

## 一句话定位

**Vibe Healthy / HealthyVibe：更健康的 vibe coding 等待室。**

当程序员把任务交给 Claude Code、Codex、Cursor Agent、Copilot Agent 等 AI 编程工具后，HealthyVibe 在 agent 开始工作时，提醒用户做一个轻量健康动作：远眺、喝水、起身活动、活动手腕、深呼吸。

它不是严肃的效率工具，也不是完整健身软件，而是一个贴近 vibe coding 场景的微休息触发器。

## 核心观察

Vibe coding 的工作流里经常出现碎片等待时间：

- 用户提交 prompt 后，等待 agent 读代码、改文件、跑命令。
- 等待期间用户容易盯着终端、刷手机、刷社交媒体。
- 这些等待时间很短，不适合进入复杂任务，但适合做轻运动、远眺、喝水。

HealthyVibe 的切入点是：**不用创造新的休息时间，而是接管 vibe coding 已经天然产生的等待时间。**

## 当前产品收敛

经过讨论，MVP 已收敛为：

- macOS 菜单栏应用。
- 单一 popover，不做独立设置窗口。
- Popover 内三页左右切换：今日任务、日历、设置。
- 通过 Homebrew Cask 或安装脚本安装，安装后使用 GUI。
- 通过隐藏 hook bridge 接入 Claude Code / Codex。
- 优先监听 `UserPromptSubmit`，即用户提交 prompt 后触发。
- 30 分钟冷却，60 分钟活跃无 hook 时兜底提醒。
- 每天生成固定任务池，每次只下发一张任务卡。
- 任务完成后显示完成状态或空态，不立即补发。
- `换一个` 仍是随机换任务，不打开选择列表。
- 不做 Snooze。
- 今日目标默认 30 分钟延寿值。
- 延寿分钟是娱乐积分，不构成医学建议。
- 本地保存个人历史和日历。
- 轻量 relay server 只同步当天小队排行榜。

## 当前核心体验

用户提交 prompt 后：

```text
Claude/Codex UserPromptSubmit hook
  -> hook bridge 写入本地 event inbox
  -> HealthyVibe 判断冷却时间和任务池
  -> macOS 系统通知
  -> 用户点击通知打开菜单栏 popover
  -> 完成任务或随机换一个任务
```

今日任务页示意：

```text
远眺 20 秒
让眼睛从 diff 里撤退一下

延寿 +2 分钟，可以多听一首歌的前奏

[完成]   [换一个]

今日 18 / 30 分钟
████████░░░░

小队排名 3/10
```

未加入小队时不显示排名。

## 为什么仍然值得做

市场上已经有很多相关产品：

- macOS 休息提醒：LookAway、Pebl、Viraam、Time Out、BreakTimer、Stretchly、Workrave 等。
- AI coding 等待伴侣：CodeBreak、Vicoa、Bridge Terminal、Claude Code notifier 类工具。
- IDE 轻娱乐：CodeType、ConnectFourBreak、Minigames、PRODO。
- 团队健康挑战：Count.It、MoveSpring、Wellable、YuMuuv 等。

但目前没有看到一个完整重合的产品同时覆盖：

- 面向 vibe coding / AI coding agent 等待期。
- macOS 菜单栏 popover。
- 用户提交 prompt 后触发。
- 健康小活动任务池。
- 延寿值和本地历史日历。
- 轻量小队当日排行榜。
- 可选接入 Claude Code / Codex 等 agent 状态。

差异化不是“又一个 break reminder”，而是：

> **程序员 vibe coding 时的健康等待室。**

## 产品边界

第一版明确不做：

- 独立设置窗口。
- 严肃健身 app。
- 医疗建议工具。
- 重度社交平台。
- 企业 HR wellness 系统。
- 新闻阅读器。
- 段子 / 轻资讯内容模块。
- 复杂效率管理器。
- 摄像头、Apple Watch、传感器检测。
- 任务选择列表。
- 通知按钮操作。

Vibe Healthy 的气质应该是：

> **轻、好玩、有梗、低打扰、贴近程序员、刚好在 AI 等待期间出现。**

## 宣传角度

核心传播点：

> **Vibe coding 很爽，但别把身体也外包给模型。**

其他文案：

- “AI 写代码的时候，你去续命。”
- “Claude 接单了，你先改一下颈椎。”
- “Codex 开始干活了，你先远眺 20 秒。”
- “把每次 AI 等待，变成一次健康微休息。”
- “A healthier waiting room for vibe coding.”
- “Take a healthy break while your agent works.”

## 技术方向

客户端：

- SwiftUI + AppKit 原生 macOS。
- `NSStatusItem + NSPopover` 承载菜单栏 popover。
- SQLite + GRDB.swift 保存本地历史。
- `UNUserNotificationCenter` 发送系统通知。

Hook：

- 隐藏 hook bridge。
- 用户不可见，不作为 CLI 产品。
- GUI 负责连接和断开 Claude Code / Codex。
- 只保存最小事件，不保存 prompt、代码路径、diff、命令内容。

后端：

- Cloudflare Workers + D1。
- 不做账号系统。
- 只同步当天小队排行榜快照。
- 个人长期历史只保存在本地。

## 免责声明

HealthyVibe 只提供一般性的健康休息提醒和娱乐积分，不提供医疗建议。涉及疾病、药物、补剂、治疗、诊断等内容不应进入产品建议。
