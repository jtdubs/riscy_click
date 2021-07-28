`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Memory Access Stage
///

module cpu_ma
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic       clk,             // clock
        input  wire logic       reset,           // reset

        // data memory
        output      word_t      dmem_addr,       // address
        output      word_t      dmem_write_data, // write data
        output      logic [3:0] dmem_write_mask, // write enable
        
        // stage inputs 
        input  wire word_t      ex_ir,           // instruction register
        input  wire word_t      ex_ma_addr,      // memory access address
        input  wire ma_mode_t   ex_ma_mode,      // memory access mode
        input  wire ma_size_t   ex_ma_size,      // memory access size
        input  wire word_t      ex_ma_data,      // memory access data
        input  wire wb_src_t    ex_wb_src,       // write-back source
        input  wire word_t      ex_wb_data,      // write-back register value
        
        // stage outputs (data hazards)
        output      regaddr_t  hz_ma_wb_addr,    // write-back address
        output      word_t     hz_ma_wb_data,    // write-back value
        output      logic      hz_ma_wb_valid,   // write-back value valid

        // stage outputs (to WB)
        output      word_t     ma_ir,            // instruction register
        output      logic      ma_is_load,       // is this a loan instruction?
        output      word_t     ma_wb_data        // write-back register value
    );
    

//
// Memory Signals
//

always_comb begin
    dmem_addr       = ex_ma_addr;
    dmem_write_data = ex_ma_data;
    dmem_write_mask = (ex_ma_mode == MA_STORE) ? 4'b1111 : 4'b0000;
end 


//
// Hazard Signals
//

always_comb begin
    hz_ma_wb_addr = ex_ir[11:7];

    case (ex_wb_src)
    WB_SRC_MEM:
        begin
            hz_ma_wb_data   = 32'b0;
            hz_ma_wb_valid  = 1'b0; // not available yet
        end
    default:  
        begin
            hz_ma_wb_data   = ex_wb_data;
            hz_ma_wb_valid  = 1'b1;
        end  
    endcase
end  


//
// Pass-through Signals to WB stage
//

always_ff @(posedge clk) begin
    ma_ir      <= ex_ir;
    ma_is_load <= (ex_ma_mode == MA_LOAD) ? 1'b1 : 1'b0;
    ma_wb_data <= ex_wb_data;
    
    if (reset) begin
        ma_ir      <= NOP_IR;
        ma_is_load <= 1'b0;
        ma_wb_data <= 32'h00000000;
    end
end

endmodule
