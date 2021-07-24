`timescale 1ns / 1ps

module register
    #(
        parameter WORD_WIDTH = 32,
        parameter RESET_VALUE = 'd0
    )
    (
        input  wire logic clk,
        input  wire logic reset,

        input  wire logic [WORD_WIDTH-1:0] data_in,
        output      logic [WORD_WIDTH-1:0] data_out,

        input  wire logic write_enable
    );

logic [WORD_WIDTH-1:0] next_data_out;

always_comb begin
    if (reset) begin
        next_data_out <= RESET_VALUE;
    end else if (write_enable) begin
        next_data_out <= data_in;
    end else begin
        next_data_out <= data_out;
    end
end

always_ff @(posedge clk) begin
    data_out <= next_data_out;
end

endmodule
