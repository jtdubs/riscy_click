`timescale 1ns / 1ps
`default_nettype none

///
/// Register File (32 x 32-bit)
///
/// Specs:
/// 2-port async read
/// 1-port sync write
///

module register_file
    // Import Constants
    import common::*;
    import cpu_common::*;
    (
        input  wire logic     clk_i,              // Clock

        // read port A
        input  wire regaddr_t ra_addr_i,       // Read Address
        output      word_t    ra_data_async_o, // Data Output

        // read port B
        input  wire regaddr_t rb_addr_i,       // Read Address
        output      word_t    rb_data_async_o, // Data Output

        // write port
        input  wire logic     wr_enable_i,     // Write Enable
        input  wire regaddr_t wr_addr_i,       // Write Address
        input  wire word_t    wr_data_i        // Write Data
    );
    
`ifdef ENABLE_XILINX_PRIMITIVES

xpm_memory_sdpram #(
  .CASCADE_HEIGHT(0),
  .CLOCKING_MODE("common_clock"),
  .ECC_MODE("no_ecc"),
  .MEMORY_INIT_FILE("none"),
  .MEMORY_INIT_PARAM("0"),
  .MEMORY_OPTIMIZATION("true"),
  .MEMORY_PRIMITIVE("distributed"),
  .MEMORY_SIZE(1024),
  .MESSAGE_CONTROL(0),
  .AUTO_SLEEP_TIME(0),
  .SIM_ASSERT_CHK(0),
  .USE_EMBEDDED_CONSTRAINT(0),
  .USE_MEM_INIT(1),
  .USE_MEM_INIT_MMI(0),
  .WAKEUP_TIME("disable_sleep"),
  .WRITE_PROTECT(1),
  
  .ADDR_WIDTH_A(5),
  .BYTE_WRITE_WIDTH_A(32),
  .RST_MODE_A("SYNC"),
  .WRITE_DATA_WIDTH_A(32),
  
  .ADDR_WIDTH_B(5),
  .READ_DATA_WIDTH_B(32),
  .READ_LATENCY_B(0),
  .READ_RESET_VALUE_B("0"),
  .WRITE_MODE_B("read_first"),
  .RST_MODE_B("SYNC")
)
register_file_1 (
  .clka(clk_i),
  .addra(wr_addr_i),
  .dina(wr_data_i),
  .ena(wr_enable_i),
  .wea(wr_enable_i),
  
  .clkb(clk_i),
  .addrb(ra_addr_i),
  .doutb(ra_data_async_o),
  
  .enb(1'b1),
  .rstb(1'b0),
  .regceb(1'b1),
  .sbiterrb(),
  .dbiterrb(),
  .injectdbiterra(1'b0),
  .injectsbiterra(1'b0),
  .sleep(1'b0)
);

xpm_memory_sdpram #(
  .CASCADE_HEIGHT(0),
  .CLOCKING_MODE("common_clock"),
  .ECC_MODE("no_ecc"),
  .MEMORY_INIT_FILE("none"),
  .MEMORY_INIT_PARAM("0"),
  .MEMORY_OPTIMIZATION("true"),
  .MEMORY_PRIMITIVE("distributed"),
  .MEMORY_SIZE(1024),
  .MESSAGE_CONTROL(0),
  .AUTO_SLEEP_TIME(0),
  .SIM_ASSERT_CHK(0),
  .USE_EMBEDDED_CONSTRAINT(0),
  .USE_MEM_INIT(1),
  .USE_MEM_INIT_MMI(0),
  .WAKEUP_TIME("disable_sleep"),
  .WRITE_PROTECT(1),
  
  .ADDR_WIDTH_A(5),
  .BYTE_WRITE_WIDTH_A(32),
  .RST_MODE_A("SYNC"),
  .WRITE_DATA_WIDTH_A(32),
  
  .ADDR_WIDTH_B(5),
  .READ_DATA_WIDTH_B(32),
  .READ_LATENCY_B(0),
  .READ_RESET_VALUE_B("0"),
  .WRITE_MODE_B("read_first"),
  .RST_MODE_B("SYNC")
)
register_file_2 (
  .clka(clk_i),
  .addra(wr_addr_i),
  .dina(wr_data_i),
  .ena(wr_enable_i),
  .wea(wr_enable_i),
  
  .clkb(clk_i),
  .addrb(rb_addr_i),
  .doutb(rb_data_async_o),
  
  .enb(1'b1),
  .rstb(1'b0),
  .regceb(1'b1),
  .sbiterrb(),
  .dbiterrb(),
  .injectdbiterra(1'b0),
  .injectsbiterra(1'b0),
  .sleep(1'b0)
);
				
`else

// Memory
word_t mem_r [31:0] = '{ default: '0 };

//// Read Addresses
//word_t ra_addr_r;
//word_t rb_addr_r;

//always_ff @(posedge clk_i) begin
//    ra_addr_r <= ra_addr_i;
//    rb_addr_r <= rb_addr_i;
//end

// Read Data
assign ra_data_async_o = mem_r[ra_addr_i];
assign rb_data_async_o = mem_r[rb_addr_i];

// Write Operations
always_ff @(posedge clk_i) begin
    if (wr_enable_i && wr_addr_i != 5'b00000) begin
        mem_r[wr_addr_i] <= wr_data_i;
    end
end

`endif

endmodule
