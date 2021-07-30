`timescale 1ns / 1ps
`default_nettype none

module cpu_clk_gen
    // Import Constants
    import common::*;
    (
        input  wire logic clk_sys, // 100MHz system clock
        input  wire logic ia_rst,  // reset
        
        // cpu clock output
        output wire logic clk_cpu, // 50MHz cpu clock
        output wire logic oa_ready // cpu clock ready
    );

// internal signals
wire logic l_clk_feedback;
wire logic l_clk_cpu;

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
  .CLKOUT0(l_clk_cpu),
  .CLKOUT1(),
  .CLKOUT2(),
  .CLKOUT3(),
  .CLKOUT4(),
  .CLKOUT5(),
  .CLKFBOUT(l_clk_feedback),
  .LOCKED(oa_ready),
  .CLKIN1(clk_sys),
  .PWRDWN(1'b0),
  .RST(ia_rst),
  .CLKFBIN(l_clk_feedback)
);

// Global Clock Buffer
BUFGCE cpu_clk_buffer (
  .O(clk_cpu),
  .CE(oa_ready),
  .I(l_clk_cpu)
);

endmodule
