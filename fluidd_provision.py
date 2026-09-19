#!/usr/bin/env python3
import argparse
import json
import os
import socket
import sys
import time
import urllib.parse
import urllib.request

BASE = "http://127.0.0.1:7125"
P3D_DIR = "/usr/data/scripts/p3d-k1"
BACKUP_DIR = os.path.join(P3D_DIR, "backups")

CATEGORIES = [
    {"id": "2d4db5a2-6cb8-4fb6-9a38-2e50a4e3a001", "name": "PRINT"},
    {"id": "2d4db5a2-6cb8-4fb6-9a38-2e50a4e3a002", "name": "CALIBRATION"},
    {"id": "2d4db5a2-6cb8-4fb6-9a38-2e50a4e3a003", "name": "KAMP"},
    {"id": "2d4db5a2-6cb8-4fb6-9a38-2e50a4e3a004", "name": "TIMELAPSE"},
]
CAT = {x["name"]: x["id"] for x in CATEGORIES}

VISIBLE = {
    "PAUSE": "PRINT",
    "RESUME": "PRINT",
    "CANCEL_PRINT": "PRINT",
    "M600": "PRINT",
    "BED_MESH_CALIBRATE": "CALIBRATION",
    "INPUT_SHAPER_CALIBRATION": "CALIBRATION",
    "BELTS_SHAPER_CALIBRATION": "CALIBRATION",
    "TEST_RESONANCES_GRAPHS": "CALIBRATION",
    "PID_HOTEND": "CALIBRATION",
    "PID_BED": "CALIBRATION",
    "KAMP_BED_MESH_SETTINGS": "KAMP",
    "KAMP_PURGE_LINE_SETTINGS": "KAMP",
    "GET_TIMELAPSE_SETUP": "TIMELAPSE",
    "TIMELAPSE_RENDER": "TIMELAPSE",
}

EXPECTED_CAMERA = {
    "enabled": True,
    "location": "printer",
    "service": "mjpegstreamer-adaptive",
    "target_fps": 15,
    "target_fps_idle": 5,
    "stream_url": "/webcam/?action=stream",
    "snapshot_url": "/webcam/?action=snapshot",
    "aspect_ratio": "4:3",
}

def req(path, method="GET", payload=None, timeout=8):
    url = BASE + path
    data = None
    headers = {}
    if payload is not None:
        data = json.dumps(payload, separators=(",", ":")).encode("utf-8")
        headers["Content-Type"] = "application/json"
    request = urllib.request.Request(url, data=data, headers=headers, method=method)
    with urllib.request.urlopen(request, timeout=timeout) as response:
        return json.loads(response.read().decode("utf-8"))

def get_fluidd():
    q = urllib.parse.urlencode({"namespace": "fluidd"})
    return req("/server/database/item?" + q)["result"]["value"]

def post_db(key, value):
    return req("/server/database/item", "POST", {
        "namespace": "fluidd",
        "key": key,
        "value": value,
    })

def get_macro_names():
    data = req("/printer/objects/query?configfile")
    settings = data["result"]["status"]["configfile"]["settings"]
    names = []
    for key in settings:
        if key.lower().startswith("gcode_macro "):
            name = key.split(None, 1)[1]
            names.append(name)
    return sorted(set(names), key=str.lower)

def backup_state(fluidd, webcams):
    os.makedirs(BACKUP_DIR, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    path = os.path.join(BACKUP_DIR, "fluidd-before-provision-%s.json" % stamp)
    with open(path, "w", encoding="utf-8") as f:
        json.dump({"fluidd": fluidd, "webcams": webcams}, f, ensure_ascii=False, indent=2)
    return path

def macro_state_matches(fluidd):
    """Compare the Fluidd layout semantically, not by category UUID.

    Fluidd generates random UUIDs when categories are created manually. A user
    may therefore already have exactly the P3D layout with different IDs. That
    must be treated as a match and must not be overwritten.
    """
    macros = fluidd.get("macros") or {}
    cats = macros.get("categories") or []
    stored = macros.get("stored") or []

    cat_by_id = {x.get("id"): x.get("name") for x in cats}
    names = [x.get("name") for x in cats]
    if names != [x["name"] for x in CATEGORIES]:
        return False

    by_name = {str(x.get("name", "")).upper(): x for x in stored}
    for macro, cat_name in VISIBLE.items():
        item = by_name.get(macro)
        if not item or item.get("visible") is not True:
            return False
        if cat_by_id.get(item.get("categoryId")) != cat_name:
            return False

    # Every explicitly stored non-baseline macro should remain hidden.
    for name, item in by_name.items():
        if name not in VISIBLE and item.get("visible") is True:
            return False
    return True

def provision_macros(force=False):
    fluidd = get_fluidd()
    macros = fluidd.get("macros") or {}
    existing_categories = macros.get("categories") or []
    existing_stored = macros.get("stored") or []

    if existing_categories and macro_state_matches(fluidd):
        return ("already", "Fluidd macro groups already match P3D baseline; existing category IDs preserved.")

    if existing_categories and not force:
        return ("preserved", "Existing custom Fluidd macro layout detected; preserved. Set P3D_K1_FLUIDD_FORCE=1 to replace it with P3D baseline.")

    names = get_macro_names()
    stored = []
    for i, name in enumerate(names):
        upper = name.upper()
        category = VISIBLE.get(upper)
        if category:
            stored.append({
                "alias": "",
                "visible": True,
                "disabledWhilePrinting": False,
                "color": "",
                "categoryId": CAT[category],
                "name": name,
            })
        else:
            stored.append({
                "alias": "",
                "visible": False,
                "disabledWhilePrinting": False,
                "color": "",
                "categoryId": "0",
                "name": name,
            })

    post_db("macros.categories", CATEGORIES)
    post_db("macros.stored", stored)
    post_db("macros.expanded", [0, 1])
    return ("applied", "Fluidd macro groups/visibility provisioned (%d macros)" % len(stored))

def get_webcams():
    return req("/server/webcams/list")["result"]["webcams"]

def provision_camera():
    webcams = get_webcams()
    db_cams = [w for w in webcams if w.get("source") == "database"]
    if db_cams:
        cam = db_cams[0]
        payload = {"uid": cam["uid"]}
        payload.update(EXPECTED_CAMERA)
        result = req("/server/webcams/item", "POST", payload)["result"]["webcam"]
        return ("updated", "Fluidd/Moonraker webcam normalized; existing name preserved: %s" % result.get("name", "camera"))
    config_cams = [w for w in webcams if w.get("source") == "config"]
    if config_cams:
        return ("preserved", "Webcam is config-managed and cannot be updated through Moonraker API; preserved.")
    name = "%s_camera" % socket.gethostname()
    payload = {"name": name}
    payload.update(EXPECTED_CAMERA)
    result = req("/server/webcams/item", "POST", payload)["result"]["webcam"]
    return ("created", "Fluidd/Moonraker webcam created: %s" % result.get("name", name))

def check_camera():
    webcams = get_webcams()
    db_cams = [w for w in webcams if w.get("source") == "database"]
    if not db_cams:
        return False, "No database-managed webcam found"
    cam = db_cams[0]
    bad = []
    for key, val in EXPECTED_CAMERA.items():
        if cam.get(key) != val:
            bad.append("%s=%r" % (key, cam.get(key)))
    if bad:
        return False, "Webcam differs from baseline: " + ", ".join(bad)
    return True, "Webcam baseline OK (name preserved: %s)" % cam.get("name", "camera")

def check_macros():
    fluidd = get_fluidd()
    if macro_state_matches(fluidd):
        return True, "Fluidd macro groups baseline OK"
    macros = fluidd.get("macros") or {}
    if macros.get("categories"):
        return None, "Custom Fluidd macro layout present (not P3D baseline)"
    return False, "Fluidd macro groups baseline missing"

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--force-macros", action="store_true")
    args = ap.parse_args()

    try:
        if args.check:
            m_ok, m_msg = check_macros()
            c_ok, c_msg = check_camera()
            print(("PASS" if m_ok is True else "WARN" if m_ok is None else "FAIL") + " MACROS " + m_msg)
            print(("PASS" if c_ok else "FAIL") + " CAMERA " + c_msg)
            if c_ok is False or m_ok is False:
                return 2
            if m_ok is None:
                return 1
            return 0

        fluidd = get_fluidd()
        webcams = get_webcams()
        backup = backup_state(fluidd, webcams)
        print("[PASS] Fluidd state backup: %s" % backup)

        force = args.force_macros or os.environ.get("P3D_K1_FLUIDD_FORCE") == "1"
        state, msg = provision_macros(force=force)
        if state in ("applied", "already"):
            print("[PASS] " + msg)
        else:
            print("[WARN] " + msg)

        state, msg = provision_camera()
        print(("[PASS]" if state in ("created", "updated") else "[WARN]") + " " + msg)

        ok, msg = check_camera()
        if not ok:
            print("[FAIL] " + msg)
            return 2
        print("[PASS] " + msg)
        return 0
    except Exception as exc:
        print("[FAIL] Fluidd provisioning error: %s" % exc)
        return 2

if __name__ == "__main__":
    sys.exit(main())
