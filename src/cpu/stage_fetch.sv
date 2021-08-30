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
    if (fetch_receive)
        fetch_valid_r <= '0;
    
    if (fetch_provide) begin
        fetch_ir_r      <= fetch_ir_next;
        fetch_pc_r      <= fetch_pc_next_r;
        fetch_pc_next_r <= fetch_pc_next_next;
        fetch_valid_r   <= '1;
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
// Cache Request Management
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
    if (icache_req_complete)
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
// Cache Response Management
//

// Actions
logic icache_resp_ready;
logic icache_resp_received;

// Registers
logic icache_resp_ready_r = '1;

// Updates
always_ff @(posedge clk_i) begin
    if (icache_resp_received)
        icache_resp_ready_r <= '0;
    
    if (icache_resp_ready)
        icache_resp_ready_r <= '1;
end

// Output
assign icache_resp_ready_o = icache_resp_ready_r;

// Triggers
always_comb begin
    icache_resp_received = icache_resp_ready_r && icache_resp_valid_i;
end


//
// Buffer Management
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
end

always_ff @(posedge clk_i) begin
    front_state_r <= front_state_next;
end


//
// Variable Logic
//

always_comb begin
    // Should another cache request be made, and for what address?
    icache_req_start     = icache_req_ready_i;
    icache_req_addr_next = icache_req_addr_r + 1;

    // Based on buffer states
    fetch_provide     = '0;
    fetch_ir_next     = '0;
    icache_resp_ready = '1;
    front_load        = '0;
    front_state_next  = front_state_r;
    back_load         = '0;
    back_transfer     = '0;

    casez ({ (fetch_valid_r && !fetch_ready_i), front_state_r, back_valid_r, icache_resp_received })
    { 1'b0, EMPTY, 1'b0, 1'b1 }:
        begin
            fetch_provide = '1;
            if (icache_resp_data_i[1:0] == 2'b11) begin
                fetch_ir_next     = icache_resp_data_i;
            end else begin
                fetch_ir_next     = { 16'b0, icache_resp_data_i[15:0] };
                front_load        = '1;
                front_state_next  = HALF;
            end
        end
    { 1'b1, EMPTY, 1'b0, 1'b1 }:
        begin
            front_load       = '1;
            front_state_next = FULL;            
        end
    { 1'b0,  HALF, 1'b0, 1'b0 }:
        begin
            if (front_r[17:16] != 3'b11) begin
                fetch_provide    = '1;
                fetch_ir_next    = { 16'b0, front_r[31:16] };
                front_state_next = EMPTY;
            end
        end
    { 1'b0,  HALF, 1'b0, 1'b1 }:
        begin
            fetch_provide = '1;
            front_load    = '1;
            if (front_r[17:16] == 3'b11) begin
                fetch_ir_next    = { icache_resp_data_i[15:0], front_r[31:16] };
            end else begin
                fetch_ir_next    = { 16'b0,                    front_r[31:16] };
                front_state_next = FULL;
            end
        end
    { 1'b1,  HALF, 1'b0, 1'b1 }:
        begin
            back_load         = '1;
            icache_resp_ready = '0;
        end
    { 1'b0,  HALF, 1'b1, 1'b0 }:
        begin
            fetch_provide   = '1;
            back_transfer   = '1;
            if (front_r[17:16] == 3'b11) begin
                fetch_ir_next    = { back_r[15:0], front_r[31:16] };
            end else begin
                fetch_ir_next    = { 16'b0,        front_r[31:16] };
                front_state_next = FULL;
            end
        end
    { 1'b1,  HALF, 1'b1, 1'b0 }:
        begin
            icache_resp_ready = '0;
        end
    { 1'b0, HALF, 1'b1, 1'b1 }:
        begin
            fetch_provide     = '1;
            icache_resp_ready = '0;
            back_transfer     = '1;
            back_load         = '1;
            if (front_r[1:0] == 2'b11) begin
                fetch_ir_next    = { front_r[31:16], back_r[15:0] };
            end else begin
                fetch_ir_next    = { 16'b0,          front_r[31:16] };
                front_state_next = FULL;
            end
        end
    { 1'b0, FULL, 1'b0, 1'b0 }:
        begin
            fetch_provide = '1;
            if (front_r[1:0] == 2'b11) begin
                fetch_ir_next    = front_r;
                front_state_next = EMPTY;
            end else begin
                fetch_ir_next    = { 16'b0, front_r[15:0] };
                front_state_next = HALF;
            end
        end
    { 1'b0, FULL, 1'b0, 1'b1 }:
        begin
            fetch_provide = '1;
            if (front_r[1:0] == 2'b11) begin
                fetch_ir_next     = front_r;
                front_load        = '1;
            end else begin
                fetch_ir_next     = { 16'b0, front_r[15:0] };
                front_state_next  = HALF;
                back_load         = '1;
                icache_resp_ready = '0;
            end
        end
    { 1'b1, FULL, 1'b0, 1'b1 }:
        begin
            back_load         = '1;
            icache_resp_ready = '0;
        end
    { 1'b0, FULL, 1'b1, 1'b0 }:
        begin
            fetch_provide = '1;
            if (front_r[1:0] == 2'b11) begin
                fetch_ir_next    = front_r;
                back_transfer    = '1;
            end else begin
                fetch_ir_next     = { 16'b0, front_r[15:0] };
                front_state_next  = HALF;
                icache_resp_ready = '0;
            end
        end
    default: ;
    endcase
    
    // What will the next PC address be?
    fetch_pc_next_next = fetch_pc_next_r + (fetch_ir_next[1:0] == 3'b11 ? 4 : 2);
end

endmodule