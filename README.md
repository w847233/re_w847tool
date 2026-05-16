# 个人工具箱

一个以 Windows 桌面为优先目标的 Flutter 工具箱项目，聚合了日常记录、时间管理、网络诊断、手机协同与实用小工具，并在本地 SQLite 基础上提供加密 WebDAV 同步能力。

当前仓库保留了 Android、iOS、macOS、Linux 与 Windows 工程，但从代码实现和脚本配置来看，开发与交付重点仍是 Windows 桌面端，同时包含用于手机管理的 Android 伴随端。

## 项目定位

这个项目不是通用模板，而是一套已经落地的个人效率工具集合，核心特征包括：

- 本地优先：数据默认落地到本机 SQLite。
- 可同步：支持把本地快照加密后上传到 WebDAV。
- 中文体验优先：界面语言、日期格式和文案都以简体中文为主。
- Windows 能力增强：包含蓝牙音频、Android 伴随端协作、DNS 设置、NAT 打洞、系统控制、Windows 原生网络通道等能力。
- 混合实现：主界面使用 Flutter/Dart，`Steam 状态`工具内置 Python 侧车服务。

## 功能概览

### 记录

- `便签`：记录临时想法和常用信息。
- `记账`：记录收入、支出和备注。

### 任务与时间

- `待办`：管理待处理事项。
- `倒数日`：追踪重要日期。
- `番茄钟`：专注计时与完成记录。

### 网络

- `检测DNS泄露`：检测 DNS 出口、对比候选 DNS，并尝试写入系统设置。
- `NAT隧道打洞`：检测 NAT 类型，保存 UDP/TCP 转发规则，并支持应用启动后自动恢复已启用规则。

### 媒体

- `蓝牙音频转换`：将手机蓝牙音频转接到 Windows 当前默认播放设备。

### 手机协同

- `手机管理`：在 Windows 管理端和 Android 伴随端之间协作，支持蓝牙音频、媒体、通讯录、消息、通话记录、文件选择与传输、远程输入和诊断。

### 系统

- `系统控制`：提供 Windows 专属系统快捷操作，目前支持一键熄屏。

### 实用

- `单位换算`：长度、重量、温度换算。
- `密码生成`：本地生成临时密码。
- `Get Token`：采集凭证额度并汇总 token 使用情况。
- `Steam 状态`：管理 Steam 登录、自定义状态与 Rich Presence，并带有本地 Python 后端。

### 首页与设置

- `主页`：默认展示欢迎区、今日待办、最近便签、本月收支、倒数日、番茄钟统计、快捷工具等小组件。
- `设置`：包含个性化、关于、字体许可证、技术栈说明与同步说明等内容。

## 技术栈

- `Flutter`
- `Dart`
- `flutter_riverpod`
- `go_router`
- `Drift + SQLite`
- `path_provider`
- `http`
- `xml`
- `cryptography`
- `stun`

## 运行环境

### 必需

- `Flutter SDK`
- 可用于 Flutter Windows 构建的本机工具链
- 可执行 `flutter` 命令的终端环境

### 与部分功能相关的额外要求

- `Steam 状态`工具要求本机可用的 `Python 3` 解释器。
- 首次进入 `Steam 状态`工具页时，程序会释放内置后端脚本，创建虚拟环境，并尝试根据 `assets/steam_status_backend/requirements.txt` 自动安装依赖。
- `检测DNS泄露` 与部分网络能力涉及本机系统网络设置，实际效果受当前操作系统权限与运行环境限制。
- `NAT隧道打洞` 的 TCP 能力依赖 Windows 原生通道支持；如果当前运行环境未加载原生模块，界面会显示受限提示。
- `手机管理` 需要 Windows 管理端与 Android 伴随端共同工作；Android 端需要开启蓝牙，并授予蓝牙、通讯录、短信、通话记录等权限。
- `系统控制` 依赖 Windows 原生通道；一键熄屏只关闭显示器，不会锁屏、睡眠或关闭程序。

## 快速开始

### 1. 获取依赖

```powershell
flutter pub get
```

### 2. 启动 Windows 桌面应用

仓库提供了 Windows 启动脚本：

```powershell
.\run.bat
```

等价命令：

```powershell
flutter run -d windows
```

`run.bat` 会优先尝试使用 `C:\tmp\flutter\bin\flutter.bat`，如果不存在，则回退到环境变量中的 `flutter`。

### 2.1 以包身份启动 Windows Debug 版

部分 Windows 蓝牙、媒体和通话能力需要 MSIX/package identity。普通 `flutter run -d windows`
启动的是未打包 exe，系统可能拒绝 `bluetooth`、`globalMediaControl` 或
`phoneLineTransportManagement` 能力。需要用 Debug 二进制调试这些能力时，运行：

```powershell
.\run_debug_msix.bat
```

这个脚本会构建 Windows Debug 产物，只给
`build\windows\x64\runner\Debug\personal_toolbox.exe` 注入调试用 package identity，
创建并签名一个本机调试用 identity MSIX，再用
`Add-AppxPackage -ExternalLocation` 把包身份关联到 Debug 输出目录，最后启动同一份
Debug exe。源码中的 `windows\runner\runner.exe.manifest` 仍保持普通桌面 manifest，
不会把 debug identity 带进 Release 构建。

脚本会用 `.dart_tool\personal_toolbox_pub_get.sha256` 记录 `pubspec.yaml` 和
`pubspec.lock` 的依赖指纹；指纹变化或缺少 `.dart_tool\package_config.json` 时才执行
`flutter pub get`。依赖未变化时会使用 `flutter build windows --debug --no-pub`，
避免每次 Debug 包身份启动都重新解析依赖。需要强制刷新依赖时可运行：

```powershell
.\run_debug_msix.bat -ForcePubGet
```

首次运行时，脚本可能会弹出 UAC，用于把本机调试签名证书导入当前机器的
`TrustedPeople` 和 `Root` 证书存储；否则 Windows 会拒绝安装自签名 MSIX。
如果只想检查脚本到打包阶段、不要弹出 UAC，可以运行：

```powershell
.\run_debug_msix.bat -NoElevate
```

如果系统拒绝 restricted capability，可以先跳过通话管理能力验证：

```powershell
.\run_debug_msix.bat -SkipRestrictedCapabilities
```

### 3. 构建 Windows 发布包

```powershell
.\build.bat
```

等价命令：

```powershell
flutter build windows
```

构建产物默认位于：

```text
build\windows\x64\runner\Release
```

## 数据与同步

### 本地数据

- 主数据存储在应用支持目录下的 `personal_toolbox.sqlite`。
- 当前数据库表覆盖：
  - 应用设置
  - 便签
  - 待办
  - 账目
  - 倒数日
  - 番茄钟会话与设置
  - Steam 状态预设与历史

### WebDAV 同步

- 远端路径固定为 `personal-toolbox/state.v1.enc.json`。
- 同步前会先导出本地快照，再使用 `AES-256-GCM + PBKDF2-HMAC-SHA256` 进行加密。
- 冲突处理以记录更新时间为准，较新的数据覆盖较旧数据。
- `NAT隧道打洞`、`Get Token` 和 `Steam 状态` 工具中的可同步状态会参与同步。
- `Steam 状态`工具中的预设与历史会参与同步。
- `Steam` 账号凭证不会进入同步快照，只保存在本机。

### 不同步或偏本机能力的工具

从工具注册表可见，以下工具不参与同步：

- `检测DNS泄露`
- `蓝牙音频转换`
- `手机管理`
- `系统控制`
- `单位换算`
- `密码生成`

这类功能更偏向本机即时操作或临时结果，不属于跨设备状态同步范围。

## 目录结构

```text
lib/
  main.dart                    应用入口
  src/
    app_router.dart            路由配置
    features/                  页面与工具 UI
    tools/                     工具注册表
    data/                      Drift 数据库与 Provider
    sync/                      WebDAV 同步与加密
    bluetooth_audio/           蓝牙音频转接能力
    get_token/                 token 使用情况采集工具
    phone_manager/             手机管理与 Android 伴随端能力
    network/                   DNS / NAT 相关能力
    system_control/            Windows 系统控制能力
    steam_status/              Steam 状态工具与侧车控制
    home/                      主页布局与小组件定义
android/                      Android 伴随端入口与权限声明
assets/
  fonts/                       HarmonyOS Sans SC 字体与许可证
  steam_status_backend/        内置 Python 侧车脚本
test/                          关键业务与界面测试
windows/                       Windows Runner 与原生网络、蓝牙、手机和系统通道
run.bat                        Windows 开发启动脚本
run_debug_msix.bat             Windows Debug 包身份启动脚本
build.bat                      Windows 发布构建脚本
```

## 开发说明

### 代码组织

- 应用入口在 `lib/main.dart`。
- 路由配置在 `lib/src/app_router.dart`。
- 工具清单定义在 `lib/src/tools/tool_registry.dart`。
- 页面主体集中在 `lib/src/features/tool_pages.dart`、`lib/src/features/home_page.dart`、`lib/src/features/settings_page.dart`。
- 本地数据库定义在 `lib/src/data/app_database.dart`。

### 生成代码

项目使用 `Drift`，如数据库定义有变更，需要重新生成代码：

```powershell
dart run build_runner build --delete-conflicting-outputs
```

### 测试

仓库当前已经包含一批针对关键能力的测试，例如：

- `test/widget_test.dart`
- `test/database_sync_test.dart`
- `test/sync_crypto_service_test.dart`

可按需执行：

```powershell
flutter test
```

## 已知前提与注意事项

- `Steam 状态`首次启动可能较慢，因为会准备 Python 运行时与依赖。
- `NAT隧道打洞`、`DNS` 设置这类功能依赖真实本机网络环境，在测试环境与 CI 中未必能完整复现。
- 项目目前的 `pubspec.yaml` 描述字段仍是默认值 `A new Flutter project.`；如果后续需要对外发布，建议一并更新元信息。

## 许可与资源

- 项目内置 `HarmonyOS Sans SC` 字体资源。
- 字体许可证文件位于 `assets/fonts/harmony_os_sans_sc/LICENSE.txt`。
