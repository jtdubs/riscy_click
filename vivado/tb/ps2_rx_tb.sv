`timescale 1ns / 1ps
`default_nettype none

module ps2_rx_tb
    import common::*;
    ();

     logic  clk_i;
     logic  reset_i;
     logic  ps2_clk_async_i;
     logic  ps2_data_async_i;
wire byte_t data_o;
wire logic  valid_o;

ps2_rx ps2_rx (.*);

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

task make_ps2_packet (input logic [7:0] data, output logic [10:0] ps2_data)
begin
    integer i;
    logic parity = 1;
    for (i=0; i<8; i++)
        parity = parity ^ data[i];
    ps2_data = { 1'b0, data, parity, 1'b1 };
end
endtask

task send_ps2_packet (input logic [7:0] data, output logic ps2_data, output logic ps2_clk)
begin
    integer i;
    logic [11:0] packet = make_ps2_packet(data);
    for (i=0; i<11; i++) begin
        ps2_data = INPUT_VECTOR[i][j];
        #200;
        ps2_clk  = 1'b0;
        #1000;
        ps2_clk  = 1'b1;
        #800;
    end
end
endtask

integer i;
initial begin
    ps2_clk_async_i  = 1'b1;
    ps2_data_async_i = 1'b0;

    #400;

    forever begin
        send_ps2_packet(8'h76, ps2_data_async_i, ps2_clk_async_i);
        #10000;
    end
end

endmodule
