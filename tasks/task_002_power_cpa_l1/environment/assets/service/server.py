#!/usr/bin/env python3
import os, re, random, subprocess, tempfile
from flask import Flask, jsonify, request

app = Flask(__name__)
BASE  = os.path.dirname(os.path.abspath(__file__))
FLAG  = open(os.path.join(BASE, "flag.txt")).read().strip()
NOISE = 0.5   # gaussian noise sigma added to power measurement


def sbox_hw_via_sim(pt_byte: int) -> int:
    """Run aes_sbox.v simulation, return Hamming weight of S-box output."""
    with tempfile.TemporaryDirectory() as d:
        out = os.path.join(d, "sim.out")
        r = subprocess.run(
            ["iverilog", f"-DINPUT_BYTE=8'h{pt_byte:02X}", "-o", out,
             os.path.join(BASE, "aes_sbox.v"),
             os.path.join(BASE, "tb_sbox.v")],
            capture_output=True, text=True, timeout=10)
        if r.returncode != 0:
            raise RuntimeError(r.stderr)
        r = subprocess.run(["vvp", out], capture_output=True, text=True, timeout=10)
        m = re.search(r"hw=(\d+)", r.stdout)
        if not m:
            raise RuntimeError(f"parse error: {r.stdout!r}")
        return int(m.group(1))


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/measure")
def measure():
    """Accept a plaintext byte, return noisy power measurement.

    Power model: HW(SBox[pt XOR SECRET_KEY]) + gaussian noise.
    Collect ~300 traces across all pt values and run CPA to recover the key.
    """
    data = request.get_json(silent=True) or {}
    pt_hex = data.get("pt", "")
    if not re.fullmatch(r"[0-9a-fA-F]{2}", str(pt_hex)):
        return jsonify({"error": "pt must be 2 hex chars (1 byte)"}), 400

    try:
        hw = sbox_hw_via_sim(int(pt_hex, 16))
    except Exception as e:
        return jsonify({"error": str(e)}), 500

    power = hw + random.gauss(0, NOISE)
    return jsonify({"power": round(power, 4)})


@app.post("/flag")
def flag():
    """Return flag when correct key byte is submitted."""
    data = request.get_json(silent=True) or {}
    key_hex = data.get("key", "")
    if not re.fullmatch(r"[0-9a-fA-F]{2}", str(key_hex)):
        return jsonify({"error": "key must be 2 hex chars"}), 400
    if int(key_hex, 16) == 0x3F:
        return jsonify({"flag": FLAG})
    return jsonify({"error": "wrong key"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=False)
