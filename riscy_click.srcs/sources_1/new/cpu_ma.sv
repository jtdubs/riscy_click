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
        input  wire logic       clk,            // clock
        input  wire logic       ic_rst,         // reset

        // data memory port
        output      word_t      oa_dmem_addr,   // address
        output      word_t      oa_dmem_wrdata,   // write data
        output      logic [3:0] oa_dmem_wrmask,   // write enable
        
        // pipeline input port
        input  wire word_t      ic_ma_ir,       // instruction register
        input  wire word_t      ic_ma_addr,     // memory access address
        input  wire ma_mode_t   ic_ma_mode,     // memory access mode
        input  wire ma_size_t   ic_ma_size,     // memory access size
        input  wire word_t      ic_ma_data,     // memory access data
        input  wire wb_src_t    ic_ma_wb_src,   // write-back source
        input  wire word_t      ic_ma_wb_data,  // write-back register value
        
        // data hazard port
        output      regaddr_t   oa_hz_ma_addr,  // write-back address
        output      word_t      oa_hz_ma_data,  // write-back value
        output      logic       oa_hz_ma_valid, // write-back value valid

        // pipeline output port
        output      word_t      oc_ma_ir,       // instruction register
        output      logic       oc_ma_is_load,  // is this a loan instruction?
        output      word_t      oc_ma_wb_data   // write-back register value
    );
    

//
// Memory Signals
//

always_comb begin
    oa_dmem_addr   = ic_ma_addr;
    oa_dmem_wrdata = ic_ma_data;
    oa_dmem_wrmask = (ic_ma_mode == MA_STORE) ? 4'b1111 : 4'b0000;
    // TODO: deal with MA_SIZE values other than W
end 


//
// Hazard Signals
//

always_comb begin
    oa_hz_ma_addr = ic_ma_ir[11:7];

    case (ic_ma_wb_src)
    WB_SRC_MEM:
        begin
            oa_hz_ma_data   = 32'b0;
            oa_hz_ma_valid  = 1'b0; // not available yet
        end
    default:  
        begin
            oa_hz_ma_data   = ic_ma_wb_data;
            oa_hz_ma_valid  = 1'b1;
        end  
    endcase
end  


//
// Pass-through Signals to WB stage
//

always_ff @(posedge clk) begin
    oc_ma_ir      <= ic_ma_ir;
    oc_ma_is_load <= (ic_ma_mode == MA_LOAD);
    oc_ma_wb_data <= ic_ma_wb_data;
    
    if (ic_rst) begin
        oc_ma_ir      <= NOP_IR;
        oc_ma_is_load <= 1'b0;
        oc_ma_wb_data <= 32'h00000000;
    end
end

endmodule
