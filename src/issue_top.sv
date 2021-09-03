`timescale 1ns / 1ps
`default_nettype none

///
/// CPU Issue Stage Top
///

module issue_top
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
    logic [2:0] display_selector;
    logic       jmp_valid;
    logic [7:0] jmp_addr;
    logic       reserved_2;
    logic       halt;
    logic       reserved_3;
    logic       ready;
} switch_input_t;

switch_input_t switch_r;
always_ff @(posedge cpu_clk_i) begin
    switch_r <= switch_i;
end


// Buttons
logic [7:0] buttons_r [4:0] = '{ default: '0 };
logic [1:0] buttons_debounced_r [4:0] = '{ default: '0 };
logic       button_pressed_r    [4:0] = '{ default: '0 };
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

wire memaddr_t icache_req_addr;
wire logic     icache_req_valid;
wire logic     icache_req_ready;
wire memaddr_t icache_resp_addr;
wire word_t    icache_resp_data;
wire logic     icache_resp_valid;
wire logic     icache_resp_ready;

instruction_cache cache (
    .clk_i        (cpu_clk_i),
    .req_addr_i   (icache_req_addr),
    .req_valid_i  (icache_req_valid),
    .req_ready_o  (icache_req_ready),
    .resp_addr_o  (icache_resp_addr),
    .resp_data_o  (icache_resp_data),
    .resp_valid_o (icache_resp_valid),
    .resp_ready_i (icache_resp_ready)
);


//
// CPU Fetch Stage
//

wire word_t fetch_pc;
wire word_t fetch_ir;
wire word_t fetch_pc_next;
wire logic  fetch_valid;
wire logic  fetch_ready;

stage_fetch stage_fetch (
    .clk_i               (cpu_clk_i),
    .halt_i              (switch_r.halt),
    .icache_req_addr_o   (icache_req_addr),
    .icache_req_valid_o  (icache_req_valid),
    .icache_req_ready_i  (icache_req_ready),
    .icache_resp_addr_i  (icache_resp_addr),
    .icache_resp_data_i  (icache_resp_data),
    .icache_resp_valid_i (icache_resp_valid),
    .icache_resp_ready_o (icache_resp_ready),
    .jmp_addr_i          ({ 22'b0, switch_r.jmp_addr, 2'b0 }),
    .jmp_valid_i         (switch_r.jmp_valid),
    .jmp_ready_o         (),
    .fetch_pc_o          (fetch_pc),
    .fetch_ir_o          (fetch_ir),
    .fetch_pc_next_o     (fetch_pc_next),
    .fetch_valid_o       (fetch_valid),
    .fetch_ready_i       (fetch_ready)
);


//
// CPU Decode Stage
//

wire word_t         decode_pc;
wire word_t         decode_ir;
wire control_word_t decode_cw;
wire word_t         decode_ra;
wire word_t         decode_rb;
wire logic          decode_valid;
wire logic          decode_ready;

stage_decode stage_decode (
    .clk_i               (cpu_clk_i),
    .fetch_pc_i          (fetch_pc),
    .fetch_ir_i          (fetch_ir),
    .fetch_pc_next_i     (fetch_pc_next),
    .fetch_valid_i       (fetch_valid),
    .fetch_ready_o       (fetch_ready),
    .decode_pc_o         (decode_pc),
    .decode_ir_o         (decode_ir),
    .decode_cw_o         (decode_cw),
    .decode_ra_o         (decode_ra),
    .decode_rb_o         (decode_rb),
    .decode_valid_o      (decode_valid),
    .decode_ready_i      (decode_ready)
);


//
// CPU Issue Stage
//

wire control_word_t issue_cw;
wire word_t         issue_alu_op1;
wire word_t         issue_alu_op2;
wire logic          issue_valid;
wire logic          issue_ready;

stage_issue stage_issue (
    .clk_i               (cpu_clk_i),
    .decode_pc_i         (decode_pc),
    .decode_ir_i         (decode_ir),
    .decode_cw_i         (decode_cw),
    .decode_ra_i         (decode_ra),
    .decode_rb_i         (decode_rb),
    .decode_valid_i      (decode_valid),
    .decode_ready_o      (decode_ready),
    .wb_addr_i           (decode_ir[19:0]),
    .wb_data_i           ({ decode_pc, decode_ir, decode_ra, decode_rb }),
    .wb_valid_i          ({ decode_ir[23:20] }),
    .wb_ready_i          ({ decode_ir[27:24] }),
    .issue_cw_o          (issue_cw),
    .issue_alu_op1_o     (issue_alu_op1),
    .issue_alu_op2_o     (issue_alu_op2),
    .issue_valid_o       (issue_valid),
    .issue_ready_i       (switch_r.ready && button_pressed_r[0])
);


//
// Latch Outputs
//

word_t         pc_r      = '0;
word_t         ir_r      = '0;
control_word_t cw_r;
word_t         alu_op1_r = '0;
word_t         alu_op2_r = '0;
logic          valid_r   = '0;

always_ff @(posedge cpu_clk_i) begin
    if (button_pressed_r[0]) begin
        pc_r      <= decode_pc;
        ir_r      <= decode_ir;
        cw_r      <= issue_cw;
        alu_op1_r <= issue_alu_op1;
        alu_op2_r <= issue_alu_op2;
        valid_r   <= issue_valid;
    end
end

// Segment Display
word_t display_data;
always_comb begin
    case (switch_r.display_selector)
    3'b000:  display_data = pc_r;
    3'b001:  display_data = ir_r;
    3'b010:  display_data = { 8'b0, cw_r };
    3'b011:  display_data = { 31'b0, valid_r };
    3'b100:  display_data = alu_op1_r;
    3'b101:  display_data = alu_op2_r;
    default: display_data = '0;
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
