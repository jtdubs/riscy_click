`timescale 1ns / 1ps
`default_nettype none

//
// aligned_jmp_aligned_w should output a NOP down the pipeline because we are
// about to stall

///
/// Risc-V CPU Instruction Fetch Stage
///

module cpu_if
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic  clk_i,       // clock
        input  wire logic  halt_i,      // halt

        // instruction memory
        output wire word_t imem_addr_o, // memory address
        input  wire word_t imem_data_i, // data

        // async input
        input  wire word_t jmp_addr_i,  // jump address
        input  wire logic  jmp_valid_i, // whether or not jump address is valid
        input  wire logic  ready_i,     // is the ID stage ready to accept input

        // pipeline output
        output wire word_t pc_o,        // program counter
        output wire word_t ir_o,        // instruction register
        output wire word_t next_pc_o    // next program counter
    );

initial start_logging();
final stop_logging();


//
// First Cycle Detection
//

logic [1:0] first_cycle_r = 2'b11;
always_ff @(posedge clk_i) begin
    first_cycle_r <= { 1'b0, first_cycle_r[1] };
end


//
// State Machine
//

// states
typedef enum logic [4:0] {
    S_STARTUP         = 5'b00001,
    S_ALIGNED         = 5'b00010,
    S_UNALIGNED       = 5'b00100,
    S_UNALIGNED_JUMP  = 5'b01000,
    S_HALTED          = 5'b10000
} state_t;

state_t state_r = S_STARTUP;
state_t state_w;

// edges
logic wait_w;
logic start_aligned_w;
logic start_unaligned_w;
logic halt_w;
logic stall_w;
logic aligned_jump_w;
logic unaligned_jump_1_w;
logic unaligned_jump_2_w;
logic stay_aligned_w;
logic lose_alignment_w;
logic stay_unaligned_w;
logic gain_alignment_w;

// edge determination
always_comb begin
    wait_w                     = (state_r == S_STARTUP)         &&  first_cycle_r[0];
    start_aligned_w            = (state_r == S_STARTUP)         && !first_cycle_r[0] && !compressed_w;
    start_unaligned_w          = (state_r == S_STARTUP)         && !first_cycle_r[0] &&  compressed_w;
    halt_w                     = (state_r == S_HALTED)          ||  halt_i;
    stall_w                    =                                   !halt_i && !ready_i;
    aligned_jump_w             =                                   !halt_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] == 2'b0;
    unaligned_jump_1_w         =                                   !halt_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] != 2'b0;
    unaligned_jump_2_w         = (state_r == S_UNALIGNED_JUMP);
    stay_aligned_w             = (state_r == S_ALIGNED)         && !halt_i &&  ready_i && !jmp_valid_i && !compressed_w;
    lose_alignment_w           = (state_r == S_ALIGNED)         && !halt_i &&  ready_i && !jmp_valid_i &&  compressed_w;
    stay_unaligned_w           = (state_r == S_UNALIGNED)       && !halt_i &&  ready_i && !jmp_valid_i && !compressed_w;
    gain_alignment_w           = (state_r == S_UNALIGNED)       && !halt_i &&  ready_i && !jmp_valid_i &&  compressed_w;
end

// next state determination
always_comb begin
    unique if (wait_w)
        state_w = S_STARTUP;
    else if (start_aligned_w || stay_aligned_w || gain_alignment_w || aligned_jump_w)
        state_w = S_ALIGNED;
    else if (start_unaligned_w || stay_unaligned_w || lose_alignment_w || unaligned_jump_2_w)
        state_w = S_UNALIGNED;
    else if (unaligned_jump_1_w)
        state_w = S_UNALIGNED_JUMP;
    else if (halt_w)
        state_w = S_HALTED;
    else if (stall_w)
        state_w = state_r;

end

// move to next state
always_ff @(posedge clk_i) begin
    state_r <= state_w;
end

// state based decompression
word_t compressed_ir_w;
word_t decompressed_ir_w;
always_comb begin
    case (state_r)
    S_STARTUP:   compressed_ir_w = imem_data_i;
    S_ALIGNED:   compressed_ir_w = imem_data_i;
    S_UNALIGNED: compressed_ir_w = { imem_data_i[15:0], saved_ir_r };
    S_UNALIGNED_JUMP,
    S_HALTED:    compressed_ir_w = NOP_IR;
    default:     compressed_ir_w = NOP_IR;
    endcase
end

logic compressed_w;
cpu_decompress decompressor (
    .ir_i         (compressed_ir_w),
    .ir_o         (decompressed_ir_w),
    .compressed_o (compressed_w)
);

// take transition actions
word_t imem_addr_r = '0;
word_t imem_addr_w;
assign imem_addr_o = imem_addr_w;

always_comb begin
    unique if (wait_w || halt_w)
        imem_addr_w = 32'd0;
    else if (stall_w || gain_alignment_w)
        imem_addr_w = imem_addr_r;
    else if (start_aligned_w || start_unaligned_w || stay_aligned_w || stay_unaligned_w || lose_alignment_w || unaligned_jump_2_w)
        imem_addr_w = imem_addr_r + 4;
    else if (aligned_jump_w || unaligned_jump_1_w)
        imem_addr_w = { jmp_addr_i[31:2], 2'b00 };
end
always_ff @(posedge clk_i) begin
    imem_addr_r <= imem_addr_w;
end

word_t ir_r = NOP_IR;
assign ir_o = ir_r;
always_ff @(posedge clk_i) begin
    if (wait_w || halt_w || aligned_jump_w || unaligned_jump_1_w || unaligned_jump_2_w)
        ir_r <= NOP_IR;
    else if (start_aligned_w || start_unaligned_w || stay_aligned_w || lose_alignment_w || gain_alignment_w || stay_unaligned_w)
        ir_r <= decompressed_ir_w;
end

word_t pc_r = NOP_PC;
assign pc_o = pc_r;
always_ff @(posedge clk_i) begin
    if (wait_w || halt_w || aligned_jump_w || unaligned_jump_1_w || unaligned_jump_2_w)
        pc_r <= NOP_PC;
    else if (start_aligned_w || start_unaligned_w || stay_aligned_w || lose_alignment_w || gain_alignment_w || stay_unaligned_w)
        pc_r <= next_pc_r;
end

word_t next_pc_r = NOP_PC;
assign next_pc_o = next_pc_r;
always_ff @(posedge clk_i) begin
    if (wait_w)
        next_pc_r <= '0;
    else if (start_unaligned_w || gain_alignment_w || lose_alignment_w)
        next_pc_r <= next_pc_r + 2;
    else if (start_aligned_w || stay_aligned_w || stay_unaligned_w)
        next_pc_r <= next_pc_r + 4;
    else if (unaligned_jump_1_w || aligned_jump_w)
        next_pc_r <= jmp_addr_i;
    else if (unaligned_jump_2_w)
        next_pc_r <= jmp_addr_r;
    else if (halt_w)
        next_pc_r <= NOP_PC;
end

// save jump address
word_t jmp_addr_r = '0;
always_ff @(posedge clk_i) begin
    if (unaligned_jump_1_w)
        jmp_addr_r <= jmp_addr_i;
end

// save unused portion of IR if needed
logic [15:0] saved_ir_r = '0;
always_ff @(posedge clk_i) begin
    if (start_unaligned_w || lose_alignment_w || stay_unaligned_w || unaligned_jump_2_w)
        saved_ir_r <= imem_data_i[31:16];
end

always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"IF\", \"pc\": \"%0d\", \"ir\": \"%0d\" }", pc_o, ir_o));
end

endmodule
