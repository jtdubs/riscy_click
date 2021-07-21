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
    #(
        parameter STALL_CYCLES = 1
    )
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

localparam integer COUNTER_SIZE = $clog2(STALL_CYCLES);

logic [COUNTER_SIZE:0] stall_ctr;
logic [COUNTER_SIZE:0] stall_ctr_next;
logic stall_condition;

word  [STALL_CYCLES:0] pc_fifo;
word pc_next;


///
/// Latch outputs
///

assign pc = pc_fifo[0];

always_ff @(posedge clk) begin
    stall_ctr <= stall_ctr_next;
    stall     <= (stall_ctr_next > 0);
    pc_fifo[STALL_CYCLES] <= pc_next;
end

always_comb begin
    if (stall_condition) begin
        stall_ctr_next <= STALL_CYCLES;
    end else if (stall_ctr_next > 0) begin
        stall_ctr_next <= stall_ctr - 1;
    end else begin
        stall_ctr_next <= 0;
    end
end

// ibus data is already registered, so pass it through
assign ir = ibus_data;

genvar i;
generate for (i=0; i<STALL_CYCLES; i++)
    always_ff @(posedge clk) begin
        pc_fifo[i] <= pc_fifo[i+1];
    end 
endgenerate



///
/// Combinational Logic
///

// Always read from the location of the next instruction
assign ibus_addr = pc_next;

// Next cycle will stall if reset, halt or jump
assign stall_condition = reset | halt | ex_jmp_valid;

// Determine next program counter
always_comb begin
    if (reset) begin
        // zero if reset
        pc_next <= 0;
    end else if (ex_jmp_valid) begin
        // respect jumps from execute stage
        pc_next <= ex_jmp;
    end else begin
        // otherwise keep advancing
        pc_next <= pc_fifo[STALL_CYCLES] + 4;
    end
end

endmodule