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
        input  wire logic      clk_i,            // clock
        input  wire logic      reset_i,         // reset_i

        // pipeline input port
        input  wire word_t     ir_i,          // instruction register
        input  wire word_t     alu_op1_i,     // ALU operand 1
        input  wire word_t     alu_op2_i,     // ALU operand 2
        input  wire alu_mode_t alu_mode_i,    // ALU mode
        input  wire ma_mode_t  ma_mode_i,     // memory access mode
        input  wire ma_size_t  ma_size_i,     // memory access size
        input  wire word_t     ma_data_i,     // memory access data
        input  wire wb_src_t   writeback_src_i,      // write-back source
        input  wire word_t     writeback_data_i,     // write-back data
        
        // data hazard port
        output      regaddr_t  ex_writeback_addr_o,     // write-back address
        output      word_t     ex_writeback_data_o,     // write-back value
        output      logic      ex_writeback_valid_o,    // write-back value valid

        // pipeline output port
        output      word_t     ir_o,          // instruction register
        output      word_t     ma_addr_o,     // memory access address
        output      ma_mode_t  ma_mode_o,     // memory access mode
        output      ma_size_t  ma_size_o,     // memory access size
        output      word_t     ma_data_o,     // memory access data
        output      wb_src_t   writeback_src_o,      // write-back source
        output      word_t     writeback_data_o      // write-back register value
    );

//
// ALU
//

wire logic  alu_zero_w;
wire word_t alu_result_w;

alu alu (
    .alu_mode_async_i(alu_mode_i),
    .alu_operand1_async_i(alu_op1_i),
    .alu_operand2_async_i(alu_op2_i),
    .alu_zero_async_o(alu_zero_w),
    .alu_result_async_o(alu_result_w)
);


//
// Hazard Signals
//

always_comb begin
    ex_writeback_addr_o  = ir_i[11:7];
    ex_writeback_data_o  = (writeback_src_i == WB_SRC_ALU) ? alu_result_w : writeback_data_i;
    ex_writeback_valid_o = (writeback_src_i != WB_SRC_MEM); 
end  


//
// Pass-through Signals to MA stage
//

always_ff @(posedge clk_i) begin
    ir_o      <= ir_i;
    ma_addr_o <= alu_result_w;
    ma_mode_o <= ma_mode_i;
    ma_size_o <= ma_size_i;
    ma_data_o <= ma_data_i;
    writeback_src_o  <= writeback_src_i;
    writeback_data_o <= ex_writeback_data_o;
    
    if (reset_i) begin
        ir_o      <= NOP_IR;
        ma_addr_o <= 32'h00000000;
        ma_mode_o <= NOP_MA_MODE;
        ma_size_o <= NOP_MA_SIZE;
        ma_data_o <= 32'h00000000;
        writeback_src_o  <= NOP_WB_SRC;
        writeback_data_o <= 32'h00000000;
    end
end

endmodule
