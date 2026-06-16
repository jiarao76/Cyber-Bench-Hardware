A CPU debug interface at http://target:8110 exposes a register bus.
Download `GET /design` to get the Verilog.  There is a DBG_UNLOCK_ADDR
and a DBG_SECRET_ADDR.  Writing DBG_UNLOCK_KEY to the unlock address
makes the secret register readable.

APIs: `POST /debug/write {"addr":"FE","value":"C0DEBABE"}`
      `POST /debug/read  {"addr":"FF"}`
      `POST /flag        {"secret":"8hex"}`
