`timescale 1ns / 1ps
`default_nettype none

module system_ram
    // Import Constants
    import common::*;
    (
        input  wire logic       clk_i,
        input  wire logic       chip_select_i,

        // read/write port
        input  wire word_t      addr_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//

// RAM primitive
xpm_memory_spram #(
    // common parameters
    .AUTO_SLEEP_TIME(0),
    .CASCADE_HEIGHT(0),
    .ECC_MODE("no_ecc"),
    .MEMORY_INIT_FILE("none"),
    .MEMORY_INIT_PARAM("0"),
    .MEMORY_OPTIMIZATION("true"),
    .MEMORY_PRIMITIVE("block"),
    .MEMORY_SIZE(32768),
    .MESSAGE_CONTROL(0),
    .SIM_ASSERT_CHK(0),
    .USE_MEM_INIT(1),
    .USE_MEM_INIT_MMI(0),
    .WAKEUP_TIME("disable_sleep"),
    .WRITE_PROTECT(1),

    // port parameters
    .ADDR_WIDTH_A(10),
    .BYTE_WRITE_WIDTH_A(8),
    .READ_DATA_WIDTH_A(32),
    .READ_LATENCY_A(1),
    .READ_RESET_VALUE_A("0"),
    .RST_MODE_A("SYNC"),
    .WRITE_DATA_WIDTH_A(32),
    .WRITE_MODE_A("read_first")
)
system_spram_inst (
    // common
    .sleep(1'b0),

    // port
    .clka(clk_i),
    .rsta(1'b0),
    .regcea(1'b1),
    .ena(chip_select_i),
    .addra(addr_i[11:2]),
    .douta(read_data_o),
    .dina(write_data_i),
    .wea(write_mask_i),
    .dbiterra(),
    .sbiterra(),
    .injectdbiterra(1'b0),
    .injectsbiterra(1'b0)
);

`else

//
// Simulator Implmentation
//

logic [31:0] mem_r [0:1023] = '{ default: '0 };

word_t read_data_r = '0;

always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        read_data_r <= mem_r[addr_i[11:2]];

        if (write_mask_i[0]) mem_r[addr_i[11:2]][ 7: 0] <= write_data_i[ 7: 0];
        if (write_mask_i[1]) mem_r[addr_i[11:2]][15: 8] <= write_data_i[15: 8];
        if (write_mask_i[2]) mem_r[addr_i[11:2]][23:16] <= write_data_i[23:16];
        if (write_mask_i[3]) mem_r[addr_i[11:2]][31:24] <= write_data_i[31:24];
    end
end

assign read_data_o = read_data_r;

`endif

endmodule
