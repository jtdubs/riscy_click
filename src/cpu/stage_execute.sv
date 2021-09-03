`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Execute Stage
///

module stage_execute
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic           clk_i,

        // decode channel
        input  wire control_word_t  issue_cw_i,
        input  wire word_t          issue_alu_op1_i,
        input  wire word_t          issue_alu_op2_i,
        input  wire logic           issue_valid_i,
        output wire logic           issue_ready_o,

        // pipeline output
        output wire word_t          execute_result_o,
        output wire logic           execute_valid_o,
        input  wire logic           execute_ready_i
    );

initial start_logging();
final stop_logging();


//
// Bypass Buffer
//

alu_mode_t     alu_mode;
word_t         alu_op1;
word_t         alu_op2;
word_t         result;

bypass_buffer #(
    .WR_WIDTH(68),
    .RD_WIDTH(32)
) bypass_buffer (
    .clk_i       (clk_i),
    .wr_data_i   ({ issue_cw_i.alu_mode, issue_alu_op1_i, issue_alu_op2_i }),
    .wr_valid_i  (issue_valid_i),
    .wr_ready_o  (issue_ready_o),
    .rd_data_o   ({ execute_result_o }),
    .rd_valid_o  (execute_valid_o),
    .rd_ready_i  (execute_ready_i),
    .tfr_data_o  ({ alu_mode, alu_op1, alu_op2 }),
    .tfr_data_i  ({ result }),
    .tfr_valid_i (1'b1)
);


//
// ALU
//

alu alu (
    .alu_mode_i         (alu_mode),
    .alu_op1_i          (alu_op1),
    .alu_op2_i          (alu_op2),
    .alu_result_async_o (result)
);

endmodule
