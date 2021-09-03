`timescale 1ns / 1ps
`default_nettype none

module bypass_buffer
    // Import Constants
    import common::*;
    #(
        parameter shortint RD_WIDTH = 0,
        parameter shortint WR_WIDTH = 0
    )
    (
        input  wire logic             clk_i,

        // write channel
        input  wire logic [WR_WIDTH-1:0] wr_data_i,
        input  wire logic                wr_valid_i,
        output wire logic                wr_ready_o,

        // read channel
        output wire logic [RD_WIDTH-1:0] rd_data_o,
        output wire logic                rd_valid_o,
        input  wire logic                rd_ready_i,

        // transform channel
        output      logic [WR_WIDTH-1:0] tfr_data_o,
        input  wire logic [RD_WIDTH-1:0] tfr_data_i,
        input  wire logic                tfr_valid_i
    );

typedef logic [RD_WIDTH-1:0] rd_data_t;
typedef logic [WR_WIDTH-1:0] wr_data_t;


//
// Write Channel
//

// Control Signals
logic wr_occurs;

always_comb begin
    wr_occurs = wr_valid_i && buffer_empty_r;
end


//
// Read Channel
//

// Registers
rd_data_t rd_data_r  = '0;
assign    rd_data_o  = rd_data_r;
logic     rd_valid_r = '0;
assign    rd_valid_o = rd_valid_r;

// Control Signals
logic rd_occurs;
logic rd_full;
logic rd_load;

// Updates
always_ff @(posedge clk_i) begin
    if (rd_occurs)
        rd_valid_r <= '0;

    if (rd_load) begin
        rd_data_r  <= tfr_data_i;
        rd_valid_r <= '1;
    end
end

always_comb begin
    rd_occurs = rd_valid_r &&  rd_ready_i;
    rd_full   = rd_valid_r && !rd_ready_i;
end

always_comb begin
    tfr_data_o = buffer_empty_r ? wr_data_i : buffer_r;
end


//
// Buffer
//

// Registers
wr_data_t buffer_r       = '0;
logic     buffer_empty_r = '1;
assign    wr_ready_o     = buffer_empty_r;

// Control Signals
logic buffer_load;
logic buffer_unload;

// Updates
always_ff @(posedge clk_i) begin
    if (buffer_unload)
        buffer_empty_r <= '1;

    if (buffer_load) begin
        buffer_r       <= wr_data_i;
        buffer_empty_r <= '0;
    end
end


//
// Control Logic
//

always_comb begin
    rd_load       = !rd_full && (!buffer_empty_r || wr_occurs) && tfr_valid_i;
    buffer_load   =  rd_full && wr_occurs;
    buffer_unload = !rd_full && !buffer_empty_r && tfr_valid_i;
end

endmodule
