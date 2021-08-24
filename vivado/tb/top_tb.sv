`timescale 1ns / 1ps
`default_nettype none

module top_tb ();

     logic        sys_clk_i;
     logic [15:0] switch_i;
     logic        ps2_clk_i;
     logic        ps2_data_i;
     logic        uart_rxd_i;
wire logic        halt_o;
wire logic [ 7:0] dsp_anode_o;
wire logic [ 7:0] dsp_cathode_o;
wire logic [ 3:0] vga_red_o;
wire logic [ 3:0] vga_green_o;
wire logic [ 3:0] vga_blue_o;
wire logic        vga_hsync_o;
wire logic        vga_vsync_o;
wire logic        uart_txd_o;

top top (.*);

// clock generator
initial begin
    sys_clk_i = 1;
    forever begin
        #5 sys_clk_i = ~sys_clk_i;
    end
end

// switches
initial begin
    switch_i = 16'h9999;
end

// ps2 signal driving
function logic [10:0] make_ps2_packet (input logic [7:0] data);
begin
    integer i;
    logic parity;
    parity = 1;
    for (i=0; i<8; i++)
        parity = parity ^ data[i];
    make_ps2_packet = { 1'b1, parity, data, 1'b0 };
end
endfunction

task automatic send_ps2_packet (input logic [7:0] data);
begin
    integer i;
    logic [10:0] packet = make_ps2_packet(data);
    for (i=0; i<11; i++) begin
        ps2_data_i = packet[i];
        #200;
        ps2_clk_i  = 1'b0;
        #1000;
        ps2_clk_i  = 1'b1;
        #800;
    end
end
endtask

localparam logic [7:0] KEYSTROKES [0:12] = { 8'h33, 8'h24, 8'h4B, 8'h4B, 8'h44, 8'h41, 8'h29, 8'h1D, 8'h44, 8'h2D, 8'h4B, 8'h23, 8'h5A };

integer i;
initial begin
    ps2_clk_i  = 1'b1;
    ps2_data_i = 1'b0;

    #400;

    forever begin
        for (i=0; i<13; i++) begin
            send_ps2_packet(KEYSTROKES[i]);
            #4000;
            send_ps2_packet(8'hF0);
            #2000;
            send_ps2_packet(KEYSTROKES[i]);
        end
    end
end

// uart signal driving
function logic [10:0] make_uart_packet (input logic [7:0] data);
begin
    integer i;
    logic parity;
    parity = 1;
    for (i=0; i<8; i++)
        parity = parity ^ data[i];
    make_uart_packet = { 1'b1, data, 1'b0 };
end
endfunction

task automatic send_uart_packet (input logic [7:0] data);
begin
    integer i;
    logic [9:0] packet = make_uart_packet(data);
    for (i=0; i<10; i++) begin
        uart_rxd_i = packet[i];
        #8680;
    end
end
endtask

localparam logic [7:0] INPUT_BUFFER [0:12] = { 8'h33, 8'h24, 8'h4B, 8'h4B, 8'h44, 8'h41, 8'h29, 8'h1D, 8'h44, 8'h2D, 8'h4B, 8'h23, 8'h5A };

integer i;
initial begin
    uart_rxd_i = 1;
    #40000;
    forever begin
        for (i=0; i<13; i++) begin
            send_uart_packet(INPUT_BUFFER[i]);
            #100000;
        end
    end
end

endmodule
