`timescale 1ns / 1ps
`default_nettype none

module keycode_rom
    // Import Constants
    import common::*;
    #(
        CONTENTS = ""
    )
    (
        input  wire logic       clk_i,

        // port
        input  wire logic [8:0] addr_i,
        output wire logic [7:0] data_o
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//

xpm_memory_sprom #(
    // common parameters
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE(CONTENTS),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("false"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(4096),
    .MESSAGE_CONTROL(0),
    .SIM_ASSERT_CHK(0),
    .USE_MEM_INIT(1),
    .USE_MEM_INIT_MMI(1),
    .WAKEUP_TIME("disable_sleep"),

    // port parameters
    .ADDR_WIDTH_A(9),
    .READ_DATA_WIDTH_A(8),
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
    .rsta(1'b0),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0)
);

`else

//
// Simulator Implmentation
//

logic [7:0] rom [0:511];

initial begin
    $readmemh(CONTENTS, rom);
end

logic [7:0] data_r = '0;

always_ff @(posedge clk_i) begin
    data_r <= rom[addr_i];
end

assign data_o = data_r;

`endif

endmodule
