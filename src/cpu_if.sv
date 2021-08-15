`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic  clk_i,             // clock
        input  wire logic  reset_i,           // reset_i
        input  wire logic  halt_i,            // halt

        // instruction memory
        output      word_t imem_addr_o,       // memory address
        input  wire word_t imem_data_i,       // data

        // async input
        input  wire word_t jmp_addr_async_i,  // jump address
        input  wire logic  jmp_valid_async_i, // whether or not jump address is valid
        input  wire logic  ready_async_i,     // is the ID stage ready to accept input

        // pipeline output
        output      word_t pc_o,              // program counter
        output      word_t ir_o               // instruction register
    );

initial start_logging();
final stop_logging();


//
// Pipeline Inputs
//

word_t pc_i, pc_w;

// choose next PC value
always_comb begin
    // default behavior is to advance to next instruction
    pc_w = pc_i + 4;

    unique0 if (reset_i)
        pc_w = 32'h0;            // back to zero on reset
    else if (halt_i || !ready_async_i)
        pc_w = pc_i;             // no change on halt or backpressure
    else if (jmp_valid_async_i)
        pc_w = jmp_addr_async_i; // respect jumps
end

// always request the IR corresponding to the next PC value
always_comb imem_addr_o = pc_w;

// update pipeline input to match the address we are requesting from imem
always_ff @(posedge clk_i) begin
    pc_i <= pc_w;
end


//
// Pipeline Outputs
//
always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"IF\", \"reset\": \"%0d\", \"pc\": \"%0d\", \"ir\": \"%0d\" }", reset_i, pc_o, ir_o));
 
    if (jmp_valid_async_i || reset_i) begin
        // if jumping or resetting, output a NOP
        pc_o <= NOP_PC;
        ir_o <= NOP_IR;
    end else if (ready_async_i) begin
        // if next stage is ready, give them new values
        pc_o <= pc_i;
        ir_o <= imem_data_i;
    end
end

endmodule
