`timescale 1ns / 1ps
`default_nettype none

///
/// Interrupt Controller
///

module interrupt_controller
    // Import Constants
    import common::*;
    (
        // Clocks
        input  wire logic       clk_i,

        // Interrupts
        input  wire word_t      interrupt_i,
        output wire logic       interrupt_o,

        // Bus Interface
        input  wire logic       chip_select_i,
        input  wire logic [3:0] addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,
        input  wire word_t      write_data_i,
        input  wire logic [3:0] write_mask_i
    );

typedef enum logic [3:0] {
    PORT_PENDING = 4'b0000,
    PORT_ENABLED = 4'b0001,
    PORT_ACTIVE  = 4'b0010
} port_t;

word_t pending_r = '0;
word_t enabled_r = '0;
word_t active;

always_comb begin
    active = pending_r & enabled_r;
end

always_ff @(posedge clk_i) begin
    pending_r <= interrupt_i;
end

logic  interrupt_r = '0;
assign interrupt_o = interrupt_r;
always_ff @(posedge clk_i) begin
    interrupt_r <= active != '0;
    // $strobe("[IRQ] %x", interrupt_r);
end

word_t read_data_r = '0;
assign read_data_o = read_data_r;
always_ff @(posedge clk_i) begin
    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_PENDING: read_data_r <= pending_r;
        PORT_ENABLED: read_data_r <= enabled_r;
        PORT_ACTIVE:  read_data_r <= active;
        default:      read_data_r <= 32'b0;
        endcase
    end
end

always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_ENABLED:
            begin
                if (write_mask_i[0]) enabled_r[ 7: 0] <= write_data_i[ 7: 0];
                if (write_mask_i[1]) enabled_r[15: 8] <= write_data_i[15: 8];
                if (write_mask_i[2]) enabled_r[23:16] <= write_data_i[23:16];
                if (write_mask_i[3]) enabled_r[31:24] <= write_data_i[31:24];
            end
        default: ;
        endcase
    end
end

endmodule
