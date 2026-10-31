# Scene Daemon Bootstrap

Boot-time provisioning and supervision of the Scene daemon (`com.omarea.vtools`) over ADB.

Deploys `scene-daemon` and the BusyBox toolkit into `/data/local/tmp`, spawns the resident
process, and relaxes the background execution policy of `com.omarea.vtools` — so Scene's core
service comes back by itself after a reboot. Everything runs over ADB; no root required.

- id: `scene_daemon_bootstrap`
- author: Sumizome
- version: 1.1.4 (versionCode 15)
- trigger: `BOOT_COMPLETED` / `late_start` (asynchronous, non-blocking)

## Dependencies and attribution

**This module requires [AxManager](https://github.com/fahrez182/AxManager).**
AxManager is an independent project by fahrez182 that provides the ADB execution environment
this module runs in (wireless debugging, ADB, or ROOT activation all work). Without an active
ADB environment the module cannot issue any command, and the status panel says exactly what
is missing instead of failing silently.

This is an **unofficial third-party module**. It is not affiliated with, endorsed by, or
connected to Scene (`com.omarea.vtools`) or its author, nor to the AxManager project.
All names, trademarks and rights belong to their respective owners.

## Prerequisites

1. **Scene** (`com.omarea.vtools`) installed, with these payloads present:
   - `/storage/emulated/0/Android/data/com.omarea.vtools/daemon`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/toolkit/busybox`
   - `/storage/emulated/0/Android/data/com.omarea.vtools/binder.so` (optional; skipped when absent)
2. **AxManager** installed and activated, with a working ADB environment.
3. If external storage is not mounted yet at this stage, the script polls for up to 30 seconds.

## Download and installation

### Download

**Option 1 — the release package (recommended)**

Open **Releases** on the right-hand side of the repository and download
`scene_daemon_bootstrap-1.1.4.zip`:

```
https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap/releases
```

**Option 2 — build it from source**

```bash
git clone https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap.git
cd Scene-Daemon-Bootstrap
zip -r ../scene_daemon_bootstrap-1.1.4.zip . -x '.*' '*/.*'
```

On a phone without a git environment, **Termux** does the same
(run `termux-setup-storage` first and grant storage access):

```bash
pkg update && pkg install git -y
git clone https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap.git
```

### Install

AxManager → Plugins → Install from storage → pick the zip → reboot.

The module also ships a standard `META-INF`, so it can be flashed with Magisk, KernelSU or
APatch. The installer detects both layouts — the plugin directory and `/data/adb/modules`.

## Features

### Home

The status card gives one overall verdict in three states, and the four probes beneath it
each reach their own conclusion — so what is wrong is stated, not left for you to work out
by comparing rows.

| State | Meaning |
| --- | --- |
| Green · Daemon active | payload provisioned and process resident |
| Yellow · Partially provisioned | something came up but not all of it; names what is missing (e.g. `Not complete: busybox`) |
| Red · Not available | Scene not installed, or no usable environment to provision through |

Four probes: target application, provisioned payload, daemon process, and BusyBox applets
(complete / partial set / links missing).

### Actions

Re-provision, provision payload, start daemon, apply policy, read runtime log, environment
self-check, clean workspace, terminate daemon, purge payload — plus a live execution console.

- Anything that changes device state is verified when it finishes, and retried up to two more
  times if the desired state was not observed. No second tap needed.
- Every button is locked while a command runs, so a second action cannot land mid-flight and
  leave the panel showing pre-action values.
- Terminate and purge additionally run a multi-round deep check that can tell the difference
  between "Scene respawned it" and "it genuinely did not stop".

### ADB

Run ADB commands directly and read their output. With no usable ADB environment the reason
is stated and execution is disabled — an input box that cannot produce a result is not
offered.

### Settings

- **General** — interface language (19 languages), theme (dark / light / follow system)
- **Behaviour** — provision on boot, launch Scene after provisioning
- **Experimental** — watchdog auto-respawn, verbose logging, force restart daemon, reset
  keep-alive policy, dump runtime state
- **Module** — version, build, author, module id, module directory
- **Project** — GitHub repository, Telegram
- **Danger zone** — reset everything (restores shipped defaults; leaves the payload and Scene alone)
- **Notes**

Settings are stored in `/data/local/tmp/.scene_daemon_bootstrap.conf`, so updating the module
does not discard them. Each switch echoes back what was written and snaps back if the write
did not land — no switch ever shows a state the device is not in.

### Automatic provisioning and suspension

Provisioning and spawn happen automatically at boot and on activation. After **Terminate
daemon** or **Purge payload**, automatic provisioning is suspended — what you just removed is
not quietly put back. One manual **Re-provision** clears the suspension and restores
automatic behaviour from then on.

## File manifest

| Path | Purpose |
| --- | --- |
| `module.prop` | module metadata (id / name / version / versionCode / author / description / axeronPlugin / banner) |
| `service.sh` | bootstrap entry run at `late_start` |
| `action.sh` | action entry; runs one full bootstrap on demand |
| `uninstall.sh` | uninstall routine: terminate, purge, revert policy |
| `config.sh` | operator overrides (for example `port`) |
| `system/functions/mainlib.sh` | shared library: provisioning, process supervision, policy, status export |
| `system/bin/scene-bootstrap` | CLI entry called by the WebUI |
| `system/bin/scene-bootstrap-bg` | background wrapper: returns at once and writes a progress file for the page to poll |
| `banner.png` / `cover.png` / `icon.png` | card artwork and icons |
| `webroot/` | WebUI: four-panel status page and operations |
| `META-INF/` | standard recovery scripts; Magisk / KernelSU / APatch compatible |

## CLI

`system/bin/scene-bootstrap` drives the WebUI and can be used directly from an ADB shell:

```
scene-bootstrap bootstrap      # provision payload, spawn daemon, apply policy
scene-bootstrap activate       # same, then bring Scene to the foreground
scene-bootstrap redeploy       # re-provision
scene-bootstrap provision      # provision payload only
scene-bootstrap start          # spawn the daemon only
scene-bootstrap stop           # terminate the daemon
scene-bootstrap status         # machine-readable status block
scene-bootstrap selfcheck      # environment diagnostic report
scene-bootstrap policy         # apply the background policy only
scene-bootstrap purge          # terminate, purge payload, revert policy
scene-bootstrap clean          # remove runtime files (log, progress, cache)
scene-bootstrap device         # device information
scene-bootstrap getconf        # print every setting
scene-bootstrap setconf K V    # write one setting
scene-bootstrap reset          # restore all defaults
scene-bootstrap force-restart  # force restart the daemon (experimental)
scene-bootstrap reset-policy   # reset the keep-alive policy (experimental)
scene-bootstrap dump-state     # dump runtime state (experimental)
scene-bootstrap watchdog       # run the watchdog loop in the foreground (experimental)
```

## Settings reference

| Key | Default | Meaning |
| --- | --- | --- |
| `AUTO_START` | 1 | provision and spawn at boot; 0 skips this boot |
| `LAUNCH_SCENE` | 1 | bring Scene to the foreground once provisioning finishes |
| `PAYLOAD_TIMEOUT` | 30 | seconds to wait for the upstream payload |
| `START_TIMEOUT` | 6 | seconds to wait for the daemon to become resident |
| `LIVE_MS` | 1000 | polling interval in milliseconds |
| `WATCHDOG` | 0 | experimental: check every 5s and respawn if the daemon dies |
| `VERBOSE` | 0 | experimental: log every command with its exit code |

`config.sh` additionally carries `SDB_LAUNCH_FLAG` (default `0x10000000`) and
`SDB_PAYLOAD_TIMEOUT` among other overrides.

## Execution flow

1. Deploy `daemon` as `/data/local/tmp/scene-daemon` and `chmod 777`
2. Deploy `busybox` to `/data/local/tmp/toolkit/` and expand every applet symlink
   (skipping `sh`, `busybox`, `shell`, `swapon`, `swapoff`, `mkswap`)
3. Deploy `binder.so`
4. Spawn the daemon with `nohup` and confirm it is resident
5. Apply the policy:
   - `cmd package compile -m speed`
   - `dumpsys deviceidle whitelist +`
   - appops `RUN_IN_BACKGROUND` / `RUN_ANY_IN_BACKGROUND` allow
   - `am set-standby-bucket active`, `am set-inactive false`
   - `am set-bg-restriction-level unrestricted`
   - `am set-foreground-service-delegate start`, `am unfreeze --sticky`

## Operational notes

- Everything runs as ADB shell (UID 2000). Root is not required.
- The routine is idempotent: a resident daemon is not spawned again.
- Automatic provisioning is suspended after a terminate or purge; see
  "Automatic provisioning and suspension" above.
- Purge removes only what this module deployed. Under `/data/local/tmp/toolkit` it deletes
  applet symlinks and keeps the directory when anything else is still in it, and it never
  signals the process chain it is itself running under — that is what keeps a purge from
  dropping the ADB session and forcing re-authorisation.
- If the installer reports a version mismatch, lower the `axeronPlugin` value in `module.prop`.
- Runtime log: `/data/local/tmp/scene_daemon_bootstrap.log`.

## Links

- Repository: <https://github.com/sumizome85-beep/Scene-Daemon-Bootstrap>
- Contact the author: <https://t.me/MR_Sumizome>