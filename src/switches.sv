`timescale 1ns / 1ps
`default_nettype none

///
/// Hardware Switches
///

module switches
    // Import Constants
    import common::*;
    (
        // Clocks
        input  wire logic        clk_i,
        output wire logic        interrupt_o,

        // Switches
        input  wire logic [15:0] switch_i,

        // Bus Interface
        input  wire logic        chip_select_i,
        input  wire logic [3:0]  addr_i,
        input  wire logic        read_enable_i,
        output wire word_t       read_data_o,
        input  wire word_t       write_data_i,
        input  wire logic [3:0]  write_mask_i
    );

typedef enum logic [3:0] {
    PORT_SWITCHES = 4'b0000
} port_t;

logic [15:0] state_r [1:0] = '{ '0, '0 };

always_ff @(posedge clk_i) begin
    state_r <= '{ switch_i, state_r[1] };
end

word_t read_data_w = '0;
assign read_data_o = read_data_w;

logic  interrupt_r = '0;
assign interrupt_o = interrupt_r;

always_ff @(posedge clk_i) begin
    if (state_r[0] != state_r[1])
        interrupt_r <= '1;

    if (chip_select_i && read_enable_i) begin
        case (addr_i)
        PORT_SWITCHES:
            begin
                read_data_w <= { 16'b0, state_r[0] };
                interrupt_r <= '0;
            end
        default:
            begin
                read_data_w <= 32'b0;
            end
        endcase
    end
end

always_ff @(posedge clk_i) begin
    if (chip_select_i) begin
        case (addr_i)
        PORT_SWITCHES:
            begin
            end
        default: ;
        endcase
    end
end

endmodule
