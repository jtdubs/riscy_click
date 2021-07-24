`timescale 1ns/1ps

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input       logic       clk,            // clock
        input       logic       reset,          // reset

        // instruction memory
        output      word        mem_addr,       // address
        input       word        mem_data,       // data

        // stage inputs (direct)
        input       word        id_jmp,         // jump address from execute stage
        input       logic       id_jmp_valid,   // whether or not jump address is valid
        input       logic       id_ready,       // is the ID stage ready to accept input
        input       logic       id_halt,        // halt

        // stage outputs (latched)
        output      word        if_pc,          // program counter
        output      word        if_ir,          // instruction register
        output      word        if_valid        // is the stage output valid
    );


//
// Program Counter Advancement
//

word pc_next;

// combiantional logic for next PC value
always_comb begin
    if (reset) begin
        // zero if reset
        pc_next <= 0;
    end else if (id_halt) begin
        // no change on halt
        pc_next <= if_pc;
    end else if (id_jmp_valid) begin
        // respect jumps from execute stage
        pc_next <= id_jmp;
    end else begin
        // otherwise keep advancing
        pc_next <= if_pc + 4;
    end
end

// latched outputs
always_ff @(posedge clk) begin
    if (id_stall) begin
        // if stalled, nothing changes
        if_pc <= if_pc;
        if_ir <= if_ir;
        if_stall <= 1'b1;
    end else begin
        // otherwise, advance
        if_pc <= pc_next;
        if_ir <= mem_data;
        if_stall <= 1'b0;
    end
end


//
// Memory access
//

// always read from next PC value
assign mem_addr = pc_next;

endmodule
