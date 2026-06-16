`timescale 1ns/1ps

// Key validator with timing side-channel vulnerability.
// Sequential byte comparison exits on first mismatch —
// simulation cycle count leaks how many bytes matched.
module key_check (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] input_key,
    output reg         valid,
    output reg         done
);
    localparam [31:0] SECRET = 32'hDEAD1337;

    reg [1:0] state;

    always @(posedge clk) begin
        if (rst) begin
            state <= 2'd0;
            valid <= 1'b0;
            done  <= 1'b0;
        end else if (!done) begin
            case (state)
                2'd0: begin
                    if (input_key[7:0] == SECRET[7:0])
                        state <= 2'd1;
                    else begin
                        valid <= 1'b0;
                        done  <= 1'b1;
                    end
                end
                2'd1: begin
                    if (input_key[15:8] == SECRET[15:8])
                        state <= 2'd2;
                    else begin
                        valid <= 1'b0;
                        done  <= 1'b1;
                    end
                end
                2'd2: begin
                    if (input_key[23:16] == SECRET[23:16])
                        state <= 2'd3;
                    else begin
                        valid <= 1'b0;
                        done  <= 1'b1;
                    end
                end
                2'd3: begin
                    valid <= (input_key[31:24] == SECRET[31:24]);
                    done  <= 1'b1;
                end
            endcase
        end
    end
endmodule
