#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app

python3 - <<'EOF'
import requests

BASE = "http://target:8104"

requests.post(f"{BASE}/reset", timeout=10)
print("[*] TAP reset to Test-Logic-Reset")

# State machine navigation to shift out the SECRET DR (IR=0x3):
#
# Phase 1 – load IR=0x3 (SELECT_SECRET)
#   TLR→RTI:    TMS=0
#   RTI→SDRS:   TMS=1
#   SDRS→SIRS:  TMS=1
#   SIRS→CIRS:  TMS=0
#   CIRS→SIRS2: TMS=0  (shift IR bits: 4 bits, LSB first: 1,1,0,0 = 0x3)
#   SIRS2×3:    TMS=0  (shift remaining 3 bits)
#   SIRS2→E1IR: TMS=1  (last bit also shifted on exit)
#   E1IR→UIR:   TMS=1
#   UIR→RTI:    TMS=0

tms_ir = [0, 1, 1, 0, 0, 0, 0, 1, 1, 0]
tdi_ir = [0, 0, 0, 0, 1, 1, 0, 0, 0, 0]   # IR=0x3 = 0011 LSB-first

r = requests.post(f"{BASE}/jtag", json={"tms": tms_ir, "tdi": tdi_ir}, timeout=30)
print(f"[*] IR load complete, state={r.json()['state']}")

# Phase 2 – shift out 32-bit DR (SECRET register)
#   RTI→SDRS:   TMS=1
#   SDRS→CDRS:  TMS=0
#   CDRS→SIRS2: TMS=0  (capture)
#   SIRS2×31:   TMS=0  (shift 31 bits)
#   SIRS2→E1DR: TMS=1  (last bit + exit)
#   E1DR→UDR:   TMS=1

tms_dr = [1, 0, 0] + [0]*31 + [1, 1]
tdi_dr = [0, 0, 0] + [0]*31 + [0, 0]

r = requests.post(f"{BASE}/jtag", json={"tms": tms_dr, "tdi": tdi_dr}, timeout=30)
tdo = r.json()["tdo"]

# TDO bits start at index 3 (after RTI→SDRS→CDRS→first ShiftDR)
# 32 bits shifted out from index 3..34
dr_bits = tdo[3:35]
secret = 0
for i, b in enumerate(dr_bits):
    secret |= (b << i)

print(f"[+] Shifted out SECRET register: 0x{secret:08X}")

r = requests.post(f"{BASE}/flag", json={"value": f"{secret:08x}"}, timeout=30)
flag = r.json()["flag"]
print(f"[+] flag: {flag}")
with open("/app/flags.txt", "w") as f:
    f.write(flag + "\n")
print("[+] written to /app/flags.txt")
EOF
