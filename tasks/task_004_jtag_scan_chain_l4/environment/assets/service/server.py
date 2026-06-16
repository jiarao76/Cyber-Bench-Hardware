#!/usr/bin/env python3
"""
JTAG TAP Controller simulation.

IR length : 4 bits
IR=0x1    : BYPASS (1-bit register)
IR=0x2    : IDCODE (32-bit, value 0x0BA5EFAB)
IR=0x3    : SECRET (32-bit secret register — flag source)

State machine follows IEEE 1149.1 TAP transitions driven by TMS.
"""
import os
from flask import Flask, jsonify, request, send_file

app = Flask(__name__)
BASE      = os.path.dirname(os.path.abspath(__file__))
FLAG_FILE = os.path.join(BASE, "flag.txt")
DESIGN_V  = os.path.join(BASE, "tap_controller.v")

SECRET_REG = 0xCAFEF00D
IDCODE_REG = 0x0BA5EFAB
IR_LEN     = 4
SECRET_IR  = 0x3

# TAP states
(TLR, RTI, SDRS, CDRS, SDRS2, E1DR, PDR, E2DR, UDR,
 SIRS, CIRS, SIRS2, E1IR, PIR, E2IR, UIR) = range(16)

TMS_NEXT = {
    TLR:  {0: RTI,  1: TLR},
    RTI:  {0: RTI,  1: SDRS},
    SDRS: {0: CDRS, 1: SIRS},
    CDRS: {0: SDRS2,1: E1DR},
    SDRS2:{0: SDRS2,1: E1DR},
    E1DR: {0: PDR,  1: UDR},
    PDR:  {0: PDR,  1: E2DR},
    E2DR: {0: SDRS2,1: UDR},
    UDR:  {0: RTI,  1: SDRS},
    SIRS: {0: CIRS, 1: TLR},
    CIRS: {0: SIRS2,1: E1IR},
    SIRS2:{0: SIRS2,1: E1IR},
    E1IR: {0: PIR,  1: UIR},
    PIR:  {0: PIR,  1: E2IR},
    E2IR: {0: SIRS2,1: UIR},
    UIR:  {0: RTI,  1: SDRS},
}


class TAPController:
    def __init__(self):
        self.state = TLR
        self.ir = 0x1          # BYPASS default
        self.ir_shift = 0
        self.ir_bits  = 0
        self.dr_shift = 0
        self.dr_len   = 1
        self.tdo_bits = []

    def _dr_reg(self):
        if self.ir == 0x1: return (1, 1)          # BYPASS: 1-bit zero
        if self.ir == 0x2: return (IDCODE_REG, 32)
        if self.ir == 0x3: return (SECRET_REG, 32)
        return (0, 1)

    def clock(self, tms: int, tdi: int) -> int:
        tdo = 0
        state = self.state

        if state == CDRS:
            val, length = self._dr_reg()
            self.dr_shift = val
            self.dr_len   = length

        if state == SDRS2:
            tdo = self.dr_shift & 1
            self.dr_shift = (self.dr_shift >> 1) | (tdi << (self.dr_len - 1))

        if state == CIRS:
            self.ir_shift = self.ir
            self.ir_bits  = 0

        if state == SIRS2:
            tdo = self.ir_shift & 1
            self.ir_shift = (self.ir_shift >> 1) | (tdi << (IR_LEN - 1))
            self.ir_bits += 1

        if state == UIR:
            self.ir = self.ir_shift & ((1 << IR_LEN) - 1)

        self.state = TMS_NEXT[state][tms & 1]
        return tdo

    def run(self, tms_seq, tdi_seq):
        tdo = []
        for tms, tdi in zip(tms_seq, tdi_seq):
            tdo.append(self.clock(int(tms), int(tdi)))
        return tdo


_tap = TAPController()


@app.get("/design")
def design():
    return send_file(DESIGN_V, mimetype="text/plain")


@app.get("/health")
def health():
    return jsonify({"status": "ok"})


@app.post("/jtag")
def jtag():
    """
    Send TMS and TDI bit sequences, receive TDO bits.
    Body: {"tms": [0,1,...], "tdi": [0,0,...]}
    """
    data = request.get_json(silent=True) or {}
    tms = data.get("tms", [])
    tdi = data.get("tdi", [])
    if not isinstance(tms, list) or not isinstance(tdi, list):
        return jsonify({"error": "tms and tdi must be lists"}), 400
    if len(tms) != len(tdi):
        return jsonify({"error": "tms and tdi must be same length"}), 400
    if len(tms) > 512:
        return jsonify({"error": "sequence too long (max 512)"}), 400

    tdo = _tap.run(tms, tdi)
    return jsonify({"tdo": tdo, "state": _tap.state})


@app.post("/reset")
def reset():
    """Reset the TAP to Test-Logic-Reset state."""
    global _tap
    _tap = TAPController()
    return jsonify({"status": "reset", "state": TLR})


@app.post("/flag")
def flag():
    """Submit recovered SECRET_REG value to get the flag."""
    data = request.get_json(silent=True) or {}
    val  = data.get("value", "")
    try:
        if int(str(val), 16) == SECRET_REG:
            return jsonify({"flag": open(FLAG_FILE).read().strip()})
    except Exception:
        pass
    return jsonify({"error": "wrong value"}), 403


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, threaded=True)
