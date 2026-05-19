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

## 当前架构

```text
Sources/HealthyVibe/
  App/              AppDelegate、菜单栏控制器、全局状态
  Design/           颜色、间距、按钮、进度条等基础设计系统
  Infrastructure/   本地目录、日志、数据库接口预留
  Models/           轻量 UI/domain model
  Views/            Popover 三页视图
Resources/
  Info.plist        app bundle 元信息，包含 LSUIElement
Scripts/
  build_app_bundle.sh
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
