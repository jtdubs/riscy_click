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
        output wire word_t     pc_o,             // program counter
        output wire word_t     ir_o,             // instruction register
        output wire word_t     ma_addr_o,        // memory access address
        output wire ma_mode_t  ma_mode_o,        // memory access mode
        output wire ma_size_t  ma_size_o,        // memory access size
        output wire word_t     ma_data_o,        // memory access data
        output wire wb_src_t   wb_src_o,         // write-back source
        output wire word_t     wb_data_o,        // write-back data
        output wire logic      wb_valid_o        // write-back valid
    );

initial start_logging();
final stop_logging();

//
// ALU
//

wire word_t alu_result_w;

alu alu (
    .alu_mode_i         (alu_mode_i),
    .alu_op1_i          (alu_op1_i),
    .alu_op2_i          (alu_op2_i),
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

    `log_strobe(("{ \"stage\": \"EX\", \"pc\": \"%0d\", \"ex_wb_addr\": \"%0d\", \"ex_wb_data\": \"%0d\", \"ex_wb_valid\": \"%0d\" }", pc_i, wb_addr_async_o, wb_data_async_o, wb_valid_async_o));
end


//
// Pipeline Output
//

word_t    pc_r       = NOP_PC;
word_t    ir_r       = NOP_IR;
word_t    ma_addr_r  = 32'b0;
ma_mode_t ma_mode_r  = NOP_MA_MODE;
ma_size_t ma_size_r  = NOP_MA_SIZE;
word_t    ma_data_r  = 32'b0;
wb_src_t  wb_src_r   = NOP_WB_SRC;
word_t    wb_data_r  = 32'b0;
logic     wb_valid_r = NOP_WB_VALID; 

always_ff @(posedge clk_i) begin
    pc_r       <= pc_i;
    ir_r       <= ir_i;
    ma_addr_r  <= (ma_mode_i == MA_X) ? 32'b0 : alu_result_w;
    ma_mode_r  <= ma_mode_i;
    ma_size_r  <= ma_size_i;
    ma_data_r  <= ma_data_i;
    wb_src_r   <= wb_src_i;
    wb_data_r  <= wb_data_async_o;
    wb_valid_r <= wb_valid_i;

    `log_strobe(("{ \"stage\": \"EX\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"ma_addr\": \"%0d\", \"ma_mode\": \"%0d\", \"ma_size\": \"%0d\", \"ma_data\": \"%0d\", \"wb_src\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" }", pc_r, ir_r, ma_addr_r, ma_mode_r, ma_size_r, ma_data_r, wb_src_r, wb_data_r, wb_valid_r));
end

assign pc_o       = pc_r;
assign ir_o       = ir_r;
assign ma_addr_o  = ma_addr_r;
assign ma_mode_o  = ma_mode_r;
assign ma_size_o  = ma_size_r;
assign ma_data_o  = ma_data_r;
assign wb_src_o   = wb_src_r;
assign wb_data_o  = wb_data_r;
assign wb_valid_o = wb_valid_r;

endmodule
