#!/system/bin/sh
# Scene Daemon Bootstrap
# Action entry point: invoke the provisioning routine on demand.
MODDIR=${0%/*}
export SDB_MODDIR="$MODDIR"

# Explicit run from the plugin card: launch Scene once the daemon is OK, and
# never bounce back. Repeat launches inside the cooldown window are suppressed
# by mainlib so a double tap cannot throw the user out of Scene.
export SDB_LAUNCH_FORCE=1

# Cooldown is only here to swallow a double tap; a manual run must be able to
# hand over to Scene every time it reports OK, so it stays very short. The
# longer default would suppress legitimate taps for two minutes.
export SDB_LAUNCH_COOLDOWN=3

# shellcheck source=/dev/null
. "$MODDIR/system/functions/mainlib.sh"

if [ -f "$MODDIR/config.sh" ]; then
  . "$MODDIR/config.sh"
fi

bootstrap
