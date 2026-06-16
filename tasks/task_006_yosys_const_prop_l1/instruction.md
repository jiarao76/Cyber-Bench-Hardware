A Verilog key-gate module is served at http://target:8106/design.
The gate computes SECRET = f(INIT) through rotate, XOR, NOT, and
swap operations on localparams.  Use `GET /design` to retrieve it,
then `POST /unlock {"key":"8hex"}` to submit the result.

Hint: You can use Yosys constant propagation to resolve the chain
automatically (`synth -flatten; opt_const -full; write_json`).
