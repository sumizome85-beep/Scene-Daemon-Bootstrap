# Scene Daemon Bootstrap

在 `BOOT_COMPLETED` 阶段为 Scene 完成守护进程的引导装载：把 `scene-daemon` 与 BusyBox
工具链配置到 `/data/local/tmp`，派生常驻进程，并为 `com.omarea.vtools` 解除后台执行管控，
使 Scene 的核心服务在重启后自动恢复可用状态。全程经 ADB 完成，无需 root。

- id：`scene_daemon_bootstrap`
- author：Sumizome
- version：1.1.4（versionCode 15）
- 执行时机：`BOOT_COMPLETED` / `late_start`（异步、非阻塞）

## 依赖与归属

**本插件必须配合 [AxManager](https://github.com/fahrez182/AxManager) 使用。**
AxManager 是 fahrez182 的独立项目，负责提供本插件运行所需的 ADB 执行环境
（无线调试 / ADB / ROOT 任一激活方式均可）。没有已激活的 ADB 环境，本插件无法下发任何命令，
状态面板会直接说明缺少什么。

本插件为**非官方第三方模块**，与 Scene（`com.omarea.vtools`）及其作者、
与 AxManager 项目均无隶属、背书或合作关系。相关名称、商标与权利归各自所有者所有。

## 前置条件

1. 已安装 **Scene**（`com.omarea.vtools`），且以下载荷存在：
   - `/storage/emulated/0/Android/data/com.omarea.vtools/daemon`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/toolkit/busybox`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/binder.so`（可选，缺失自动跳过）
2. 已安装并激活 **AxManager**，ADB 环境处于可用状态。
3. 若外部存储在此阶段尚未挂载，脚本最多轮询等待 30 秒。

## 下载与安装

### 下载

**方式一：直接下载安装包（推荐）**

到仓库右侧的 **Releases** 页面，下载最新版的 `scene_daemon_bootstrap-1.1.4.zip`：

```
https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap/releases
```

**方式二：取源码后自行打包**

```bash
git clone https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap.git
cd Scene-Daemon-Bootstrap
zip -r ../scene_daemon_bootstrap-1.1.4.zip . -x '.*' '*/.*'
```

手机上没有 git 环境时，可用 **Termux** 完成同一件事（需先执行 `termux-setup-storage`
并授权访问存储）：

```bash
pkg update && pkg install git -y
git clone https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap.git
```

### 安装

AxManager → 插件 → 从本地安装 → 选择该 zip → 重启。

模块同时提供标准 `META-INF`，因此也可以用 Magisk / KernelSU / APatch 刷入，
安装脚本会自动识别插件目录与 `/data/adb/modules` 两种落点。

## 功能

### 主页

顶部状态卡以三态给出整体结论，下方四项检测各自独立出结论，因此"哪一项不对"是明说的，
不需要自己在明细里比对：

| 状态 | 含义 |
| --- | --- |
| 绿色 · 守护进程已就绪 | 载荷已装载且进程常驻 |
| 黄色 · 部分就绪 | 有东西起来了但没齐，会点名缺什么（如 `Not complete: busybox`） |
| 红色 · 不可用 | Scene 未安装，或没有可用的执行环境 |

四项检测：目标应用、已装载载荷、守护进程、BusyBox 小程序（完整 / 数量偏少 / 链接缺失）。

### 操作页

重新装载、装载载荷、启动守护进程、应用保活策略、读取运行时日志、环境自检、
清理运行文件、终止守护进程、清除载荷，以及实时执行控制台。

- 会改变设备状态的动作执行完会自动复核；未达成目标最多再试两轮，无需重复点击
- 执行期间所有按钮锁定，避免中途插入动作导致面板显示操作前的状态
- 终止与清除额外做多轮深度检测，能识别出"已被 Scene 自行拉起"和"确实没停掉"的区别

### ADB 页

直接执行 ADB 命令并查看输出。没有可用的 ADB 环境时会明确说明原因并禁用执行，
不让一个跑不出结果的输入框摆在那里。

### 设置页

- **通用**：界面语言（19 种）、主题（深色 / 浅色 / 跟随系统）
- **行为**：开机自动装载、装载后唤起 Scene
- **实验性**：看门狗自动拉起、详细日志、强制重启守护进程、重置保活策略、导出运行状态
- **模块**：版本、构建号、作者、模块 id、模块目录
- **项目**：GitHub 仓库、Telegram
- **危险操作**：重置全部数据（恢复出厂默认，不碰载荷与 Scene 本身）
- **注意事项**

设置写入 `/data/local/tmp/.scene_daemon_bootstrap.conf`，更新模块不会丢弃，
开关会回显校验——命令没写成功就弹回原位，不会出现"显示关了、实际还在跑"。

### 自动装载与暂停

开机与模块激活时自动完成装载与拉起。但执行过「终止守护进程」或「清除载荷」之后，
自动装载会被暂停——不把刚移除的东西又装回去。手动点一次「重新装载」清除暂停标记，
此后恢复自动。

## 文件清单

| 路径 | 用途 |
| --- | --- |
| `module.prop` | 模块元数据（id / name / version / versionCode / author / description / axeronPlugin / banner） |
| `service.sh` | `late_start` 阶段执行的引导入口 |
| `action.sh` | Action 入口，按需触发一次完整引导 |
| `uninstall.sh` | 卸载例程：终止进程、清除载荷、回滚策略 |
| `config.sh` | 运算符覆盖项（如 `port`） |
| `system/functions/mainlib.sh` | 共享库：载荷装载、进程监管、策略下发、状态导出 |
| `system/bin/scene-bootstrap` | CLI 入口，供 WebUI 调用 |
| `system/bin/scene-bootstrap-bg` | 后台执行包装：立即返回并写入进度文件，供页面轮询 |
| `banner.png` / `cover.png` / `icon.png` | 卡片封面与图标 |
| `webroot/` | WebUI：四页状态面板与运维入口 |
| `META-INF/` | 标准 recovery 安装脚本，支持 Magisk / KernelSU / APatch |

## CLI

`system/bin/scene-bootstrap` 由 WebUI 调用，也可在 ADB shell 中直接使用：

```
scene-bootstrap bootstrap      # 装载载荷、派生守护进程、下发策略
scene-bootstrap activate       # 同上，并在完成后唤起 Scene
scene-bootstrap redeploy       # 重新装载
scene-bootstrap provision      # 仅装载载荷
scene-bootstrap start          # 仅派生守护进程
scene-bootstrap stop           # 终止守护进程
scene-bootstrap status         # 输出机器可读状态块
scene-bootstrap selfcheck      # 输出环境诊断报告
scene-bootstrap policy         # 仅下发后台管控策略
scene-bootstrap purge          # 终止进程、清除载荷、回滚策略
scene-bootstrap clean          # 清理运行文件（日志、进度、缓存）
scene-bootstrap device         # 输出设备信息
scene-bootstrap getconf        # 读取全部设置
scene-bootstrap setconf K V    # 写入一项设置
scene-bootstrap reset          # 恢复全部默认设置
scene-bootstrap force-restart  # 强制重启守护进程（实验性）
scene-bootstrap reset-policy   # 重置保活策略（实验性）
scene-bootstrap dump-state     # 导出运行状态（实验性）
scene-bootstrap watchdog       # 前台运行看门狗循环（实验性）
```

## 设置项

| 键 | 默认 | 说明 |
| --- | --- | --- |
| `AUTO_START` | 1 | 开机自动装载并拉起；置 0 则本次开机跳过 |
| `LAUNCH_SCENE` | 1 | 装载完成后唤起 Scene 界面 |
| `PAYLOAD_TIMEOUT` | 30 | 等待上游载荷出现的秒数 |
| `START_TIMEOUT` | 6 | 等待守护进程常驻的秒数 |
| `LIVE_MS` | 1000 | 轮询间隔（毫秒） |
| `WATCHDOG` | 0 | 实验性：每 5 秒检查并在守护进程消失时重新拉起 |
| `VERBOSE` | 0 | 实验性：把每条命令及其退出码记入日志 |

`config.sh` 中另有 `SDB_LAUNCH_FLAG`（默认 `0x10000000`）与 `SDB_PAYLOAD_TIMEOUT` 等覆盖项。

## 执行流程

1. 将 `daemon` 装载为 `/data/local/tmp/scene-daemon` 并置 `chmod 777`
2. 将 `busybox` 装载至 `/data/local/tmp/toolkit/`，展开全部 applet 符号链接
   （跳过 `sh`、`busybox`、`shell`、`swapon`、`swapoff`、`mkswap`）
3. 装载 `binder.so`
4. 以 `nohup` 派生 daemon 进程，并校验常驻状态
5. 下发策略：
   - `cmd package compile -m speed`
   - `dumpsys deviceidle whitelist +`
   - appops `RUN_IN_BACKGROUND` / `RUN_ANY_IN_BACKGROUND` allow
   - `am set-standby-bucket active`、`am set-inactive false`
   - `am set-bg-restriction-level unrestricted`
   - `am set-foreground-service-delegate start`、`am unfreeze --sticky`

## 运维说明

- 全部操作在 ADB shell（UID 2000）权限下完成，不需要 root。
- 流程具备幂等性：守护进程常驻时不会重复派生。
- 终止或清除后自动装载会暂停，需手动重新装载才会恢复，见上文"自动装载与暂停"。
- 清除载荷只删除自己部署的文件（`/data/local/tmp/toolkit` 下仅移除 applet 符号链接，
  目录非空则保留），并且不会杀掉承载自身的进程链——这是避免出现"清完需要重新授权"的关键。
- 若安装器报告版本不匹配，调低 `module.prop` 中的 `axeronPlugin` 数值。
- 运行时日志写入 `/data/local/tmp/scene_daemon_bootstrap.log`。

## 链接

- 仓库：<https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap>
- 联系作者：<https://t.me/MR_Sumizome>