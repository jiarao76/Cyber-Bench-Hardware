`timescale 1ns/1ps

`ifndef INPUT_BYTE
  `define INPUT_BYTE 8'h00
`endif

module tb;
    reg  [7:0] pt;
    wire [7:0] sb_out;
    integer hw, i;

    aes_sbox dut (.pt_byte(pt), .sb_out(sb_out));

    initial begin
        pt = `INPUT_BYTE;
        #1;
        hw = 0;
        for (i = 0; i < 8; i = i + 1)
            hw = hw + sb_out[i];
        $display("OUTPUT byte=%02h hw=%0d", sb_out, hw);
        $finish;
    end
endmodule
