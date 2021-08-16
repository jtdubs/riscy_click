`timescale 1ns / 1ps
`default_nettype none

module uart_tb
    import common::*;
    ();

     logic        clk_i;
     logic        chip_select_i;
wire logic        interrupt_o;
     logic        rxd_i;
wire logic        txd_o;
     logic [1:0]  addr_i;
     logic        read_enable_i;
wire word_t       read_data_o;
     word_t       write_data_i;
     logic        write_enable_i;

uart uart (.*);

// clk_i
initial begin
    clk_i = 1;
    forever begin
        #10 clk_i = ~clk_i;
    end
end

// chip select
initial begin
    chip_select_i = 1;
end

// always read from fifo
initial begin
    addr_i = 1;
    read_enable_i = 1;
    write_data_i = 0;
    write_enable_i = 0;
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
        rxd_i = packet[i];
        #8680;
    end
end
endtask

localparam logic [7:0] INPUT_BUFFER [0:12] = { 8'h33, 8'h24, 8'h4B, 8'h4B, 8'h44, 8'h41, 8'h29, 8'h1D, 8'h44, 8'h2D, 8'h4B, 8'h23, 8'h5A };

integer i;
initial begin
    rxd_i = 1;
    #40000;
    forever begin
        for (i=0; i<13; i++) begin
            send_uart_packet(INPUT_BUFFER[i]);
            #100000;
        end
    end
end

endmodule
