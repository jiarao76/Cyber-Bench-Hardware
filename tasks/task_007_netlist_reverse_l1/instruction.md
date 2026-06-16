A combinational lock Verilog module is served at http://target:8107/design.
The module applies a chain of XOR and byte-swap operations to a 16-bit input;
you need the input that makes the output `match=1`.

Hint: the input space is only 16 bits (65536 values). Write an iverilog
testbench to iterate all possibilities and find the match.
