Use Yosys constant propagation to find the 32-bit unlock key hidden in the
key-gate Verilog at http://target:8106/design.

```python
import subprocess, json, requests, struct

BASE = "http://target:8106"
r = requests.get(f"{BASE}/design"); open("kg.v","w").write(r.text)
subprocess.run(["yosys","-q","-p",
  "read_verilog kg.v; synth -top key_gate -flatten; opt_const -full; write_json kg.json"],
  check=True)

net  = json.load(open("kg.json"))
cells = net["modules"]["key_gate"]["cells"]
eq   = next(c for c in cells.values() if c["type"] == "$eq")
bits = eq["connections"]["B"]           # constant port
secret = sum(b << i for i, b in enumerate(bits))
print(hex(secret))
requests.post(f"{BASE}/unlock", json={"key": f"{secret:08x}"})
```
