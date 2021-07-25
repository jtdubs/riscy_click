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
// Finite State Machine
//

//                      |--run--|
//                      |       v
// [EMPTY]  ---load---> [RUNNING]  ---buffer---> [FULL]
// [EMPTY] <--unload--  [RUNNING] <--unbuffer--  [FULL]
   

// state definitions
typedef enum logic [1:0] {
    EMPTY   = 2'b00, // buffer empty; no output available
    RUNNING = 2'b01, // buffer input and output both possible
    FULL    = 2'b10  // buffer full; no input available
} sb_state;

// current and next state
sb_state state, next_state; 

// which buffer operations are requested
logic insert, remove;
assign insert = input_valid  & input_ready;  // insert will occur if data is being provided, and can be accepted
assign remove = output_valid & output_ready; // output will occur if data is being requested, and can be provided

// which state transition is occuring
logic load, unload, buffer, unbuffer, run;
assign load     = (state == EMPTY)   &  insert;           // inserting into an empty output register
assign unload   = (state == RUNNING) & ~insert &  remove; // output register consumed; now empty
assign buffer   = (state == RUNNING) &  insert & ~remove; // inserting but output register full; new data stored in buffer
assign unbuffer = (state == FULL)              &  remove; // output register consumed; reload from buffer
assign run      = (state == RUNNING) &  insert &  remove; // inserting into an just emptied output register

// what will the next state be
always_comb begin
    if (load | unbuffer) begin
        next_state <= RUNNING;
    end else if (buffer) begin
        next_state <= FULL;
    end else if (unload) begin
        next_state <= EMPTY;
    end else begin
        next_state <= state;
    end
end


//
// Latched Updates
//

logic [WORD_WIDTH-1:0] data_buffer;

always_ff @(posedge clk) begin
    if (reset) begin
        // reset to EMPTY state
        state             <= EMPTY;
        input_ready       <= 1'b1;
        output_valid      <= 1'b0;
        output_data       <= 'd0;
        data_buffer       <= 'd0;
    end else begin
        state <= next_state; // advance to next state
        
        input_ready  <= (next_state != FULL);  // can input if not full
        output_valid <= (next_state != EMPTY); // can output if not empty
        
        if (load | run) begin
            // make input available in output register
            output_data <= input_data;
        end else if (unload) begin
            // clear output buffer
            output_data <= 'd0;
        end else if (buffer) begin
            // buffer the input, because output register is already full
            data_buffer <= input_data;
        end else if (unbuffer) begin     
            // transfer buffer to output register
            output_data <= data_buffer;
            data_buffer <= 'd0;
        end 
    end
end

endmodule