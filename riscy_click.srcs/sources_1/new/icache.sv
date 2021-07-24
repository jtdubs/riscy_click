`timescale 1ns/1ps

///
/// Risc-V CPU Instruction Cache
///
/// Design:
/// - Trivial Direct map cache

module icache
    // Import Constants
    import consts::*;
    #(
        // The number of cycles required for memory access
        parameter MEM_ACCESS_CYCLES = 2
    )
    (
        // cpu signals
        input       logic       clk,            // clock
        input       logic       reset,          // reset

        // instruction memory
        output      word        mem_addr,       // address
        input       word        mem_data,       // data

        // stage inputs (latched)
        input       word        req_addr,       // requested address

        // stage outputs (latched)
        output      logic       ic_hit,         // cache hit indicator
        output      word        ic_data         // data from cache
    );

endmodule
