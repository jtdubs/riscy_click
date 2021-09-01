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

        // icache flush channel
        output wire logic        icache_flush_o,
        
        // icache request channel
        output wire memaddr_t    icache_req_addr_o,
        output wire logic        icache_req_valid_o,
        input  wire logic        icache_req_ready_i,
        
        // icache response channel
        input  wire memaddr_t    icache_resp_addr_i,
        input  wire word_t       icache_resp_data_i,
        input  wire logic        icache_resp_valid_i,
        output wire logic        icache_resp_ready_o,

        // jump channel
        input  wire word_t       jmp_addr_i,
        input  wire logic        jmp_valid_i,
        output wire logic        jmp_ready_o,

        // fetch channel
        output wire word_t       fetch_pc_o,
        output wire word_t       fetch_ir_o,
        output wire word_t       fetch_pc_next_o,
        output wire logic        fetch_valid_o,
        input  wire logic        fetch_ready_i
    );

initial start_logging();
final stop_logging();

//
// Flush Channel
//

// Actions
logic flush;

// Registers
logic icache_flush_r = '0;

// Updates
always_ff @(posedge clk_i) begin
    icache_flush_r <= '0;
    
    if (flush)
        icache_flush_r <= '1;
end

// Output
assign icache_flush_o = icache_flush_r;


//
// Fetch Channel
//

// Actions
logic fetch_provide;
logic fetch_receive;

// Registers
word_t fetch_ir_r      = '0;
word_t fetch_pc_r      = '0;
logic  fetch_valid_r   = '0;
word_t fetch_pc_next_r = '0;

// Variables
word_t fetch_ir_next;
word_t fetch_pc_next_next;

// Updates
always_ff @(posedge clk_i) begin
    if (fetch_receive || flush)
        fetch_valid_r   <= '0;
    
    if (fetch_provide) begin
        fetch_ir_r      <= fetch_ir_next;
        fetch_pc_r      <= fetch_pc_next_r;
        fetch_valid_r   <= !flush;
        fetch_pc_next_r <= fetch_pc_next_next;
    end
end

// Output
assign fetch_ir_o      = fetch_ir_r;
assign fetch_pc_o      = fetch_pc_r;
assign fetch_valid_o   = fetch_valid_r;
assign fetch_pc_next_o = fetch_pc_next_r;

// Triggers
always_comb begin
    fetch_receive = fetch_ready_i && fetch_valid_r;
end


//
// Cache Request Channel
//

// Actions
logic icache_req_start;
logic icache_req_complete;

// Registers
memaddr_t icache_req_addr_r  = '0;
logic     icache_req_valid_r = '1;

// Variables
memaddr_t icache_req_addr_next;

// Updates
always_ff @(posedge clk_i) begin
    if (icache_req_complete || flush)
        icache_req_valid_r <= '0;
    
    if (icache_req_start) begin
        icache_req_addr_r  <= icache_req_addr_next;
        icache_req_valid_r <= '1;
    end
end

// Output
assign icache_req_addr_o  = icache_req_addr_r;
assign icache_req_valid_o = icache_req_valid_r;

// Triggers
always_comb begin
    icache_req_complete = icache_req_ready_i  && icache_req_valid_r;
end


//
// Cache Response Channel
//

// Actions
logic icache_resp_ready;
logic icache_resp_received;
logic icache_unaligned_jump;

// Registers
logic     icache_resp_ready_r         = '1;
logic     icache_resp_discard_half_r  = '0;

// Variables
logic     icache_resp_half_full;

// Updates
always_ff @(posedge clk_i) begin
    if (icache_resp_received)
        icache_resp_ready_r <= '0;
    
    if (icache_resp_ready && !flush)
        icache_resp_ready_r <= '1;
end

always_ff @(posedge clk_i) begin
    if (icache_resp_received)
        icache_resp_discard_half_r <= '0;
    
    if (icache_unaligned_jump)
        icache_resp_discard_half_r <= '1;
end

// Output
assign icache_resp_ready_o = icache_resp_ready_r;

// Triggers
always_comb begin
    icache_resp_received  = icache_resp_ready_r && icache_resp_valid_i;
    icache_resp_half_full = icache_resp_received && icache_resp_discard_half_r;
end


//
// Jump Channel
//

// Actions
logic jmp_received;
logic jmp_ready;

// Registers
logic jmp_ready_r = '1;

// Updates
always_ff @(posedge clk_i) begin
    if (jmp_received)
        jmp_ready_r <= '0;
    
    if (jmp_ready)
        jmp_ready_r <= '1;
end

// Output
assign jmp_ready_o = jmp_ready_r;

// Triggers
always_comb begin
    jmp_received = jmp_ready_r && jmp_valid_i;
end


//
// Buffers
//

// Actions
logic front_load;
logic back_load;
logic back_transfer;

// Types
typedef enum logic [1:0] {
    EMPTY = 2'b00,
    HALF  = 2'b01,
    FULL  = 2'b10
} buffer_state_t;

// Registers
word_t         front_r       = '0;
buffer_state_t front_state_r = EMPTY;
word_t         back_r        = '0;
logic          back_valid_r  = '0;

// Variables
buffer_state_t front_state_next;

// Updates
always_ff @(posedge clk_i) begin
    if (front_load)
        front_r <= icache_resp_data_i;
    
    if (back_transfer) begin
        front_r      <= back_r;
        back_valid_r <= '0;
    end
    
    if (back_load) begin
        back_r       <= icache_resp_data_i;
        back_valid_r <= '1;
    end
    
    if (flush)
        back_valid_r <= '0;
end

always_ff @(posedge clk_i) begin
    front_state_r <= flush ? EMPTY : front_state_next;
end

//
// Decompression
//

logic compressed;

decompressor decompressor (
    .ir_i (compressed_ir),
    .ir_o (fetch_ir_next),
    .compressed_o (compressed)
);


//
// Action Determination Logic
//

//`define USE_CASE_STATEMENT

logic  fetch_full;
word_t compressed_ir;
    
always_comb begin
    //
    // Calculate Helper Values
    //
    
    unique case (front_state_r)
    EMPTY: compressed_ir = icache_resp_half_full ? { 16'b0, icache_resp_data_i[31:16] } : icache_resp_data_i;
    HALF:  compressed_ir = { (back_valid_r ? back_r[15:0] : icache_resp_data_i[15:0]), front_r[31:16] };
    FULL:  compressed_ir = front_r;
    endcase
            
    fetch_full = fetch_valid_r && !fetch_ready_i;

`ifdef USE_CASE_STATEMENT
    fetch_provide     = '0;
    icache_resp_ready = '1;
    front_load        = '0;
    front_state_next  = front_state_r;
    back_load         = '0;
    back_transfer     = '0;

    unique casez ({ fetch_full, front_state_r, back_valid_r, icache_resp_received, icache_resp_half_full, compressed })
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
        end
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_load        = '1;
            front_state_next  = HALF;
        end
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b1, 1'b0 }:
        begin
            front_load        = '1;
            front_state_next  = HALF;
        end
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b1, 1'b1 }:         
        begin
            fetch_provide     = '1;
        end
    { 1'b1, EMPTY, 1'b0, 1'b1, 1'b0, 1'b? }:
        begin
            front_load        = '1;
            front_state_next  = FULL;
        end
    { 1'b1, EMPTY, 1'b0, 1'b1, 1'b1, 1'b? }:
        begin
            front_load        = '1;
            front_state_next  = HALF;
        end
    { 1'b0,  HALF, 1'b0, 1'b0, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_state_next  = EMPTY;
        end
    { 1'b0,  HALF, 1'b0, 1'b1, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            front_load        = '1;
        end
    { 1'b0,  HALF, 1'b0, 1'b1, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_load        = '1;
            front_state_next  = FULL;
        end
    { 1'b1,  HALF, 1'b0, 1'b1, 1'b0, 1'b? }:
        begin
            back_load         = '1;
            icache_resp_ready = '0;
        end
    { 1'b0,  HALF, 1'b1, 1'b0, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            back_transfer     = '1;
        end
    { 1'b0,  HALF, 1'b1, 1'b0, 1'b0, 1'b1 }:   
        begin
            fetch_provide     = '1;
            back_transfer     = '1;
            front_state_next  = FULL;
        end
    { 1'b1,  HALF, 1'b1, 1'b0, 1'b0, 1'b? }:
        begin
            icache_resp_ready = '0;
        end
    { 1'b0, HALF, 1'b1, 1'b1, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            icache_resp_ready = '0;
            back_transfer     = '1;
            back_load         = '1;
        end
    { 1'b0, HALF, 1'b1, 1'b1, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            icache_resp_ready = '0;
            back_transfer     = '1;
            back_load         = '1;
            front_state_next  = FULL;
        end
    { 1'b0, FULL, 1'b0, 1'b0, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            front_state_next  = EMPTY;
        end
    { 1'b0, FULL, 1'b0, 1'b0, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_state_next  = HALF;
        end
    { 1'b0, FULL, 1'b0, 1'b1, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            front_load        = '1;
        end
    { 1'b0, FULL, 1'b0, 1'b1, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_state_next  = HALF;
            back_load         = '1;
            icache_resp_ready = '0;
        end
    { 1'b1, FULL, 1'b0, 1'b1, 1'b0, 1'b? }:
        begin
            back_load         = '1;
            icache_resp_ready = '0;
        end
    { 1'b0, FULL, 1'b1, 1'b0, 1'b0, 1'b0 }:
        begin
            fetch_provide     = '1;
            back_transfer     = '1;
        end
    { 1'b0, FULL, 1'b1, 1'b0, 1'b0, 1'b1 }:
        begin
            fetch_provide     = '1;
            front_state_next  = HALF;
            icache_resp_ready = '0;
        end
    { 1'b1, FULL, 1'b1, 1'b0, 1'b0, 1'b? }:
        begin
            icache_resp_ready = '0;
        end
    default: ;
    endcase
`else
    fetch_provide = '0;
    if (!fetch_full) begin
        unique0 casez ({ front_state_r, back_valid_r, icache_resp_received, icache_resp_half_full, compressed })
        { EMPTY, 1'b0, 1'b1, 1'b0, 1'b? },
        { EMPTY, 1'b0, 1'b1, 1'b1, 1'b1 },
        {  HALF, 1'b0, 1'b0, 1'b0, 1'b1 },
        {  HALF, 1'b?, 1'b1, 1'b0, 1'b? },
        {  HALF, 1'b1, 1'b0, 1'b?, 1'b? },
        {  FULL, 1'b1, 1'b0, 1'b?, 1'b? },
        {  FULL, 1'b0, 1'b?, 1'b0, 1'b? }: fetch_provide = '1;
        endcase
    end
        
    front_load = '0;
    if (!back_valid_r && icache_resp_received) begin
        unique0 casez ({ fetch_full, front_state_r, icache_resp_half_full, compressed })
        { 1'b0, EMPTY, 1'b0, 1'b1 }, 
        { 1'b0, EMPTY, 1'b1, 1'b0 },
        { 1'b1, EMPTY, 1'b?, 1'b? },
        { 1'b0,  HALF, 1'b0, 1'b? },
        { 1'b0,  FULL, 1'b0, 1'b0 }: front_load = '1;
        endcase
    end
    
    back_load = '0;
    if (icache_resp_received && !icache_resp_half_full) begin
        unique0 casez ({ fetch_full, front_state_r, back_valid_r, compressed })
        { 1'b1,  HALF, 1'b0, 1'b? },
        { 1'b0,  HALF, 1'b1, 1'b? },
        { 1'b0,  FULL, 1'b0, 1'b1 },
        { 1'b1,  FULL, 1'b0, 1'b? }: back_load = '1;
        endcase
    end
    
    back_transfer = '0;
    if (!fetch_full && back_valid_r) begin
        unique0 casez ({ front_state_r, icache_resp_received, icache_resp_half_full, compressed })
        {  HALF, 1'b0, 1'b?, 1'b? },
        {  HALF, 1'b1, 1'b0, 1'b? },
        {  FULL, 1'b0, 1'b?, 1'b0 }: back_transfer = '1;
        endcase
    end
    
    icache_resp_ready = '1;
    unique0 casez ({ fetch_full, front_state_r, back_valid_r, icache_resp_received, icache_resp_half_full, compressed })
    { 1'b1,  HALF, 1'b0, 1'b1, 1'b0, 1'b? },
    { 1'b1,  HALF, 1'b1, 1'b0, 1'b?, 1'b? },
    { 1'b0,  HALF, 1'b1, 1'b1, 1'b0, 1'b? },
    { 1'b0,  FULL, 1'b0, 1'b1, 1'b0, 1'b1 },
    { 1'b1,  FULL, 1'b0, 1'b1, 1'b0, 1'b? },
    { 1'b0,  FULL, 1'b1, 1'b0, 1'b?, 1'b1 },
    { 1'b1,  FULL, 1'b1, 1'b0, 1'b?, 1'b? }: icache_resp_ready = '0; 
    endcase
    
    front_state_next = front_state_r;
    unique0 casez ({ fetch_full, front_state_r, back_valid_r, icache_resp_received, icache_resp_half_full, compressed })
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b0, 1'b0 },
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b1, 1'b1 },
    { 1'b0,  HALF, 1'b0, 1'b0, 1'b?, 1'b1 },
    { 1'b0,  FULL, 1'b0, 1'b0, 1'b?, 1'b0 }: front_state_next = EMPTY;
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b0, 1'b1 },
    { 1'b0, EMPTY, 1'b0, 1'b1, 1'b1, 1'b0 },
    { 1'b1, EMPTY, 1'b0, 1'b1, 1'b1, 1'b? },
    { 1'b0,  HALF, 1'b?, 1'b?, 1'b0, 1'b0 },
    { 1'b1,  HALF, 1'b0, 1'b1, 1'b0, 1'b? },
    { 1'b1,  HALF, 1'b1, 1'b0, 1'b?, 1'b? },
    { 1'b0,  FULL, 1'b?, 1'b0, 1'b?, 1'b1 },
    { 1'b0,  FULL, 1'b0, 1'b1, 1'b0, 1'b1 }: front_state_next = HALF;
    { 1'b1, EMPTY, 1'b0, 1'b1, 1'b0, 1'b? },
    { 1'b0,  HALF, 1'b0, 1'b1, 1'b0, 1'b1 },
    { 1'b0,  HALF, 1'b1, 1'b?, 1'b0, 1'b1 },
    { 1'b0,  FULL, 1'b0, 1'b1, 1'b0, 1'b0 },
    { 1'b0,  FULL, 1'b1, 1'b0, 1'b?, 1'b0 },
    { 1'b1,  FULL, 1'b0, 1'b1, 1'b0, 1'b? },
    { 1'b1,  FULL, 1'b1, 1'b0, 1'b?, 1'b? }: front_state_next = FULL;
    endcase
`endif

    //
    // Flow Control
    //
 
    jmp_ready        = '1;
    flush            = '0;
    icache_req_start = '0;
    
    // If icache request completed, start one for the next memory address
    icache_req_addr_next = icache_req_addr_r + 1;
    if (icache_req_complete) begin
        icache_req_start = '1;
    end
    
    // Next PC advanced based on compression of instruction
    if (compressed)
        fetch_pc_next_next = fetch_pc_next_r + 2;
    else
        fetch_pc_next_next = fetch_pc_next_r + 4;
        
    // If jumping 
    if (jmp_received) begin
        // Request jump address 
        icache_req_addr_next           = jmp_addr_i[31:2];
        icache_req_start               = '1;
        // Next PC is jump address
        fetch_pc_next_next             = jmp_addr_i;
        // Flush all buffers
        flush                          = '1;
    end
end

endmodule