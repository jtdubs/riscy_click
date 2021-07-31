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
        input  wire logic  clk_i,       // clock
        input  wire logic  reset_i,     // reset_i
        input  wire logic  halt_i,      // halt

        // instruction memory port
        output      word_t imem_addr_o, // memory address
        input  wire word_t imem_data_i, // data
        
        // control flow port
        input  wire word_t jmp_addr_i,  // jump address
        input  wire logic  jmp_valid_i, // whether or not jump address is valid
        
        // backpressure port
        input  wire logic  ready_i,     // is the ID stage ready to accept input

        // pipeline output port
        output wire word_t pc_o,        // program counter
        output wire word_t ir_o,        // instruction register
        output wire logic  valid_o      // is the stage output valid
    );
   

//
// Skid Buffer
//

wire logic  write_ready_w; // can skid accept data?
     logic  write_valid_w; // is skip input valid?
     logic  reset_w;       // reset_i signal
     word_t write_pc_r;    // IR and PC to input
     word_t write_ir_w;    // IR and PC to input

// flush the skid buffer on jump, as those instructions aren't valid     
always_comb reset_w = reset_i || jmp_valid_i;

// Skid input is valid if we aren't jumping
always_comb write_valid_w = ~jmp_valid_i;

skid_buffer #(.WORD_WIDTH(64)) output_buffer (
    .clk_i         (clk_i),
    .reset_i       (reset_w),
    .write_ready_o (write_ready_w),
    .write_valid_i (write_valid_w),
    .write_data_i  ({ write_pc_r, write_ir_w }),
    .read_ready_i  (ready_i),
    .read_valid_o  (valid_o),
    .read_data_o   ({ pc_o, ir_o })
);


//
// Program Counter Advancement
//

word_t write_pc_w;

// combiantional logic for next PC value
always_comb begin
    priority if (halt_i)
        write_pc_w = write_pc_r;     // no change on halt  
    else if (jmp_valid_i)
        write_pc_w = jmp_addr_i;     // respect jumps
    else if (~write_ready_w)
        write_pc_w = write_pc_r;     // no change backpressure
    else
        write_pc_w = write_pc_r + 4; // otherwise keep advancing
end

// advance every clock cycle
always_ff @(posedge clk_i) begin
    write_pc_r <= reset_i ? 32'h0 : write_pc_w;
end


//
// Memory Access
//

always_comb begin
    write_ir_w  = reset_i ? 32'h0 : imem_data_i; // Data from memory is IR
    imem_addr_o = reset_i ? 32'h0 : write_pc_w;  // Address to request for next cycle is next PC value
end

endmodule
