#!/usr/bin/env python3
"""
I2C EEPROM simulation (24C-series style).

Normal reads (address 0x00-0x0F): return public lorem-ipsum data.
Hidden manufacturer page (address 0x80-0x8F): locked, returns 0xFF.

Unlock sequence:
  Write 0xA5 to address 0xFE  (write unlock token)
  Write 0x5A to address 0xFF  (confirm)
  Then reads from 0x80-0x8F   return the secret page.

The secret at address 0x80 is 0xBEEFC0DE (4 bytes, big-endian, spanning 0x80-0x83).
The flag is claimed by POSTing the correct 4-byte secret to /flag.
"""
import os
from flask import Flask, jsonify, request

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")

# Public EEPROM data (addresses 0x00-0x0F)
PUBLIC_MEM = {i: (0xA0 + i) & 0xFF for i in range(0x10)}

# Secret manufacturer page (addresses 0x80-0x8F)
SECRET_PAGE = {
    0x80: 0xBE, 0x81: 0xEF, 0x82: 0xC0, 0x83: 0xDE,
    **{i: 0x00 for i in range(0x84, 0x90)},
}

_unlock_step = 0   # 0=locked, 1=got 0xA5, 2=unlocked


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/i2c/write")
def i2c_write():
    """Simulate an I2C write transaction: {"addr": 0xNN, "data": 0xNN}"""
    global _unlock_step
    data = request.get_json(silent=True) or {}
    addr = data.get("addr")
    val  = data.get("data")
    if not isinstance(addr, int) or not isinstance(val, int):
        return jsonify({"error": "addr and data must be integers"}), 400
    if not (0 <= addr <= 0xFF and 0 <= val <= 0xFF):
        return jsonify({"error": "addr and data must be 0-255"}), 400

    # Unlock state machine
    if addr == 0xFE and val == 0xA5:
        _unlock_step = 1
    elif addr == 0xFF and val == 0x5A and _unlock_step == 1:
        _unlock_step = 2
    else:
        _unlock_step = 0      # wrong sequence resets lock

    return jsonify({"ack": True})


@app.post("/i2c/read")
def i2c_read():
    """Simulate an I2C read transaction: {"addr": 0xNN} -> {"data": 0xNN}"""
    data = request.get_json(silent=True) or {}
    addr = data.get("addr")
    if not isinstance(addr, int) or not (0 <= addr <= 0xFF):
        return jsonify({"error": "addr must be 0-255"}), 400

    if addr in PUBLIC_MEM:
        return jsonify({"data": PUBLIC_MEM[addr]})

    if addr in SECRET_PAGE:
        if _unlock_step == 2:
            return jsonify({"data": SECRET_PAGE[addr]})
        return jsonify({"data": 0xFF})   # locked: return 0xFF

    return jsonify({"data": 0xFF})


@app.post("/flag")
def flag():
    """Submit 4-byte secret (hex string) to claim the flag."""
    data = request.get_json(silent=True) or {}
    secret = data.get("secret", "")
    if str(secret).upper() == "BEEFC0DE":
        return jsonify({"flag": open(FLAG_FILE).read().strip()})
    return jsonify({"error": "wrong secret"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
