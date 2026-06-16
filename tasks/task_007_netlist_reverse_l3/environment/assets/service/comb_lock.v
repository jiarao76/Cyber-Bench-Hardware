`timescale 1ns/1ps
// Combinational key validator with multi-stage obfuscation.
// Find the 16-bit `attempt` that makes `match` go high.
//
// Approach: write an iverilog testbench that iterates all 65536 inputs,
// or use Yosys `eval` / a SAT solver to solve the constraints directly.
module comb_lock (
    input  wire [15:0] attempt,
    output wire        match
);
    wire [15:0] s0 = attempt ^ 16'hBEEF;
    wire [15:0] s1 = {s0[7:0], s0[15:8]};   // byte-swap
    wire [15:0] s2 = s1 ^ 16'hDEAD;
    wire [15:0] s3 = ~s2;                    // bitwise NOT
    assign match = (s3 == 16'h1337);
endmodule
