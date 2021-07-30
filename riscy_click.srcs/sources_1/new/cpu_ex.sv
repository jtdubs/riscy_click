`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Execution Stage
///

module cpu_ex
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic      clk,            // clock
        input  wire logic      ia_rst,         // reset

        // pipeline input port
        input  wire word_t     ic_ex_ir,          // instruction register
        input  wire word_t     ic_ex_alu_op1,     // ALU operand 1
        input  wire word_t     ic_ex_alu_op2,     // ALU operand 2
        input  wire alu_mode_t ic_ex_alu_mode,    // ALU mode
        input  wire ma_mode_t  ic_ex_ma_mode,     // memory access mode
        input  wire ma_size_t  ic_ex_ma_size,     // memory access size
        input  wire word_t     ic_ex_ma_data,     // memory access data
        input  wire wb_src_t   ic_ex_wb_src,      // write-back source
        input  wire word_t     ic_ex_wb_data,     // write-back data
        
        // data hazard port
        output      regaddr_t  oa_hz_ex_addr,     // write-back address
        output      word_t     oa_hz_ex_data,     // write-back value
        output      logic      oa_hz_ex_valid,    // write-back value valid

        // pipeline output port
        output      word_t     oc_ex_ir,          // instruction register
        output      word_t     oc_ex_ma_addr,     // memory access address
        output      ma_mode_t  oc_ex_ma_mode,     // memory access mode
        output      ma_size_t  oc_ex_ma_size,     // memory access size
        output      word_t     oc_ex_ma_data,     // memory access data
        output      wb_src_t   oc_ex_wb_src,      // write-back source
        output      word_t     oc_ex_wb_data      // write-back register value
    );

//
// ALU
//

wire logic  a_alu_zero;
wire word_t a_alu_result;

alu alu (
    .ia_alu_mode(ic_ex_alu_mode),
    .ia_alu_operand1(ic_ex_alu_op1),
    .ia_alu_operand2(ic_ex_alu_op2),
    .oa_alu_zero(a_alu_zero),
    .oa_alu_result(a_alu_result)
);


//
// Hazard Signals
//

always_comb begin
    oa_hz_ex_addr  = ic_ex_ir[11:7];
    oa_hz_ex_data  = (ic_ex_wb_src == WB_SRC_ALU) ? a_alu_result : ic_ex_wb_data;
    oa_hz_ex_valid = (ic_ex_wb_src != WB_SRC_MEM); 
end  


//
// Pass-through Signals to MA stage
//

always_ff @(posedge clk) begin
    oc_ex_ir      <= ic_ex_ir;
    oc_ex_ma_addr <= a_alu_result;
    oc_ex_ma_mode <= ic_ex_ma_mode;
    oc_ex_ma_size <= ic_ex_ma_size;
    oc_ex_ma_data <= ic_ex_ma_data;
    oc_ex_wb_src  <= ic_ex_wb_src;
    oc_ex_wb_data <= oa_hz_ex_data;
    
    if (ia_rst) begin
        oc_ex_ir      <= NOP_IR;
        oc_ex_ma_addr <= 32'h00000000;
        oc_ex_ma_mode <= NOP_MA_MODE;
        oc_ex_ma_size <= NOP_MA_SIZE;
        oc_ex_ma_data <= 32'h00000000;
        oc_ex_wb_src  <= NOP_WB_SRC;
        oc_ex_wb_data <= 32'h00000000;
    end
end

endmodule
