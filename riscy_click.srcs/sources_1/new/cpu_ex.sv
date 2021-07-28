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
        input  wire logic      reset,          // reset

        // stage inputs
        input  wire word_t     id_ir,          // instruction register
        input  wire word_t     id_alu_op1,     // ALU operand 1
        input  wire word_t     id_alu_op2,     // ALU operand 2
        input  wire alu_mode_t id_alu_mode,    // ALU mode
        input  wire ma_mode_t  id_ma_mode,     // memory access mode
        input  wire ma_size_t  id_ma_size,     // memory access size
        input  wire word_t     id_ma_data,     // memory access data
        input  wire wb_src_t   id_wb_src,      // write-back source
        input  wire word_t     id_wb_data,     // write-back data
        
        // stage outputs (data hazards)
        output      regaddr_t  hz_ex_wb_addr,     // write-back address
        output      word_t     hz_ex_wb_data,     // write-back value
        output      logic      hz_ex_wb_valid,    // write-back value valid

        // stage outputs (to MA)
        output      word_t     ex_ir,          // instruction register
        output      word_t     ex_ma_addr,     // memory access address
        output      ma_mode_t  ex_ma_mode,     // memory access mode
        output      ma_size_t  ex_ma_size,     // memory access size
        output      word_t     ex_ma_data,     // memory access data
        output      wb_src_t   ex_wb_src,      // write-back source
        output      word_t     ex_wb_data      // write-back register value
    );

//
// ALU
//

wire logic  alu_zero;
wire word_t alu_result;

alu alu (
    .mode(id_alu_mode),
    .operand1(id_alu_op1),
    .operand2(id_alu_op2),
    .zero(alu_zero),
    .result(alu_result)
);


//
// Hazard Signals
//

always_comb begin
    hz_ex_wb_addr  = id_ir[11:7];
    hz_ex_wb_data  = (id_wb_src == WB_SRC_ALU) ? alu_result : id_wb_data;
    hz_ex_wb_valid = (id_wb_src != WB_SRC_MEM); 
end  


//
// Pass-through Signals to MA stage
//

always_ff @(posedge clk) begin
    ex_ir      <= id_ir;
    ex_ma_addr <= alu_result;
    ex_ma_mode <= id_ma_mode;
    ex_ma_size <= id_ma_size;
    ex_ma_data <= id_ma_data;
    ex_wb_src  <= id_wb_src;
    ex_wb_data <= hz_ex_wb_data;
    
    if (reset) begin
        ex_ir      <= NOP_IR;
        ex_ma_addr <= 32'h00000000;
        ex_ma_mode <= NOP_MA_MODE;
        ex_ma_size <= NOP_MA_SIZE;
        ex_ma_data <= 32'h00000000;
        ex_wb_src  <= NOP_WB_SRC;
        ex_wb_data <= 32'h00000000;
    end
end

endmodule
