`timescale 1ns / 1ps
`default_nettype none

module block_ram
    // Import Constants
    import common::*;
    (
        input  wire logic       clk,
        input  wire logic       reset,
        
        input  wire word_t      addr,
        output wire word_t      read_data,
        input  wire word_t      write_data,
        input  wire logic [3:0] write_mask
    );

   // xpm_memory_spram: Single Port RAM
   // Xilinx Parameterized Macro, version 2021.1

   xpm_memory_spram #(
      .ADDR_WIDTH_A(10),             // DECIMAL
      .AUTO_SLEEP_TIME(0),           // DECIMAL
      .BYTE_WRITE_WIDTH_A(8),        // DECIMAL
      .CASCADE_HEIGHT(0),            // DECIMAL
      .ECC_MODE("no_ecc"),           // String
      .MEMORY_INIT_FILE("none"),     // String
      .MEMORY_INIT_PARAM("0"),       // String
      .MEMORY_OPTIMIZATION("false"), // String
      .MEMORY_PRIMITIVE("block"),    // String
      .MEMORY_SIZE(32768),           // DECIMAL
      .MESSAGE_CONTROL(0),           // DECIMAL
      .READ_DATA_WIDTH_A(32),        // DECIMAL
      .READ_LATENCY_A(1),            // DECIMAL
      .READ_RESET_VALUE_A("0"),      // String
      .RST_MODE_A("SYNC"),           // String
      .SIM_ASSERT_CHK(0),            // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
      .USE_MEM_INIT(1),              // DECIMAL
      .USE_MEM_INIT_MMI(0),          // DECIMAL
      .WAKEUP_TIME("disable_sleep"), // String
      .WRITE_DATA_WIDTH_A(32),       // DECIMAL
      .WRITE_MODE_A("read_first"),   // String
      .WRITE_PROTECT(0)              // DECIMAL
   )
   xpm_memory_spram_inst (
      .dbiterra(),                     // 1-bit output: Status signal to indicate double bit error occurrence
                                       // on the data output of port A.

      .douta(read_data),               // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
      .sbiterra(),                     // 1-bit output: Status signal to indicate single bit error occurrence
                                       // on the data output of port A.

      .addra(addr[11:2]),              // ADDR_WIDTH_A-bit input: Address for port A write and read operations.
      .clka(clk),                      // 1-bit input: Clock signal for port A.
      .dina(write_data),               // WRITE_DATA_WIDTH_A-bit input: Data input for port A write operations.
      .ena(1'b1),                      // 1-bit input: Memory enable signal for port A. Must be high on clock
                                       // cycles when read or write operations are initiated. Pipelined
                                       // internally.

      .injectdbiterra(1'b0),           // 1-bit input: Controls double bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .injectsbiterra(1'b0),           // 1-bit input: Controls single bit error injection on input data when
                                       // ECC enabled (Error injection capability is not available in
                                       // "decode_only" mode).

      .regcea(1'b1),                   // 1-bit input: Clock Enable for the last register stage on the output
                                       // data path.

      .rsta(1'b0),                     // 1-bit input: Reset signal for the final port A output register stage.
                                       // Synchronously resets output port douta to the value specified by
                                       // parameter READ_RESET_VALUE_A.

      .sleep(1'b0),                    // 1-bit input: sleep signal to enable the dynamic power saving feature.
      .wea(write_mask)                 // WRITE_DATA_WIDTH_A/BYTE_WRITE_WIDTH_A-bit input: Write enable vector
                                       // for port A input data port dina. 1 bit wide when word-wide writes are
                                       // used. In byte-wide write configurations, each bit controls the
                                       // writing one byte of dina to address addra. For example, to
                                       // synchronously write only bits [15-8] of dina when WRITE_DATA_WIDTH_A
                                       // is 32, wea would be 4'b0010.

   );

   // End of xpm_memory_spram_inst instantiation
				
endmodule
