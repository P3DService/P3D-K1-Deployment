#!/bin/sh
set -eu

P3D_DIR="/usr/data/scripts/p3d-k1"
HELPER_DIR="/usr/data/helper-script"
HELPER_REPO="https://github.com/Guilouz/Creality-Helper-Script.git"
HELPER_TESTED_COMMIT="b46787a61b3ce2f04ec04d115a73a46c26814057"
LOG="$P3D_DIR/deploy.log"

mkdir -p "$P3D_DIR"
: > "$LOG"

say() { echo "$*" | tee -a "$LOG"; }
fail() { say "[FAIL] $*"; exit 1; }
pass() { say "[PASS] $*"; }
step() { say ""; say "== $* =="; }

[ "$(id -u)" = "0" ] || fail "Run as root"
[ -d /usr/data ] || fail "/usr/data not found"

MODEL_RAW="$(/usr/bin/get_sn_mac.sh model 2>&1 || true)"
echo "$MODEL_RAW" | grep -qi 'K1' || fail "This baseline is only for Creality K1 series. Detected: $MODEL_RAW"
pass "K1-series printer detected: $MODEL_RAW"

command -v git >/dev/null 2>&1 || fail "git not found"
command -v wget >/dev/null 2>&1 || fail "wget not found"

FREE_KB="$(df -Pk /usr/data | awk 'NR==2 {print $4}')"
[ -n "$FREE_KB" ] || fail "Cannot read free space"
[ "$FREE_KB" -gt 250000 ] || fail "Less than ~250 MB free on /usr/data"
pass "Free space precheck OK"

step "Helper Script baseline"
if [ ! -d "$HELPER_DIR/.git" ]; then
  [ ! -e "$HELPER_DIR" ] || mv "$HELPER_DIR" "${HELPER_DIR}.pre-p3d.$(date +%Y%m%d-%H%M%S)"
  git clone --depth 1 "$HELPER_REPO" "$HELPER_DIR" 2>&1 | tee -a "$LOG"
fi

cd "$HELPER_DIR"
CURRENT_HELPER="$(git rev-parse HEAD 2>/dev/null || true)"
if [ "$CURRENT_HELPER" != "$HELPER_TESTED_COMMIT" ]; then
  fail "Helper Script revision is $CURRENT_HELPER, but P3D baseline is tested only with $HELPER_TESTED_COMMIT. Stop and review before deployment."
fi
pass "Helper Script tested revision $CURRENT_HELPER"

HELPER_SCRIPT_FOLDER="$HELPER_DIR"
export HELPER_SCRIPT_FOLDER

[ -f "$HELPER_DIR/scripts/menu/functions.sh" ] || fail "Helper Script menu/functions.sh missing"
. "$HELPER_DIR/scripts/menu/functions.sh"

for script in "$HELPER_DIR"/scripts/*.sh; do
  . "$script"
done
set_paths
set_permissions
model="K1"
export model

for fn in top_line title inner_line hr bottom_line install_msg ok_msg error_msg start_moonraker stop_moonraker start_nginx stop_nginx restart_nginx restart_klipper; do
  command -v "$fn" >/dev/null 2>&1 || fail "Required Helper Script support function missing: $fn"
done
pass "Helper Script support API loaded"

for fn in install_moonraker_nginx install_fluidd install_entware install_gcode_shell_command install_kamp install_nozzle_cleaning_fan_control install_improved_shapers install_useful_macros install_save_zoffset_macros install_m600_support install_moonraker_timelapse; do
  command -v "$fn" >/dev/null 2>&1 || fail "Required Helper Script function missing: $fn"
done
pass "Helper Script internal API compatibility check"

run_yes() {
  name="$1"; fn="$2"
  say "[INSTALL] $name"
  if printf 'y\n' | "$fn" >>"$LOG" 2>&1; then
    pass "$name"
  else
    tail -40 "$LOG"
    fail "$name installation failed"
  fi
}

run_kamp() {
  say "[INSTALL] Klipper Adaptive Meshing & Purging (PrusaSlicer macros: NO)"
  if printf 'y\nn\n' | install_kamp >>"$LOG" 2>&1; then
    pass "KAMP"
  else
    tail -40 "$LOG"
    fail "KAMP installation failed"
  fi
}

step "P3D approved Helper Script components"

if [ -d "$MOONRAKER_FOLDER" ] && [ -d "$NGINX_FOLDER" ]; then pass "Moonraker + Nginx already present"; else run_yes "Moonraker + Nginx" install_moonraker_nginx; fi
if [ -d "$FLUIDD_FOLDER" ]; then pass "Fluidd already present"; else run_yes "Fluidd" install_fluidd; fi
if [ -f "$ENTWARE_FILE" ]; then pass "Entware already present"; else run_yes "Entware" install_entware; fi
if [ -f "$KLIPPER_SHELL_FILE" ]; then pass "Gcode Shell already present"; else run_yes "Klipper Gcode Shell Command" install_gcode_shell_command; fi
if [ -d "$KAMP_FOLDER" ]; then pass "KAMP already present"; else run_kamp; fi
if [ -d "$NOZZLE_CLEANING_FOLDER" ]; then pass "Nozzle Cleaning Fan Control already present"; else run_yes "Nozzle Cleaning Fan Control" install_nozzle_cleaning_fan_control; fi
if [ -d "$IMP_SHAPERS_FOLDER" ]; then pass "Improved Shapers already present"; else run_yes "Improved Shapers Calibrations" install_improved_shapers; fi
if [ -f "$USEFUL_MACROS_FILE" ]; then pass "Useful Macros already present"; else run_yes "Useful Macros" install_useful_macros; fi
if [ -f "$SAVE_ZOFFSET_FILE" ]; then pass "Save Z-Offset Macros already present"; else run_yes "Save Z-Offset Macros" install_save_zoffset_macros; fi
if [ -f "$M600_SUPPORT_FILE" ]; then pass "M600 Support already present"; else run_yes "M600 Support" install_m600_support; fi
if [ -f "$TIMELAPSE_FILE" ]; then pass "Moonraker Timelapse already present"; else run_yes "Moonraker Timelapse" install_moonraker_timelapse; fi

if [ -f "$FAN_CONTROLS_FILE" ]; then
  fail "Fans Control Macros detected at $FAN_CONTROLS_FILE. P3D baseline forbids this component. Remove it via Helper Script before continuing."
fi
pass "Fans Control Macros absent"

step "P3D camera compatibility"
CAMERA_OK=0
rm -f /tmp/p3d_snapshot.jpg
if wget -q -T 5 -O /tmp/p3d_snapshot.jpg 'http://127.0.0.1:8080/?action=snapshot' 2>/dev/null; then
  SIZE="$(stat -c %s /tmp/p3d_snapshot.jpg 2>/dev/null || echo 0)"
  [ "$SIZE" -gt 1000 ] && CAMERA_OK=1
fi

if [ "$CAMERA_OK" -eq 0 ]; then
  [ -x /usr/bin/mjpg_streamer ] || fail "Camera snapshot unavailable and /usr/bin/mjpg_streamer missing"
  [ -d /usr/lib/mjpg-streamer ] || fail "Camera snapshot unavailable and /usr/lib/mjpg-streamer missing"
  cat > /etc/init.d/S99mjpg_camera <<'CAMERAEOF'
#!/bin/sh
PIDFILE=/var/run/main-video-4_mjpg.pid
MJPG=/usr/bin/mjpg_streamer
LIB=/usr/lib/mjpg-streamer
case "$1" in
  start)
    pidof mjpg_streamer >/dev/null 2>&1 && exit 0
    LD_LIBRARY_PATH="$LIB" start-stop-daemon -S -b -m -p "$PIDFILE" --exec "$MJPG" -- \
      -i "input_memfd.so -t 0" \
      -o "output_http.so -w /usr/share/mjpg-streamer/www/ -p 8080"
    ;;
  stop)
    start-stop-daemon -K -p "$PIDFILE" 2>/dev/null || true
    rm -f "$PIDFILE"
    ;;
  restart|reload)
    "$0" stop; sleep 1; "$0" start
    ;;
  *) echo "Usage: $0 {start|stop|restart}"; exit 1;;
esac
CAMERAEOF
  chmod +x /etc/init.d/S99mjpg_camera
  /etc/init.d/S99mjpg_camera restart
  sleep 2
fi

rm -f /tmp/p3d_snapshot.jpg
wget -q -T 5 -O /tmp/p3d_snapshot.jpg 'http://127.0.0.1:8080/?action=snapshot' || fail "Camera snapshot test failed"
SIZE="$(stat -c %s /tmp/p3d_snapshot.jpg 2>/dev/null || echo 0)"
[ "$SIZE" -gt 1000 ] || fail "Camera snapshot invalid ($SIZE bytes)"
pass "Camera snapshot OK ($SIZE bytes)"

step "Stock Creality timelapse OFF"
CREALITY_CFG="/usr/data/creality/userdata/config/user_print_refer.json"
if [ -f "$CREALITY_CFG" ]; then
  [ -f "$CREALITY_CFG.p3d-original" ] || cp -p "$CREALITY_CFG" "$CREALITY_CFG.p3d-original"
  sed -i '/"delay_image":{/,/}/ s/"switch":1/"switch":0/' "$CREALITY_CFG"
  DELAY="$(sed -n '/"delay_image":{/,/}/p' "$CREALITY_CFG" | grep -o '"switch":[01]' | head -n1 | cut -d: -f2 || true)"
  [ "$DELAY" = "0" ] || fail "Could not confirm Creality timelapse switch=0"
  pass "Creality stock timelapse disabled"
else
  fail "$CREALITY_CFG missing"
fi

step "Moonraker Timelapse ffmpeg compatibility"
if [ -x /opt/bin/ffmpeg ]; then
  pass "/opt/bin/ffmpeg already available"
elif [ -x /usr/bin/ffmpeg ]; then
  mkdir -p /opt/bin
  ln -sf /usr/bin/ffmpeg /opt/bin/ffmpeg
  pass "Created /opt/bin/ffmpeg -> /usr/bin/ffmpeg"
else
  fail "No usable ffmpeg found"
fi
/opt/bin/ffmpeg -version >/dev/null 2>&1 || fail "ffmpeg execution failed"

step "Timelapse cleanup"
mkdir -p /usr/data/scripts
cat > /usr/data/scripts/timelapse_cleanup.sh <<'CLEANEOF'
#!/bin/sh
HIGH=80
LOW=75
DIR1="/usr/data/printer_data/timelapse"
DIR2="/usr/data/creality/userdata/delay_image/video"
usage_percent() { df -P /usr/data | awk 'NR==2 {gsub("%","",$5); print $5}'; }
USED="$(usage_percent)"
[ -z "$USED" ] && exit 1
[ "$USED" -lt "$HIGH" ] && exit 0
while [ "$USED" -gt "$LOW" ]; do
  OLDEST="$(find "$DIR1" "$DIR2" -type f 2>/dev/null | while read FILE; do MTIME="$(stat -c %Y "$FILE" 2>/dev/null)"; [ -n "$MTIME" ] && echo "$MTIME $FILE"; done | sort -n | head -n1 | cut -d' ' -f2-)"
  [ -n "$OLDEST" ] || exit 0
  rm -f "$OLDEST"
  USED="$(usage_percent)"
done
CLEANEOF
chmod +x /usr/data/scripts/timelapse_cleanup.sh
pass "Cleanup policy installed (80% -> 75%)"

mkdir -p /usr/data/cron
CRON=/usr/data/cron/root
touch "$CRON"
grep -q '/usr/data/scripts/timelapse_cleanup.sh' "$CRON" || echo '0 * * * * /usr/data/scripts/timelapse_cleanup.sh >> /usr/data/scripts/timelapse_cleanup.log 2>&1' >> "$CRON"
grep -q '/usr/data/scripts/p3d-k1/healthcheck.sh --quick' "$CRON" || echo '17 3 * * * /usr/data/scripts/p3d-k1/healthcheck.sh --quick >/dev/null 2>&1' >> "$CRON"
chmod 600 "$CRON"

cat > /etc/init.d/S98timelapse_cron <<'CRONEOF'
#!/bin/sh
CROND=/usr/sbin/crond
CRONDIR=/usr/data/cron
LOG=/usr/data/scripts/crond.log
case "$1" in
  start)
    pidof crond >/dev/null 2>&1 && exit 0
    "$CROND" -b -c "$CRONDIR" -L "$LOG"
    ;;
  stop) killall crond 2>/dev/null || true;;
  restart) "$0" stop; sleep 1; "$0" start;;
  *) echo "Usage: $0 {start|stop|restart}"; exit 1;;
esac
CRONEOF
chmod +x /etc/init.d/S98timelapse_cron
/etc/init.d/S98timelapse_cron restart
pass "Cron installed"

step "Healthcheck boot hook"
cat > /etc/init.d/S99z_p3d_healthcheck <<'BOOTEOF'
#!/bin/sh
case "$1" in
  start)
    ( sleep 25; /usr/data/scripts/p3d-k1/healthcheck.sh --quick >/dev/null 2>&1 ) &
    ;;
  stop) ;;
  restart) "$0" start;;
  *) echo "Usage: $0 {start|stop|restart}"; exit 1;;
esac
BOOTEOF
chmod +x /etc/init.d/S99z_p3d_healthcheck
pass "Automatic QUICK healthcheck enabled at boot"

step "Restart Moonraker"
if [ -x /etc/init.d/S56moonraker_service ]; then
  set +e
  /etc/init.d/S56moonraker_service restart >>"$LOG" 2>&1
  RESTART_RC=$?
  set -e
  if [ "$RESTART_RC" -eq 0 ]; then
    pass "Moonraker restart command accepted"
  else
    say "[WARN] Moonraker init-script returned rc=$RESTART_RC; API readiness is authoritative"
  fi
else
  say "[WARN] Moonraker init-script missing; API readiness is authoritative"
fi

step "Wait for Moonraker API readiness"
MOONRAKER_READY=0
MOONRAKER_WAITED=0
MOONRAKER_TIMEOUT=45
while [ "$MOONRAKER_WAITED" -lt "$MOONRAKER_TIMEOUT" ]; do
  if wget -q -T 3 -O /tmp/p3d_moonraker_ready.json 'http://127.0.0.1:7125/server/info' 2>/dev/null; then
    MOONRAKER_READY=1
    break
  fi
  sleep 2
  MOONRAKER_WAITED=$((MOONRAKER_WAITED + 2))
done

if [ "$MOONRAKER_READY" -eq 1 ]; then
  pass "Moonraker API ready after ${MOONRAKER_WAITED}s"
else
  fail "Moonraker API did not become ready within ${MOONRAKER_TIMEOUT}s"
fi

step "Fluidd provisioning"
PROVISION="$P3D_DIR/fluidd_provision.py"
[ -f "$PROVISION" ] || fail "$PROVISION is missing. Install the complete P3D deployment package."

PYTHON="/usr/data/moonraker/moonraker-env/bin/python"
if [ ! -x "$PYTHON" ]; then
  PYTHON="$(command -v python3 2>/dev/null || true)"
fi
[ -n "$PYTHON" ] && [ -x "$PYTHON" ] || fail "Python 3 runtime not found for Fluidd provisioning"

set +e
PROVISION_OUTPUT="$("$PYTHON" "$PROVISION" 2>&1)"
PROVISION_RC=$?
set -e
[ -n "$PROVISION_OUTPUT" ] && say "$PROVISION_OUTPUT"

case "$PROVISION_RC" in
  0) pass "Fluidd provisioning completed" ;;
  1) say "[WARN] Fluidd provisioning preserved custom user state; FULL healthcheck will report WARN" ;;
  *) fail "Fluidd provisioning failed (rc=$PROVISION_RC)" ;;
esac

[ -x "$P3D_DIR/healthcheck.sh" ] || fail "$P3D_DIR/healthcheck.sh is missing. Copy the complete P3D deployment package before running deploy.sh."

step "FULL post-deploy gate"
set +e
"$P3D_DIR/healthcheck.sh" --full
rc=$?
set -e

case "$rc" in
  0)
    pass "FULL healthcheck passed"
    say ""
    say "========================================"
    say " P3D K1 DEPLOYMENT: PASS"
    say "========================================"
    exit 0
    ;;
  1)
    say "[WARN] FULL healthcheck completed with warnings"
    say ""
    say "========================================"
    say " P3D K1 DEPLOYMENT: WARN"
    say " Review warnings before production use."
    say "========================================"
    exit 1
    ;;
  *)
    say ""
    say "========================================"
    say " P3D K1 DEPLOYMENT: FAIL (healthcheck rc=$rc)"
    say "========================================"
    exit "$rc"
    ;;
esac
