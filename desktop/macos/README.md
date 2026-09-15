# 日序 Mac 客户端

使用 AppKit 和系统 WebKit 的轻量桌面客户端，连接现有日序网站与云端数据库。客户端有独立 Dock 图标、窗口、登录存储、前进 / 返回 / 刷新按钮和常用编辑快捷键。

## 安装与使用

- 下载 [Dayweave 1.0.0 通用安装包](https://github.com/MOONLZH/dayweave-planner/raw/refs/heads/main/downloads/macos/Dayweave-1.0.0-universal.dmg)。
- 支持 macOS 14 或更高版本；安装包包含 arm64 和 x86_64 两种架构。
- 使用系统 WebKit；网站的 Tailwind CSS 4 需要较新的 Safari 引擎，因此客户端将最低系统版本设为 macOS 14。参见 [Tailwind 浏览器兼容说明](https://tailwindcss.com/docs/compatibility)。
- 打开 DMG，将 `日序.app` 拖入 `Applications`，再从“应用程序”打开。
- 首次打开需要登录有访问权限的 ChatGPT 账号。当前默认站点为私人实例，安装客户端不会授予其他账号访问权限。
- 需要网络连接；项目、任务、备注继续使用云端数据库，不是离线版本。
- WebKit 登录状态与 Safari、Chrome 独立，由系统持久化保存；不读取其他浏览器的 Cookie。

## 构建

在安装了 Apple Command Line Tools 的 Mac 上执行：

```sh
bash desktop/macos/build.sh
```

无需安装 npm 依赖。生成的 `.app`、`.dmg`、`.zip` 和 SHA-256 校验文件位于 `releases/macos/`。该目录不纳入 Git。

源文件说明：

- `Dayweave.swift`：窗口、菜单、导航、持久登录、网页对话框与错误提示。
- `Info.plist`：应用标识、版本和系统要求。
- `MakeIcon.swift`：从本项目图标图形生成多分辨率 macOS 图标。
- `build.sh`：编译两个架构、合并、签名与制作安装镜像。

修改 `Dayweave.swift` 中的 `homeURL` 可以连接自行部署的站点。使用自己的站点仍需配置正确的后端认证。

## 签名与分发

默认构建使用 ad-hoc 签名，未经过 Apple 公证。网络下载后，macOS 可能阻止首次打开。安装包中的 `安装说明.txt` 会注明这一状态。

正式分发可设置 `DAYWEAVE_SIGNING_IDENTITY` 为钥匙串中已有的 Developer ID Application 身份。脚本会启用 Hardened Runtime 和时间戳。随后由证书持有人使用 Apple 的 `notarytool` 提交公证并装订票据；该脚本不会创建凭据、变更钥匙串或自动提交公证。

## 安全边界

客户端不向网页注入脚本、不暴露文件系统或 Shell 接口，也不忽略 TLS 证书错误。登录流程可在 HTTPS 域名之间跳转，实际域名始终显示在原生工具栏。应用仅载入站点；项目数据的账户隔离和保存规则仍由站点服务端负责。

## 验证范围

已在 Apple 芯片、macOS 15 上检查启动、原生窗口、项目界面与 ChatGPT 登录页。安装镜像经过校验和、应用签名结构及双架构检查。Intel 版本尚未实机验证；首次账号登录和登录后的云端同步需要使用者完成确认。
