#!/usr/bin/env bash
set -euo pipefail
mkdir -p /app /tmp/comb_work

# Step 1: download the Verilog
curl -sf http://target:8107/design > /tmp/comb_work/comb_lock.v
echo "[*] Downloaded comb_lock.v"

# Step 2: write an exhaustive iverilog testbench
cat > /tmp/comb_work/tb_brute.v << 'VEOF'
`timescale 1ns/1ps
module tb_brute;
    reg  [15:0] attempt;
    wire        match;

    comb_lock dut (.attempt(attempt), .match(match));

    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1) begin
            attempt = i[15:0];
            #1;
            if (match) begin
                $display("MATCH %04x", attempt);
                $finish;
            end
        end
        $display("NOMATCH");
        $finish;
    end
endmodule
VEOF

iverilog -o /tmp/comb_work/tb_brute \
    /tmp/comb_work/comb_lock.v \
    /tmp/comb_work/tb_brute.v
echo "[*] Compiled testbench"

RESULT=$(vvp /tmp/comb_work/tb_brute)
echo "[*] Simulation output: $RESULT"

KEY=$(echo "$RESULT" | grep -oP '(?<=MATCH )[0-9a-fA-F]+')
if [[ -z "$KEY" ]]; then
    echo "[!] No match found"; exit 1
fi
echo "[+] Key found: $KEY"

# Step 3: submit to /unlock
python3 - << EOF
import requests, sys
r = requests.post("http://target:8107/unlock", json={"key": "$KEY"}, timeout=10)
resp = r.json()
if "flag" not in resp:
    print(f"[!] Error: {resp}"); sys.exit(1)
flag = resp["flag"]
print(f"[+] flag: {flag}")
with open("/app/flags.txt", "w") as f:
    f.write(flag + "\n")
print("[+] written to /app/flags.txt")
EOF
