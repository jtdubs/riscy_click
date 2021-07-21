`timescale 1ns/1ps

///
/// Risc-V CPU Instruction Fetch Stage
///
/// Assumes:
/// - Memory has fixed latency of `MEM_ACCESS_CYCLES`
/// - Jumps will be asserted during a single positive clock edge
/// - Reset signal duration is greater than memory access latency
///
/// Design:
/// - Fetches an address every clock cycle, placing the address into a FIFO whose depth is MEM_ACCESS_CYCLES
/// - The FIFO is popped every clock cycle, and the value is asserted as the stage's PC output
/// - As the memory latency and FIFO depth are equal, a PC will come out of the FIFO during the same cycle it's corresponding IR comes out of memory
///
/// Limitations:
/// - Will continue running for `MEM_ACCESS_CYCLES` cycles after halt is asserted
///

module cpu_if
    // Import Constants
    import consts::*;
    #(
        // The number of cycles required for memory access
        parameter MEM_ACCESS_CYCLES = 1
    )
    (
        // cpu signals
        input       logic       clk,            // clock
        input       logic       reset,          // reset
        input       logic       halt,           // halt

        // instruction memory access
        output      word        mem_addr,       // address
        input       word        mem_data,       // data

        // stage inputs
        input       word        ex_jmp,         // jump address from execute stage
        input       logic       ex_jmp_valid,   // whether or not jump address is valid

        // stage outputs
        output      word        pc,             // program counter
        output      word        ir              // instruction register
    );


///
/// Program Counter FIFO
///

word [MEM_ACCESS_CYCLES:0] pc_fifo; // FIFO of PC values
word                       pc_next; // Next PC to be added to FIFO


//
// Outputs
//

assign pc = pc_fifo[0];     // PC is taken from bottom of FIFO
assign ir = mem_data;      // IR is corresponding result from mem access
assign mem_addr = pc_next; // Always start accessing the next PC ALU_ADD


//
// FIFO Behavior
//

// Push pc_next to FIFO each clock
always_ff @(posedge clk) begin
    pc_fifo[MEM_ACCESS_CYCLES] <= pc_next;
end

// Pop from FIFO each clock
genvar i;
generate for (i=0; i<MEM_ACCESS_CYCLES; i++)
    always_ff @(posedge clk) begin
        // Carry values down through the FIFO
        pc_fifo[i] <= pc_fifo[i+1];
    end 
endgenerate


//
// Program Counter Advancement
//

always_comb begin
    if (reset) begin
        // zero if reset
        pc_next <= 0;
    end else if (halt) begin
        pc_next <= pc_fifo[MEM_ACCESS_CYCLES];    
    end else if (ex_jmp_valid) begin
        // respect jumps from execute stage
        pc_next <= ex_jmp;
    end else begin
        // otherwise keep advancing
        pc_next <= pc_fifo[MEM_ACCESS_CYCLES] + 4;
    end
end

endmodule