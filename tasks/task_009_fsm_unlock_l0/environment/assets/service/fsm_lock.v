`timescale 1ns/1ps

// 5-state FSM lock. Applies XOR mask to inputs before comparison,
// and uses non-sequential Gray-coded state encoding to hinder manual tracing.
// Yosys fsm_detect + fsm_extract + fsm_info reveals the true transition table.
module fsm_lock (
    input  wire       clk,
    input  wire       rst,
    input  wire [7:0] in,
    output reg        unlocked
);
    // Gray-coded state encoding
    localparam [3:0] IDLE = 4'h0,
                     S1   = 4'h1,
                     S2   = 4'h3,
                     S3   = 4'h2,
                     OPEN = 4'h6;

    // Input tokens (XOR-masked to obscure unlock sequence)
    localparam [7:0] IMASK = 8'h55;
    localparam [7:0] K0    = 8'h8B;  // actual input: K0^IMASK = 0xDE
    localparam [7:0] K1    = 8'hF8;  // actual input: K1^IMASK = 0xAD
    localparam [7:0] K2    = 8'hEB;  // actual input: K2^IMASK = 0xBE
    localparam [7:0] K3    = 8'hBA;  // actual input: K3^IMASK = 0xEF

    reg [3:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            unlocked <= 1'b0;
        end else begin
            unlocked <= (state == OPEN);
            case (state)
                IDLE: state <= ((in ^ IMASK) == K0) ? S1   : IDLE;
                S1:   state <= ((in ^ IMASK) == K1) ? S2   : IDLE;
                S2:   state <= ((in ^ IMASK) == K2) ? S3   : IDLE;
                S3:   state <= ((in ^ IMASK) == K3) ? OPEN : IDLE;
                OPEN: state <= OPEN;
                default: state <= IDLE;
            endcase
        end
    end
endmodule
