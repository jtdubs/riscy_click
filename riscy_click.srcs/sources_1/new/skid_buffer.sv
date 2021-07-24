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

//
// State Transition Logic
//

typedef enum {
    EMPTY = 2'b00,
    BUSY  = 2'b01,
    FULL  = 2'b10 
} sb_state;

// current and next state
sb_state state, state_next; 

// whether or not an insert or remove will occur
logic insert, remove;
assign insert = input_valid  & input_ready;  // insert will occur if data is being provided, and can be accepted
assign remove = output_valid & output_ready; // output will occur if data is being requested, and can be provided

// which operation is occuring
logic load, flow, fill, flush, unload;
assign load    = (state == EMPTY) &  insert && ~remove; // Empty datapath inserts data into output register.
assign flow    = (state == BUSY)  &  insert &&  remove; // New inserted data into output register as the old data is removed.
assign fill    = (state == BUSY)  &  insert && ~remove; // New inserted data into buffer register. Data not removed from output register.
assign flush   = (state == FULL)  & ~insert &&  remove; // Move data from buffer register into output register. Remove old data. No new data inserted.
assign unload  = (state == BUSY)  & ~insert &   remove; // Remove data from output register, leaving the datapath empty.

// what will the next state be
always_comb begin
    if (load | flow | flush) begin
        state_next <= BUSY;
    end else if (fill) begin
        state_next <= FULL;
    end else if (unload) begin
        state_next <= EMPTY;
    end else begin
        state_next <= state;
    end
end


//
// Latched Updates
//

logic [WORD_WIDTH-1:0] data_buffer;

always_ff @(posedge clk) begin
    if (reset) begin
        // Reset to EMPTY state
        output_data  <= 'd0;
        data_buffer  <= 'd0;
        state        <= EMPTY;
        input_ready  <= 1'b1;
        output_valid <= 1'b0;
    end else begin
        state <= state_next; // Advance to next state
        
        input_ready  <= (state_next != FULL);  // Can input if not full
        output_valid <= (state_next != EMPTY); // Can output if not empty
       
        if (load | flow) begin
            output_data <= input_data;
        end else if (flush) begin     
            // Output the buffered value, and we are now "transparent"
            output_data <= data_buffer;
        end else if (fill) begin
            // Buffer the input, we are are now full
            data_buffer <= input_data;
        end
    end
end

endmodule