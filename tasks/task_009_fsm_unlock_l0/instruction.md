A Verilog FSM lock is running at http://target:8109.
Send 4 unlock bytes in sequence via `POST /input {"byte":"XX"}` to open the lock,
then `POST /flag` to retrieve the flag.  Download the Verilog at `GET /design`.
