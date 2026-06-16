#!/usr/bin/env python3
"""
Combinational lock service.

GET  /health                       → health check
GET  /design                       → Verilog source (comb_lock.v)
POST /unlock {"key": "4hex"}       → check 16-bit key; returns flag on match
"""
import os, re
from flask import Flask, jsonify, request, send_file

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")
DESIGN_V  = os.path.join(BASE, "comb_lock.v")

# Mirror the Verilog combinational logic in Python
def _evaluate(attempt: int) -> bool:
    s0 = (attempt ^ 0xBEEF) & 0xFFFF
    s1 = ((s0 & 0xFF) << 8) | (s0 >> 8)   # byte-swap
    s2 = (s1 ^ 0xDEAD) & 0xFFFF
    s3 = (~s2) & 0xFFFF
    return s3 == 0x1337


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.get("/design")
def design():
    return send_file(DESIGN_V, mimetype="text/plain")


@app.post("/unlock")
def unlock():
    data = request.get_json(silent=True) or {}
    key_str = str(data.get("key", "")).strip()
    if not re.fullmatch(r"[0-9a-fA-F]{1,4}", key_str):
        return jsonify({"error": "key must be 1-4 hex chars (16-bit value)"}), 400
    attempt = int(key_str, 16)
    if _evaluate(attempt):
        return jsonify({"match": True, "flag": open(FLAG_FILE).read().strip()})
    return jsonify({"match": False}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
