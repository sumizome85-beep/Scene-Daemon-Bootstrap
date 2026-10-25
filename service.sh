#!/system/bin/sh
# Scene Daemon Bootstrap
# ADB plugin - late_start service script
# Author: Sumizome
#
# Trigger : BOOT_COMPLETED, late_start stage (asynchronous, non-blocking)
# Purpose : Provision the scene-daemon binary and the BusyBox toolkit into
#           /data/local/tmp, spawn the daemon, and relax the background
#           execution policy of com.omarea.vtools so the service survives
#           across reboots.

MODDIR=${0%/*}
export SDB_MODDIR="$MODDIR"

# Module activation (boot / plugin enable) provisions and spawns in the
# background. Only an explicit run from the WebUI or the action button brings
# the Scene UI forward, so enabling the plugin never yanks the app on screen.
export SDB_LAUNCH_SCENE=0

# Marks this run as automatic, so the suspension set by a deliberate
# terminate/purge is honoured instead of being provisioned straight back.
export SDB_AUTO_RUN=1

# shellcheck source=/dev/null
. "$MODDIR/system/functions/mainlib.sh"

if [ -f "$MODDIR/config.sh" ]; then
  . "$MODDIR/config.sh"
fi

# late_start runs before the package manager and /data/local/tmp are
# guaranteed to be up. Waiting here is what makes a background activation
# actually succeed instead of aborting on the first check.
await_env

bootstrap

# Detect at activation time, outside the WebUI, and leave the result on disk.
# Opening the plugin page then reads this file instead of probing the device
# while the page is still laying out.
write_status_cache
