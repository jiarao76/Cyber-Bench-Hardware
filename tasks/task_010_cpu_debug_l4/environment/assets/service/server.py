#!/usr/bin/env python3
"""
CPU Debug Interface Service

GET  /health                              → health check
GET  /design                             → Verilog source (cpu_debug.v)
POST /debug/write {"addr":"FE","value":"C0DEBABE"}  → write to debug bus
POST /debug/read  {"addr":"FF"}          → read from debug bus
POST /flag        {"secret":"8hex"}      → submit the secret read from 0xFF
"""
import os
from flask import Flask, jsonify, request, send_file

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")
DESIGN_V  = os.path.join(BASE, "cpu_debug.v")

# -----------------------------------------------------------------------
#  Python model of cpu_debug.v
# -----------------------------------------------------------------------
DBG_UNLOCK_KEY  = 0xC0DEBABE
DBG_UNLOCK_ADDR = 0xFE
DBG_SECRET_ADDR = 0xFF
DBG_SECRET      = 0xDEADC0DE

_gpr      = {i: 0 for i in range(16)}
_gpr[0x0] = 0x00000001   # PC (halted)
_gpr[0x1] = 0xBAADF00D   # SP
_gpr[0x2] = 0x00004000   # LR
_unlocked = False


def _cpu_write(addr: int, value: int):
    global _unlocked
    if addr == DBG_UNLOCK_ADDR and value == DBG_UNLOCK_KEY:
        _unlocked = True
    elif addr < 0x10:
        _gpr[addr] = value & 0xFFFFFFFF


def _cpu_read(addr: int) -> int:
    if addr == DBG_SECRET_ADDR:
        return DBG_SECRET if _unlocked else 0xDEADBEEF
    if addr < 0x10:
        return _gpr.get(addr, 0)
    return 0


# -----------------------------------------------------------------------
#  Routes
# -----------------------------------------------------------------------
@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/design")
def design():
    return send_file(DESIGN_V, mimetype="text/plain")


@app.post("/debug/write")
def dbg_write():
    data = request.get_json(silent=True) or {}
    try:
        addr  = int(str(data.get("addr",  "")), 16)
        value = int(str(data.get("value", "")), 16)
    except ValueError:
        return jsonify({"error": "addr and value must be hex strings"}), 400
    if not (0 <= addr <= 0xFF):
        return jsonify({"error": "addr out of range"}), 400
    _cpu_write(addr, value)
    return jsonify({"ok": True, "unlocked": _unlocked})


@app.post("/debug/read")
def dbg_read():
    data = request.get_json(silent=True) or {}
    try:
        addr = int(str(data.get("addr", "")), 16)
    except ValueError:
        return jsonify({"error": "addr must be a hex string"}), 400
    if not (0 <= addr <= 0xFF):
        return jsonify({"error": "addr out of range"}), 400
    val = _cpu_read(addr)
    return jsonify({"value": f"{val:08X}"})


@app.post("/flag")
def flag():
    data   = request.get_json(silent=True) or {}
    secret = str(data.get("secret", "")).strip().upper().lstrip("0X")
    if secret == f"{DBG_SECRET:08X}":
        return jsonify({"flag": open(FLAG_FILE).read().strip()})
    return jsonify({"error": "wrong secret"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
