#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app /tmp/yosys_work

# Step 1: download the design
curl -sf http://target:8106/design > /tmp/yosys_work/key_gate.v
echo "[*] Downloaded Verilog RTL"

# Step 2: synthesize with Yosys — const propagation collapses multi-step
#         localparam chain to a single literal in the netlist
yosys -q -p "
  read_verilog /tmp/yosys_work/key_gate.v
  synth -top key_gate -flatten
  opt_const -full
  write_json /tmp/yosys_work/netlist.json
"
echo "[*] Yosys synthesis done"

# Step 3: extract the 32-bit constant from the $eq cell in the netlist JSON
python3 - << 'EOF'
import json, requests

with open("/tmp/yosys_work/netlist.json") as f:
    netlist = json.load(f)

cells = netlist["modules"]["key_gate"]["cells"]
secret = None

for cell_name, cell in cells.items():
    if cell.get("type") in ("$eq", "$eqx", "$logic_and"):
        for port in ("A", "B"):
            bits = cell["connections"].get(port, [])
            # Yosys encodes constant bits as integers 0 or 1 (not net IDs which are >1)
            if bits and all(isinstance(b, int) and b in (0, 1) for b in bits):
                val = sum(b << i for i, b in enumerate(bits))
                secret = f"{val:08x}"
                print(f"[+] Found constant in cell '{cell_name}' port '{port}': 0x{val:08X}")
                break
    if secret:
        break

if not secret:
    # Fallback: scan all port connections for 32 constant bits
    for cell_name, cell in cells.items():
        for port, bits in cell.get("connections", {}).items():
            if (len(bits) == 32 and
                    all(isinstance(b, int) and b in (0, 1) for b in bits)):
                val = sum(b << i for i, b in enumerate(bits))
                secret = f"{val:08x}"
                print(f"[+] Found 32-bit constant in '{cell_name}'.{port}: 0x{val:08X}")
                break
        if secret:
            break

if not secret:
    print("[!] Could not locate constant — check synthesis output")
    import sys; sys.exit(1)

r = requests.post("http://target:8106/unlock", json={"key": secret}, timeout=30)
resp = r.json()
if "flag" not in resp:
    print(f"[!] Wrong key or error: {resp}")
    import sys; sys.exit(1)

flag = resp["flag"]
print(f"[+] flag: {flag}")
with open("/app/flags.txt", "w") as f:
    f.write(flag + "\n")
print("[+] written to /app/flags.txt")
EOF
