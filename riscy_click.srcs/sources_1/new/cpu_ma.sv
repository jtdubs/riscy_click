`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Memory Access Stage
///

module cpu_ma
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input  wire logic    clk,              // clock
        input  wire logic    reset,            // reset
        input  wire logic    halt,             // halt

        // data memory
        output      word     mem_addr,         // address
        input  wire word     mem_read_data,    // read data
        output      word     mem_write_data,   // write data
        output      logic    mem_write_enable, // write enable
        
        // stage inputs
        input  wire word     ex_pc,            // program counter
        input  wire word     ex_ir,            // instruction register
        input  wire word     ex_alu_result,    // alu result
        input  wire ma_mode  ex_ma_mode,       // memory access mode
        input  wire ma_size  ex_ma_size,       // memory access size
        input  wire word     ex_ma_data,       // memory access data
        input  wire wb_src   ex_wb_src,        // write-back source
        input  wire regaddr  ex_wb_addr,       // write-back register address
        input  wire word     ex_wb_data,       // write-back register value
        
        // stage outputs (data hazards)
        output      regaddr  hz_ma_wb_addr,    // write-back address
        output      word     hz_ma_wb_data,    // write-back value
        output      logic    hz_ma_wb_valid,   // write-back value valid

        // stage outputs (to WB)
        output      word     ma_pc,            // program counter
        output      word     ma_ir,            // instruction register
        output      regaddr  ma_wb_addr,       // write-back register address
        output      word     ma_wb_data        // write-back register value
    );
    

//
// Memory Signals
//

always_comb begin
    mem_addr         = ex_alu_result;
    mem_write_data   = ex_ma_data;
    mem_write_enable = (ex_ma_mode == MA_STORE) ? 1'b1 : 1'b0;
end 


//
// Hazard Signals
//

always_comb begin
    case (ex_wb_src)
    WB_SRC_MEM:
        begin
            hz_ma_wb_addr   = ex_wb_addr;
            hz_ma_wb_data   = 32'b0;
            hz_ma_wb_valid  = 1'b0; // not available yet
        end
    default:  
        begin
            hz_ma_wb_addr   = ex_wb_addr;
            hz_ma_wb_data   = ex_wb_data;
            hz_ma_wb_valid  = 1'b1;
        end  
    endcase
end  


//
// Pass-through Signals to WB stage
//

always_ff @(posedge clk) begin
    ma_pc         <= ex_pc;
    ma_ir         <= ex_ir;
    ma_wb_addr    <= ex_wb_addr;
    ma_wb_data    <= (ex_ma_mode == MA_LOAD) ? mem_read_data : ex_wb_data;
end

endmodule
