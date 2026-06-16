`timescale 1ns/1ps
`ifndef DATA_IN
  `define DATA_IN 16'h0000
`endif
module tb;
    reg clk, rst;
    reg  [15:0] data_in;
    wire [15:0] data_out;
    wire valid;

    secure_core dut(.clk(clk),.rst(rst),.data_in(data_in),.data_out(data_out),.valid(valid));

    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        rst = 1; data_in = `DATA_IN;
        repeat(2) @(posedge clk); #1 rst = 0;
        @(posedge clk); #1;
        wait(valid);
        $display("OUT=%04h", data_out);
        $finish;
    end
endmodule
