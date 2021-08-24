`timescale 1ns / 1ps
`default_nettype none

///
/// Keyboard Controller
///

module keyboard_controller
    // Import Constants
    import common::*;
    import keyboard_common::*;
    (
        // System Interface
        input  wire logic       clk_i,
        output wire logic       interrupt_o,

        // PS/2 Interface
        input  wire logic       ps2_clk_i,
        input  wire logic       ps2_data_i,

        // Bus Interface
        input  wire logic       chip_select_i,
        input  wire logic [3:0] addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );


//
// Bus Interface
//

wire logic [8:0] fifo_data;
wire logic       fifo_valid;

// ports
typedef enum logic [3:0] {
    PORT_DATA    = 4'b0000,
    PORT_CONTROL = 4'b0001
} port_t;

// read
word_t read_data_r = '0;
assign read_data_o = read_data_r;
always_ff @(posedge clk_i) begin
    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_DATA:    read_data_r <= { 15'b0, fifo_valid, 7'b0, fifo_data };
        PORT_CONTROL: read_data_r <= 32'b0;
        default:      read_data_r <= 32'b0;
        endcase
    end
end

// write
always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_CONTROL:
            begin
                // TODO
            end
        default: ;
        endcase
    end
end


// PS2 RX
byte_t      ps2_data;
logic       ps2_valid;

ps2_rx ps2_rx (
    .clk_i      (clk_i),
    .ps2_clk_i  (ps2_clk_i),
    .ps2_data_i (ps2_data_i),
    .data_o     (ps2_data),
    .valid_o    (ps2_valid)
);


// Keyboard
ps2_kbd_event_t ps2_kbd_event;
logic           ps2_kbd_valid;

ps2_keyboard ps2_keyboard (
    .clk_i      (clk_i),
    .data_i     (ps2_data),
    .valid_i    (ps2_valid),
    .event_o    (ps2_kbd_event),
    .valid_o    (ps2_kbd_valid)
);


// Keycode Translation ROM
logic           is_break_r = '0;
logic           vk_valid_r = '0;
byte_t          vk;

keycode_rom #(.CONTENTS("krom.mem")) krom (
    .clk_i         (clk_i),
    .read_enable_i (ps2_kbd_valid), // 1'b1),
    .read_addr_i   (ps2_kbd_event[8:0]),
    .read_data_o   (vk)
);

always_ff @(posedge clk_i) begin
    is_break_r  <= ps2_kbd_event.is_break;
    vk_valid_r  <= ps2_kbd_valid;
end


// Buffer
fifo #(
    .DATA_WIDTH(9),
    .ADDR_WIDTH(5)
) fifo (
    .clk_i               (clk_i),
    .write_data_i        ({ is_break_r, vk }),
    .write_enable_i      (vk_valid_r),
    .read_enable_i       (chip_select_i && read_enable_i),
    .read_data_o         (fifo_data),
    .read_valid_o        (fifo_valid),
    .fifo_empty_o        (),
    .fifo_almost_empty_o (),
    .fifo_almost_full_o  (),
    .fifo_full_o         ()
);

// interrupt
assign interrupt_o = fifo_valid;

endmodule
