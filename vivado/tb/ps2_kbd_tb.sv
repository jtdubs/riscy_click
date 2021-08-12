`timescale 1ns / 1ps
`default_nettype none

module ps2_kbd_tb
    import common::*;
    ();

     logic       clk_i;
     logic       reset_i;
     logic       clk_ps2_async_i;
     logic       ps2_data_async_i;
wire byte_t      data_w;
wire logic       valid_w;
wire kbd_event_t event_o;
wire logic       valid_o;

ps2_rx ps2_rx (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .clk_ps2_async_i(clk_ps2_async_i),
    .ps2_data_async_i(ps2_data_async_i),
    .data_o(data_w),
    .valid_o(valid_w)
);

ps2_kbd ps2_kbd (
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

// ps2_rx input simulator
localparam logic [10:0] INPUT_VECTOR = 11'b11001100110;

integer i;
initial begin
    clk_ps2_async_i  = 1'b1;
    ps2_data_async_i = 1'b0;

    #400;

    forever begin
        for (i=0; i<11; i++) begin
            #800;
            ps2_data_async_i = INPUT_VECTOR[i];
            #200;
            clk_ps2_async_i  = 1'b0;
            #1000;
            clk_ps2_async_i  = 1'b1;
        end

        #10000;
    end
end

endmodule
