`timescale 1ns / 1ps
`default_nettype none

///
/// CPU Fetch Stage Top
///

module fetch_top
    // Import Constants
    import common::*;
    import cpu_common::*;
    (
`ifdef USE_EXTERNAL_CLOCKS
        // Clocks
        input  wire logic        cpu_clk_i,      // CPU clock
        input  wire logic        pxl_clk_i,      // Pixel clock
`else
        // Clocks
        input  wire logic        sys_clk_i,      // CPU clock
`endif

        // Halt
        output wire logic        halt_o,         // halt output

        // PS/2
        input  wire logic        ps2_clk_i,      // PS2 HID clock (async)
        input  wire logic        ps2_data_i,     // PS2 HID data (async)

        // UART
        input  wire logic        uart_rxd_i,
        output wire logic        uart_txd_o,

        // Buttons
        input  wire logic [4:0]  buttons_i,      // async hardware dpad buttons
        
        // Switches
        input  wire logic [15:0] switch_i,       // async hardware switch bank input

        // Seven Segment Display
        output wire logic [ 7:0] dsp_anode_o,    // seven segment display anodes output
        output wire logic [ 7:0] dsp_cathode_o,  // seven segment display cathodes output

        // VGA
        output wire logic [ 3:0] vga_red_o,      // vga red output
        output wire logic [ 3:0] vga_green_o,    // vga green output
        output wire logic [ 3:0] vga_blue_o,     // vga blue output
        output wire logic        vga_hsync_o,    // vga horizontal sync output
        output wire logic        vga_vsync_o     // vga vertical sync output
    );


//
// Clocks
//

`ifndef USE_EXTERNAL_CLOCKS
wire logic cpu_clk_i;
wire logic pxl_clk_i;

clk_gen clk_gen (
    .sys_clk_i     (sys_clk_i),
    .cpu_clk_o     (cpu_clk_i),
    .pxl_clk_o     (pxl_clk_i),
    .ready_async_o ()
);
`endif


//
// Unused Outputs
//

assign vga_red_o    = '0;
assign vga_green_o  = '0;
assign vga_blue_o   = '0;
assign vga_hsync_o  = '0;
assign vga_vsync_o  = '0;
assign uart_txd_o   = '0;
assign halt_o       = '0;


// Switches
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

(* MARK_DEBUG = "true" *) switch_input_t switch_r;
always_ff @(posedge cpu_clk_i) begin
    switch_r <= switch_i;
end


// Buttons
logic [7:0] buttons_r [4:0] = '{ default: '0 };
(* MARK_DEBUG = "true" *) logic [1:0] buttons_debounced_r [4:0] = '{ default: '0 };
(* MARK_DEBUG = "true" *) logic button_pressed_r [4:0]  = '{ default: '0 };
genvar i;
generate for (i=0; i<5; i++) begin
    always_ff @(posedge cpu_clk_i) begin
        buttons_r[i] <= { buttons_i[i], buttons_r[i][7:1] };
        if (buttons_r[i] == 8'h00)
            buttons_debounced_r[i] <= { 1'b0, buttons_debounced_r[i][1] }; 
        else if (buttons_r[i] == 8'hFF)
            buttons_debounced_r[i] <= { 1'b1, buttons_debounced_r[i][1] };
        button_pressed_r[i] <= !buttons_debounced_r[i][0] && buttons_debounced_r[i][1];
    end
end
endgenerate


//
// Instruction Cache
//

(* MARK_DEBUG = "true" *) wire memaddr_t req_addr;
(* MARK_DEBUG = "true" *) wire logic     req_valid;
(* MARK_DEBUG = "true" *) wire logic     req_ready;
(* MARK_DEBUG = "true" *) wire memaddr_t resp_addr;
(* MARK_DEBUG = "true" *) wire word_t    resp_data;
(* MARK_DEBUG = "true" *) wire logic     resp_valid;
(* MARK_DEBUG = "true" *) wire logic     resp_ready;

instruction_cache cache (
    .clk_i        (cpu_clk_i),
    .req_addr_i   (req_addr),
    .req_valid_i  (req_valid),
    .req_ready_o  (req_ready),
    .resp_addr_o  (resp_addr),
    .resp_data_o  (resp_data),
    .resp_valid_o (resp_valid),
    .resp_ready_i (resp_ready)
);


//
// CPU Fetch Stage
//

(* MARK_DEBUG = "true" *) wire word_t pc;
(* MARK_DEBUG = "true" *) wire word_t ir;
(* MARK_DEBUG = "true" *) wire word_t pc_next;
(* MARK_DEBUG = "true" *) wire logic  valid;

stage_fetch stage_fetch (
    .clk_i               (cpu_clk_i),
    .halt_i              (switch_r.halt),
    .icache_req_addr_o   (req_addr),
    .icache_req_valid_o  (req_valid),
    .icache_req_ready_i  (req_ready),
    .icache_resp_addr_i  (resp_addr),
    .icache_resp_data_i  (resp_data),
    .icache_resp_valid_i (resp_valid),
    .icache_resp_ready_o (resp_ready),
    .jmp_addr_i          ({ 22'b0, switch_r.jmp_addr, 2'b0 }),
    .jmp_valid_i         (switch_r.jmp_valid),
    .jmp_ready_o         (),
    .fetch_pc_o          (pc),
    .fetch_ir_o          (ir),
    .fetch_pc_next_o     (pc_next),
    .fetch_valid_o       (valid),
    .fetch_ready_i       (switch_r.ready && button_pressed_r[0])
);

word_t pc_r = '0;
word_t ir_r = '0;
word_t pc_next_r = '0;
logic valid_r = '0;

always_ff @(posedge cpu_clk_i) begin
    if (button_pressed_r[0]) begin
        pc_r <= pc;
        ir_r <= ir;
        pc_next_r <= pc_next;
        valid_r <= valid;
    end
end

// Segment Display
(* MARK_DEBUG = "true" *) word_t display_data;
always_comb begin
    case (switch_r.display_selector)
    2'b00: display_data = pc_r;
    2'b01: display_data = ir_r;
    2'b10: display_data = pc_next_r;
    2'b11: display_data = { 31'b0, valid_r };
    endcase
end

segment_display #(
    .INIT_ENABLED(1)
) segment_display (
    .clk_i         (cpu_clk_i),
    .dsp_anode_o   (dsp_anode_o),
    .dsp_cathode_o (dsp_cathode_o),
    .chip_select_i (1'b1),
    .addr_i        (4'b0001),
    .read_enable_i (1'b0),
    .read_data_o   (),
    .write_data_i  (display_data),
    .write_mask_i  (4'b1111)
);

endmodule
