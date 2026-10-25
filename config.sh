#!/system/bin/sh
# Scene Daemon Bootstrap - operator overrides.
# Sourced by service.sh / action.sh and by the CLI after mainlib.sh, so any
# variable defined in mainlib.sh can be adjusted here.

# Every value below is applied with ":=", so an entry point that exports its
# own value first (service.sh exports SDB_LAUNCH_SCENE=0) is never overridden.

# Seconds to wait for am/cmd and /data/local/tmp to become usable at
# activation time. A boot run that checks once and gives up is the reason a
# background activation could silently do nothing.
: "${SDB_ENV_TIMEOUT:=60}"

# Seconds to wait for the payload files to appear (external storage may still
# be unmounted during late_start).
: "${SDB_PAYLOAD_TIMEOUT:=30}"

# Seconds to wait for the spawned daemon to become resident before reporting
# a failure. The pid from $! is checked first, so this is rarely reached.
: "${SDB_START_TIMEOUT:=6}"

# Seconds to wait after SIGTERM before escalating to SIGKILL.
: "${SDB_TERM_TIMEOUT:=5}"

# 1 = launch the Scene splash activity as part of the routine (matches the
# original script). Set to 0 to provision and spawn without ever pulling the
# Scene UI to the foreground.
: "${SDB_LAUNCH_SCENE:=1}"

# 1 = a manual run (action button / WebUI run) launches Scene whenever the
# daemon is OK, even if it was already resident. 0 = only launch when this run
# actually spawned it. Boot and module activation ignore this: service.sh sets
# SDB_LAUNCH_SCENE=0 and stays silent either way.
: "${SDB_LAUNCH_FORCE:=1}"

# Seconds to wait after the daemon becomes resident before handing over to
# Scene. Launching while it is still initialising can leave the splash with
# nothing to attach to, and it then finishes straight back to the previous
# task that was in front -- the "bounced back" symptom.
: "${SDB_LAUNCH_DELAY:=1}"

# Seconds during which a repeat Scene launch is suppressed. Scene re-enters
# its own splash while ADB mode is being granted; launching again in that
# window throws the user back out before the dialog finishes.
: "${SDB_LAUNCH_COOLDOWN:=120}"

# Activity flags for the Scene splash launch. Default 0x10000000 is
# FLAG_ACTIVITY_NEW_TASK alone; the original 0x10008000 also cleared the task,
# which made Scene jump forward twice. Set it back if you need that behaviour.
: "${SDB_LAUNCH_FLAG:=0x10000000}"

# Live output file used by the WebUI while a routine runs detached.
: "${SDB_PROGRESS:=/data/local/tmp/.scene_daemon_bootstrap.progress}"

# Port value forwarded to the Scene splash activity. Leave empty unless your
# Scene build expects one.
: "${port:=}"
