`timescale 1ns / 1ps
`default_nettype none

module fifo_tb
    import common::*;
    ();

     logic       clk_i;
     logic       reset_i;
     logic [7:0] write_data_i;
     logic       write_enable_i;
     logic       read_enable_i;
wire logic [7:0] read_data_o;
wire logic       read_valid_o;
wire logic       fifo_empty_o;
wire logic       fifo_almost_empty_o;
wire logic       fifo_almost_full_o;
wire logic       fifo_full_o;

fifo #( .DATA_WIDTH(8), .ADDR_WIDTH(3) ) fifo (.*);

// clk_i
initial begin
    clk_i = 1;
    forever begin
        #10 clk_i = ~clk_i;
    end
end

// reset_i pulse
initial begin
    reset_i = 1;
    #100;
    @(posedge clk_i) reset_i = 0;
end

// write port tickling
integer i;
initial begin
    write_data_i = 8'b0;
    write_enable_i = 1'b0;
    #200
    forever begin
        for (i=0; i<255; i++) begin
            @(negedge clk_i) begin
                write_data_i   = i;
                write_enable_i = 1'b1;
            end
            @(negedge clk_i) begin
                write_data_i   = i;
                write_enable_i = 1'b0;
            end
            #100;
        end
    end
end

// read port
integer d;
initial begin
    read_enable_i = 1'b0;
    #600;
    forever begin
        @(negedge clk_i) read_enable_i = 1'b1;
        #1000;
        @(negedge clk_i) read_enable_i = 1'b0;
        #2000;
    end
end

endmodule
