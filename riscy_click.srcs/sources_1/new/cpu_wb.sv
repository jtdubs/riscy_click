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
        input  wire logic     clk,           // clock
        input  wire logic     ia_rst,        // reset
        
        // data memory port
        input  wire word_t    ia_dmem_rddata,  // memory data

        // pipeline input port
        input  wire word_t    ic_wb_ir,      // instruction register
        input  wire logic     ic_wb_is_load, // is this a load instruction?
        input  wire word_t    ic_wb_data,    // write-back register value
        
        // pipeline output port
        output      regaddr_t oa_wb_addr,    // write-back address
        output      word_t    oa_wb_data     // write-back value
    );
    

//
// Write Back Signals
//

always_comb begin
    oa_wb_addr = ic_wb_ir[11:7];
    oa_wb_data = ic_wb_is_load ? ia_dmem_rddata : ic_wb_data;
end 

endmodule
