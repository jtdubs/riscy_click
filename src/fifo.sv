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
        input  wire logic                    reset_i,

        // write port
        input  wire logic [(DATA_WIDTH-1):0] write_data_i,
        input  wire logic                    write_enable_i,

        // read port
        input  wire logic                    read_enable_i,
        output      logic [(DATA_WIDTH-1):0] read_data_o,
        output      logic                    read_valid_o,

        // fifo status
        output      logic                    fifo_empty_o,
        output      logic                    fifo_almost_empty_o,
        output      logic                    fifo_almost_full_o,
        output      logic                    fifo_full_o
    );

typedef logic [(DATA_WIDTH-1):0] data_t;
typedef logic [(ADDR_WIDTH-1):0] addr_t;

localparam addr_t CAPACITY           = addr_t'((1 << ADDR_WIDTH) - 1);
localparam addr_t ALMOST_EMPTY_COUNT = addr_t'(ALMOST_EMPTY_MARGIN);
localparam addr_t ALMOST_FULL_COUNT  = addr_t'(CAPACITY - addr_t'(ALMOST_FULL_MARGIN));

// variables
data_t data_r [CAPACITY:0];
addr_t read_ptr_r;
addr_t write_ptr_r;

// determine next state
addr_t write_ptr_w;
addr_t read_ptr_w;

always_comb begin
    if (write_enable_i && !fifo_full_o) begin
        write_ptr_w = write_ptr_r + 1;
    end else begin
        write_ptr_w = write_ptr_r;
    end

    if (read_enable_i && !fifo_empty_o) begin
        read_ptr_w = read_ptr_r + 1;
    end else begin
        read_ptr_w = read_ptr_r;
    end
end

// pending fifo count
addr_t count_w;
always_comb count_w = write_ptr_w - read_ptr_w;

// update registers
always_ff @(posedge clk_i) begin
    fifo_empty_o        <= (count_w == '0);
    fifo_almost_empty_o <= (count_w <= ALMOST_EMPTY_COUNT);
    fifo_almost_full_o  <= (count_w >= ALMOST_FULL_COUNT);
    fifo_full_o         <= (count_w == CAPACITY);
    read_ptr_r          <= read_ptr_w;
    write_ptr_r         <= write_ptr_w;

    if (write_enable_i && !fifo_full_o)
        data_r[write_ptr_r] <= write_data_i;

    if (read_enable_i && !fifo_empty_o) begin
        read_data_o  <= data_r[read_ptr_r];
        read_valid_o <= 1'b1;
    end else begin
        read_data_o  <= '0;
        read_valid_o <= 1'b0;
    end

    if (reset_i) begin
        read_data_o         <= '0;
        read_valid_o        <= 1'b0;
        fifo_empty_o        <= 1'b1;
        fifo_almost_empty_o <= 1'b1;
        fifo_almost_full_o  <= 1'b0;
        fifo_full_o         <= 1'b0;
        read_ptr_r          <= '0;
        write_ptr_r         <= '0;
    end
end

endmodule
