`timescale 1ns/1ps

// Obfuscated key comparator.
// Developer believed chaining constant operations would hide the secret.
// Synthesis with const-propagation trivially collapses all steps to one literal.
module key_gate (
    input  wire [31:0] attempt,
    output wire        match
);
    localparam [31:0] INIT   = 32'hDEADC0DE;
    localparam [31:0] STEP1  = {INIT[23:0],   INIT[31:24]};   // rotate-left-8
    localparam [31:0] STEP2  = STEP1 ^ 32'h13371337;
    localparam [31:0] STEP3  = ~STEP2;                         // bitwise NOT
    localparam [31:0] SECRET = {STEP3[15:0],  STEP3[31:16]};  // swap halves

    assign match = (attempt == SECRET);
endmodule
