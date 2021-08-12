`timescale 1ns / 1ps
`default_nettype none

module pixel_clk_gen
    // Import Constants
    import common::*;
    (
        input  wire logic sys_clk_i,     // 100MHz system clock
        input  wire logic reset_async_i, // reset

        // cpu clock output
        output      logic pxl_clk_o,     // 25.2MHz VGA pixel clock
        output      logic ready_async_o  // cpu clock ready
    );

`ifdef ENABLE_XILINX_PRIMITIVES

//
// Synthesizable Implementation
//

// internal signals
wire logic clk_feedback_w;
wire logic pxl_clk_w;

MMCME2_BASE #(
  .BANDWIDTH("OPTIMIZED"),
  .CLKFBOUT_MULT_F(31.5),
  .CLKFBOUT_PHASE(0.0),
  .CLKIN1_PERIOD(10),
  .CLKOUT1_DIVIDE(1),
  .CLKOUT2_DIVIDE(1),
  .CLKOUT3_DIVIDE(1),
  .CLKOUT4_DIVIDE(1),
  .CLKOUT5_DIVIDE(1),
  .CLKOUT6_DIVIDE(1),
  .CLKOUT0_DIVIDE_F(25),
  .CLKOUT0_DUTY_CYCLE(0.5),
  .CLKOUT1_DUTY_CYCLE(0.5),
  .CLKOUT2_DUTY_CYCLE(0.5),
  .CLKOUT3_DUTY_CYCLE(0.5),
  .CLKOUT4_DUTY_CYCLE(0.5),
  .CLKOUT5_DUTY_CYCLE(0.5),
  .CLKOUT6_DUTY_CYCLE(0.5),
  .CLKOUT0_PHASE(0.0),
  .CLKOUT1_PHASE(0.0),
  .CLKOUT2_PHASE(0.0),
  .CLKOUT3_PHASE(0.0),
  .CLKOUT4_PHASE(0.0),
  .CLKOUT5_PHASE(0.0),
  .CLKOUT6_PHASE(0.0),
  .CLKOUT4_CASCADE("FALSE"),
  .DIVCLK_DIVIDE(5),
  .REF_JITTER1(0.0),
  .STARTUP_WAIT("TRUE")
)
pixel_clk_mmcm (
  .CLKOUT0(pxl_clk_w),
  .CLKOUT0B(),
  .CLKOUT1(),
  .CLKOUT1B(),
  .CLKOUT2(),
  .CLKOUT2B(),
  .CLKOUT3(),
  .CLKOUT3B(),
  .CLKOUT4(),
  .CLKOUT5(),
  .CLKOUT6(),
  .CLKFBOUT(clk_feedback_w),
  .CLKFBOUTB(),
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
pixel_clk_buffer (
  .O(pxl_clk_o),       // 1-bit output: Clock output
  .CE0(ready_async_o), // 1-bit input: Clock enable input for I0
  .CE1(1'b0),          // 1-bit input: Clock enable input for I1
  .I0(pxl_clk_w),      // 1-bit input: Primary clock
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

logic [1:0] counter_r = 2'b00;

always_comb begin
    ready_async_o = 1'b1;
    pxl_clk_o = counter_r[1];
end

always_ff @(posedge sys_clk_i) begin
    counter_r <= counter_r + 1;

    if (reset_async_i) begin
        counter_r <= 2'b00;
    end
end

`endif

endmodule
