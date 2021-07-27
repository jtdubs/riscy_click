`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Write Back Stage
///

module cpu_wb
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input  wire logic    clk,        // clock
        input  wire logic    reset,      // reset
        input  wire logic    halt,       // halt
        
        // data memory
        input  wire word     dmem_read_data,  // memory data

        // stage inputs
        input  wire word     ma_pc,      // program counter
        input  wire word     ma_ir,      // instruction register
        input  wire logic    ma_is_load, // is this a load instruction?
        input  wire regaddr  ma_wb_addr, // write-back register address
        input  wire word     ma_wb_data, // write-back register value
        
        // stage outputs (data hazards)
        output      regaddr  hz_wb_addr, // write-back address
        output      word     hz_wb_data  // write-back value
    );
    

//
// Write Back Signals
//

always_comb begin
    hz_wb_addr = ma_wb_addr;
    hz_wb_data = ma_is_load ? dmem_read_data : ma_wb_data;
end 

endmodule
