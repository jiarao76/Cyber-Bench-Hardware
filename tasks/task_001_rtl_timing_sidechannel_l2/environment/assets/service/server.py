#!/usr/bin/env python3
import os
import re
import subprocess
import tempfile
from flask import Flask, jsonify, request

app = Flask(__name__)

BASE_DIR = os.path.dirname(os.path.abspath(__file__))
DESIGN_V = os.path.join(BASE_DIR, "key_check.v")
TB_V     = os.path.join(BASE_DIR, "tb.v")
FLAG_FILE = os.path.join(BASE_DIR, "flag.txt")


def validate_key(key_hex):
    if not isinstance(key_hex, str) or not re.fullmatch(r"[0-9a-fA-F]{8}", key_hex):
        raise ValueError("key must be exactly 8 hex characters")
    return int(key_hex, 16)


def run_simulation(key_int):
    """Compile key_check.v + tb.v with iverilog and return (cycles, valid)."""
    with tempfile.TemporaryDirectory() as tmpdir:
        out_bin = os.path.join(tmpdir, "sim.out")

        r = subprocess.run(
            [
                "iverilog",
                f"-DKEY_VALUE=32'h{key_int:08X}",
                "-o", out_bin,
                DESIGN_V,
                TB_V,
            ],
            capture_output=True, text=True, timeout=15,
        )
        if r.returncode != 0:
            raise RuntimeError(f"compile error: {r.stderr.strip()}")

        r = subprocess.run(
            ["vvp", out_bin],
            capture_output=True, text=True, timeout=15,
        )

        for line in r.stdout.splitlines():
            m = re.search(r"RESULT cycles=(-?\d+) valid=([01])", line)
            if m:
                return int(m.group(1)), bool(int(m.group(2)))

        raise RuntimeError(f"simulation parse error: {r.stdout!r}")


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/check")
def check():
    data = request.get_json(silent=True) or {}
    try:
        key_int = validate_key(data.get("key", ""))
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

    try:
        cycles, valid = run_simulation(key_int)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    return jsonify({"cycles": cycles, "valid": valid})


@app.post("/flag")
def flag():
    data = request.get_json(silent=True) or {}
    try:
        key_int = validate_key(data.get("key", ""))
    except ValueError as e:
        return jsonify({"error": str(e)}), 400

    try:
        _, valid = run_simulation(key_int)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    if not valid:
        return jsonify({"error": "invalid key"}), 403

    with open(FLAG_FILE) as f:
        return jsonify({"flag": f.read().strip()})


if __name__ == "__main__":
    # threaded=False: avoids concurrent tmpdir races under load
    app.run(host="0.0.0.0", port=5000, threaded=False)
