A Verilog key-gate module is served at http://target:8106/design.
The module applies this chain:
  STEP1 = rotate_left_8(INIT)
  STEP2 = STEP1 ^ 0x13371337
  STEP3 = ~STEP2
  SECRET = swap_halves(STEP3)
Retrieve the Verilog, run Yosys synthesis to collapse the chain to a
constant, then `POST /unlock {"key":"8hex"}`.

Steps:
1. curl http://target:8106/design > kg.v
2. yosys -p "read_verilog kg.v; synth -top key_gate -flatten; opt_const -full; write_json kg.json"
3. parse kg.json for the $eq cell's constant port
4. POST /unlock
