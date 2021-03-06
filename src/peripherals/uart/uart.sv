`timescale 1ns / 1ps
`default_nettype none

///
/// UART
///

module uart
    // Import Constants
    import common::*;
    import uart_common::*;
    (
        input  wire logic       clk_i,
        output      logic       interrupt_o,

        // UART
        input  wire logic       rxd_i,
        output wire logic       txd_o,

        // Bus Interface
        input  wire logic       chip_select_i,
        input  wire logic [3:0] addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );


// Default is 115200/8-N-1 without flow control, based on a 50MHz system clock
uart_config_t config_r = '{ DATA_EIGHT, PARITY_NONE, STOP_ONE, FLOW_NONE, 1'b0, 24'd434 };


//
// Bus Interface
//

logic [7:0] rx_fifo_data;
logic       rx_fifo_valid;

// ports
typedef enum logic [3:0] {
    PORT_CONFIG = 4'b0000,
    PORT_STATUS = 4'b0001,
    PORT_READ   = 4'b0010,
    PORT_WRITE  = 4'b0011
} port_t;

// read
word_t read_data_r = '0;
assign read_data_o = read_data_r;
always_ff @(posedge clk_i) begin
    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_CONFIG: read_data_r <= config_r;
        PORT_READ:   read_data_r <= { 23'b0, rx_fifo_valid, rx_fifo_data };
        default:     read_data_r <= 32'b0;
        endcase
    end
end

// write
always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_CONFIG:
            begin
                if (write_mask_i[0]) config_r[7 : 0] <= write_data_i[ 7: 0];
                if (write_mask_i[1]) config_r[15: 8] <= write_data_i[15: 8];
                if (write_mask_i[2]) config_r[23:16] <= write_data_i[23:16];
                if (write_mask_i[3]) config_r[31:24] <= write_data_i[31:24];
            end
        default: ;
        endcase
    end
end


//
// Receiver
//

logic [7:0] rx_data;
logic       rx_valid;
logic       rx_fifo_empty;

uart_rx rx (
    .clk_i        (clk_i),
    .config_i     (config_r),
    .rxd_i        (rxd_i),
    .data_o       (rx_data),
    .data_valid_o (rx_valid)
);

fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) rx_fifo (
    .clk_i               (clk_i),
    .write_data_i        (rx_data),
    .write_enable_i      (rx_valid),
    .read_enable_i       (addr_i == PORT_READ && read_enable_i),
    .read_data_o         (rx_fifo_data),
    .read_valid_o        (rx_fifo_valid),
    .fifo_empty_o        (rx_fifo_empty),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);

always_comb interrupt_o = !rx_fifo_empty;


//
// Transmitter
//

logic       tx_read_enable;
logic       tx_read_valid;
logic [7:0] tx_read_data;

fifo #(
    .DATA_WIDTH(8),
    .ADDR_WIDTH(4)
) tx_fifo (
    .clk_i               (clk_i),
    .write_data_i        (write_data_i[7:0]),
    .write_enable_i      (addr_i == PORT_WRITE & write_mask_i[0]),
    .read_enable_i       (tx_read_enable),
    .read_data_o         (tx_read_data),
    .read_valid_o        (tx_read_valid),
    .fifo_empty_o        (),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);

uart_tx tx (
    .clk_i         (clk_i),
    .config_i      (config_r),
    .txd_o         (txd_o),
    .read_enable_o (tx_read_enable),
    .read_data_i   (tx_read_data),
    .read_valid_i  (tx_read_valid)
);

endmodule
