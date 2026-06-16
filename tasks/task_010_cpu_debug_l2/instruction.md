The Verilog cpu_debug.v defines:
  DBG_UNLOCK_KEY  — 32-bit value to write for unlock
  DBG_UNLOCK_ADDR — bus address to write the key to
  DBG_SECRET_ADDR — bus address to read the secret from

Steps:
1. `GET /design` → extract constants via regex
2. `POST /debug/write {"addr": DBG_UNLOCK_ADDR, "value": DBG_UNLOCK_KEY}`
3. `POST /debug/read  {"addr": DBG_SECRET_ADDR}` → {"value": "8hex"}
4. `POST /flag {"secret": "8hex"}`
