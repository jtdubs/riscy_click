`timescale 1ns/1ps

///
/// Clock Divider
///

module clkdiv
    // Import Constants
    import consts::*;
    #(
        parameter DIVISOR = 10000 // Clock ratio
    )
    (
        input logic clk,
        input logic reset,
        output logic derived_clk
    );

// Counter rolls over at half the divisor so that a full cycle of the derived clock occurs at the divided frequency
localparam COUNTER_ROLLOVER = (DIVISOR / 2) - 1;

// Registers
logic [15:0] counter;

// Clocked Dividing
always_ff @(posedge clk)
begin
    if (reset)
    begin
        counter <= 0;
        derived_clk <= 0;
    end
    else if (counter == COUNTER_ROLLOVER)
    begin
        counter <= 0;
        derived_clk <= ~derived_clk;
    end
    else
    begin
        counter <= counter + 1;
        derived_clk <= derived_clk;
    end
end

endmodule