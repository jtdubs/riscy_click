`timescale 1ns / 1ps

module skid_buffer
    #(
        parameter WORD_WIDTH = 0
    )
    (
        input  wire logic                  clk,
        input  wire logic                  reset,
    
        input  wire logic                  input_valid,
        output      logic                  input_ready,
        input  wire logic [WORD_WIDTH-1:0] input_data,
    
        output      logic                  output_valid,
        input  wire logic                  output_ready,
        output      logic [WORD_WIDTH-1:0] output_data
    );

localparam WORD_ZERO = {WORD_WIDTH{1'b0}};

//
// Buffer Register
//

logic                  data_buffer_wren;
logic [WORD_WIDTH-1:0] data_buffer;

always_ff @(posedge clk) begin
    if (reset) begin
        data_buffer <= WORD_ZERO;
    end else if (data_buffer_wren) begin
        data_buffer <= input_data;
    end
end

//
// Output Register
//

logic data_out_wren;
logic use_buffered_data;

always_ff @(posedge clk) begin
    if (reset) begin
        output_data <= WORD_ZERO;
    end else if (data_out_wren) begin
        output_data <= (use_buffered_data == 1'b1) ? data_buffer : input_data;
    end
end


//
// FSM
//

typedef enum {
    EMPTY = 2'b00,
    BUSY  = 2'b01,
    FULL  = 2'b10
} sb_state;

sb_state state, state_next; 

// Can input as long as state isn't going to be FULL
always_ff @(posedge clk) begin
    if (reset) begin
        input_ready <= 1'b1;
    end else begin
        input_ready <= (state_next != FULL);
    end
end 

// Can output as long as state isn't going to be EMPTY
always_ff @(posedge clk) begin
    if (reset) begin
        output_valid <= 1'b0;
    end else begin
        output_valid <= (state_next != EMPTY);
    end
end

logic insert, remove;
assign insert = (input_valid  == 1'b1) && (input_ready  == 1'b1);
assign remove = (output_valid == 1'b1) && (output_ready == 1'b1);

logic load, flow, fill, flush, unload;
assign load    = (state == EMPTY) && (insert == 1'b1) && (remove == 1'b0); // Empty datapath inserts data into output register.
assign flow    = (state == BUSY)  && (insert == 1'b1) && (remove == 1'b1); // New inserted data into output register as the old data is removed.
assign fill    = (state == BUSY)  && (insert == 1'b1) && (remove == 1'b0); // New inserted data into buffer register. Data not removed from output register.
assign flush   = (state == FULL)  && (insert == 1'b0) && (remove == 1'b1); // Move data from buffer register into output register. Remove old data. No new data inserted.
assign unload  = (state == BUSY)  && (insert == 1'b0) && (remove == 1'b1); // Remove data from output register, leaving the datapath empty.

always_comb begin
    state_next = (load   == 1'b1) ? BUSY  : state;
    state_next = (flow   == 1'b1) ? BUSY  : state_next;
    state_next = (fill   == 1'b1) ? FULL  : state_next;
    state_next = (flush  == 1'b1) ? BUSY  : state_next;
    state_next = (unload == 1'b1) ? EMPTY : state_next;
end

always_ff @(posedge clk) begin
    if (reset) begin
        state <= EMPTY;
    end else begin
        state <= state_next;
    end
end

assign data_out_wren     = load | flow | flush;
assign data_buffer_wren  = fill;
assign use_buffered_data = flush;

endmodule