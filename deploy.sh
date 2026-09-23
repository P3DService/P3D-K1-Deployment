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

step "K1 Max motherboard fan compatibility"
if echo "$MODEL_RAW" | grep -qi 'K1[[:space:]_-]*Max'; then
  PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
  [ -f "$PRINTER_CFG" ] || fail "$PRINTER_CFG missing"

  BOARD_FAN_PY="/usr/data/moonraker/moonraker-env/bin/python"
  if [ ! -x "$BOARD_FAN_PY" ]; then
    BOARD_FAN_PY="$(command -v python3 2>/dev/null || true)"
  fi
  [ -n "$BOARD_FAN_PY" ] && [ -x "$BOARD_FAN_PY" ] || fail "Python 3 runtime not found for K1 Max board-fan compatibility patch"

  "$BOARD_FAN_PY" - "$PRINTER_CFG" <<'PYEOF'
from pathlib import Path
import re
import sys

path = Path(sys.argv[1])
original = path.read_text()
text = original

fixed = """# P3D: mainboard fan must never stop; Creality raises CF0502 after sustained 0 RPM.
# 50% idle cooling, 100% above 48C MCU temperature, with 42C/48C hysteresis.
[output_pin board_fan]
pin: PB2
pwm: True
cycle_time: 0.010
value: 0.50
shutdown_value: 1.0

[delayed_gcode P3D_BOARD_FAN_CONTROL]
initial_duration: 2
gcode:
    {% set temp = printer["temperature_sensor mcu_temp"].temperature|float %}
    {% set speed = printer["output_pin board_fan"].value|float %}
    {% if temp >= 48.0 %}
        SET_PIN PIN=board_fan VALUE=1.0
    {% elif temp <= 42.0 %}
        SET_PIN PIN=board_fan VALUE=0.50
    {% elif speed < 0.50 %}
        SET_PIN PIN=board_fan VALUE=0.50
    {% endif %}
    UPDATE_DELAYED_GCODE ID=P3D_BOARD_FAN_CONTROL DURATION=5
"""

if "[output_pin board_fan]" in text and "[delayed_gcode P3D_BOARD_FAN_CONTROL]" in text:
    pattern = (
        r'(?ms)^# P3D: mainboard fan must never stop;.*?'
        r'^\[output_pin board_fan\]\n.*?'
        r'^\[delayed_gcode P3D_BOARD_FAN_CONTROL\]\n.*?(?=^\[|\Z)'
    )
    text, count = re.subn(pattern, fixed + "\n", text, count=1)
    if count != 1:
        raise SystemExit("cannot reconcile existing P3D board-fan block")
elif "[controller_fan board_fan]" in text:
    pattern = (
        r'(?ms)^(?:# P3D: cool the mainboard during cold calibration and motor holding\.\n)?'
        r'\[controller_fan board_fan\]\n.*?(?=^\[|\Z)'
    )
    text, count = re.subn(pattern, fixed + "\n", text, count=1)
    if count != 1:
        raise SystemExit("cannot replace existing [controller_fan board_fan]")
else:
    m = re.search(r'(?ms)^\[multi_pin heater_fans\]\n(.*?)(?=^\[|\Z)', text)
    if not m:
        raise SystemExit("K1 Max [multi_pin heater_fans] section not found")
    section = m.group(0)
    pin_line = re.search(r'(?m)^pins\s*:\s*(.+)$', section)
    if not pin_line:
        raise SystemExit("K1 Max heater_fans pins line not found")
    pins = [p.strip() for p in pin_line.group(1).split(",")]
    if "PB2" not in pins:
        raise SystemExit("PB2 is not present in stock heater_fans mapping; refusing unknown layout")
    pins = [p for p in pins if p != "PB2"]
    if not pins:
        raise SystemExit("heater_fans would become empty")
    new_section = section[:pin_line.start(1)] + ",".join(pins) + section[pin_line.end(1):]
    text = text[:m.start()] + new_section + text[m.end():]
    if not text.endswith("\n"):
        text += "\n"
    text += "\n" + fixed

backup = path.with_name("printer.cfg.p3d-pre-cf0502-fix")
if not backup.exists():
    backup.write_text(original)
path.write_text(text)
PYEOF

  grep -q '^\[output_pin board_fan\]$' "$PRINTER_CFG" || fail "K1 Max board_fan output_pin not installed"
  grep -q '^\[delayed_gcode P3D_BOARD_FAN_CONTROL\]$' "$PRINTER_CFG" || fail "K1 Max board-fan controller not installed"
  grep -q '^value:[[:space:]]*0\.50$' "$PRINTER_CFG" || fail "K1 Max board-fan idle floor is not 50%"
  grep -q '^shutdown_value:[[:space:]]*1\.0$' "$PRINTER_CFG" || fail "K1 Max board-fan shutdown value is not 100%"
  if grep -q '^\[controller_fan board_fan\]$' "$PRINTER_CFG"; then
    fail "Legacy controller_fan board_fan still present"
  fi
  pass "K1 Max board fan CF0502 compatibility patch installed"

  GCODE_MACRO_CFG="/usr/data/printer_data/config/gcode_macro.cfg"
  [ -f "$GCODE_MACRO_CFG" ] || fail "$GCODE_MACRO_CFG missing"

  "$BOARD_FAN_PY" - "$GCODE_MACRO_CFG" <<'PYEOF'
from pathlib import Path
import sys

path = Path(sys.argv[1])
text = path.read_text()

marker = "# P3D: K1 Max rear/chamber fan (fan1 / PC0) can fail to start"

if marker not in text:
    old = """  {% if value >= 255 %}
    {% set value = 255 %}
  {% endif %}
  SET_PIN PIN=fan{fan} VALUE={value}

[gcode_macro M107]
"""

    new = """  {% if value >= 255 %}
    {% set value = 255 %}
  {% endif %}

  # P3D: K1 Max rear/chamber fan (fan1 / PC0) can fail to start
  # from rest at reduced PWM. Give it a short 100% kick before
  # settling to the requested speed.
  {% if fan == 1 and value > 0 and value < 255
        and printer['output_pin fan1'].value|float == 0 %}
    SET_PIN PIN=fan1 VALUE=255
    G4 P500
  {% endif %}

  SET_PIN PIN=fan{fan} VALUE={value}

[gcode_macro M107]
"""

    if old not in text:
        raise SystemExit("expected stock M106 tail not found; refusing unknown macro layout")

    backup = path.with_name("gcode_macro.cfg.p3d-pre-fan1-kickstart")
    if not backup.exists():
        backup.write_text(text)

    text = text.replace(old, new, 1)
    path.write_text(text)
PYEOF

  grep -q '^  # P3D: K1 Max rear/chamber fan (fan1 / PC0) can fail to start    pass "Klipper restarted to apply K1 Max board-fan baseline"
  else
    fail "Klipper restart failed after K1 Max board-fan patch"
  fi
  sleep 5
else
  pass "K1 Max board fan patch not applicable to this model"
fi

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
 "$GCODE_MACRO_CFG" \
    || fail "K1 Max rear-fan kick-start marker missing"
  grep -q "printer\['output_pin fan1'\].value|float == 0" "$GCODE_MACRO_CFG" \
    || fail "K1 Max rear-fan zero-state guard missing"
  grep -q '^    G4 P500    pass "Klipper restarted to apply K1 Max board-fan baseline"
  else
    fail "Klipper restart failed after K1 Max board-fan patch"
  fi
  sleep 5
else
  pass "K1 Max board fan patch not applicable to this model"
fi

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
 "$GCODE_MACRO_CFG" \
    || fail "K1 Max rear-fan 500 ms kick missing"
  pass "K1 Max rear/chamber fan reduced-PWM kick-start installed"

  if restart_klipper >>"$LOG" 2>&1; then
    pass "Klipper restarted to apply K1 Max board-fan baseline"
  else
    fail "Klipper restart failed after K1 Max board-fan patch"
  fi
  sleep 5
else
  pass "K1 Max board fan patch not applicable to this model"
fi

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
