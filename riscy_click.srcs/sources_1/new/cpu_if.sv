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
        output      logic       stage_valid     // whether or not stage outputs are valid (false if stalled)
    );


///
/// Variables
///

logic stall;
logic reg_stall;        // track if we are in the first cycle after a reset
word  pc_next;          // next cycle's pc value, and therefore this cycle's memory address 


///
/// Registers
///
assign stall = reset | halt | ex_jmp_valid;

always_ff @(posedge clk) begin
    reg_stall <= stall; // stall if reset or jumping
end


///
/// Latch outputs
///
always_ff @(posedge clk) begin
    pc          <= pc_next;
    stage_valid <= ~stall;
end

assign ir = ibus_data; // ram output is already registered, so pass it through


///
/// Combinational Logic
///

// Always read from the location of the next instruction
assign ibus_addr = pc_next;

// PC logic
always_comb begin
    if (reset) begin
        // zero if reset
        pc_next <= 0;
    end else if (reg_stall) begin
        // no change if stall
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
