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
        input  wire logic        clk_i,
        input  wire logic        halt_i,

        // instruction memory (request channel)
        output wire memaddr_t    icache_req_addr_o,
        output wire logic        icache_req_valid_o,
        input  wire logic        icache_req_ready_i,

        // instruction memory (response channel)
        input  wire memaddr_t    icache_resp_addr_i,
        input  wire word_t       icache_resp_data_i,
        input  wire logic        icache_resp_valid_i,
        output wire logic        icache_resp_ready_o,

        // jumps and branches
        input  wire word_t       jmp_addr_i,
        input  wire logic        jmp_valid_i,

        // pipeline interface
        output wire word_t       pc_o,
        output wire word_t       ir_o,
        output wire word_t       pc_next_o,
        output wire logic        valid_o,
        input  wire logic        ready_i
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

// signals
logic compressed;
memaddr_t imem_addr;

// registers
word_t    jmp_addr_r  = '0;

memaddr_t imem_addr_r = '0;
assign    imem_addr_o = imem_addr;

word_t    ir_r        = NOP_IR;
assign    ir_o        = ir_r;

word_t    pc_r        = NOP_PC;
assign    pc_o        = pc_r;

logic     valid_r     = '0;
assign    valid_o     = valid_r;

word_t    pc_next_r   = NOP_PC;
assign    pc_next_o   = pc_next_r;

logic [15:0] saved_ir_r = '0;

// edges
logic waiting;
logic start_aligned;
logic start_unaligned;
logic halt;
logic stall;
logic mem_stall;
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
    mem_stall        =                                   !halt_i && !imem_valid_i;
    stall            =                                   !halt_i &&  imem_valid_i && !ready_i;
    aligned_jump     =                                   !halt_i &&  imem_valid_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] == 2'b0;
    unaligned_jump_1 =                                   !halt_i &&  imem_valid_i &&  ready_i &&  jmp_valid_i && jmp_addr_i[1:0] != 2'b0;
    unaligned_jump_2 = (state_r == S_UNALIGNED_JUMP);
    stay_aligned     = (state_r == S_ALIGNED)         && !halt_i &&  imem_valid_i &&  ready_i && !jmp_valid_i && !compressed;
    lose_alignment   = (state_r == S_ALIGNED)         && !halt_i &&  imem_valid_i &&  ready_i && !jmp_valid_i &&  compressed;
    stay_unaligned   = (state_r == S_UNALIGNED)       && !halt_i &&  imem_valid_i &&  ready_i && !jmp_valid_i && !compressed;
    gain_alignment   = (state_r == S_UNALIGNED)       && !halt_i &&  imem_valid_i &&  ready_i && !jmp_valid_i &&  compressed;
end

// next state determination
always_comb begin
    if (waiting)
        state_next = S_STARTUP;
    else if (start_aligned || stay_aligned || gain_alignment || aligned_jump)
        state_next = S_ALIGNED;
    else if (start_unaligned || stay_unaligned || lose_alignment || unaligned_jump_2)
        state_next = S_UNALIGNED;
    else if (unaligned_jump_1)
        state_next = S_UNALIGNED_JUMP;
    else if (halt)
        state_next = S_HALTED;
    else if (stall || mem_stall)
        state_next = state_r;
    else
        state_next = state_r;

end

// move to next state
always_ff @(posedge clk_i) begin
    state_r <= state_next;
end

// state based decompression
word_t ir;
always_comb begin
    case (state_r)
    S_STARTUP:   ir = imem_data_i;
    S_ALIGNED:   ir = imem_data_i;
    S_UNALIGNED: ir = { imem_data_i[15:0], saved_ir_r };
    S_UNALIGNED_JUMP,
    S_HALTED:    ir = NOP_IR;
    default:     ir = NOP_IR;
    endcase
end

// compressed instruction detection
always_comb begin
    compressed = (ir[1:0] != 2'b11);
end

// take transition actions
always_comb begin
    if (waiting || halt)
        imem_addr = 30'd0;
    else if (mem_stall || stall || gain_alignment)
        imem_addr = imem_addr_r;
    else if (start_aligned || start_unaligned || stay_aligned || stay_unaligned || lose_alignment || unaligned_jump_2)
        imem_addr = imem_addr_r + 1;
    else if (aligned_jump || unaligned_jump_1)
        imem_addr = jmp_addr_i[31:2];
    else
        imem_addr = imem_addr_r;
end

always_ff @(posedge clk_i) begin
    imem_addr_r <= imem_addr;
end

always_ff @(posedge clk_i) begin
    if (mem_stall || waiting || halt || aligned_jump || unaligned_jump_1 || unaligned_jump_2) begin
        valid_r <= !ready_i;
    end else if (start_aligned || start_unaligned || stay_aligned || lose_alignment || gain_alignment || stay_unaligned)  begin
        ir_r    <= compressed ? { 16'b0, ir[15:0] } : ir;
        pc_r    <= pc_next_r;
        valid_r <= 1'b1;
    end
end

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
end

// save jump address
always_ff @(posedge clk_i) begin
    if (unaligned_jump_1)
        jmp_addr_r <= jmp_addr_i;
end

// save unused portion of IR if needed
always_ff @(posedge clk_i) begin
    if (start_unaligned || lose_alignment || stay_unaligned || unaligned_jump_2)
        saved_ir_r <= imem_data_i[31:16];
end

always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"IF\", \"pc\": \"%0d\", \"ir\": \"%0d\" }", pc_o, ir_o));
end

endmodule
