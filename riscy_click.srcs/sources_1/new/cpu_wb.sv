`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Write Back Stage
///

module cpu_wb
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic     clk,             // clock
        input  wire logic     reset,           // reset
        
        // data memory
        input  wire word_t    dmem_read_data,  // memory data

        // stage inputs
        input  wire word_t    ma_ir,           // instruction register
        input  wire logic     ma_is_load,      // is this a load instruction?
        input  wire word_t    ma_wb_data,      // write-back register value
        
        // stage outputs (data hazards)
        output      regaddr_t hz_wb_addr,      // write-back address
        output      word_t    hz_wb_data       // write-back value
    );
    

//
// Write Back Signals
//

always_comb begin
    hz_wb_addr = ma_ir[11:7];
    hz_wb_data = ma_is_load ? dmem_read_data : ma_wb_data;
end 

endmodule
