# Scene Daemon Bootstrap

在 BOOT_COMPLETED 阶段为 Scene 完成守护进程的引导装载：将 `scene-daemon` 与 `busybox`
工具链配置到 `/data/local/tmp`，派生常驻进程，并为 `com.omarea.vtools` 解除后台执行管控，
使 Scene 的核心服务在重启后自动恢复可用状态。全程经 ADB 完成。

- id: `scene_daemon_bootstrap`
- author: Sumizome
- version: 1.1.4 (versionCode 15)
- 更新日期: 2026-10-25 (ISO 8601)
- 执行时机：BOOT_COMPLETED / late_start（异步、非阻塞），由插件宿主调度

## 前置条件

1. 已安装 Scene (`com.omarea.vtools`)，且以下载荷存在：
   - `/storage/emulated/0/Android/data/com.omarea.vtools/daemon`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/toolkit/busybox`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/binder.so`（可选，缺失自动跳过）
2. 插件宿主已通过无线调试 / ADB / ROOT 任一方式激活。

## 依赖与归属

本插件运行于宿主提供的 ADB 环境之上，为非官方第三方模块，与宿主项目无从属、
背书或合作关系。相关权利与商标归各自所有者所有。
3. 若外部存储在此阶段尚未挂载，脚本最多轮询等待 30 秒。

## 安装

插件宿主 → 插件 → 从本地安装 → 选择本 zip → 重启。

## 文件清单

| 路径 | 用途 |
| --- | --- |
| `module.prop` | 插件元数据（id / name / version / versionCode / author / description / axeronPlugin / banner） |
| `service.sh` | late_start 阶段执行的引导入口 |
| `action.sh` | Action 入口，按需触发一次完整引导 |
| `uninstall.sh` | 卸载例程：终止进程、清除载荷、回滚策略 |
| `config.sh` | 运算符覆盖项（如 `port`） |
| `system/functions/mainlib.sh` | 共享库：载荷装载、进程监管、策略下发、状态导出 |
| `system/bin/scene-bootstrap` | CLI 入口，供 WebUI 调用（宿主会将此目录注入 PATH） |
| `banner.png` | 插件卡片封面（`module.prop` 的 `banner` 字段引用） |
| `webroot/` | WebUI：运行时状态面板与运维操作入口 |

## 执行流程

1. 将 `daemon` 装载为 `/data/local/tmp/scene-daemon` 并置 `chmod 777`
2. 将 `busybox` 装载至 `/data/local/tmp/toolkit/`，展开全部 applet 符号链接
   （跳过 `sh`、`busybox`、`shell`、`swapon`、`swapoff`、`mkswap`）
3. 装载 `binder.so`
4. 以 `nohup` 派生 daemon 进程，并用 `pgrep` 校验常驻状态（输出 `Scene-Daemon OK` / `Scene-Daemon Fail`）
5. 唤起 Scene 启动页，随后下发策略：
   - `cmd package compile -m speed`
   - `dumpsys deviceidle whitelist +`
   - appops `RUN_IN_BACKGROUND` / `RUN_ANY_IN_BACKGROUND` allow
   - `am set-standby-bucket active`、`am set-inactive false`
   - `am set-bg-restriction-level unrestricted`
   - `am set-foreground-service-delegate start`、`am unfreeze --sticky`

## CLI

`system/bin/scene-bootstrap` 在 WebUI 下发命令时可直接使用（宿主会前置
`export PATH=<module>/system/bin:$PATH`）：

```
scene-bootstrap bootstrap    # 装载载荷、派生守护进程、下发策略
scene-bootstrap start        # 仅派生守护进程
scene-bootstrap stop         # 终止守护进程
scene-bootstrap status       # 输出机器可读状态块
scene-bootstrap selfcheck    # 输出环境诊断报告
scene-bootstrap policy       # 仅下发后台管控策略
scene-bootstrap purge        # 终止进程、清除载荷、回滚策略
```

## WebUI

打开插件页的 WebUI 入口时**不会下发任何命令**：状态面板保持空闲，直至显式点击
「Query Status」或执行某个操作。所有命令均经 `ksu.exec` / `Axeron.exec` 桥接下发。

状态面板字段：`Scene Package`、`Daemon`（含 pid）、`Payload`、`Applets`。

## 配置开关（config.sh）

| 变量 | 默认 | 说明 |
| --- | --- | --- |
| `SDB_PAYLOAD_TIMEOUT` | 30 | 等待上游载荷出现的秒数 |
| `SDB_START_TIMEOUT` | 6 | 等待守护进程常驻的秒数 |
| `SDB_LAUNCH_SCENE` | 1 | 是否唤起 Scene 界面；置 0 则只装载与拉起，不跳转 |
| `SDB_LAUNCH_FLAG` | 0x10000000 | 唤起时使用的 Activity flag；原值 0x10008000 含 CLEAR_TASK，会导致跳转两次 |

## 激活方式

| 触发方式 | 行为 |
| --- | --- |
| 模块启用 / 开机（`service.sh`） | 后台装载并拉起，不显示 Scene 界面 |
| WebUI 运行按钮、`action.sh` | 完成后唤起 Scene 界面 |

## 运行时日志

输出写入 `/data/local/tmp/scene_daemon_bootstrap.log`；亦可在插件页触发 Action 获取实时输出。

## 运维说明

- 全部操作均在 ADB shell (UID 2000) 权限下完成。
- 流程具备幂等性：daemon 处于常驻态时不会重复派生。
- 若安装器报告版本不匹配，调低 `module.prop` 中的 `axeronPlugin` 数值。
- 卡片上的 Action 按钮会执行完整引导（含唤起 Scene 启动页）；WebUI 打开时不执行任何命令。

## 关于封面

宿主通过 `module.prop` 的 `banner` 字段解析插件卡片封面：
以 `http` 开头则作为远程 URL，否则视为插件目录下的相对文件名，经文件服务读取字节。
本模块因此采用 `banner=banner.png`，并将图片置于模块根目录。

卡片渲染时封面作为背景绘制，叠加 `alpha = 0.18` 与竖向渐变遮罩，故呈现为淡色调背景层而非整幅图，属预期表现。

WebUI 中封面优先加载 `webroot/cover.png`，加载失败时回退至内嵌的 base64 数据。

封面图像仅经过压缩噪点抑制与边缘重建，构图、配色与元素均未改动，无任何水印。