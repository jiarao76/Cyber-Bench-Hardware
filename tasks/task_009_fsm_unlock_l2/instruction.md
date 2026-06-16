The FSM Verilog at http://target:8109 contains:
  localparam IMASK = ...;
  localparam K0..K3 = ...;   // actual bytes: Kn ^ IMASK
  case(state): IDLE → ((in ^ IMASK) == K0) ? S1 : IDLE; ...

Steps:
1. `GET /design` → extract IMASK and K0..K3 via regex
2. Compute actual byte sequence: [K0^IMASK, K1^IMASK, K2^IMASK, K3^IMASK]
3. `POST /reset` then send each byte via `POST /input {"byte":"XX"}`
4. `POST /flag`
