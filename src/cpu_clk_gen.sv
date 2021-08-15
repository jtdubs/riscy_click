`timescale 1ns / 1ps
`default_nettype none

module cpu_clk_gen
    // Import Constants
    import common::*;
    (
        input  wire logic sys_clk_i,     // 100MHz system clock
        input  wire logic reset_async_i, // reset

        // cpu clock output
        output wire logic cpu_clk_o,     // 50MHz cpu clock
        output wire logic ready_async_o  // cpu clock ready
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//

// internal signals
wire logic clk_feedback_w;
wire logic cpu_clk_w;

// PLL Module
PLLE2_BASE #(
  .BANDWIDTH("OPTIMIZED"),
  .CLKFBOUT_MULT(16),
  .CLKFBOUT_PHASE(0.0),
  .CLKIN1_PERIOD(10.0),
  .CLKOUT0_DIVIDE(32),
  .CLKOUT1_DIVIDE(1),
  .CLKOUT2_DIVIDE(1),
  .CLKOUT3_DIVIDE(1),
  .CLKOUT4_DIVIDE(1),
  .CLKOUT5_DIVIDE(1),
  .CLKOUT0_DUTY_CYCLE(0.5),
  .CLKOUT1_DUTY_CYCLE(0.5),
  .CLKOUT2_DUTY_CYCLE(0.5),
  .CLKOUT3_DUTY_CYCLE(0.5),
  .CLKOUT4_DUTY_CYCLE(0.5),
  .CLKOUT5_DUTY_CYCLE(0.5),
  .CLKOUT0_PHASE(0.0),
  .CLKOUT1_PHASE(0.0),
  .CLKOUT2_PHASE(0.0),
  .CLKOUT3_PHASE(0.0),
  .CLKOUT4_PHASE(0.0),
  .CLKOUT5_PHASE(0.0),
  .DIVCLK_DIVIDE(1),
  .REF_JITTER1(0.0),
  .STARTUP_WAIT("TRUE")
)
cpu_clk_pll (
  .CLKOUT0(cpu_clk_w),
  .CLKOUT1(),
  .CLKOUT2(),
  .CLKOUT3(),
  .CLKOUT4(),
  .CLKOUT5(),
  .CLKFBOUT(clk_feedback_w),
  .LOCKED(ready_async_o),
  .CLKIN1(sys_clk_i),
  .PWRDWN(1'b0),
  .RST(reset_async_i),
  .CLKFBIN(clk_feedback_w)
);

// Global Clock Buffer
BUFGCTRL #(
  .INIT_OUT(0),            // Initial value of BUFGCTRL output ($VALUES;)
  .PRESELECT_I0("TRUE"),   // BUFGCTRL output uses I0 input ($VALUES;)
  .PRESELECT_I1("FALSE"),  // BUFGCTRL output uses I1 input ($VALUES;)
  .SIM_DEVICE("7SERIES")
)
cpu_clk_buffer (
  .O(cpu_clk_o),       // 1-bit output: Clock output
  .CE0(ready_async_o), // 1-bit input: Clock enable input for I0
  .CE1(1'b0),          // 1-bit input: Clock enable input for I1
  .I0(cpu_clk_w),      // 1-bit input: Primary clock
  .I1(1'b0),           // 1-bit input: Secondary clock
  .IGNORE0(1'b0),      // 1-bit input: Clock ignore input for I0
  .IGNORE1(1'b1),      // 1-bit input: Clock ignore input for I1
  .S0(1'b1),           // 1-bit input: Clock select for I0
  .S1(1'b0)            // 1-bit input: Clock select for I1
);

`else

//
// Simulator Implementation
//

logic [1:0] counter_r = '0;

assign ready_async_o = 1'b1;
assign cpu_clk_o     = counter_r[0];

always_ff @(posedge sys_clk_i) begin
    counter_r <= counter_r + 1;

    if (reset_async_i) begin
        counter_r <= 2'b00;
    end
end

`endif

endmodule
