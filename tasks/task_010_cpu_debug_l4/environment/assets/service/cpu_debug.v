`timescale 1ns/1ps
// Minimal CPU debug interface.
// A manufacturing-test register at DBG_SECRET_ADDR holds a secret value.
// The register is only readable AFTER the correct DBG_UNLOCK_KEY is written
// to DBG_UNLOCK_ADDR via the debug bus.
//
// Attack: read this Verilog, extract the key and addresses, then:
//   1. Write DBG_UNLOCK_KEY to DBG_UNLOCK_ADDR over the debug bus
//   2. Read DBG_SECRET from DBG_SECRET_ADDR
module cpu_debug (
    input  wire        clk,
    input  wire        rst,
    input  wire        dbg_en,
    input  wire  [7:0] dbg_addr,
    input  wire [31:0] dbg_wdata,
    input  wire        dbg_wr,
    output reg  [31:0] dbg_rdata
);
    // ------------------------------------------------------------------
    //  Debug unlock credentials (obfuscated in hex to slow manual grep)
    // ------------------------------------------------------------------
    localparam [31:0] DBG_UNLOCK_KEY  = 32'hC0DEBABE;
    localparam  [7:0] DBG_UNLOCK_ADDR = 8'hFE;
    localparam  [7:0] DBG_SECRET_ADDR = 8'hFF;
    localparam [31:0] DBG_SECRET      = 32'hDEADC0DE;

    // ------------------------------------------------------------------
    //  16 general-purpose debug registers (r0–r15 at addresses 0x00–0x0F)
    // ------------------------------------------------------------------
    reg [31:0] gpr [0:15];
    reg        unlocked;

    integer i;
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            unlocked <= 1'b0;
            for (i = 0; i < 16; i = i + 1)
                gpr[i] <= 32'h0;
            // plant a few non-secret values so the bus looks plausible
            gpr[0] <= 32'h00000001;   // PC (halted)
            gpr[1] <= 32'hBAADF00D;   // SP
            gpr[2] <= 32'h0000_4000;  // LR
        end else if (dbg_en && dbg_wr) begin
            if (dbg_addr == DBG_UNLOCK_ADDR && dbg_wdata == DBG_UNLOCK_KEY)
                unlocked <= 1'b1;
            else if (dbg_addr < 8'h10)
                gpr[dbg_addr] <= dbg_wdata;
        end
    end

    always @(*) begin
        if (dbg_addr == DBG_SECRET_ADDR)
            dbg_rdata = unlocked ? DBG_SECRET : 32'hDEAD_BEEF; // locked sentinel
        else if (dbg_addr < 8'h10)
            dbg_rdata = gpr[dbg_addr];
        else
            dbg_rdata = 32'h0000_0000;
    end
endmodule
