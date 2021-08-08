`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Execution Stage
///

module cpu_ex
    // Import Constants
    import common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic      clk_i,            // clock
        input  wire logic      reset_i,          // reset_i

        // pipeline input
        input  wire word_t     pc_i,             // program counter
        input  wire word_t     ir_i,             // instruction register
        input  wire word_t     alu_op1_i,        // ALU operand 1
        input  wire word_t     alu_op2_i,        // ALU operand 2
        input  wire alu_mode_t alu_mode_i,       // ALU mode
        input  wire ma_mode_t  ma_mode_i,        // memory access mode
        input  wire ma_size_t  ma_size_i,        // memory access size
        input  wire word_t     ma_data_i,        // memory access data
        input  wire wb_src_t   wb_src_i,         // write-back source
        input  wire word_t     wb_data_i,        // write-back data
        input  wire logic      wb_valid_i,       // write-back valid
        
        // async output
        output      regaddr_t  wb_addr_async_o,  // write-back address
        output      word_t     wb_data_async_o,  // write-back data
        output      logic      wb_ready_async_o, // write-back data ready
        output      logic      wb_valid_async_o, // write-back valid
        output      logic      empty_async_o,    // stage empty

        // pipeline output
        output      word_t     pc_o,             // program counter
        output      word_t     ir_o,             // instruction register
        output      word_t     ma_addr_o,        // memory access address
        output      ma_mode_t  ma_mode_o,        // memory access mode
        output      ma_size_t  ma_size_o,        // memory access size
        output      word_t     ma_data_o,        // memory access data
        output      wb_src_t   wb_src_o,         // write-back source
        output      word_t     wb_data_o,        // write-back data
        output      logic      wb_valid_o        // write-back valid
    );

initial start_logging();
final stop_logging();

//
// ALU
//

wire logic  alu_zero_w;
wire word_t alu_result_w;

alu alu (
    .alu_mode_async_i   (alu_mode_i),
    .alu_op1_async_i    (alu_op1_i),
    .alu_op2_async_i    (alu_op2_i),
    .alu_zero_async_o   (alu_zero_w),
    .alu_result_async_o (alu_result_w)
);


//
// Async Outputs
//

always_comb begin
    wb_addr_async_o  = ir_i[11:7];
    wb_data_async_o  = (wb_src_i == WB_SRC_ALU) ? alu_result_w : wb_data_i;
    wb_ready_async_o = (wb_src_i != WB_SRC_MEM);
    wb_valid_async_o = wb_valid_i;
    empty_async_o    = pc_i == NOP_PC;

`ifdef VERILATOR
    $strobe("{ \"stage\": \"EX\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ex_wb_addr\": \"%0d\", \"ex_wb_data\": \"%0d\", \"ex_wb_valid\": \"%0d\" },", $time, pc_i, wb_addr_async_o, wb_data_async_o, wb_valid_async_o);
`else
    $fstrobe(log_fd, "{ \"stage\": \"EX\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ex_wb_addr\": \"%0d\", \"ex_wb_data\": \"%0d\", \"ex_wb_valid\": \"%0d\" },", $time, pc_i, wb_addr_async_o, wb_data_async_o, wb_valid_async_o);
`endif

end  


//
// Pipeline Output
//

always_ff @(posedge clk_i) begin
    pc_o       <= pc_i;
    ir_o       <= ir_i;
    ma_addr_o  <= alu_result_w;
    ma_mode_o  <= ma_mode_i;
    ma_size_o  <= ma_size_i;
    ma_data_o  <= ma_data_i;
    wb_src_o   <= wb_src_i;
    wb_data_o  <= wb_data_async_o;
    wb_valid_o <= wb_valid_i;
    
    if (reset_i) begin
        pc_o       <= NOP_PC;
        ir_o       <= NOP_IR;
        ma_addr_o  <= 32'b0;
        ma_mode_o  <= NOP_MA_MODE;
        ma_size_o  <= NOP_MA_SIZE;
        ma_data_o  <= 32'b0;
        wb_src_o   <= NOP_WB_SRC;
        wb_data_o  <= 32'b0;
        wb_valid_o <= NOP_WB_VALID; 
    end

`ifdef VERILATOR
    $strobe("{ \"stage\": \"EX\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"ma_addr\": \"%0d\", \"ma_mode\": \"%0d\", \"ma_size\": \"%0d\", \"ma_data\": \"%0d\", \"wb_src\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" },", $time, pc_o, ir_o, ma_addr_o, ma_mode_o, ma_size_o, ma_data_o, wb_src_o, wb_data_o, wb_valid_o);
`else
    $fstrobe(log_fd, "{ \"stage\": \"EX\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"ma_addr\": \"%0d\", \"ma_mode\": \"%0d\", \"ma_size\": \"%0d\", \"ma_data\": \"%0d\", \"wb_src\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" },", $time, pc_o, ir_o, ma_addr_o, ma_mode_o, ma_size_o, ma_data_o, wb_src_o, wb_data_o, wb_valid_o);
`endif

end

endmodule
