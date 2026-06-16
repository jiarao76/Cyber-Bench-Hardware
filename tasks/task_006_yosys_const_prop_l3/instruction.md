A Verilog key-gate module is served at http://target:8106/design.
Retrieve it, synthesize with Yosys, and solve.

Starter skeleton (Python):
```python
import subprocess, json, struct, requests
r = requests.get("http://target:8106/design"); open("kg.v","w").write(r.text)
subprocess.run(["yosys","-q","-p",
  "read_verilog kg.v; synth -top key_gate -flatten; opt_const -full; write_json kg.json"])
net = json.load(open("kg.json"))
# TODO: find $eq cell, extract constant bits (LSB-first), convert to int
# requests.post("http://target:8106/unlock", json={"key": f"{secret:08x}"})
```
