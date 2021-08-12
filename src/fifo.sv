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
        parameter shortint WIDTH              = 16,
        parameter shortint DEPTH              = 32,
        parameter shortint ALMOST_EMPTY_COUNT = 2,
        parameter shortint ALMOST_FULL_COUNT  = (DEPTH-2)
    )
    (
        input  wire logic               clk_i,
        input  wire logic               reset_i,

        // write port
        input  wire logic [(WIDTH-1):0] write_data_i,
        input  wire logic               write_enable_i,

        // read port
        input  wire logic               read_enable_i,
        output      logic [(WIDTH-1):0] read_data_o,
        output      logic               read_valid_o,

        // fifo status
        output      logic               fifo_empty_o,
        output      logic               fifo_almost_empty_o,
        output      logic               fifo_almost_full_o,
        output      logic               fifo_full_o
    );

localparam int COUNTER_SIZE = $clog2(DEPTH);

typedef logic [(WIDTH-1       ):0] data_t;
typedef logic [(COUNTER_SIZE-1):0] counter_t;

localparam counter_t C_DEPTH              = counter_t'(DEPTH);
localparam counter_t C_ALMOST_EMPTY_COUNT = counter_t'(ALMOST_EMPTY_COUNT);
localparam counter_t C_ALMOST_FULL_COUNT  = counter_t'(ALMOST_FULL_COUNT);

// variables
data_t    data_r [(DEPTH-1):0];
data_t    read_data_w;
logic     read_valid_w;
counter_t read_ptr_r, read_ptr_w;
counter_t write_ptr_r, write_ptr_w;
counter_t count_w;
logic     fifo_empty_w;
logic     fifo_almost_empty_w;
logic     fifo_almost_full_w;
logic     fifo_full_w;

// determine next state
always_comb begin
    if (write_enable_i && !fifo_full_o) begin
        if (write_ptr_r == (C_DEPTH-1))
            write_ptr_w = '0;
        else
            write_ptr_w = write_ptr_r + 1;
    end else begin
        write_ptr_w = write_ptr_r;
    end

    if (read_enable_i && !fifo_empty_o) begin
        if (read_ptr_r == (C_DEPTH-1))
            read_ptr_w = '0;
        else
            read_ptr_w = read_ptr_r + 1;
        read_data_w  = data_r[read_ptr_w];
        read_valid_w = 1'b1;
    end else begin
        read_ptr_w   = read_ptr_r;
        read_data_w  = '0;
        read_valid_w = 1'b0;
    end

    unique if (write_ptr_r > read_ptr_r)
        count_w = write_ptr_w - read_ptr_w;
    else
        count_w = read_ptr_w - write_ptr_w;

    fifo_empty_w        = (count_w == '0);
    fifo_almost_empty_w = (count_w <= C_ALMOST_EMPTY_COUNT);
    fifo_almost_full_w  = (count_w >= C_ALMOST_FULL_COUNT);
    fifo_full_w         = (count_w == C_DEPTH);

end

// update registers
always_ff @(posedge clk_i) begin
    read_data_o         <= read_data_w;
    read_valid_o        <= read_valid_w;
    fifo_empty_o        <= fifo_empty_w;
    fifo_almost_empty_o <= fifo_almost_empty_w;
    fifo_almost_full_o  <= fifo_almost_full_w;
    fifo_full_o         <= fifo_full_w;
    read_ptr_r          <= read_ptr_w;
    write_ptr_r         <= write_ptr_w;

    if (write_enable_i && !fifo_full_o)
        data_r[write_ptr_w] <= write_data_i;

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
