# HealthyVibe / Vibe延寿指南

HealthyVibe 是一款给 AI 时代程序员准备的 macOS 菜单栏小工具。

当你把 prompt 交给 Claude Code 或 Codex，等 AI 写代码的时候，HealthyVibe 会提醒你做一点很短的健康任务：喝口水、远眺一下、起身活动、动动肩颈或手腕。

AI 在工作，碳基生物也可以顺手续一会儿命。

这不是医学建议，只是一个轻量、温和的小提醒：让 AI 多写一点代码，让我们多活一点生活。

## 安装

```bash
brew install --cask xfey/tap/healthyvibe
```

如果你更喜欢先添加 tap：

```bash
brew tap xfey/tap
brew install --cask healthyvibe
```

安装完成后，打开 `HealthyVibe.app`。它不会弹出一个大窗口，只会出现在 macOS 菜单栏里。

## 怎么用

第一次打开后，点击菜单栏里的 HealthyVibe 图标。

在设置页里连接你正在使用的 agent：

- Claude Code
- Codex

连接后，重启对应的 agent 会话。之后每当你提交 prompt，HealthyVibe 就会通过系统通知提醒你做一个小任务。

通知里可以直接选择：

- `已完成`
- `30分钟后提醒`
- `两小时后提醒`

如果你没有点完成，下次提交 prompt 时它还会继续提醒。只有完成任务后，才会进入 30 分钟冷却。

## 今日任务

HealthyVibe 每天会准备一组固定的小任务，例如：

- 喝一杯水
- 远眺 20 秒
- 起身活动 30 秒
- 活动肩颈
- 活动手腕
- 深呼吸几次

每次完成任务都会获得一点“延寿分钟”。这是应用里的娱乐积分，用来给短暂休息一点正反馈。

今日目标是 30 分钟。你不需要一次做完所有任务，HealthyVibe 会在合适的时候慢慢提醒。

## 日历

日历页会记录你每天完成了多少延寿分钟。

累计时间旁边会出现一些更有生活感的小描述，帮你直观感受这些零碎休息加起来可以换来什么。

## 小队

小队不需要账号。

点击 `创建` 会得到一个 6 位邀请码。把这个号码发给朋友，朋友在小队页输入同一个 6 位码并点击 `加入`，就会进入同一个当天排行榜。

排行榜只比较今天的延寿分钟。它不需要复杂数据，也不需要认真竞争，能让大家互相提醒一下就够了。

## 隐私

HealthyVibe 只关心一件事：你是不是刚刚把 prompt 交给了 agent。

它不会保存你的 prompt、代码、diff、文件路径或命令内容，也不会上传这些内容。

小队功能只用于生成当天排行榜，不需要账号。你的个人历史记录保存在本机。

## 卸载

```bash
brew uninstall --cask healthyvibe
```

如果你想同时清理本地数据：

```bash
brew uninstall --cask --zap healthyvibe
```

## 自己编译或修改

如果你需要自己编译、修改代码并进行部署，可以查看：

- `DEVELOPMENT.md`：本地开发、项目结构和调试说明
- `DISTRIBUTION.md`：签名、公证、打包和 Homebrew Cask 发布流程
- `relay/`：小队排行榜服务的接口说明和参考实现

常用命令：

```bash
make build
make bundle
swift test
make package
```

## 致谢

HealthyVibe 的“延寿”表达和部分健康任务灵感来自 [程序员延寿指南](https://github.com/geekan/HowToLiveLonger)。

也感谢那些愿意把等待 AI 的几十秒，换成喝水、远眺和起身活动的人。

## License

MIT
