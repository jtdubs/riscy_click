`timescale 1ns / 1ps
`default_nettype none

///
/// Synchronous FIFO
///
/// Writes to a full FIFO are discarded.
/// Reads from an empty FIFO return invalid data.
///

module fifo
    // Import Constants
    import common::*;
    #(
        parameter shortint DATA_WIDTH         = 16,
        parameter shortint ADDR_WIDTH          = 5,
        parameter shortint ALMOST_EMPTY_MARGIN = 2,
        parameter shortint ALMOST_FULL_MARGIN  = 2
    )
    (
        input  wire logic                    clk_i,

        // write port
        input  wire logic [(DATA_WIDTH-1):0] write_data_i,
        input  wire logic                    write_enable_i,

        // read port
        input  wire logic                    read_enable_i,
        output wire logic [(DATA_WIDTH-1):0] read_data_o,
        output wire logic                    read_valid_o,

        // fifo status
        output wire logic                    fifo_empty_o,
        output wire logic                    fifo_almost_empty_o,
        output wire logic                    fifo_almost_full_o,
        output wire logic                    fifo_full_o
    );

typedef logic [(DATA_WIDTH-1):0] data_t;
typedef logic [(ADDR_WIDTH-1):0] addr_t;

localparam addr_t CAPACITY           = addr_t'((1 << ADDR_WIDTH) - 1);
localparam addr_t ALMOST_EMPTY_COUNT = addr_t'(ALMOST_EMPTY_MARGIN);
localparam addr_t ALMOST_FULL_COUNT  = addr_t'(CAPACITY - addr_t'(ALMOST_FULL_MARGIN));

// variables
data_t data_r [CAPACITY:0] = '{ default: '0 };
addr_t read_ptr_r          = '0;
addr_t write_ptr_r         = '0;

// determine next state
addr_t read_ptr_next;
addr_t write_ptr_next;

always_comb begin
    unique if (write_enable_i && !fifo_full_o) begin
        write_ptr_next = write_ptr_r + 1;
    end else begin
        write_ptr_next = write_ptr_r;
    end

    unique if (read_enable_i && !fifo_empty_o) begin
        read_ptr_next = read_ptr_r + 1;
    end else begin
        read_ptr_next = read_ptr_r;
    end
end

// pending fifo count
addr_t count_next;
always_comb count_next = write_ptr_next - read_ptr_next;

// update registers
logic [(DATA_WIDTH-1):0] read_data_r         = '0;
logic                    read_valid_r        = '0;
logic                    fifo_empty_r        = '1;
logic                    fifo_almost_empty_r = '1;
logic                    fifo_almost_full_r  = '0;
logic                    fifo_full_r         = '0;

always_ff @(posedge clk_i) begin
    fifo_empty_r        <= (count_next == '0);
    fifo_almost_empty_r <= (count_next <= ALMOST_EMPTY_COUNT);
    fifo_almost_full_r  <= (count_next >= ALMOST_FULL_COUNT);
    fifo_full_r         <= (count_next == CAPACITY);
    read_ptr_r          <= read_ptr_next;
    write_ptr_r         <= write_ptr_next;
    read_valid_r        <= !fifo_empty_r;
    read_data_r         <= data_r[read_ptr_r];

    if (write_enable_i && !fifo_full_r)
        data_r[write_ptr_r] <= write_data_i;
end

assign read_data_o         = read_data_r;
assign read_valid_o        = read_valid_r;
assign fifo_empty_o        = fifo_empty_r;
assign fifo_almost_empty_o = fifo_almost_empty_r;
assign fifo_almost_full_o  = fifo_almost_full_r;
assign fifo_full_o         = fifo_full_r;

endmodule
