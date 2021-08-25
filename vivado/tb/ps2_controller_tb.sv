`timescale 1ns / 1ps
`default_nettype none

module ps2_controller_tb
    import common::*;
    ();

logic clk_i;
tri logic ps2_clk_io;
tri logic ps2_data_io;
logic [15:0] debug_o;

ps2_controller dut (.*);

logic kbd_clk;
logic kbd_data;

assign (weak1, weak0) ps2_clk_io = kbd_clk;
assign (weak1, weak0) ps2_data_io = kbd_data;

// clk_i
initial begin
    clk_i = 1;
    forever begin
        #5 clk_i = ~clk_i;
    end
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
        kbd_data = packet[i];
        #200;
        kbd_clk  = 1'b0;
        #1000;
        kbd_clk  = 1'b1;
        #800;
    end
end
endtask

task automatic read_ps2_packet ();
begin
    integer i;
    for (i=0; i<11; i++) begin
        kbd_clk  = 1'b0;
        #1000;
        kbd_clk  = 1'b1;
        #800;
    end
end
endtask

integer i;
initial begin
    kbd_clk  = 1'b1;
    kbd_data = 1'b1;

    #10000;

    forever begin
        for (i=0; i<13; i++) begin
            send_ps2_packet(8'hAA);
            @(posedge ps2_clk_io);
            #1000;
            read_ps2_packet();
            #100000;
        end
    end
end

endmodule
