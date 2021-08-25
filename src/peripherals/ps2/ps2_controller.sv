`timescale 1ns / 1ps
`default_nettype none

///
/// PS/2 Controller
///

module ps2_controller
    // Import Constants
    import common::*;
    (
        input  wire logic clk_i,

        // PS2 Bus
        (* PULLUP = "true" *) inout  tri  logic ps2_clk_io,
        (* PULLUP = "true" *) inout  tri  logic ps2_data_io,
        
        // Debug
        output wire logic [15:0] debug_o
    );

typedef enum logic {
    IO_OUTPUT = 1'b0,
    IO_INPUT  = 1'b1
} io_dir_t;

io_dir_t clk_dir_r = IO_INPUT;
io_dir_t data_dir_r = IO_INPUT;

logic tx_clk_r = '0;
logic tx_data_r = '0;

wire logic ps2_clk_i;
wire logic ps2_data_i;
wire logic ps2_clk_o;
wire logic ps2_data_o;

assign ps2_clk_o = '0;
assign ps2_data_o = '0;

IOBUF #(
  .DRIVE(12), // Specify the output drive strength
  .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
  .IOSTANDARD("DEFAULT"), // Specify the I/O standard
  .SLEW("SLOW") // Specify the output slew rate
) clk_buf (
  .O(ps2_clk_i),        // Buffer output
  .IO(ps2_clk_io), // Buffer inout port (connect directly to top-level port)
  .I(tx_clk_r),     // Buffer input
  .T(clk_dir_r)      // 3-state enable input, high=input, low=output
);

IOBUF #(
  .DRIVE(12), // Specify the output drive strength
  .IBUF_LOW_PWR("TRUE"),  // Low Power - "TRUE", High Performance = "FALSE" 
  .IOSTANDARD("DEFAULT"), // Specify the I/O standard
  .SLEW("SLOW") // Specify the output slew rate
) data_buf (
  .O(ps2_data_i),        // Buffer output
  .IO(ps2_data_io), // Buffer inout port (connect directly to top-level port)
  .I(tx_data_r),     // Buffer input
  .T(data_dir_r)      // 3-state enable input, high=input, low=output
);

logic [7:0] clk_r = '0;
logic [1:0] clk_debounced_r = '0;

always_ff @(posedge clk_i) begin
    clk_r <= { ps2_clk_i, clk_r[7:1] };
    if (clk_r == 8'b11111111)
        clk_debounced_r <= { 1'b1, clk_debounced_r[1] };
    else if (clk_r == 8'b00000000)
        clk_debounced_r <= { 1'b0, clk_debounced_r[1] };
end

logic falling_edge;
always_comb falling_edge = !clk_debounced_r[1] && clk_debounced_r[0];

logic [10:0] rx_data_r = 11'b11111111111;

logic start_good;
logic stop_good;
logic even_parity;
logic parity_good;
logic packet_good;
always_comb begin
    start_good = !rx_data_r[0];
    stop_good  =  rx_data_r[10];
    
    even_parity =
        rx_data_r[1] ^
        rx_data_r[2] ^
        rx_data_r[3] ^
        rx_data_r[4] ^
        rx_data_r[5] ^
        rx_data_r[6] ^
        rx_data_r[7] ^
        rx_data_r[8];
        
    parity_good = rx_data_r[9] != even_parity;
    packet_good = start_good && stop_good & parity_good;
end

always_ff @(posedge clk_i) begin
    if (falling_edge)
        rx_data_r <= { ps2_data_i, rx_data_r[10:1] };
    else if (watchdog_r == '0 || packet_good)
        rx_data_r <= 11'b11111111111;
end


localparam int WATCHDOG_VALUE = 16'd20000;
logic [15:0] watchdog_r = WATCHDOG_VALUE;

always_ff @(posedge clk_i) begin
    if (falling_edge || tx_hold_start)
        watchdog_r <= WATCHDOG_VALUE;
    else if (watchdog_r != 0)
        watchdog_r <= watchdog_r - 1;
    else
        watchdog_r <= WATCHDOG_VALUE;
end

typedef enum logic [2:0] {
    RX      = 3'b001,
    TX_HOLD = 3'b010,
    TX      = 3'b100
} state_t;

logic [12:0] tx_buffer_r = 12'b0;
logic tx_buffer_empty;
always_comb tx_buffer_empty = (tx_buffer_r == 12'b0);

state_t state_r = RX;
state_t state_next;

logic rx_idle;
logic tx_hold_start;
logic tx_hold;
logic tx_start;
logic tx_bit;
logic tx_complete;

always_comb begin
    rx_idle       = (state_r == RX) &&  tx_buffer_empty;
    tx_hold_start = (state_r == RX) && !tx_buffer_empty;
    tx_hold       = (state_r == TX_HOLD) && watchdog_r != 12'b0;
    tx_start      = (state_r == TX_HOLD) && watchdog_r == 12'b0;
    tx_bit        = (state_r == TX) && !tx_buffer_empty;
    tx_complete   = (state_r == TX) &&  tx_buffer_empty;
end

always_comb begin
    if (rx_idle || tx_complete)
        state_next = RX;
    else if (tx_hold_start || tx_hold)
        state_next = TX_HOLD;
    else if (tx_start || tx_bit)
        state_next = TX;
    else
        state_next = state_r;
end

always_ff @(posedge clk_i) begin
    state_r <= state_next;
end

always_ff @(posedge clk_i) begin
    if (tx_hold_start) begin
        clk_dir_r <= IO_OUTPUT;
    end else if (tx_start) begin
        data_dir_r <= IO_OUTPUT;
        tx_data_r <= tx_buffer_r[0];
        clk_dir_r <= IO_INPUT;
    end else if (tx_bit) begin
        tx_data_r <= tx_buffer_r[0];
    end else if (tx_complete) begin
        data_dir_r <= IO_INPUT;
    end
end

always_ff @(posedge clk_i) begin
    if (tx_bit && falling_edge)
        tx_buffer_r <= { 1'b0, tx_buffer_r[12:1] };
    else if (rx_idle && packet_good && rx_data_r[8:1] == 8'hAA)
        tx_buffer_r <= 11'b111110110101; // ED - set/reset status indicators
    else if (rx_idle && packet_good && rx_data_r[8:1] == 8'hFA)
        tx_buffer_r <= 11'b101111010001; // F4 - enable
end

logic [15:0] debug_r;
assign debug_o = debug_r;
always_ff @(posedge clk_i) begin
    if (rx_idle && packet_good)
        debug_r <= { 4'b0, rx_data_r };
end



//Keyboard: AA  Self-test passed                ;Keyboard controller init 
//Host:     ED  Set/Reset Status Indicators  
//Keyboard: FA  Acknowledge 
//Host:     00  Turn off all LEDs 
//Keyboard: FA  Acknowledge 
//Host:     F2  Read ID 
//Keyboard: FA  Acknowledge 
//Keyboard: AB  First byte of ID 
//Host:     ED  Set/Reset Status Indicators     ;BIOS init 
//Keyboard: FA  Acknowledge 
//Host:     02  Turn on Num Lock LED 
//Keyboard: FA  Acknowledge 
//Host:     F3  Set Typematic Rate/Delay        ;Windows init 
//Keyboard: FA  Acknowledge 
//Host:     20  500 ms / 30.0 reports/sec 
//Keyboard: FA  Acknowledge 
//Host:     F4  Enable 
//Keyboard: FA  Acknowledge 
//Host:     F3  Set Typematic Rate/delay 
//Keyboard: FA  Acknowledge 
//Host:     00  250 ms / 30.0 reports/sec
//Keyboard: FA  Acknowledge

endmodule
