# HealthyVibe Distribution

日期：2026-05-19

## 目标

MVP 的分发口径是：用户可以通过 Homebrew Cask 或透明安装脚本完成 CLI 风格安装，安装后的配置和日常使用仍在菜单栏 GUI 中完成。

## Release 打包

本地生成 release app、zip、sha256 和本地 cask：

```bash
make package
```

输出：

```text
dist/HealthyVibe-0.1.0.zip
dist/HealthyVibe-0.1.0.zip.sha256
dist/healthyvibe.rb
```

`dist/` 不提交到仓库。

## 签名

有 Developer ID Application 证书时：

```bash
HEALTHYVIBE_SIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)" make package
```

脚本会使用 hardened runtime：

```text
codesign --options runtime --timestamp
```

无签名身份时，脚本会生成 unsigned 本地包，只用于开发验证。

## Notarization

先在本机 keychain 保存 notarytool profile：

```bash
xcrun notarytool store-credentials healthyvibe-notary
```

然后：

```bash
HEALTHYVIBE_SIGN_IDENTITY="Developer ID Application: Example, Inc. (TEAMID)" \
HEALTHYVIBE_NOTARY_PROFILE="healthyvibe-notary" \
make package
```

脚本会：

- 提交 zip 到 Apple notary service。
- 等待 notarization 结果。
- staple app。
- 重新生成最终 zip 和 sha256。

## Homebrew Cask

生成 GitHub Release URL 版 cask：

```bash
HEALTHYVIBE_RELEASE_URL="https://github.com/xfey/HealthyVibe/releases/download/v0.1.0/HealthyVibe-0.1.0.zip" make package
```

生成的 `dist/healthyvibe.rb` 包含：

- `app "HealthyVibe.app"`
- macOS 13+ 约束。
- uninstall 时退出 app。
- uninstall 前清理 HealthyVibe 写入的 Claude Code / Codex hook，不删除用户自己的 hook。
- `zap` 清理本地 HealthyVibe 数据。

Homebrew 5.1 起会拒绝直接安装任意路径 cask；本地验证需要放入临时 tap。

## 透明安装脚本

本地验证：

```bash
HEALTHYVIBE_ZIP_PATH="$PWD/dist/HealthyVibe-0.1.0.zip" \
HEALTHYVIBE_INSTALL_DIR="/tmp/HealthyVibeInstall" \
HEALTHYVIBE_SKIP_OPEN=1 \
./Scripts/install.sh
```

线上安装时可设置：

```bash
HEALTHYVIBE_ZIP_URL="https://github.com/xfey/HealthyVibe/releases/latest/download/HealthyVibe.zip" ./Scripts/install.sh
```

未来官网可以暴露为：

```bash
curl -fsSL https://healthyvibe.dev/install | sh
```

## 已验证

当前本地已验证：

```bash
make package
ruby -c dist/healthyvibe.rb
```

并使用临时 Homebrew tap、临时 `HOME` 和临时 `--appdir` 验证过：

```bash
brew install --cask healthyvibe/local/healthyvibe
brew uninstall --cask healthyvibe/local/healthyvibe
```

未执行真实发布 notarization，因为当前仓库未配置 Developer ID 证书和 Apple notary profile。
