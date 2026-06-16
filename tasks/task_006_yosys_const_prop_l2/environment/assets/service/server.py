#!/usr/bin/env python3
import os, re
from flask import Flask, jsonify, request, send_file

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")
DESIGN_V  = os.path.join(BASE, "key_gate.v")

# Mirror the Verilog constant chain
_INIT   = 0xDEADC0DE
_STEP1  = ((_INIT & 0xFFFFFF) << 8) | (_INIT >> 24)
_STEP2  = _STEP1 ^ 0x13371337
_STEP3  = (~_STEP2) & 0xFFFFFFFF
SECRET  = ((_STEP3 & 0xFFFF) << 16) | (_STEP3 >> 16)   # 0x32164108


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/design")
def design():
    """Return the Verilog RTL for analysis."""
    return send_file(DESIGN_V, mimetype="text/plain")


@app.post("/unlock")
def unlock():
    """Submit recovered key to claim the flag."""
    data = request.get_json(silent=True) or {}
    key = data.get("key", "")
    if not re.fullmatch(r"[0-9a-fA-F]{8}", str(key)):
        return jsonify({"error": "key must be 8 hex chars"}), 400
    if int(key, 16) == SECRET:
        return jsonify({"flag": open(FLAG_FILE).read().strip()})
    return jsonify({"error": "wrong key"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
