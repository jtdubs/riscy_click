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
// ALU
//

word_t result;

alu alu (
    .alu_mode_i         (cw.alu_mode),
    .alu_op1_i          (alu_op1),
    .alu_op2_i          (alu_op2),
    .alu_result_async_o (result)
);


//
// Issue Input
//

logic issue_occurs;
logic issue_ready;

logic issue_ready_r = '1;

always_ff @(posedge clk_i) begin
    if (issue_occurs)
        issue_ready_r <= '0;

    if (issue_ready)
        issue_ready_r <= '1;
end

always_comb begin
    issue_occurs = issue_valid_i && issue_ready_o;
end

assign issue_ready_o = issue_ready_r;


//
// Execute Output
//

logic execute_unload;
logic execute_load;

control_word_t cw;
word_t         alu_op1;
word_t         alu_op2;

word_t         execute_result_r = '0;
logic          execute_valid_r  = '0;

always_ff @(posedge clk_i) begin
    if (execute_unload)
        execute_valid_r <= '0;

    if (execute_load) begin
        execute_result_r <= result;
        execute_valid_r  <= '1;
    end
end

always_comb begin
    execute_unload = execute_valid_o && execute_ready_i;
end

assign execute_result_o = execute_result_r;
assign execute_valid_o  = execute_valid_r;


//
// Skid Buffer
//

logic skid_load;
logic skid_unload;

control_word_t skid_cw_r      = '0;
word_t         skid_alu_op1_r = '0;
word_t         skid_alu_op2_r = '0;
logic          skid_valid_r   = '0;

always_ff @(posedge clk_i) begin
    if (skid_unload)
        skid_valid_r <= '0;

    if (skid_load) begin
        skid_cw_r      <= issue_cw_i;
        skid_alu_op1_r <= issue_alu_op1_i;
        skid_alu_op2_r <= issue_alu_op2_i;
        skid_valid_r   <= '1;
    end
end


//
// Logic
//

logic execute_full;

always_comb begin
    // calculations
    execute_full = execute_valid_r && !execute_ready_i;

    // prefer skid
    if (skid_valid_r) begin
        cw      = skid_cw_r;
        alu_op1 = skid_alu_op1_r;
        alu_op2 = skid_alu_op2_r;
    end else begin
        cw      = issue_cw_i;
        alu_op1 = issue_alu_op1_i;
        alu_op2 = issue_alu_op2_i;
    end

    // choose actions
    execute_load = !execute_full && (issue_occurs || skid_valid_r);
    skid_load    = issue_occurs && execute_full;
    skid_unload  = !execute_full && skid_valid_r;
    issue_ready  =
          (!skid_valid_r && !skid_load)
       || (skid_valid_r && skid_unload && !skid_load);
end

endmodule
