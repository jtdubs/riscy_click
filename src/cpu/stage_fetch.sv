`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Fetch Stage
///

module stage_fetch
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
        output wire word_t pc_next_o    // next program counter
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
state_t state_next;

// edges
logic waiting;
logic start_aligned;
logic start_unaligned;
logic halt;
logic stall;
logic aligned_jump;
logic unaligned_jump_1;
logic unaligned_jump_2;
logic stay_aligned;
logic lose_alignment;
logic stay_unaligned;
logic gain_alignment;

// edge determination
always_comb begin
    waiting          = (state_r == S_STARTUP)         &&  first_cycle_r[0];
    start_aligned    = (state_r == S_STARTUP)         && !first_cycle_r[0] && !compressed;
    start_unaligned  = (state_r == S_STARTUP)         && !first_cycle_r[0] &&  compressed;
    halt             = (state_r == S_HALTED)          ||  halt_i;
    stall            =                                   !halt_i && !ready_i;
    aligned_jump     =                                   !halt_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] == 2'b0;
    unaligned_jump_1 =                                   !halt_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] != 2'b0;
    unaligned_jump_2 = (state_r == S_UNALIGNED_JUMP);
    stay_aligned     = (state_r == S_ALIGNED)         && !halt_i &&  ready_i && !jmp_valid_i && !compressed;
    lose_alignment   = (state_r == S_ALIGNED)         && !halt_i &&  ready_i && !jmp_valid_i &&  compressed;
    stay_unaligned   = (state_r == S_UNALIGNED)       && !halt_i &&  ready_i && !jmp_valid_i && !compressed;
    gain_alignment   = (state_r == S_UNALIGNED)       && !halt_i &&  ready_i && !jmp_valid_i &&  compressed;
end

// next state determination
always_comb begin
    unique if (waiting)
        state_next = S_STARTUP;
    else if (start_aligned || stay_aligned || gain_alignment || aligned_jump)
        state_next = S_ALIGNED;
    else if (start_unaligned || stay_unaligned || lose_alignment || unaligned_jump_2)
        state_next = S_UNALIGNED;
    else if (unaligned_jump_1)
        state_next = S_UNALIGNED_JUMP;
    else if (halt)
        state_next = S_HALTED;
    else if (stall)
        state_next = state_r;

end

// move to next state
always_ff @(posedge clk_i) begin
    state_r <= state_next;
end

// state based decompression
word_t compressed_ir;
word_t decompressed_ir;
always_comb begin
    case (state_r)
    S_STARTUP:   compressed_ir = imem_data_i;
    S_ALIGNED:   compressed_ir = imem_data_i;
    S_UNALIGNED: compressed_ir = { imem_data_i[15:0], saved_ir_r };
    S_UNALIGNED_JUMP,
    S_HALTED:    compressed_ir = NOP_IR;
    default:     compressed_ir = NOP_IR;
    endcase
end

logic compressed;
decompressor decompressor (
    .ir_i         (compressed_ir),
    .ir_o         (decompressed_ir),
    .compressed_o (compressed)
);

// take transition actions
word_t imem_addr_r = '0;
word_t imem_addr;
assign imem_addr_o = imem_addr;

always_comb begin
    unique if (waiting || halt)
        imem_addr = 32'd0;
    else if (stall || gain_alignment)
        imem_addr = imem_addr_r;
    else if (start_aligned || start_unaligned || stay_aligned || stay_unaligned || lose_alignment || unaligned_jump_2)
        imem_addr = imem_addr_r + 4;
    else if (aligned_jump || unaligned_jump_1)
        imem_addr = { jmp_addr_i[31:2], 2'b00 };
end
always_ff @(posedge clk_i) begin
    imem_addr_r <= imem_addr;
end

word_t ir_r = NOP_IR;
assign ir_o = ir_r;
always_ff @(posedge clk_i) begin
    if (waiting || halt || aligned_jump || unaligned_jump_1 || unaligned_jump_2)
        ir_r <= NOP_IR;
    else if (start_aligned || start_unaligned || stay_aligned || lose_alignment || gain_alignment || stay_unaligned)
        ir_r <= decompressed_ir;
end

word_t pc_r = NOP_PC;
assign pc_o = pc_r;
always_ff @(posedge clk_i) begin
    if (waiting || halt || aligned_jump || unaligned_jump_1 || unaligned_jump_2)
        pc_r <= NOP_PC;
    else if (start_aligned || start_unaligned || stay_aligned || lose_alignment || gain_alignment || stay_unaligned)
        pc_r <= pc_next_r;
end

word_t pc_next_r = NOP_PC;
assign pc_next_o = pc_next_r;
always_ff @(posedge clk_i) begin
    if (waiting)
        pc_next_r <= '0;
    else if (start_unaligned || gain_alignment || lose_alignment)
        pc_next_r <= pc_next_r + 2;
    else if (start_aligned || stay_aligned || stay_unaligned)
        pc_next_r <= pc_next_r + 4;
    else if (unaligned_jump_1 || aligned_jump)
        pc_next_r <= jmp_addr_i;
    else if (unaligned_jump_2)
        pc_next_r <= jmp_addr_r;
    else if (halt)
        pc_next_r <= NOP_PC;
end

// save jump address
word_t jmp_addr_r = '0;
always_ff @(posedge clk_i) begin
    if (unaligned_jump_1)
        jmp_addr_r <= jmp_addr_i;
end

// save unused portion of IR if needed
logic [15:0] saved_ir_r = '0;
always_ff @(posedge clk_i) begin
    if (start_unaligned || lose_alignment || stay_unaligned || unaligned_jump_2)
        saved_ir_r <= imem_data_i[31:16];
end

always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"IF\", \"pc\": \"%0d\", \"ir\": \"%0d\" }", pc_o, ir_o));
end

endmodule
