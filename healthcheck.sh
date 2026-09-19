#!/bin/sh
set -u

MODE="${1:---quick}"
case "$MODE" in
  --quick|--full) ;;
  *) echo "Usage: $0 [--quick|--full]"; exit 64;;
esac

P3D_DIR="/usr/data/scripts/p3d-k1"
LOG="$P3D_DIR/healthcheck.log"
STATUS_FILE="$P3D_DIR/status"
RUNLOG="/tmp/p3d_k1_healthcheck.$$"
HELPER_DIR="/usr/data/helper-script"
HELPER_TESTED_COMMIT="b46787a61b3ce2f04ec04d115a73a46c26814057"
MOONRAKER_REPO="/usr/data/moonraker/moonraker"
MOONRAKER_CONF="/usr/data/printer_data/config/moonraker.conf"
PRINTER_CFG="/usr/data/printer_data/config/printer.cfg"
CREALITY_CFG="/usr/data/creality/userdata/config/user_print_refer.json"

mkdir -p "$P3D_DIR"
: > "$RUNLOG"
PASS=0
WARN=0
FAIL=0

out() { echo "$*" | tee -a "$RUNLOG"; }
pass() { PASS=$((PASS+1)); out "[PASS] $*"; }
warn() { WARN=$((WARN+1)); out "[WARN] $*"; }
fail() { FAIL=$((FAIL+1)); out "[FAIL] $*"; }

out "========================================"
out " P3D K1 HEALTHCHECK $MODE"
out " $(date '+%Y-%m-%d %H:%M:%S' 2>/dev/null || date)"
out "========================================"

MODEL_RAW="$(/usr/bin/get_sn_mac.sh model 2>&1 || true)"
if echo "$MODEL_RAW" | grep -qi 'K1'; then pass "K1-series model: $MODEL_RAW"; else fail "Unexpected model: $MODEL_RAW"; fi

if ps | grep '[k]lippy' >/dev/null 2>&1 || ps | grep '[k]lipper' >/dev/null 2>&1; then pass "Klipper process running"; else fail "Klipper process not running"; fi
if ps | grep '[m]oonraker' >/dev/null 2>&1; then pass "Moonraker process running"; else fail "Moonraker process not running"; fi
if ps | grep '[n]ginx' >/dev/null 2>&1; then pass "Nginx process running"; else fail "Nginx process not running"; fi

if wget -q -T 5 -O /tmp/p3d_moonraker_info.json 'http://127.0.0.1:7125/server/info' 2>/dev/null; then
  pass "Moonraker API reachable"
  if grep -Eq '"klippy_connected"[[:space:]]*:[[:space:]]*true' /tmp/p3d_moonraker_info.json; then
    pass "Klippy connected to Moonraker"
  else
    warn "Moonraker API reachable but klippy_connected=true not confirmed"
  fi
else
  fail "Moonraker API not reachable on :7125"
fi

if wget -q -T 5 -O /tmp/p3d_fluidd.html 'http://127.0.0.1:4408/' 2>/dev/null && [ -s /tmp/p3d_fluidd.html ]; then
  pass "Fluidd HTTP reachable on :4408"
else
  fail "Fluidd HTTP unavailable on :4408"
fi

if ps | grep '[m]jpg_streamer' >/dev/null 2>&1; then pass "mjpg_streamer running"; else fail "mjpg_streamer not running"; fi
if netstat -lnt 2>/dev/null | grep ':8080 ' >/dev/null 2>&1; then pass "Camera port 8080 listening"; else fail "Camera port 8080 not listening"; fi
rm -f /tmp/p3d_snapshot.jpg
if wget -q -T 5 -O /tmp/p3d_snapshot.jpg 'http://127.0.0.1:8080/?action=snapshot' 2>/dev/null; then
  SNAP_SIZE="$(stat -c %s /tmp/p3d_snapshot.jpg 2>/dev/null || echo 0)"
  if [ "$SNAP_SIZE" -gt 1000 ]; then pass "Camera snapshot OK ($SNAP_SIZE bytes)"; else fail "Camera snapshot too small ($SNAP_SIZE bytes)"; fi
else
  fail "Camera snapshot request failed"
fi

rm -f /tmp/p3d_fluidd_snapshot.jpg
if wget -q -T 5 -O /tmp/p3d_fluidd_snapshot.jpg 'http://127.0.0.1:4408/webcam/?action=snapshot' 2>/dev/null; then
  FLUIDD_SNAP_SIZE="$(stat -c %s /tmp/p3d_fluidd_snapshot.jpg 2>/dev/null || echo 0)"
  if [ "$FLUIDD_SNAP_SIZE" -gt 1000 ]; then
    pass "Fluidd /webcam/ proxy snapshot OK ($FLUIDD_SNAP_SIZE bytes)"
  else
    fail "Fluidd /webcam/ proxy snapshot too small ($FLUIDD_SNAP_SIZE bytes)"
  fi
else
  fail "Fluidd /webcam/ proxy snapshot failed"
fi

if [ -x /opt/bin/ffmpeg ]; then
  if /opt/bin/ffmpeg -version >/dev/null 2>&1; then pass "Timelapse ffmpeg executable OK"; else fail "/opt/bin/ffmpeg exists but cannot execute"; fi
else
  fail "/opt/bin/ffmpeg missing"
fi

TIMELAPSE_PY="/usr/data/moonraker/moonraker/moonraker/components/timelapse.py"
[ -f "$TIMELAPSE_PY" ] && pass "Moonraker Timelapse component present" || fail "Moonraker Timelapse component missing"

grep -q '^\[timelapse\]' "$MOONRAKER_CONF" 2>/dev/null && pass "[timelapse] enabled" || fail "[timelapse] not enabled"
grep -q 'ffmpeg_binary_path:[[:space:]]*/opt/bin/ffmpeg' "$MOONRAKER_CONF" 2>/dev/null && pass "Timelapse ffmpeg path OK" || warn "Timelapse ffmpeg path differs from baseline"
grep -q 'Helper-Script/timelapse.cfg' "$PRINTER_CFG" 2>/dev/null && pass "timelapse.cfg included" || fail "timelapse.cfg include missing"

if [ -f "$CREALITY_CFG" ]; then
  DELAY="$(sed -n '/"delay_image":{/,/}/p' "$CREALITY_CFG" 2>/dev/null | grep -o '"switch":[01]' | head -n1 | cut -d: -f2 || true)"
  case "$DELAY" in
    0) pass "Creality stock timelapse disabled";;
    1) fail "Creality stock timelapse enabled";;
    *) warn "Cannot determine Creality stock timelapse state";;
  esac
else
  fail "Creality user_print_refer.json missing"
fi

CROND_COUNT="$(ps | grep '[c]rond' | wc -l | tr -d ' ')"
if [ "$CROND_COUNT" = "1" ]; then pass "crond running exactly once"; elif [ "$CROND_COUNT" = "0" ]; then fail "crond not running"; else warn "Multiple crond processes: $CROND_COUNT"; fi
[ -x /usr/data/scripts/timelapse_cleanup.sh ] && pass "Timelapse cleanup script installed" || warn "Timelapse cleanup script missing"

USED="$(df -P /usr/data 2>/dev/null | awk 'NR==2 {gsub("%","",$5); print $5}')"
if [ -z "$USED" ]; then warn "Cannot read /usr/data usage"; elif [ "$USED" -lt 75 ]; then pass "/usr/data usage ${USED}%"; elif [ "$USED" -lt 80 ]; then warn "/usr/data usage ${USED}% near cleanup threshold"; else fail "/usr/data usage ${USED}% at/above cleanup threshold"; fi

FAN_FILE="/usr/data/printer_data/config/Helper-Script/fans-control.cfg"
[ ! -f "$FAN_FILE" ] && pass "Fans Control Macros absent" || fail "Fans Control Macros detected"

LOGFILE="/usr/data/printer_data/logs/moonraker.log"
if [ -f "$LOGFILE" ]; then
  CRIT="$(tail -400 "$LOGFILE" | grep -iE 'fatal|timelapse: .*not found|failed to load component|unable to load component|server initialization failed|unhandled exception' | tail -10 || true)"
  [ -z "$CRIT" ] && pass "No obvious critical Moonraker errors in recent log" || { warn "Potential recent Moonraker errors:"; out "$CRIT"; }
else
  warn "Moonraker log not found"
fi

if [ "$MODE" = "--full" ]; then
  out ""
  out "--- FULL validation ---"

  if [ -d "$HELPER_DIR/.git" ]; then
    HC="$(cd "$HELPER_DIR" && git rev-parse HEAD 2>/dev/null || true)"
    [ -n "$HC" ] && pass "Helper Script git revision: $HC" || fail "Cannot read Helper Script revision"
    if [ "$HC" = "$HELPER_TESTED_COMMIT" ]; then pass "Helper Script matches tested deployment baseline"; else warn "Helper Script differs from tested deployment baseline $HELPER_TESTED_COMMIT"; fi
  else
    fail "Helper Script git repository missing"
  fi

  MENU="$HELPER_DIR/scripts/menu/K1/install_menu_K1.sh"

  check_helper_api() {
    token="$1"
    file="$2"
    if [ -f "$file" ] && grep -q "function $token" "$file" 2>/dev/null; then
      pass "Helper API present: $token"
    else
      fail "Helper API missing: $token ($file)"
    fi
  }

  check_helper_api install_moonraker_nginx "$HELPER_DIR/scripts/moonraker_nginx.sh"
  check_helper_api install_fluidd "$HELPER_DIR/scripts/fluidd.sh"
  check_helper_api install_entware "$HELPER_DIR/scripts/entware.sh"
  check_helper_api install_gcode_shell_command "$HELPER_DIR/scripts/gcode_shell_command.sh"
  check_helper_api install_kamp "$HELPER_DIR/scripts/kamp.sh"
  check_helper_api install_nozzle_cleaning_fan_control "$HELPER_DIR/scripts/nozzle_cleaning_fan_control.sh"
  check_helper_api install_improved_shapers "$HELPER_DIR/scripts/improved_shapers.sh"
  check_helper_api install_useful_macros "$HELPER_DIR/scripts/useful_macros.sh"
  check_helper_api install_save_zoffset_macros "$HELPER_DIR/scripts/save_zoffset_macros.sh"
  check_helper_api install_m600_support "$HELPER_DIR/scripts/m600_support.sh"
  check_helper_api install_moonraker_timelapse "$HELPER_DIR/scripts/moonraker_timelapse.sh"

  [ -f "$MENU" ] && pass "K1 install menu present" || fail "K1 install menu missing"

  [ -d /usr/data/moonraker ] && pass "Moonraker installation directory present" || fail "Moonraker directory missing"
  [ -d /usr/data/nginx ] && pass "Nginx installation directory present" || fail "Nginx directory missing"
  [ -d /usr/data/fluidd ] && pass "Fluidd installation directory present" || fail "Fluidd directory missing"
  [ -x /opt/bin/opkg ] && pass "Entware opkg present" || fail "Entware opkg missing"
  [ -f /usr/share/klipper/klippy/extras/gcode_shell_command.py ] && pass "Gcode Shell component present" || fail "Gcode Shell component missing"
  [ -d /usr/data/printer_data/config/Helper-Script/KAMP ] && pass "KAMP config directory present" || fail "KAMP config directory missing"
  [ -d /usr/share/klipper/klippy/extras/prtouch_v2_fan ] && pass "Nozzle Cleaning Fan Control present" || fail "Nozzle Cleaning Fan Control missing"
  [ -d /usr/data/printer_data/config/Helper-Script/improved-shapers ] && pass "Improved Shapers present" || fail "Improved Shapers missing"
  [ -f /usr/data/printer_data/config/Helper-Script/useful-macros.cfg ] && pass "Useful Macros present" || fail "Useful Macros missing"
  [ -f /usr/data/printer_data/config/Helper-Script/save-zoffset.cfg ] && pass "Save Z-Offset Macros present" || fail "Save Z-Offset Macros missing"
  [ -f /usr/data/printer_data/config/Helper-Script/M600-support.cfg ] && pass "M600 Support present" || fail "M600 Support missing"

  [ -x /etc/init.d/S99mjpg_camera ] && pass "Camera boot service present" || warn "P3D camera boot service absent (may be unnecessary if stock stream persists)"
  [ -x /etc/init.d/S98timelapse_cron ] && pass "Cleanup cron boot service present" || fail "Cleanup cron boot service missing"
  [ -x /etc/init.d/S99z_p3d_healthcheck ] && pass "P3D boot healthcheck hook present" || fail "P3D boot healthcheck hook missing"

  if [ -d "$MOONRAKER_REPO/.git" ]; then
    TRACKED="$(cd "$MOONRAKER_REPO" && git status --porcelain 2>/dev/null | grep -v '^?? ' || true)"
    if [ -z "$TRACKED" ]; then pass "Moonraker tracked Git files clean"; else warn "Moonraker tracked Git changes detected:"; out "$TRACKED"; fi
    UNTRACKED="$(cd "$MOONRAKER_REPO" && git status --porcelain 2>/dev/null | grep '^?? ' | grep -v '^?? moonraker/components/timelapse.py$' | grep -v '^?? moonraker.conf$' | grep -v '^?? .files-list.before$' || true)"
    if [ -z "$UNTRACKED" ]; then pass "No unexpected Moonraker untracked files"; else warn "Unexpected Moonraker untracked files:"; out "$UNTRACKED"; fi
  else
    fail "Moonraker Git repository missing"
  fi

  if wget -q -T 5 -O /tmp/p3d_printer_info.json 'http://127.0.0.1:7125/printer/info' 2>/dev/null; then
    pass "Moonraker printer/info endpoint reachable"
    grep -Eq '"state"[[:space:]]*:[[:space:]]*"(ready|standby)"' /tmp/p3d_printer_info.json && pass "Klipper state ready/standby" || warn "Klipper state not confirmed ready/standby"
  else
    warn "Moonraker printer/info endpoint unavailable"
  fi

  grep -q 'include Helper-Script/KAMP/KAMP_Settings.cfg' "$PRINTER_CFG" 2>/dev/null && pass "KAMP include enabled in printer.cfg" || fail "KAMP include missing"

  PROVISION="$P3D_DIR/fluidd_provision.py"
  PYTHON="/usr/data/moonraker/moonraker-env/bin/python"
  if [ ! -x "$PYTHON" ]; then
    PYTHON="$(command -v python3 2>/dev/null || true)"
  fi
  if [ -f "$PROVISION" ] && [ -n "$PYTHON" ] && [ -x "$PYTHON" ]; then
    set +e
    PROVISION_CHECK="$("$PYTHON" "$PROVISION" --check 2>&1)"
    PROVISION_RC=$?
    set -e
    case "$PROVISION_RC" in
      0) pass "Fluidd provisioning baseline OK" ;;
      1) warn "Fluidd provisioning differs from P3D baseline: $PROVISION_CHECK" ;;
      *) fail "Fluidd provisioning validation failed: $PROVISION_CHECK" ;;
    esac
  else
    fail "Fluidd provisioning helper/runtime missing"
  fi
fi

out ""
out "========================================"
out " RESULT"
out "========================================"
out "PASS: $PASS"
out "WARN: $WARN"
out "FAIL: $FAIL"

if [ "$FAIL" -gt 0 ]; then STATUS="FAIL"; RC=2; elif [ "$WARN" -gt 0 ]; then STATUS="WARN"; RC=1; else STATUS="PASS"; RC=0; fi
out "STATUS: $STATUS"
out "========================================"

echo "$STATUS" > "$STATUS_FILE"
cat "$RUNLOG" >> "$LOG"
rm -f "$RUNLOG"
exit "$RC"
