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
wire word_t    bios_read_data;
wire logic     bios_read_valid;

// Component
bios_rom #(
    .CONTENTS("bios.mem")
) bios (
    .clk_i          (clk_i),
    .read1_addr_i   ({ req_addr_i, 2'b0 }),
    .read1_enable_i (req_occurs),
    .read1_data_o   (bios_read_data),
    .read2_addr_i   (32'b0),
    .read2_enable_i (1'b0),
    .read2_data_o   ()
);

// Generate bios_read_valid signal on a ROM_LATENCY cycle delay
logic bios_read_valid_r [ROM_LATENCY-1:0] = '{ default: '0 };
always_ff @(posedge clk_i) begin
    bios_read_valid_r <= { req_occurs, bios_read_valid_r[ROM_LATENCY-1:1] };
end
assign bios_read_valid = bios_read_valid_r[0];


//
// Output Registers
//

assign    req_ready_o  = addr_write_ready;

memaddr_t resp_addr_r  = 28'b0;
assign    resp_addr_o  = resp_addr_r;

word_t    resp_data_r  = 32'b0;
assign    resp_data_o  = resp_data_r;

logic     resp_valid_r = 1'b0;
assign    resp_valid_o = resp_valid_r;


//
// Request Queues
//

word_t data;
logic  data_valid;

fifo #(
    .DATA_WIDTH     (32),
    .ADDR_WIDTH     (2)
) data_fifo (
    .clk_i          (clk_i),
    .read_enable_i  (unqueue_data),
    .read_data_o    (data),
    .read_valid_o   (data_valid),
    .write_data_i   (bios_read_data),
    .write_enable_i (queue_data)
);

// Address Queue
memaddr_t addr;
logic     addr_write_ready;

fifo #(
    .DATA_WIDTH     (30),
    .ADDR_WIDTH     (2)
) addr_fifo (
    .clk_i          (clk_i),
    .read_enable_i  (load_resp),
    .read_data_o    (addr),
    .write_data_i   (req_addr_i),
    .write_enable_i (req_occurs),
    .write_ready_o  (addr_write_ready)
);

// Operations
logic req_occurs;
logic resp_occurs;
logic load_resp;
logic queue_data;
logic unqueue_data;


//
// Output Registers
//

// Response
always_ff @(posedge clk_i) begin
    if (resp_occurs)
        resp_valid_r <= 1'b0;

    if (load_resp) begin
        resp_addr_r  <= addr;
        resp_data_r  <= unqueue_data ? data : bios_read_data;
        resp_valid_r <= 1'b1;
    end
end


//
// Logic
//

always_comb begin
    // a request occurs when the request inputs are valid and the address fifo can accept writes
    req_occurs   = req_valid_i && addr_write_ready;
    
    // a response occurs when the response data is valid and the receiver is ready
    resp_occurs  = resp_valid_r && resp_ready_i;
    
    // load a new response if there will be room and there is data to load
    load_resp    = (resp_occurs || !resp_valid_r) && (data_valid || bios_read_valid);
    
    // queue data when received and we are either not loading a response, or there is valid data in the queue to output first
    queue_data   = bios_read_valid && (!load_resp || data_valid);
    
    // unqueue data when loading a response and queue has valid data
    unqueue_data = load_resp && data_valid; 
end

endmodule
