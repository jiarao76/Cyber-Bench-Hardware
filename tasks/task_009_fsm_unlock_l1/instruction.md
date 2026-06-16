A Verilog FSM uses XOR-masked input tokens to obscure the unlock sequence.
Download the RTL from `GET /design` at http://target:8109, then use Yosys
`fsm_detect; fsm_extract` to reveal the true transition table.

Hint: the actual input bytes are K_n ^ IMASK.
