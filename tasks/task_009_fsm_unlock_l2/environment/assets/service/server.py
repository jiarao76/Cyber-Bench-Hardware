#!/usr/bin/env python3
"""
Verilog FSM lock service.  The unlock sequence is hidden in the RTL
via Gray-coded state encoding and XOR-masked input tokens.

GET  /design          → Verilog source (for Yosys analysis)
POST /input {"byte": "XX"}  → drive FSM one step, returns {"unlocked": bool}
POST /reset           → return FSM to IDLE
POST /flag            → return flag if FSM is currently in OPEN state
"""
import os
from flask import Flask, jsonify, request, send_file

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")
DESIGN_V  = os.path.join(BASE, "fsm_lock.v")

# Mirror the Verilog FSM (state values are integers, not Gray codes)
UNLOCK_SEQ = [0xDE, 0xAD, 0xBE, 0xEF]
_step_idx  = 0   # how many bytes of the sequence have been accepted
_unlocked  = False


def _transition(byte: int):
    global _step_idx, _unlocked
    if _unlocked:
        return
    if byte == UNLOCK_SEQ[_step_idx]:
        _step_idx += 1
        if _step_idx == len(UNLOCK_SEQ):
            _unlocked = True
    else:
        _step_idx = 0   # wrong byte → return to IDLE
        # Give the new byte a chance as K0 in one step
        if byte == UNLOCK_SEQ[0]:
            _step_idx = 1


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/design")
def design():
    return send_file(DESIGN_V, mimetype="text/plain")


@app.post("/input")
def fsm_input():
    global _step_idx, _unlocked
    data = request.get_json(silent=True) or {}
    byte_hex = data.get("byte", "")
    if not isinstance(byte_hex, str) or len(byte_hex) != 2:
        return jsonify({"error": "byte must be 2 hex chars"}), 400
    try:
        byte = int(byte_hex, 16)
    except ValueError:
        return jsonify({"error": "invalid hex"}), 400
    _transition(byte)
    return jsonify({"unlocked": _unlocked, "progress": _step_idx if not _unlocked else 4})


@app.post("/reset")
def reset():
    global _step_idx, _unlocked
    _step_idx = 0
    _unlocked = False
    return jsonify({"status": "reset"})


@app.post("/flag")
def flag():
    if _unlocked:
        return jsonify({"flag": open(FLAG_FILE).read().strip()})
    return jsonify({"error": "FSM not in OPEN state"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
