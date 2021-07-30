`timescale 1ns / 1ps
`default_nettype none

module block_rom
    // Import Constants
    import common::*;
    #(
        CONTENTS = ""
    )
    (
        input  wire logic  clk,
        input  wire logic  ic_rst,
        
        // read port a
        input  wire word_t ic_ra_addr,
        output wire word_t oa_ra_data,
        
        // read port b
        input  wire word_t ic_rb_addr,
        output wire word_t oa_rb_data
    );

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
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC"),
    
    // port B
    .ADDR_WIDTH_B(10),
    .READ_DATA_WIDTH_B(32),
    .READ_LATENCY_B(1),
    .READ_RESET_VALUE_B("0"),
    .RST_MODE_B("SYNC")
)
rom_inst (
    // common
    .sleep(1'b0),
    
    // port A
    .clka(clk),
    .rsta(ic_rst),
    .ena(1'b1),
    .regcea(1'b1),
    .addra(ic_ra_addr[11:2]),
    .douta(oa_ra_data),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0),
      
    // port B
    .clkb(clk),
    .rstb(ic_rst),
    .enb(1'b1),
    .regceb(1'b1),
    .addrb(ic_rb_addr[11:2]),
    .doutb(oa_rb_data),
    .dbiterrb(),
    .sbiterrb(),
    .injectdbiterrb(1'b0),
    .injectsbiterrb(1'b0)
);

endmodule
