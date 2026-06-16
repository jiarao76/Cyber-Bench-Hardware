#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app /tmp/fsm_work

# Download RTL
curl -sf http://target:8109/design > /tmp/fsm_work/fsm_lock.v
echo "[*] Downloaded Verilog FSM"

# Use Yosys to simplify the design — const propagation resolves IMASK^Kn
# and fsm_extract shows the raw state transitions
yosys -q -p "
  read_verilog /tmp/fsm_work/fsm_lock.v
  hierarchy -top fsm_lock
  proc
  opt_const -full
  fsm_detect
  fsm_extract
  write_rtlil /tmp/fsm_work/fsm_simplified.rtlil
" 2>/dev/null && echo "[*] Yosys FSM extraction done" || true

# Also grep the Verilog for the unlock sequence directly
# (Yosys opt_const reduces (in ^ IMASK) == Kn  →  in == Kn^IMASK)
python3 - << 'EOF'
import re, requests

BASE = "http://target:8109"

# Read the RTLIL (simplified) or fall back to the raw Verilog
try:
    with open("/tmp/fsm_work/fsm_simplified.rtlil") as f:
        src = f.read()
except FileNotFoundError:
    src = ""

# After opt_const, comparisons become  $eq{A=in, B=const_val}
# Look for 8-bit hex constants in the simplified design
tokens_rtlil = re.findall(r"8'([0-9a-fA-F]{2})", src)

# Also check raw Verilog: compute K_n ^ IMASK
verilog = requests.get(f"{BASE}/design", timeout=10).text
imask_m = re.search(r"IMASK\s*=\s*8'h([0-9a-fA-F]{2})", verilog)
kvals   = re.findall(r"\bK\d+\s*=\s*8'h([0-9a-fA-F]{2})", verilog)

if imask_m and kvals:
    imask   = int(imask_m.group(1), 16)
    seq     = [int(k, 16) ^ imask for k in kvals]
    print(f"[+] Recovered unlock sequence from Verilog (Kn^IMASK): "
          f"{[hex(b) for b in seq]}")
elif tokens_rtlil:
    seq = [int(t, 16) for t in tokens_rtlil[:4]]
    print(f"[+] Recovered sequence from Yosys RTLIL: {[hex(b) for b in seq]}")
else:
    print("[!] Falling back to brute-force exploration (depth-4 BFS)...")
    from itertools import product
    found = None
    # Reset and try every 4-byte combination until unlocked (not feasible for real,
    # but demonstrates the approach when no source is available)
    for seq in product(range(256), repeat=4):
        requests.post(f"{BASE}/reset", timeout=5)
        for b in seq:
            r = requests.post(f"{BASE}/input", json={"byte": f"{b:02x}"}, timeout=5)
            if r.json().get("unlocked"):
                found = list(seq)
                break
        if found:
            break
    seq = found or []

# Send unlock sequence
requests.post(f"{BASE}/reset", timeout=5)
for b in seq:
    r = requests.post(f"{BASE}/input", json={"byte": f"{b:02x}"}, timeout=10)
    print(f"    sent 0x{b:02X} → unlocked={r.json()['unlocked']}")

r = requests.post(f"{BASE}/flag", timeout=10)
resp = r.json()
if "flag" not in resp:
    print(f"[!] Error: {resp}")
    import sys; sys.exit(1)

flag = resp["flag"]
print(f"[+] flag: {flag}")
with open("/app/flags.txt", "w") as f:
    f.write(flag + "\n")
print("[+] written to /app/flags.txt")
EOF
