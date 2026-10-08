# Coremail for NixOS

将 Coremail 官方 Ubuntu beta deb 包重新打包为 Nix 软件包，用于华南理工邮箱等
Coremail 邮件服务。当前版本为 **4.2.1-1427**，仅支持 **x86_64-linux**。
这是官方通用客户端，不是学校定制客户端。

## 构建与运行

```bash
cd /home/x12w/projects/nix/coremail
nix build
nix run
```

构建产物为 `result/`，也可执行 `./result/bin/coremail`（别名 `cmclient`）。
安装到用户环境后，会出现 Coremail 桌面启动项和邮件图标：

```bash
nix profile add /home/x12w/projects/nix/coremail
```

独立 flake 已允许此非自由软件；`flake.lock` 固定 nixpkgs 版本。

## 在 NixOS / Home Manager 中使用

普通配置可直接调用：

```nix
{ pkgs, ... }:
{
  nixpkgs.config.allowUnfree = true;
  environment.systemPackages = [
    (pkgs.callPackage /home/x12w/projects/nix/coremail/package.nix { })
  ];
}
```

Home Manager 将 `environment.systemPackages` 换成 `home.packages`。
这个 flake 也提供 `packages.x86_64-linux.coremail` 和 `overlays.default`。

## 来源与更新

构建直接使用以下链接，通过 `fetchurl` 下载，无需在项目中放置 deb 文件：

<https://lunkr.coremail.cn/dl?p=mail&arch_type=amd64.ubuntu.deb&customer_type=beta>

本次该入口重定向到：

<https://lunkrcdn.icoremail.net/cab/publish/lunkr4mail/cn.coremail.cmclient-ubuntu_4.2.1-1427_amd64.ubuntu.deb>

固定 SHA-256：

```text
sha256-QdMkudYnu7FthrqXoT7cL3+w90mHh4R4Gv5X6M+fGXs=
```

这是滚动 beta 下载入口；上游发布新包后，旧定义会报告 hash mismatch。
更新时先检查新 deb 的版本，再同时修改 `package.nix` 中的 `version` 和 `hash`：

```bash
nix store prefetch-file --json \
  'https://lunkr.coremail.cn/dl?p=mail&arch_type=amd64.ubuntu.deb&customer_type=beta'
```

## 兼容处理

- 用 `autoPatchelfHook` 修复可执行文件和随包库的 ELF 解释器、依赖路径。
- 将主程序的 WebKitGTK / JavaScriptCore 4.0 依赖改为 nixpkgs 提供的 4.1；
  该二进制未直接引用 libsoup API。
- 保留上游 CEF、资源和语言文件；用 GTK wrapper 配置 GSettings、GIO 等运行环境。
- 启动器固定 `GDK_BACKEND=x11`：上游界面直接调用 X11 API，原生 Wayland
  会出现 `GdkWaylandScreen` 转换错误并崩溃。Wayland 桌面需要启用 XWayland。
- 修正桌面文件中的 `/opt` 路径，保留 `mailto:` 和 `.eml` 文件关联声明。
- 不运行 Debian 安装/卸载脚本。升级通过更新 Nix 定义并重新构建完成，
  不使用客户端内置更新器修改只读 Nix store。

首次运行后，在客户端中添加自己的邮箱账号。打包过程不包含账号或密码。

## 已验证范围

- `nix build`、`nix flake check` 和 overlay 求值通过。
- 包内 11 个 ELF 文件的 `ldd -r` 检查无缺库、无未解析符号。
- 桌面文件通过 `desktop-file-validate`（上游名称与描述相同的提示保留）。
- Xvfb / X11 下可显示中文主窗口和新增邮箱账号对话框。
- 实际 KDE Wayland 会话下通过 XWayland 显示主窗口和新增邮箱账号对话框；
  即使会话设置 `GDK_BACKEND=wayland`，启动器仍会使用 `x11`。

未验证真实账号登录和收发邮件。原生 Wayland 不受此版本支持；
Wayland 会话下启动器会自动使用 XWayland。
