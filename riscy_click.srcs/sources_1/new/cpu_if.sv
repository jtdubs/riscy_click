`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic  clk,           // clock
        input  wire logic  ic_rst,        // reset
        input  wire logic  ic_halt,       // halt

        // instruction memory port
        output      word_t oa_imem_addr,  // memory address
        input  wire word_t ia_imem_data,  // data
        
        // control flow port
        input  wire word_t ia_jmp_addr,   // jump address
        input  wire logic  ia_jmp_valid,  // whether or not jump address is valid
        
        // backpressure port
        input  wire logic  ia_ready,      // is the ID stage ready to accept input

        // pipeline output port
        output wire word_t oc_if_pc,      // program counter
        output wire word_t oc_if_ir,      // instruction register
        output wire logic  oc_if_valid    // is the stage output valid
    );
   

//
// Skid Buffer
//

wire logic  c_buf_ready; // can skid accept data?
     logic  a_buf_valid; // is skip input valid?
     logic  a_buf_reset; // reset signal
     word_t c_buf_pc;    // IR and PC to input
     word_t a_buf_ir;    // IR and PC to input

// flush the skid buffer on jump, as those instructions aren't valid     
always_comb a_buf_reset = ic_rst || ia_jmp_valid;

// Skid input is valid if we aren't jumping
always_comb a_buf_valid = ~ia_jmp_valid;

skid_buffer #(.WORD_WIDTH(64)) output_buffer (
    .clk(clk),
    .ic_rst(a_buf_reset),
    .oc_in_ready(c_buf_ready),
    .ic_in_valid(a_buf_valid),
    .ic_in_data({ c_buf_pc, a_buf_ir }),
    .ic_out_ready(ia_ready),
    .oc_out_valid(oc_if_valid),
    .oc_out_data({ oc_if_pc, oc_if_ir })
);


//
// Program Counter Advancement
//

word_t a_buf_pc_next;

// combiantional logic for next PC value
always_comb begin
    priority if (ic_halt)
        a_buf_pc_next = c_buf_pc;     // no change on halt  
    else if (ia_jmp_valid)
        a_buf_pc_next = ia_jmp_addr; // respect jumps
    else if (~c_buf_ready)
        a_buf_pc_next = c_buf_pc;     // no change backpressure
    else
        a_buf_pc_next = c_buf_pc + 4; // otherwise keep advancing
end

// advance every clock cycle
always_ff @(posedge clk) begin
    c_buf_pc <= ic_rst ? 32'h0 : a_buf_pc_next;
end


//
// Memory Access
//

always_comb begin
    a_buf_ir     = ic_rst ? 32'h0 : ia_imem_data;  // Data from memory is IR
    oa_imem_addr = ic_rst ? 32'h0 : a_buf_pc_next; // Address to request for next cycle is next PC value
end

endmodule
