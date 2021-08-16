`timescale 1ns / 1ps
`default_nettype none

module video_ram
    // Import Constants
    import common::*;
    (
        // cpu interface
        input  wire logic        cpu_clk_i,
        input  wire word_t       cpu_addr_i,
        input  wire word_t       cpu_write_data_i,
        input  wire logic [ 3:0] cpu_write_mask_i,
        output wire word_t       cpu_read_data_o,

        // vga controller interface
        input  wire logic        pxl_clk_i,
        input  wire logic [11:0] pxl_addr_i,
        output wire byte_t       pxl_data_o
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//

xpm_memory_tdpram #(
    // common parameters
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .CLOCKING_MODE("independent_clock"),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(32768),
    .MESSAGE_CONTROL(0),
    .SIM_ASSERT_CHK(0),
    .USE_EMBEDDED_CONSTRAINT(0),
    .USE_MEM_INIT(1),
    .USE_MEM_INIT_MMI(0),
    .WAKEUP_TIME("disable_sleep"),
    .WRITE_PROTECT(0),

    // cpu port
    .ADDR_WIDTH_A(10),
    .BYTE_WRITE_WIDTH_A(8),
    .READ_DATA_WIDTH_A(32),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC"),
    .WRITE_DATA_WIDTH_A(32),
    .WRITE_MODE_A("no_change"),

    // vga port
    .ADDR_WIDTH_B(12),
    .BYTE_WRITE_WIDTH_B(8),
    .READ_DATA_WIDTH_B(8),
    .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("0"),
    .RST_MODE_B("SYNC"),
    .WRITE_DATA_WIDTH_B(8),
    .WRITE_MODE_B("no_change")
)
video_tdpram_inst (
    // common parameters
    .sleep(1'b0),

    // port a
    .clka(cpu_clk_i),
    .addra(cpu_addr_i[11:2]),
    .douta(cpu_read_data_o),
    .dina(cpu_write_data_i),
    .wea(cpu_write_mask_i),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(1'b0),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),

    // port b
    .clkb(pxl_clk_i),
    .addrb(pxl_addr_i),
    .doutb(pxl_data_o),
    .dinb(8'b0),
    .web(1'b0),
    .enb(1'b1),
    .regceb(1'b1),
    .rstb(1'b0),
    .dbiterrb(),
    .sbiterrb(),
    .injectdbiterrb(1'b0),
    .injectsbiterrb(1'b0)
);

`else

//
// Simulator Implementation
//

byte_t mem_r [0:4095] = '{ default: '0 };


// cpu side
word_t cpu_read_data_r = '0;

always_ff @(posedge cpu_clk_i) begin
    cpu_read_data_r <= { mem_r[cpu_addr_i+3], mem_r[cpu_addr_i+2], mem_r[cpu_addr_i+1], mem_r[cpu_addr_i+0] };

    if (cpu_write_mask_i[0]) mem_r[cpu_addr_i+0] <= cpu_write_data_i[ 7: 0];
    if (cpu_write_mask_i[1]) mem_r[cpu_addr_i+1] <= cpu_write_data_i[15: 8];
    if (cpu_write_mask_i[2]) mem_r[cpu_addr_i+2] <= cpu_write_data_i[23:16];
    if (cpu_write_mask_i[3]) mem_r[cpu_addr_i+3] <= cpu_write_data_i[31:24];
end

assign cpu_read_data_o = cpu_read_data_r;


// vga side
byte_t pxl_data_r = '0;

always_ff @(posedge pxl_clk_i) begin
    pxl_data_r <= mem_r[pxl_addr_i];
end

assign pxl_data_o = pxl_data_r;

`endif

endmodule
