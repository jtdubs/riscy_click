`timescale 1ns / 1ps
`default_nettype none

module skid_buffer_tb ();

logic clk_i, reset_i;
logic input_ready, output_ready;
logic input_valid, output_valid;
logic [7:0] input_data, output_data;

skid_buffer #(.WORD_WIDTH(8)) sb (.*);

// clock generator
initial begin
    clk_i = 1;
    forever begin
        #50 clk_i <= ~clk_i;
    end
end

// reset_i pulse (2 cycle)
initial begin
    reset_i = 1;
    #150 reset_i = 0;
end

// input side
logic [7:0] counter;
logic [7:0] next_counter;
logic [1:0] state;

assign next_counter = counter + 1;
assign input_data = counter;
assign input_valid = state[0];
assign output_ready = state[1];

initial counter = 8'h00;

always_ff @(negedge clk_i) begin
    if (input_ready & input_valid) begin
        counter <= next_counter;
    end
end

// walk through states
initial begin
    state <= 0;
    forever begin
        #600 @(negedge clk_i) state <= state + 1;
    end
end

endmodule
