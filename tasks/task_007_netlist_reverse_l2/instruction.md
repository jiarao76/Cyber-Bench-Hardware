Download the Verilog from http://target:8107/design.
The circuit applies: XOR → byte-swap → XOR → NOT → compare.
Find the 16-bit `attempt` that produces `match=1`.

Approach A (iverilog — hardware simulation):
  Write a testbench with a for-loop over 0..65535, print the matching value.
  `iverilog -o tb comb_lock.v tb_brute.v && vvp tb`

Approach B (algebraic — trace back through the gates):
  Work backwards from the comparison constant to find the required input.

Submit: `POST /unlock {"key": "4hex"}`
