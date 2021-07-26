`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input  wire logic clk,          // clock
        input  wire logic reset,        // reset
        input  wire logic halt,         // halt

        // instruction memory
        output      word  mem_addr,     // address
        input  wire word  mem_data,     // data

        // stage inputs
        input  wire word  id_jmp_addr,  // jump address from execute stage
        input  wire logic id_jmp_valid, // whether or not jump address is valid
        input  wire logic id_ready,     // is the ID stage ready to accept input

        // stage outputs
        output wire word  if_pc,        // program counter
        output wire word  if_ir,        // instruction register
        output wire logic if_valid      // is the stage output valid
    );
   

//
// Skid Buffer
//

wire logic skid_ready;       // can skid accept data?
     logic skid_valid;       // is skip input valid?
     word  skid_pc, skid_ir; // IR and PC to input
     
skid_buffer #(.WORD_WIDTH(64)) output_buffer (
    .clk(clk),
    .reset(reset),
    .input_valid(skid_valid),
    .input_ready(skid_ready),
    .input_data({ skid_pc, skid_ir }),
    .output_valid(if_valid),
    .output_ready(id_ready),
    .output_data({ if_pc, if_ir })
);

// Skid input is valid if we aren't jumping
always_comb skid_valid = ~id_jmp_valid; 


//
// Program Counter Advancement
//

word skid_pc_next;

// combiantional logic for next PC value
always_comb begin
    if (halt | ~skid_ready)
        skid_pc_next = skid_pc;     // no change on halt or backpressure
    else if (id_jmp_valid)
        skid_pc_next = id_jmp_addr; // respect jumps from execute stage
    else
        skid_pc_next = skid_pc + 4; // otherwise keep advancing
end

// advance every clock cycle
always_ff @(posedge clk) begin
    skid_pc <= reset ? 32'b0 : skid_pc_next;
end


//
// Memory Access
//

always_comb begin
    skid_ir  = mem_data;       // Data from memory is IR
    mem_addr = skid_pc_next;   // Address to request for next cycle is next PC value
end

endmodule
