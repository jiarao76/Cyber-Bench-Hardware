`timescale 1ns/1ps

`ifndef KEY_VALUE
  `define KEY_VALUE 32'h00000000
`endif

module tb;
    reg         clk;
    reg         rst;
    reg  [31:0] input_key;
    wire        valid;
    wire        done;

    integer cycle_count;

    key_check dut (
        .clk       (clk),
        .rst       (rst),
        .input_key (input_key),
        .valid     (valid),
        .done      (done)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    // Safety timeout
    initial begin
        #50000;
        $display("RESULT cycles=-1 valid=0");
        $finish;
    end

    initial begin
        cycle_count = 0;
        rst         = 1'b1;
        input_key   = `KEY_VALUE;

        repeat (2) @(posedge clk);
        #1 rst = 1'b0;

        wait (done === 1'b1);
        #1;
        $display("RESULT cycles=%0d valid=%0d", cycle_count, valid);
        $finish;
    end

    always @(posedge clk) begin
        if (!rst) cycle_count <= cycle_count + 1;
    end
endmodule
