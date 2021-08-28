`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Cache
///

// NOTE: For now, this just provides a wrapper around the BIOS ROM that
// can accomodate variable latency as prep for a future cache/memory hierarchy

module instruction_cache
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic     clk_i,

        // request channel
        input  wire memaddr_t req_addr_i,
        input  wire logic     req_valid_i,
        output wire logic     req_ready_o,

        // response channel
        output wire memaddr_t resp_addr_o,
        output wire word_t    resp_data_o,
        output wire logic     resp_valid_o,
        input  wire logic     resp_ready_i
    );


localparam shortint ROM_LATENCY   = 2;
localparam shortint COUNTER_DEPTH = $clog2(ROM_LATENCY);
typedef logic [COUNTER_DEPTH:0] counter_t;


//
// BIOS
//

// Interface
     memaddr_t bios_read_addr;
     logic     bios_read_enable;
wire word_t    bios_read_data;
wire logic     bios_read_valid;

// Component
bios_rom #(
    .CONTENTS("bios.mem")
) bios (
    .clk_i          (clk_i),
    .read1_addr_i   ({ bios_read_addr, 2'b0 }),
    .read1_enable_i (bios_read_enable),
    .read1_data_o   (bios_read_data),
    .read2_addr_i   (32'b0),
    .read2_enable_i (1'b0),
    .read2_data_o   ()
);

// Generate bios_read_valid signal on a ROM_LATENCY cycle delay
logic bios_read_valid_r [ROM_LATENCY-1:0] = '{ default: '0 };
always_ff @(posedge clk_i) begin
    bios_read_valid_r <= { bios_read_enable, bios_read_valid_r[ROM_LATENCY-1:1] };
end
assign bios_read_valid = bios_read_valid_r[0];


//
// Output Registers
//

logic     req_ready_r  = 1'b1;
assign    req_ready_o  = req_ready_r;

memaddr_t resp_addr_r  = 28'b0;
assign    resp_addr_o  = resp_addr_r;

word_t    resp_data_r  = 32'b0;
assign    resp_data_o  = resp_data_r;

logic     resp_valid_r = 1'b0;
assign    resp_valid_o = resp_valid_r;


//
// Request Queues
//

// Address Queue
memaddr_t addr_queue_r[3:0]  = '{ default: '0 };
counter_t addr_read_ptr_r    = '0;
counter_t addr_write_ptr_r   = '0;
counter_t addr_count_r       = '0;
logic     addr_queue_empty_r = '1;
logic     addr_queue_full_r  = '0;

// Data Queue
word_t    data_queue_r[3:0]  = '{ default: '0 };
counter_t data_read_ptr_r    = '0;
counter_t data_write_ptr_r   = '0;
counter_t data_count_r       = '0;
logic     data_queue_empty_r = '1;
logic     data_queue_full_r  = '0;

// Operations
logic req_occurs;
logic resp_occurs;
logic load_resp;
logic queue_data;
logic unqueue_data;
logic queue_addr;
logic unqueue_addr;

// Pointers
always_ff @(posedge clk_i) begin
    if (unqueue_addr)
        addr_read_ptr_r <= addr_read_ptr_r + 1;

    if (queue_addr) begin
        addr_write_ptr_r <= addr_write_ptr_r + 1;
        addr_queue_r[addr_write_ptr_r] <= req_addr_i;
    end

    if (unqueue_data)
        data_read_ptr_r <= data_read_ptr_r + 1;
    
    if (queue_data) begin
        data_write_ptr_r <= data_write_ptr_r + 1;
        data_queue_r[data_write_ptr_r] <= bios_read_data;
    end
end


// Queue Size
counter_t addr_count_next;
counter_t data_count_next;

always_comb begin
    if (queue_addr && !unqueue_addr)
        addr_count_next = addr_count_r + 1;
    else if (!queue_addr && unqueue_addr)
        addr_count_next = addr_count_r - 1;
    else
        addr_count_next = addr_count_r;
    
    if (queue_data && !unqueue_data)
        data_count_next = data_count_r + 1;
    else if (!queue_data && unqueue_data)
        data_count_next = data_count_r - 1;
    else
        data_count_next = data_count_r;
end

always_ff @(posedge clk_i) begin
    addr_count_r <= addr_count_next;
    data_count_r <= data_count_next;
end

// Queue Status
logic addr_queue_empty_next;
logic addr_queue_full_next;
logic data_queue_empty_next;
logic data_queue_full_next;

always_comb begin
    addr_queue_empty_next = (addr_count_next == 0);
    addr_queue_full_next  = (addr_count_next == 3);
    data_queue_empty_next = (data_count_next == 0);
    data_queue_full_next  = (data_count_next == 3);
end

always_ff @(posedge clk_i) begin
    addr_queue_empty_r <= addr_queue_empty_next;
    addr_queue_full_r  <= addr_queue_full_next;
    data_queue_empty_r <= data_queue_empty_next;
    data_queue_full_r  <= data_queue_full_next;
end


//
// Output Registers
//

// Request
always_ff @(posedge clk_i) begin
    req_ready_r <= !data_queue_full_next && !addr_queue_full_next;
end

// Response
always_ff @(posedge clk_i) begin
    if (resp_occurs)
        resp_valid_r <= 1'b0;

    if (load_resp) begin
        resp_addr_r  <= addr_queue_r[addr_read_ptr_r];
        resp_data_r  <= unqueue_data ? data_queue_r[data_read_ptr_r] : bios_read_data;
        resp_valid_r <= 1'b1;
    end
end


//
// Logic
//

always_comb begin
    req_occurs       = req_valid_i && req_ready_r;
    resp_occurs      = resp_valid_r && resp_ready_i;
    load_resp        = (resp_occurs || !resp_valid_r) && (!data_queue_empty_r || bios_read_valid);
    queue_addr       = req_occurs;
    unqueue_addr     = load_resp;
    queue_data       = bios_read_valid && !(data_queue_empty_r && load_resp);
    unqueue_data     = load_resp && !data_queue_empty_r; 
    bios_read_addr   = req_addr_i;
    bios_read_enable = req_occurs;
end

endmodule
