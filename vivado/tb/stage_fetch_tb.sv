`timescale 1ns / 1ps
`default_nettype none

module stage_fetch_tb
    // Import Constants
    import common::*;
    import cpu_common::*;
    ();

typedef struct packed {
    logic [1:0] display_selector;
    logic       reserved_1;
    logic       jmp_valid;
    logic [7:0] jmp_addr;
    logic       reserved_2;
    logic       halt;
    logic       imem_valid;
    logic       ready;
} switch_input_t;

logic          sys_clk_i  = '1;
logic          halt_o     = '0;
logic          ps2_clk_i;
logic          ps2_data_i;
logic          uart_rxd_i;
logic          uart_txd_o;
logic [4:0]    buttons_i  = '0;
switch_input_t switch_i   = '{ default: '0 };
logic [ 7:0]   dsp_anode_o;
logic [ 7:0]   dsp_cathode_o;
logic [ 3:0]   vga_red_o;
logic [ 3:0]   vga_green_o;
logic [ 3:0]   vga_blue_o;
logic          vga_hsync_o;
logic          vga_vsync_o;

fetch_top fetch_top (.*);

// clock generator
initial begin
    sys_clk_i <= 1;
    forever begin
        #5 sys_clk_i <= ~sys_clk_i;
    end
end

// ps2
assign ps2_clk_i  = 1'b1;
assign ps2_data_i = 1'b1;

// uart
assign uart_rxd_i = 1'b1;

// step button
initial begin
    buttons_i <= 5'b0;
    forever begin
        #1000 buttons_i[0] <= 1'b1;
        #1000 buttons_i[0] <= 1'b0;
    end
end

// halt eventually
initial begin
    switch_i.halt <= 0;
    #10000
    @(posedge sys_clk_i) switch_i.halt <= 1;
end

// test backpressure
initial begin
    switch_i.ready <= 1'b1;

    forever begin
        #1000
        @(posedge sys_clk_i) switch_i.ready <= 1'b0;
        @(posedge sys_clk_i) switch_i.ready <= 1'b1;
        #1000
        @(posedge sys_clk_i) switch_i.ready <= 1'b0;
        #40
        @(posedge sys_clk_i) switch_i.ready <= 1'b1;
    end
end

// do some jumps
initial begin
    switch_i.jmp_addr  <= 8'h00;
    switch_i.jmp_valid <= 1'b0;
    #500
    forever begin
        #1000
        @(posedge sys_clk_i) begin
            switch_i.jmp_addr  <= 8'h80;
            switch_i.jmp_valid <= 1'b1;
        end
        @(posedge sys_clk_i) begin
            switch_i.jmp_addr  <= 8'h00;
            switch_i.jmp_valid <= 1'b0;
        end
    end
end

// try making memory output valid
initial begin
    switch_i.imem_valid <= 1'b1;
    #700
    forever begin
        #2000
        @(posedge sys_clk_i) switch_i.imem_valid <= 1'b0;
        @(posedge sys_clk_i) switch_i.imem_valid <= 1'b1;
    end
end

// change display selector
initial begin
    switch_i.display_selector <= 2'b00;
    forever begin
        #2000
        @(posedge sys_clk_i) begin
            switch_i.display_selector <= switch_i.display_selector + 1;
        end     
    end
end

endmodule
