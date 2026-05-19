# HealthyVibe / Vibe延寿指南

HealthyVibe 是一个 macOS 菜单栏应用，把 Claude Code / Codex 等 AI coding agent 的等待时间变成轻量健康微休息。

当你提交 prompt 后，HealthyVibe 通过系统通知提醒你做一张短任务卡：喝水、远眺、起身活动、肩颈活动、手腕活动或深呼吸。

## MVP 功能

- macOS 菜单栏 popover，包含今日任务、日历、设置三页。
- Claude Code / Codex `UserPromptSubmit` hook 接入。
- 系统通知提醒，不做自定义弹窗。
- 30 分钟冷却，连续 60 分钟活跃无 hook 时兜底提醒。
- 每日固定任务池，完成后不立即补发下一张。
- 今日 30 分钟延寿进度和本地历史日历。
- 轻量小队排行榜，无账号系统。
- Homebrew Cask / shell script 风格安装入口。

## 本地开发

```bash
make build
make icon
make bundle
make run
swift test
```

生成的 app：

```text
.build/HealthyVibe.app
```

本地数据：

```text
~/Library/Application Support/HealthyVibe/
```

## 打包

```bash
make package
```

输出：

```text
dist/HealthyVibe-0.1.0.zip
dist/HealthyVibe-0.1.0.zip.sha256
dist/healthyvibe.rb
```

签名、公证和 Homebrew Cask 说明见 `DISTRIBUTION.md`。

## Relay

小队 Relay 位于 `relay/`：

```bash
cd relay
npm run typecheck
npm test
```

Relay 只保存小队 hash、匿名 member hash、日期、延寿分钟、完成次数和更新时间。它不接收、不保存 prompt、代码、diff、路径或 hook 原始 payload。

## 隐私边界

- Hook bridge 会读取 stdin 后立即丢弃，不保存 prompt。
- 本地只记录 `source`、`event`、`receivedAt` 这类最小事件。
- 个人历史保存在本地 SQLite。
- 小队上传只包含匿名 hash 和当天榜单结果。

## 免责声明

延寿分钟是 HealthyVibe 内的娱乐积分，用于鼓励短暂休息和轻量活动，不构成医学建议。

## License

MIT
