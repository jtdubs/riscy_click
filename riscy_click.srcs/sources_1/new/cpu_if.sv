`timescale 1ns/1ps

///
/// Risc-V CPU Instruction Fetch stage
///
/// Assumes:
/// - memory bus takes 1 cycle and has registered output
///

module cpu_if
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input       logic       clk,            // clock
        input       logic       reset,          // reset
        input       logic       halt,           // halt

        // instruction memory bus
        output      word        ibus_addr,      // address
        input       word        ibus_data,      // data

        // stage inputs
        input       word        ex_jmp,         // jump address from execute stage
        input       logic       ex_jmp_valid,   // whether or not jump address is valid

        // stage outputs
        output      word        pc,             // program counter
        output      word        ir,             // instruction register
        output      logic       stall           // stall indicator
    );


///
/// Variables
///

logic stall_next; // is the next cycle a stall
word  pc_next;    // what's the next cycle's program counter 


///
/// Latch outputs
///

always_ff @(posedge clk) begin
    pc    <= pc_next;
    stall <= stall_next;
end

// ibus data is already registered, so pass it through
assign ir = ibus_data;


///
/// Combinational Logic
///

// Always read from the location of the next instruction
assign ibus_addr = pc_next;

// Next cycle will stall if reset, halt or jump
assign stall_next = reset | halt | ex_jmp_valid;

// Determine next program counter
always_comb begin
    if (reset) begin
        // zero if reset
        pc_next <= 0;
    end else if (stall) begin
        // no change if in stall cycle
        pc_next <= pc_next;
    end else if (ex_jmp_valid) begin
        // respect jumps from execute stage
        pc_next <= ex_jmp;
    end else begin
        // otherwise keep advancing
        pc_next <= pc + 4;
    end
end

endmodule