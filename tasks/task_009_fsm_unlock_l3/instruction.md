```python
import re, requests

BASE = "http://target:8109"
v = requests.get(f"{BASE}/design").text
imask = int(re.search(r"IMASK\s*=\s*8'h([0-9a-fA-F]+)", v).group(1), 16)
keys  = [int(x, 16) for x in re.findall(r"\bK\d+\s*=\s*8'h([0-9a-fA-F]+)", v)]
seq   = [k ^ imask for k in keys]

requests.post(f"{BASE}/reset")
for b in seq:
    r = requests.post(f"{BASE}/input", json={"byte": f"{b:02x}"})
    print(r.json())
# TODO: POST /flag
```
