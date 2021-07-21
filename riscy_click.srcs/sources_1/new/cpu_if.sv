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
logic reg_reset;        // registered reset input 
logic reg_first_cycle;  // track if we are in the first cycle after a reset
word  reg_ex_jmp;       // registered jmp input
logic reg_ex_jmp_valid; // registered jmp valid input
word  pc_next;          // next cycle's pc value, and therefore this cycle's memory address 
logic stage_valid_next; // next cycle's validity


///
/// Register inputs
///
always_ff @(posedge clk) begin
    reg_reset        <= reset;
    reg_first_cycle  <= reg_reset;   // we are first cycle if last cycle was still reset
    reg_ex_jmp       <= ex_jmp;
    reg_ex_jmp_valid <= ex_jmp_valid;
end


///
/// Latch outputs
///
always_ff @(posedge clk) begin
    pc          <= pc_next;
    stage_valid <= stage_valid_next;
end

assign ir = ibus_data; // ram output is already registered, so pass it through


///
/// Combinational Logic
///

// Always read from the location of the next instruction
assign ibus_addr = pc_next;

// PC logic
always_comb begin
    if (reg_reset | reg_first_cycle) begin
        // zero if reset or first cycle
        pc_next <= 0;
    end else if (halt) begin
        // unchanging if halted
        pc_next <= pc;
    end else if (ex_jmp_valid) begin
        // respect jumps from execute stage
        pc_next <= ex_jmp;
    end else begin
        // otherwise keep advancing
        pc_next <= pc + 4;
    end
end

// Stage Valid logic
always_comb begin
    // next cycle won't be valid if we are resetting or jumping
    if (ex_jmp | reg_reset) begin
        stage_valid_next <= 0;
    end else begin
        stage_valid_next <= 1;
    end
end

endmodule
