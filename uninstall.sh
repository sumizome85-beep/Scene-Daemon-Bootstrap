#!/system/bin/sh
# Scene Daemon Bootstrap
# Uninstall routine: terminate the daemon, purge provisioned payloads and
# revert the background execution policy applied by service.sh.

MODDIR=${0%/*}
export SDB_MODDIR="$MODDIR"

# shellcheck source=/dev/null
. "$MODDIR/system/functions/mainlib.sh"

terminate_daemon
purge_payload
revert_policy
rm -f "$LOG_FILE"
