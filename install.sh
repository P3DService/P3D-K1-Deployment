#!/bin/sh
set -eu

REPO="P3DService/P3D-K1-Deployment"
REF="${P3D_K1_REF:-v0.5.1}"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${REF}"
DEST="/usr/data/scripts/p3d-k1"
TMP="/tmp/p3d-k1-bootstrap.$$"

fail() {
  echo "[FAIL] $*" >&2
  rm -rf "$TMP" 2>/dev/null || true
  exit 1
}

pass() {
  echo "[PASS] $*"
}

[ "$(id -u)" = "0" ] || fail "Run as root"

MODEL_RAW="$(/usr/bin/get_sn_mac.sh model 2>&1 || true)"
echo "$MODEL_RAW" | grep -qi 'K1' || fail "Unsupported printer model: $MODEL_RAW"
pass "K1-series printer detected: $MODEL_RAW"

command -v wget >/dev/null 2>&1 || fail "wget not found"

mkdir -p "$TMP" "$DEST"

echo "[INFO] Downloading P3D K1 Deployment from $REPO @ $REF"

wget -q -T 20 -O "$TMP/deploy.sh" "$RAW_BASE/deploy.sh" || fail "Cannot download deploy.sh"
wget -q -T 20 -O "$TMP/healthcheck.sh" "$RAW_BASE/healthcheck.sh" || fail "Cannot download healthcheck.sh"
wget -q -T 20 -O "$TMP/VERSION" "$RAW_BASE/VERSION" || fail "Cannot download VERSION"

# Added in the v0.6 development line. Keep this optional so the bootstrap
# remains able to install older immutable releases such as v0.5.1.
if wget -q -T 20 -O "$TMP/fluidd_provision.py" "$RAW_BASE/fluidd_provision.py" 2>/dev/null; then
  [ -s "$TMP/fluidd_provision.py" ] || rm -f "$TMP/fluidd_provision.py"
else
  rm -f "$TMP/fluidd_provision.py"
fi

[ -s "$TMP/deploy.sh" ] || fail "Downloaded deploy.sh is empty"
[ -s "$TMP/healthcheck.sh" ] || fail "Downloaded healthcheck.sh is empty"

chmod +x "$TMP/deploy.sh" "$TMP/healthcheck.sh"

cp "$TMP/deploy.sh" "$DEST/deploy.sh"
cp "$TMP/healthcheck.sh" "$DEST/healthcheck.sh"
cp "$TMP/VERSION" "$DEST/VERSION"
if [ -s "$TMP/fluidd_provision.py" ]; then
  cp "$TMP/fluidd_provision.py" "$DEST/fluidd_provision.py"
fi
chmod +x "$DEST/deploy.sh" "$DEST/healthcheck.sh"

VERSION="$(cat "$DEST/VERSION" 2>/dev/null || echo unknown)"
pass "P3D K1 Deployment $VERSION installed to $DEST"

rm -rf "$TMP"

echo "[INFO] Starting deployment..."
exec "$DEST/deploy.sh"
