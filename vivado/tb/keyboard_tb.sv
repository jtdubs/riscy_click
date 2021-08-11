`timescale 1ns / 1ps
`default_nettype none

module keyboard_tb ();

     logic       clk_i;
     logic       reset_i;
     logic       clk_kbd_async_i;
     logic       kbd_data_async_i;
wire logic       ready_o;
wire logic [7:0] scancode_o;

keyboard keyboard (.*);

// clk_i
initial begin
    clk_i = 1;
    forever begin
        #10 clk_i = ~clk_i;
    end
end

// reset_i pulse
initial begin
    reset_async_i = 1;
    #100 reset_async_i = 0;
end

// keyboard input simulator
localparam logic [10:0] INPUT_VECTOR = 11'b10001100110;

integer i;
initial begin
    clk_kbd_async_i  = 1'b1;
    kbd_data_async_i = 1'b0;

    #400

    forever begin
        for (i=0; i<10; i++) begin
            #800
            kbd_data_async_i = INPUT_VECTOR[i];
            #200
            clk_kbd_async_i  = 1'b0;
            #1000
            clk_kbd_async_i  = 1'b1;
        end

        #10000
    end
end

endmodule
