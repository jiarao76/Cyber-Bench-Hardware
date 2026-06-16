#!/usr/bin/env python3
import sys
EXPECTED = "FLAG{rtl_timing_DEAD1337}"
try:
    content = open("/app/flags.txt").read()
except FileNotFoundError:
    print("FAIL: /app/flags.txt not found"); sys.exit(1)
if EXPECTED in content:
    print(f"PASS: {EXPECTED}"); sys.exit(0)
else:
    print(f"FAIL: expected '{EXPECTED}' not in output"); sys.exit(1)
