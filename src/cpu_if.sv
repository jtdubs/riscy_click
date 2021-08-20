`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic  clk_i,       // clock
        input  wire logic  halt_i,      // halt

        // instruction memory
        output wire word_t imem_addr_o, // memory address
        input  wire word_t imem_data_i, // data

        // async input
        input  wire word_t jmp_addr_i,  // jump address
        input  wire logic  jmp_valid_i, // whether or not jump address is valid
        input  wire logic  ready_i,     // is the ID stage ready to accept input

        // pipeline output
        output wire word_t pc_o,        // program counter
        output wire word_t ir_o,        // instruction register
        output wire word_t next_pc_o    // next program counter
    );

initial start_logging();
final stop_logging();


//
// First Cycle Detection
//

logic [1:0] first_cycle_r = 2'b11;
always_ff @(posedge clk_i) begin
    first_cycle_r <= { 1'b0, first_cycle_r[1] };
end


//
// Pipeline Inputs
//


word_t pc_i = '0;
word_t pc_w;

// choose next PC value
always_comb begin
    // default behavior is to advance to next instruction
    pc_w = pc_i + 4;

    unique0 if (first_cycle_r[0])
        pc_w = '0;
    if (halt_i || !ready_i)
        pc_w = pc_i;             // no change on halt or backpressure
    else if (jmp_valid_i)
        pc_w = jmp_addr_i; // respect jumps
end

// always request the IR corresponding to the next PC value
assign imem_addr_o = pc_w;

// update pipeline input to match the address we are requesting from imem
always_ff @(posedge clk_i) begin
    pc_i <= pc_w;
end


//
// Pipeline Outputs
//

word_t pc_r = NOP_PC;
assign pc_o = pc_r;

word_t ir_r = NOP_IR;
assign ir_o = ir_r;

word_t next_pc_r = NOP_PC;
assign next_pc_o = next_pc_r;


always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"IF\", \"pc\": \"%0d\", \"ir\": \"%0d\" }", pc_r, ir_r));
 
    if (jmp_valid_i | first_cycle_r[0]) begin
        // if jumping, output a NOP
        pc_r      <= NOP_PC;
        ir_r      <= NOP_IR;
        next_pc_r <= NOP_PC;
    end else if (ready_i) begin
        // if next stage is ready, give them new values
        pc_r      <= pc_i;
        ir_r      <= imem_data_i;
        next_pc_r <= pc_w;
    end
end

endmodule
