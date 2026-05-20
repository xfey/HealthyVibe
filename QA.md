# HealthyVibe MVP QA Checklist

日期：2026-05-19

## 新用户 5 分钟路径

- [ ] 通过 Homebrew Cask 或安装脚本安装 app。
- [ ] 启动后只看到菜单栏图标，不出现主窗口。
- [ ] 点击菜单栏图标，popover 默认打开今日任务页。
- [ ] 进入设置页，开启系统通知权限。
- [ ] 连接 Claude Code 或 Codex。
- [ ] 点击设置页的 `模拟 prompt_submitted`。
- [ ] 收到系统通知。
- [ ] 不点击通知 action 时，再次提交 prompt 仍会继续收到提醒。
- [ ] 点击通知里的 `已完成` 后，任务完成并进入 30 分钟冷却。
- [ ] 点击通知里的 `30分钟后提醒` 或 `两小时后提醒` 后，冷却期内不重复通知，并在到期后收到延迟通知。
- [ ] 完成冷却内再次提交 prompt 时，设置页显示 hook 已收到和冷却剩余时间，不重复通知。
- [ ] 点击通知后打开今日任务页。
- [ ] 点击 `完成` 后今日进度增加，任务不会立即补发。

## 页面状态

- [ ] 今日页等待态：未连接 agent 时展示连接入口。
- [ ] 今日页等待态：已连接 agent 时展示 30 分钟冷却和 60 分钟兜底说明。
- [ ] 今日页任务态：标题、副标题、延寿值、完成/换一个按钮不溢出。
- [ ] 今日页完成态：展示本轮完成和下一次触发说明。
- [ ] 今日页目标达成：进度条和 `目标达成` 标签显示正常。
- [ ] 今日页全部完成：不再出现完成按钮或补发入口。
- [ ] 日历页：当月日期、今日、连续、累计和选中日期详情可读。
- [ ] 设置页：通知关闭时展示原因和系统设置入口。
- [ ] 设置页：Claude Code / Codex 连接、断开可用。
- [ ] 小队页：未加入时可创建小队或输入 6 位码加入。
- [ ] 小队页：加入后可查看今日排行榜，Relay 不可用时不阻塞本地任务完成。

## 隐私与卸载

- [ ] hook bridge 写入的事件不包含 prompt。
- [ ] hook bridge 只丢弃 stdin，不解析、不输出、不上传 hook payload。
- [ ] Claude Code / Codex 断开时只删除 HealthyVibe 自己写入的 hook。
- [ ] Homebrew Cask uninstall preflight 只删除 HealthyVibe hook handler。
- [ ] `zap` 清理 `~/Library/Application Support/HealthyVibe`。
- [ ] 设置页隐私说明明确标注娱乐积分和非医学建议。

## 分发验证

- [x] `make package` 生成 release zip、sha256 和 cask。
- [x] `ruby -c dist/healthyvibe.rb` 通过。
- [x] 临时 Homebrew tap 中可以安装/卸载 cask。
- [x] 本地安装脚本可以从 zip 安装到指定目录。
- [x] 有 Developer ID 凭据时完成签名和 notarization。
