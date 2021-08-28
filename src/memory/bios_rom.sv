`timescale 1ns / 1ps
`default_nettype none

module bios_rom
    // Import Constants
    import common::*;
    #(
        parameter string CONTENTS = ""
    )
    (
        input  wire logic  clk_i,

        // read port a
        input  wire word_t read1_addr_i,
        input  wire logic  read1_enable_i,
        output wire word_t read1_data_o,

        // read port b
        input  wire word_t read2_addr_i,
        input  wire logic  read2_enable_i,
        output wire word_t read2_data_o
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//


// ROM primitive
xpm_memory_dprom #(
    // common parameters
    .MEMORY_INIT_FILE(CONTENTS),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("false"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(32768),
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .CLOCKING_MODE("common_clock"),
    .ECC_MODE("no_ecc"),
    .MESSAGE_CONTROL(0),
    .SIM_ASSERT_CHK(0),
    .USE_MEM_INIT(1),
    .USE_MEM_INIT_MMI(1),
    .WAKEUP_TIME("disable_sleep"),

    // port A
    .ADDR_WIDTH_A(10),
    .READ_DATA_WIDTH_A(32),
    .READ_LATENCY_A(2),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC"),

    // port B
    .ADDR_WIDTH_B(10),
    .READ_DATA_WIDTH_B(32),
    .READ_LATENCY_B(2),
    .READ_RESET_VALUE_B("0"),
    .RST_MODE_B("SYNC")
)
bios_dprom_inst (
    // common
    .sleep(1'b0),

    // port A
    .clka(clk_i),
    .rsta(1'b0),
    .ena(read1_enable_i),
    .regcea(1'b1),
    .addra(read1_addr_i[11:2]),
    .douta(read1_data_o),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),

    // port B
    .clkb(clk_i),
    .rstb(1'b0),
    .enb(read2_enable_i),
    .regceb(1'b1),
    .addrb(read2_addr_i[11:2]),
    .doutb(read2_data_o),
    .dbiterrb(),
    .sbiterrb(),
    .injectdbiterrb(1'b0),
    .injectsbiterrb(1'b0)
);

`else

//
// Simulator Implmentation
//


logic [31:0] mem_r [0:1023];

initial begin
    $readmemh(CONTENTS, mem_r);
end

word_t read1_data_r [1:0] = '{ default: '0 };
word_t read2_data_r [1:0] = '{ default: '0 };

always_ff @(posedge clk_i) begin
    if (read1_enable_i)
        read1_data_r <= { mem_r[read1_addr_i[11:2]], read1_data_r[1] };

    if (read2_enable_i)
        read2_data_r <= { mem_r[read2_addr_i[11:2]], read2_data_r[1] };
end

assign read1_data_o = read1_data_r[0];
assign read2_data_o = read2_data_r[0];

`endif

endmodule
