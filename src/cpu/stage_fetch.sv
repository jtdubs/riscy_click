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
// Pipeline Management
//

// Actions
logic start_output;
logic output_received;

// Registers
word_t ir_r      = '0;
word_t pc_r      = '0;
logic  valid_r   = '0;
word_t pc_next_r = '0;

// Variables
word_t next_ir;
word_t next_pc_next;

// Updates
always_ff @(posedge clk_i) begin
    if (output_received)
        valid_r <= '0;
    
    if (start_output) begin
        ir_r      <= next_ir;
        pc_r      <= pc_next_r;
        pc_next_r <= next_pc_next;
        valid_r   <= '1;
    end
end

// Output
assign ir_o      = ir_r;
assign pc_o      = pc_r;
assign valid_o   = valid_r;
assign pc_next_o = pc_next_r;


//
// Cache Request Management
//

// Actions
logic start_cache_request;
logic cache_request_received;

// Registers
memaddr_t icache_req_addr_r  = '0;
logic     icache_req_valid_r = '1;

// Variables
memaddr_t cache_request_addr;

// Updates
always_ff @(posedge clk_i) begin
    if (cache_request_received)
        icache_req_valid_r <= '0;
    
    if (start_cache_request) begin
        icache_req_addr_r  <= cache_request_addr;
        icache_req_valid_r <= '1;
    end
end

// Output
assign icache_req_addr_o  = icache_req_addr_r;
assign icache_req_valid_o = icache_req_valid_r;


//
// Cache Response Management
//

// Actions
logic accept_cache_response;
logic cache_response_received;

// Registers
logic icache_resp_ready_r = '1;

// Updates
always_ff @(posedge clk_i) begin
    if (cache_response_received)
        icache_resp_ready_r <= '0;
    
    if (accept_cache_response)
        icache_resp_ready_r <= '1;
end

// Output
assign icache_resp_ready_o = icache_resp_ready_r;


//
// Buffer Management
//

// Actions
logic fill_buffer;

// Types
typedef enum logic [1:0] {
    EMPTY = 2'b00,
    HALF  = 2'b01,
    FULL  = 2'b10
} buffer_state_t;

// Registers
word_t         buffer_r       = '0;
buffer_state_t buffer_state_r = EMPTY;

// Variables
buffer_state_t buffer_state_next;

// Updates
always_ff @(posedge clk_i) begin
    if (fill_buffer)
        buffer_r <= icache_resp_data_i;
end

always_ff @(posedge clk_i) begin
    buffer_state_r <= buffer_state_next;
end


//
// Variable Logic
//

logic compressed;
logic next_ir_ready;

always_comb begin
    // What requests were received?
    output_received         = ready_i && valid_r;
    cache_request_received  = icache_req_ready_i && icache_req_valid_r;
    cache_response_received = icache_resp_valid_i && icache_resp_ready_r;

    // What's the next IR and is it compressed?
    case (buffer_state_r)
    EMPTY: next_ir[15:0] = icache_resp_data_i[15:0];
    HALF:  next_ir[15:0] = buffer_r[31:16];
    FULL:  next_ir[15:0] = buffer_r[15:0];
    endcase
    compressed = next_ir[1:0] != 2'b11;
    if (compressed) begin
        next_ir[31:16] = 16'b0;
    end else begin
        case (buffer_state_r)
        EMPTY: next_ir[31:16] = icache_resp_data_i[31:16];
        HALF:  next_ir[31:16] = icache_resp_data_i[15:0];
        FULL:  next_ir[31:16] = buffer_r[31:16];
        endcase
    end
    
    // Is the next IR ready to output?
    case (buffer_state_r)
    EMPTY: next_ir_ready = cache_response_received;
    HALF:  next_ir_ready = cache_response_received || compressed;
    FULL:  next_ir_ready = '1;
    endcase

    // Should another cache request be made, and what address?
    start_cache_request = icache_req_ready_i;
    cache_request_addr  = icache_req_addr_r + 1;

    // What will the next PC address be?
    next_pc_next = pc_next_r + (compressed ? 2 : 4);
    
    // Perform a pipeline output?
    start_output = next_ir_ready && (output_received || !valid_r);
    
    // Fill the buffer?
    fill_buffer = cache_response_received;

    // What will the next buffer state be?
    priority casez ({ buffer_state_r, fill_buffer, start_output, compressed })
    { EMPTY, 1'b1, 1'b0, 1'b? }: buffer_state_next = FULL; 
    { EMPTY, 1'b1, 1'b1, 1'b1 }: buffer_state_next = HALF;
    { HALF,  1'b0, 1'b1, 1'b1 }: buffer_state_next = EMPTY;
    { HALF,  1'b1, 1'b1, 1'b1 }: buffer_state_next = FULL;
    { FULL,  1'b0, 1'b1, 1'b0 }: buffer_state_next = EMPTY;
    { FULL,  1'b0, 1'b1, 1'b1 }: buffer_state_next = HALF;
    default:                     buffer_state_next = buffer_state_r;
    endcase
    
    // Accept another cache response?
    accept_cache_response = buffer_state_next != FULL;
end

endmodule