`timescale 1ns / 1ps
`default_nettype none

///
/// UART
///

module uart
    // Import Constants
    import common::*;
    (
        input  wire logic clk_i,
        input  wire logic chip_select_i,
        output      logic interrupt_o,

        // UART
        input  wire logic rxd_i,
        output wire logic txd_o,

        // Memory Mapped Interface
        input  wire logic [1:0] addr_i,
        input  wire logic       read_enable_i,
        output      word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic       write_enable_i
    );


// Default is 115200/8-N-1 without flow control, based on a 50MHz system clock
uart_config_t config_r = '{ DATA_EIGHT, PARITY_NONE, STOP_ONE, FLOW_NONE, 1'b0, 25'd434 };


//
// Reads & Writes
//

typedef struct packed {
    logic uart_config;
    logic read_fifo;
    logic write_fifo;
} chip_select_t;

chip_select_t chip_select_w;
chip_select_t chip_select_r;

wire word_t config_data_w;
wire word_t read_fifo_data_w;
wire word_t write_fifo_data_w;
wire word_t read_data_w;

always_ff @(posedge clk_i) begin
    chip_select_r <= chip_select_w;
end

always_comb begin
    unique casez (addr_i)
    2'b00: chip_select_w = '{ uart_config: 1'b1, default: 1'b0 };
    2'b01: chip_select_w = '{ read_fifo:   1'b1, default: 1'b0 };
    2'b10: chip_select_w = '{ write_fifo:  1'b1, default: 1'b0 };
    2'b11: chip_select_w = '{                    default: 1'b0 };
    endcase
end

always_comb begin
    if (chip_select_r.uart_config)
        read_data_o = config_r;
    else if (chip_select_r.read_fifo)
        read_data_o = { 23'b0, rx_fifo_valid_w, rx_fifo_data_w };
    else if (chip_select_r.write_fifo)
        read_data_o = 32'b0;
    else
        read_data_o = 32'b0;
end

always_ff @(posedge clk_i) begin
    if (write_enable_i) begin
        if (chip_select_r.uart_config)
            config_r <= write_data_i;
    end
end


//
// Receiver
//

logic [7:0] rx_data_w;
logic       rx_valid_w;
logic [7:0] rx_fifo_data_w;
logic       rx_fifo_valid_w;
logic       rx_fifo_empty_w;

uart_rx rx (
    .clk_i        (clk_i),
    .config_i     (config_r),
    .rxd_i        (rxd_i),
    .data_o       (rx_data_w),
    .data_valid_o (rx_valid_w)
);

fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) rx_fifo (
    .clk_i               (clk_i),
    .write_data_i        (rx_data_w),
    .write_enable_i      (rx_valid_w),
    .read_enable_i       (chip_select_w.read_fifo),
    .read_data_o         (rx_fifo_data_w),
    .read_valid_o        (rx_fifo_valid_w),
    .fifo_empty_o        (rx_fifo_empty_w),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);


//
// Interrupt
//

always_comb interrupt_o = !rx_fifo_empty_w;

endmodule
