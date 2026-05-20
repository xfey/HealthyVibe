# HealthyVibe / Vibe延寿指南

HealthyVibe 是一款给 AI 时代程序员准备的 macOS 菜单栏健康提醒工具。

当你把 prompt 交给 Claude Code / Codex，等待 AI 写代码的时候，HealthyVibe 会轻轻提醒你：起来喝口水、远眺一下、活动肩颈、动动手腕。让 AI 干活的时候，碳基生物也顺手续一会儿命。

这不是医学建议，只是一个温柔的小工具：让 AI 多写一点代码，让我们多活一点生活。

## 安装

```bash
brew install --cask xfey/tap/healthyvibe
```

或者：

```bash
brew tap xfey/tap
brew install --cask healthyvibe
```

安装后启动 `HealthyVibe.app`，它只会出现在菜单栏里。后续连接 Claude Code / Codex、通知权限、小队等配置都在菜单栏小窗口里完成。

## 它会做什么

- 在 Claude Code / Codex 收到你的 prompt 后提醒你休息一下。
- 使用系统通知，不做突兀的自定义弹窗。
- 通知里可以直接选择 `已完成`、`30分钟后提醒`、`两小时后提醒`。
- 健康任务包括喝水、远眺、起身活动、肩颈活动、手腕活动和深呼吸。
- 每天有 30 分钟“延寿”目标，完成任务会填充进度条。
- 日历页记录过去每天的延寿分钟和完成情况。
- 小队页可以创建 / 加入 6 位码小队，看看今天谁最会续命。
- 支持 Homebrew / CLI 风格安装，但日常使用保持 GUI。

## 小队

小队不需要账号。

点击 `创建` 会自动生成一个 6 位邀请码。把这个号码发给朋友，朋友在小队页输入同一个 6 位码并点击 `加入`，就会进入同一个当天排行榜。

Relay 只保存小队 hash、匿名 member hash、日期、延寿分钟、完成次数和更新时间。个人长期历史仍保存在本地 SQLite。

## 隐私边界

HealthyVibe 的 hook bridge 会丢弃输入内容，只写入最小事件：

```json
{
  "source": "codex 或 claude",
  "event": "prompt_submitted",
  "receivedAt": "时间戳"
}
```

它不会保存 prompt、代码、diff、路径、命令内容，也不会把这些内容上传到 relay。

小队功能只上传匿名 hash、日期、延寿分钟和完成任务次数，用于生成当天排行榜。

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
dist/HealthyVibe-1.0.0.zip
dist/HealthyVibe-1.0.0.zip.sha256
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

## 致谢

HealthyVibe 的「延寿」表达和部分健康任务灵感来自 [程序员延寿指南](https://github.com/geekan/HowToLiveLonger)。

也感谢那些愿意把等待 AI 的几十秒，换成喝水、远眺和起身活动的人。

## License

MIT
