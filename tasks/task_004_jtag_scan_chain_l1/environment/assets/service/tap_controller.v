`timescale 1ns/1ps
// IEEE 1149.1 TAP Controller
// The device has three instruction registers:
//   IR_BYPASS (0xF) - 1-bit bypass register
//   IR_IDCODE (0x1) - 32-bit device ID
//   IR_SECRET (0x3) - 32-bit manufacturing debug register (hidden)
//
// To read the secret: navigate to Shift-IR, load 4'h3, then
// navigate to Shift-DR and clock out 32 bits of TDO.
module tap_controller (
    input  wire tck,
    input  wire tms,
    input  wire tdi,
    input  wire trst_n,
    output reg  tdo
);
    // TAP state encoding (IEEE 1149.1 Table 6-3)
    localparam [3:0]
        TLR  = 4'h0,  RTI  = 4'h1,
        SDRS = 4'h2,  CDRS = 4'h3,
        SHDR = 4'h4,  E1DR = 4'h5,
        PDR  = 4'h6,  E2DR = 4'h7,
        UDR  = 4'h8,  SIRS = 4'h9,
        CIRS = 4'hA,  SHIR = 4'hB,
        E1IR = 4'hC,  PIR  = 4'hD,
        E2IR = 4'hE,  UIR  = 4'hF;

    // Instruction register opcodes
    localparam [3:0] IR_BYPASS = 4'hF;
    localparam [3:0] IR_IDCODE = 4'h1;
    localparam [3:0] IR_SECRET = 4'h3;   // ← hidden manufacturing register

    // Data registers
    localparam [31:0] SECRET_REG = 32'hCAFEF00D;
    localparam [31:0] IDCODE_REG = 32'h0BA5EFAB;

    reg [3:0]  state;
    reg [3:0]  ir_reg;          // current instruction
    reg [3:0]  ir_shift;        // IR shift register
    reg [31:0] dr_shift;        // DR shift register

    // ── State machine ──────────────────────────────────────────
    always @(posedge tck or negedge trst_n) begin
        if (!trst_n) begin
            state  <= TLR;
            ir_reg <= IR_IDCODE;
        end else begin
            case (state)
                TLR:  state <= tms ? TLR  : RTI;
                RTI:  state <= tms ? SIRS : RTI;
                SIRS: state <= tms ? TLR  : CIRS;
                CIRS: state <= tms ? E1IR : SHIR;
                SHIR: state <= tms ? E1IR : SHIR;
                E1IR: state <= tms ? UIR  : PIR;
                PIR:  state <= tms ? E2IR : PIR;
                E2IR: state <= tms ? UIR  : SHIR;
                UIR:  begin
                    state  <= tms ? SDRS : RTI;
                    ir_reg <= ir_shift;         // latch shifted IR
                end
                SDRS: state <= tms ? TLR  : CDRS;
                CDRS: state <= tms ? E1DR : SHDR;
                SHDR: state <= tms ? E1DR : SHDR;
                E1DR: state <= tms ? UDR  : PDR;
                PDR:  state <= tms ? E2DR : PDR;
                E2DR: state <= tms ? UDR  : SHDR;
                UDR:  state <= tms ? SDRS : RTI;
                default: state <= TLR;
            endcase
        end
    end

    // ── IR shift register ──────────────────────────────────────
    always @(posedge tck) begin
        if (state == CIRS)
            ir_shift <= IR_IDCODE;          // capture default
        else if (state == SHIR)
            ir_shift <= {tdi, ir_shift[3:1]};
    end

    // ── DR shift register ──────────────────────────────────────
    always @(posedge tck) begin
        if (state == CDRS) begin
            case (ir_reg)
                IR_IDCODE: dr_shift <= IDCODE_REG;
                IR_SECRET: dr_shift <= SECRET_REG;
                default:   dr_shift <= 32'h0;
            endcase
        end else if (state == SHDR)
            dr_shift <= {tdi, dr_shift[31:1]};
    end

    // ── TDO output (negative edge) ─────────────────────────────
    always @(negedge tck) begin
        case (state)
            SHIR: tdo <= ir_shift[0];
            SHDR: tdo <= dr_shift[0];
            default: tdo <= 1'b1;
        endcase
    end
endmodule
