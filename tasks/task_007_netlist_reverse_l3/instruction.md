Solve the combinational lock at http://target:8107.

Starter testbench skeleton (`tb_brute.v`):
```verilog
`timescale 1ns/1ps
module tb_brute;
    reg  [15:0] attempt;
    wire        match;
    comb_lock dut (.attempt(attempt), .match(match));
    integer i;
    initial begin
        for (i = 0; i < 65536; i = i + 1) begin
            attempt = i[15:0]; #1;
            if (match) begin $display("MATCH %04x", attempt); $finish; end
        end
    end
endmodule
```
Compile: `iverilog -o tb comb_lock.v tb_brute.v && vvp tb`
Then: `POST /unlock {"key": "<result>"}`
