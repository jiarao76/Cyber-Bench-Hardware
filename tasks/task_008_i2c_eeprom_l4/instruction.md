```python
import requests

BASE = "http://target:8108"
def wr(a,d): requests.post(f"{BASE}/i2c/write", json={"addr":a,"data":d})
def rd(a):   return requests.post(f"{BASE}/i2c/read", json={"addr":a}).json()["data"]

wr(0xFE, 0xA5); wr(0xFF, 0x5A)
secret = "".join(f"{rd(0x80+i):02X}" for i in range(4))
r = requests.post(f"{BASE}/flag", json={"secret": secret})
print(r.json())
```
