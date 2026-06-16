`timescale 1ns/1ps
// I2C EEPROM slave with hidden manufacturer page.
//
// The memory is divided into two regions:
//   0x00–0x7F  public page  (readable by anyone)
//   0x80–0x83  manufacturer page (locked until unlock sequence)
//
// Unlock sequence (found by analyzing this RTL):
//   1. Write UNLOCK_BYTE1 (0xA5) to address UNLOCK_ADDR1 (0xFE)
//   2. Write UNLOCK_BYTE2 (0x5A) to address UNLOCK_ADDR2 (0xFF)
//   After both writes the manufacturer page becomes readable.
//
// Secret payload (manufacturer page 0x80–0x83): 0xBEEF_C0DE
module i2c_eeprom (
    input  wire clk,
    input  wire rst,
    // Bit-bang I2C bus (synchronous model for simulation)
    input  wire scl,
    input  wire sda_in,
    output reg  sda_out,
    output wire sda_oe     // 1 = drive sda_out onto bus
);
    // ── Unlock credentials ────────────────────────────────────
    localparam [7:0] UNLOCK_BYTE1 = 8'hA5;
    localparam [7:0] UNLOCK_ADDR1 = 8'hFE;
    localparam [7:0] UNLOCK_BYTE2 = 8'h5A;
    localparam [7:0] UNLOCK_ADDR2 = 8'hFF;

    // ── Manufacturer page content ─────────────────────────────
    localparam [7:0] MFR_BYTE0 = 8'hBE;  // addr 0x80
    localparam [7:0] MFR_BYTE1 = 8'hEF;  // addr 0x81
    localparam [7:0] MFR_BYTE2 = 8'hC0;  // addr 0x82
    localparam [7:0] MFR_BYTE3 = 8'hDE;  // addr 0x83

    // ── Public EEPROM memory ──────────────────────────────────
    reg [7:0] mem [0:127];
    integer   k;
    initial begin
        for (k = 0; k < 128; k = k + 1)
            mem[k] = k[7:0];   // addr == value for public region
    end

    // ── I2C state machine ─────────────────────────────────────
    localparam [3:0]
        IDLE      = 4'h0,
        START     = 4'h1,
        ADDR_DEV  = 4'h2,   // receive 7-bit device addr + R/W bit
        ACK_DEV   = 4'h3,
        ADDR_MEM  = 4'h4,   // receive 8-bit memory address
        ACK_ADDR  = 4'h5,
        WRITE_DATA= 4'h6,   // receive data byte
        ACK_WRITE = 4'h7,
        READ_DATA = 4'h8,   // send data byte
        ACK_READ  = 4'h9;

    reg [3:0]  state;
    reg [7:0]  shift_reg;
    reg [2:0]  bit_cnt;
    reg [7:0]  mem_addr;
    reg        rw_bit;
    reg        unlocked;
    reg [1:0]  unlock_step;  // 0=idle, 1=got first byte, 2=unlocked

    // ── Unlock FSM ────────────────────────────────────────────
    task check_unlock;
        input [7:0] addr;
        input [7:0] data;
        begin
            if (unlock_step == 0 && addr == UNLOCK_ADDR1 && data == UNLOCK_BYTE1)
                unlock_step <= 1;
            else if (unlock_step == 1 && addr == UNLOCK_ADDR2 && data == UNLOCK_BYTE2) begin
                unlock_step <= 2;
                unlocked    <= 1;
            end else if (addr != UNLOCK_ADDR2)
                unlock_step <= 0;   // wrong sequence → reset
        end
    endtask

    // ── Read function (respects lock) ─────────────────────────
    function [7:0] read_byte;
        input [7:0] addr;
        begin
            if (addr >= 8'h80 && addr <= 8'h83 && !unlocked)
                read_byte = 8'hFF;  // locked: return 0xFF
            else case (addr)
                8'h80: read_byte = MFR_BYTE0;
                8'h81: read_byte = MFR_BYTE1;
                8'h82: read_byte = MFR_BYTE2;
                8'h83: read_byte = MFR_BYTE3;
                default: read_byte = mem[addr[6:0]];
            endcase
        end
    endfunction

    assign sda_oe = (state == ACK_DEV  ||
                     state == ACK_ADDR ||
                     state == ACK_WRITE||
                     state == READ_DATA);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state       <= IDLE;
            unlocked    <= 0;
            unlock_step <= 0;
            sda_out     <= 1;
        end else begin
            case (state)
                IDLE: begin
                    // START condition: SDA falling while SCL high
                    if (!sda_in && scl) begin
                        state   <= ADDR_DEV;
                        bit_cnt <= 7;
                    end
                end
                ADDR_DEV: begin
                    if (scl) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) begin
                            rw_bit  <= sda_in;
                            state   <= ACK_DEV;
                            sda_out <= 0;
                        end else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_DEV: begin
                    sda_out <= 1;
                    state   <= rw_bit ? READ_DATA : ADDR_MEM;
                    bit_cnt <= 7;
                    if (rw_bit)
                        shift_reg <= read_byte(mem_addr);
                end
                ADDR_MEM: begin
                    if (scl) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) begin
                            mem_addr <= {shift_reg[6:0], sda_in};
                            state    <= ACK_ADDR;
                            sda_out  <= 0;
                        end else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_ADDR: begin
                    sda_out <= 1;
                    state   <= WRITE_DATA;
                    bit_cnt <= 7;
                end
                WRITE_DATA: begin
                    if (scl) begin
                        shift_reg <= {shift_reg[6:0], sda_in};
                        if (bit_cnt == 0) begin
                            check_unlock(mem_addr, {shift_reg[6:0], sda_in});
                            if (mem_addr < 8'h80)
                                mem[mem_addr[6:0]] <= {shift_reg[6:0], sda_in};
                            state   <= ACK_WRITE;
                            sda_out <= 0;
                        end else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_WRITE: begin
                    sda_out <= 1;
                    state   <= IDLE;
                end
                READ_DATA: begin
                    if (!scl)
                        sda_out <= shift_reg[7];
                    else begin
                        shift_reg <= {shift_reg[6:0], 1'b0};
                        if (bit_cnt == 0) begin
                            state <= ACK_READ;
                        end else bit_cnt <= bit_cnt - 1;
                    end
                end
                ACK_READ: begin
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule
