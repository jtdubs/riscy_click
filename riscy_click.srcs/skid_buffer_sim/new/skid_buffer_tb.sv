`timescale 1ns / 1ps
`default_nettype none

module skid_buffer_tb ();

logic clk, reset;
logic input_ready, output_ready;
logic input_valid, output_valid;
logic [7:0] input_data, output_data;

skid_buffer #(.WORD_WIDTH(8)) sb (
    .clk(clk),
    .reset(reset),
    .input_ready(input_ready),
    .input_data(input_data),
    .input_valid(input_valid),
    .output_ready(output_ready),
    .output_data(output_data),
    .output_valid(output_valid)
);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse (2 cycle)
initial begin
    reset = 1;
    #150 reset = 0;
end

// input side
logic [7:0] counter = 8'h00;
logic [7:0] next_counter;
logic [1:0] state;

assign next_counter = counter + 1;
assign input_data = counter;
assign input_valid = state[0];
assign output_ready = state[1];

always_ff @(negedge clk) begin
    if (input_ready & input_valid) begin
        counter <= next_counter;
    end
end

// walk through states
initial begin
    state <= 0;
    forever begin
        #600 @(negedge clk) state <= state + 1;
    end
end

endmodule
