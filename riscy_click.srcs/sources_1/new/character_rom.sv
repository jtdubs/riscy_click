`timescale 1ns / 1ps
`default_nettype none

module character_rom
    // Import Constants
    import common::*;
    #(
        CONTENTS = ""
    )
    (
        input  wire logic  clk_i,
        input  wire logic  reset_i,
        
        // port
        input  wire word_t addr_i,
        output wire word_t data_o
    );
    
    
 xpm_memory_sprom #(
    // common parameters
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE(CONTENTS),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("false"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(131072),
    .MESSAGE_CONTROL(0),
    .SIM_ASSERT_CHK(0),
    .USE_MEM_INIT(1),
    .USE_MEM_INIT_MMI(1),
    .WAKEUP_TIME("disable_sleep"),
    
    // port parameters
    .ADDR_WIDTH_A(12),
    .READ_DATA_WIDTH_A(32),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC")
)
character_sprom_inst (
    // common parameters
    .sleep(1'b0),
    
    // port parameters
    .clka(clk_i),
    .addra(addr_i),
    .douta(data_o),
    .ena(1'b1),
    .regcea(1'b1),
    .rsta(reset_i),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0)
);

endmodule
