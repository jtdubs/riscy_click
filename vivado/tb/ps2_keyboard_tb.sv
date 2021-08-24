`timescale 1ns / 1ps
`default_nettype none

module ps2_keyboard_tb
    import keyboard_common::*;
    ();

     logic       clk_i;
     logic       reset_i;
     logic       ps2_clk_async_i;
     logic       ps2_data_async_i;
wire byte_t      data_w;
wire logic       valid_w;
wire kbd_event_t event_o;
wire logic       valid_o;

ps2_rx ps2_rx (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .ps2_clk_async_i(ps2_clk_async_i),
    .ps2_data_async_i(ps2_data_async_i),
    .data_o(data_w),
    .valid_o(valid_w)
);

ps2_keyboard ps2_keyboard (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .data_i(data_w),
    .valid_i(valid_w),
    .event_o(event_o),
    .valid_o(valid_o)
);

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
        ps2_data_async_i = packet[i];
        #200;
        ps2_clk_async_i  = 1'b0;
        #1000;
        ps2_clk_async_i  = 1'b1;
        #800;
    end
end
endtask

localparam logic [7:0] KEYSTROKES [0:12] = { 8'h33, 3'h24, 8'h4B, 8'h4B, 8'h44, 8'h41, 8'h29, 8'h1D, 8'h44, 8'h2D, 8'h4B, 8'h23, 8'h5A };

integer i;
initial begin
    ps2_clk_async_i  = 1'b1;
    ps2_data_async_i = 1'b0;

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

endmodule
