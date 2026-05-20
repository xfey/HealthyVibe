# HealthyVibe / Vibe延寿指南

HealthyVibe 是一个 macOS 菜单栏应用，把 Claude Code / Codex 等 AI coding agent 的等待时间变成轻量健康微休息。

当你提交 prompt 后，HealthyVibe 通过系统通知提醒你做一张短任务卡：喝水、远眺、起身活动、肩颈活动、手腕活动或深呼吸。

## MVP 功能

- macOS 菜单栏 popover，包含今日任务、小队、日历、设置、关于五页。
- Claude Code / Codex `UserPromptSubmit` hook 接入。
- 系统通知提醒，不做自定义弹窗，通知内支持 `已完成`、`30分钟后提醒`、`两小时后提醒`。
- 完成任务后进入 30 分钟冷却；未确认的任务会在后续 hook 继续提醒。
- 连续 60 分钟活跃无 hook 时兜底提醒。
- 每日固定任务池，完成后不立即补发下一张。
- 今日 30 分钟延寿进度和本地历史日历。
- 轻量小队排行榜，无账号系统。
- Homebrew Cask / shell script 风格安装入口。

## 本地开发

```bash
make build
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

生产 Relay 地址：

```text
https://healthyvibe.owlib.ai
```

健康检查：

```text
https://healthyvibe.owlib.ai/healthz
```

Relay 参考实现与接口文档位于 `relay/`：

```bash
cd relay
npm run typecheck
npm test
```

Relay 只保存小队 hash、匿名 member hash、日期、延寿分钟、完成次数和更新时间。它不接收、不保存 prompt、代码、diff、路径或 hook 原始 payload。

## 隐私边界

- Claude Code / Codex 的 `UserPromptSubmit` hook 可能把 prompt payload 通过 stdin 传给 hook command；HealthyVibe 的 hook bridge 只执行 `cat >/dev/null` 丢弃 stdin，不解析、不输出、不落盘、不上传。
- 本地只记录 `source`、`event`、`receivedAt` 这类最小事件，用于判断 agent 是否刚开始工作。
- 完成任务后的 30 分钟冷却内，hook 仍会记录，但不会重复下发任务或发送系统通知。
- 个人历史保存在本地 SQLite。
- 小队上传只包含匿名 hash 和当天榜单结果。
- Relay 不接收 hook 原始 payload，不接收 prompt、代码、diff、文件路径或命令内容。

## 致谢

HealthyVibe 的「延寿」表达和部分健康任务灵感来自 [程序员延寿指南](https://github.com/geekan/HowToLiveLonger)。

## 免责声明

延寿分钟是 HealthyVibe 内的娱乐积分，用于鼓励短暂休息和轻量活动，不构成医学建议。

## License

MIT
