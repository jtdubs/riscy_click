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
        input  wire logic  reset,
        
        // port a
        input  wire word_t addr_a,
        output wire word_t data_a,
        
        // port b
        input  wire word_t addr_b,
        output wire word_t data_b
    );
    
// xpm_memory_dprom: Dual Port ROM
// Xilinx Parameterized Macro, version 2021.1

xpm_memory_dprom #(
  .ADDR_WIDTH_A(10),              // DECIMAL
  .ADDR_WIDTH_B(10),              // DECIMAL
  .AUTO_SLEEP_TIME(0),            // DECIMAL
  .CASCADE_HEIGHT(0),             // DECIMAL
  .CLOCKING_MODE("common_clock"), // String
  .ECC_MODE("no_ecc"),            // String
  .MEMORY_INIT_FILE(CONTENTS),    // String
  .MEMORY_INIT_PARAM("0"),        // String
  .MEMORY_OPTIMIZATION("false"),  // String
  .MEMORY_PRIMITIVE("block"),     // String
  .MEMORY_SIZE(32768),            // DECIMAL
  .MESSAGE_CONTROL(0),            // DECIMAL
  .READ_DATA_WIDTH_A(32),         // DECIMAL
  .READ_DATA_WIDTH_B(32),         // DECIMAL
  .READ_LATENCY_A(1),             // DECIMAL
  .READ_LATENCY_B(1),             // DECIMAL
  .READ_RESET_VALUE_A("0"),       // String
  .READ_RESET_VALUE_B("0"),       // String
  .RST_MODE_A("SYNC"),            // String
  .RST_MODE_B("SYNC"),            // String
  .SIM_ASSERT_CHK(0),             // DECIMAL; 0=disable simulation messages, 1=enable simulation messages
  .USE_MEM_INIT(1),               // DECIMAL
  .USE_MEM_INIT_MMI(1),           // DECIMAL
  .WAKEUP_TIME("disable_sleep")   // String
)
xpm_memory_dprom_inst (
  .dbiterra(),                     // 1-bit output: Leave open.
  .dbiterrb(),                     // 1-bit output: Leave open.
  .douta(data_a),                  // READ_DATA_WIDTH_A-bit output: Data output for port A read operations.
  .doutb(data_b),                  // READ_DATA_WIDTH_B-bit output: Data output for port B read operations.
  .sbiterra(),                     // 1-bit output: Leave open.
  .sbiterrb(),                     // 1-bit output: Leave open.
  .addra(addr_a[11:2]),            // ADDR_WIDTH_A-bit input: Address for port A read operations.
  .addrb(addr_b[11:2]),            // ADDR_WIDTH_B-bit input: Address for port B read operations.
  .clka(clk),                      // 1-bit input: Clock signal for port A. Also clocks port B when
                                   // parameter CLOCKING_MODE is "common_clock".

  .clkb(clk),                      // 1-bit input: Clock signal for port B when parameter CLOCKING_MODE is
                                   // "independent_clock". Unused when parameter CLOCKING_MODE is
                                   // "common_clock".

  .ena(1'b1),                      // 1-bit input: Memory enable signal for port A. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .enb(1'b1),                      // 1-bit input: Memory enable signal for port B. Must be high on clock
                                   // cycles when read operations are initiated. Pipelined internally.

  .injectdbiterra(1'b0),           // 1-bit input: Do not change from the provided value.
  .injectdbiterrb(1'b0),           // 1-bit input: Do not change from the provided value.
  .injectsbiterra(1'b0),           // 1-bit input: Do not change from the provided value.
  .injectsbiterrb(1'b0),           // 1-bit input: Do not change from the provided value.
  .regcea(1'b1),                   // 1-bit input: Do not change from the provided value.
  .regceb(1'b1),                   // 1-bit input: Do not change from the provided value.
  .rsta(1'b0),                     // 1-bit input: Reset signal for the final port A output register stage.
                                   // Synchronously resets output port douta to the value specified by
                                   // parameter READ_RESET_VALUE_A.

  .rstb(1'b0),                     // 1-bit input: Reset signal for the final port B output register stage.
                                   // Synchronously resets output port doutb to the value specified by
                                   // parameter READ_RESET_VALUE_B.

  .sleep(1'b0)                     // 1-bit input: sleep signal to enable the dynamic power saving feature.
);

// End of xpm_memory_dprom_inst instantiation

endmodule
