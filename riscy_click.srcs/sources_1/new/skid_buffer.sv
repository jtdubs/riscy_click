`timescale 1ns / 1ps
`default_nettype none

module skid_buffer
    #(
        parameter int unsigned WORD_WIDTH = 0
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
    
localparam logic [WORD_WIDTH-1:0] WORD_ZERO = {WORD_WIDTH{1'b0}};

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
always_comb begin
    insert = input_valid  && input_ready;  // insert will occur if data is being provided, and can be accepted
    remove = output_valid && output_ready; // output will occur if data is being requested, and can be provided
end

// which state transition is occuring
logic load, unload, buffer, unbuffer, run;
always_comb begin
    load     = (state == EMPTY)   &&  insert;            // inserting into an empty output register
    unload   = (state == RUNNING) && !insert &&  remove; // output register consumed; now empty
    buffer   = (state == RUNNING) &&  insert && !remove; // inserting but output register full; new data stored in buffer
    unbuffer = (state == FULL)               &&  remove; // output register consumed; reload from buffer
    run      = (state == RUNNING) &&  insert &&  remove; // inserting into an just emptied output register
end

// what will the next state be
always_comb begin
    priority if (load || unbuffer)
        next_state = RUNNING;
    else if (buffer)
        next_state = FULL;
    else if (unload)
        next_state = EMPTY;
    else
        next_state = state;
end


//
// Register Updates
//

logic [WORD_WIDTH-1:0] data_buffer;

always_ff @(posedge clk) begin
    // advance to next state
    state <= next_state; 
    
    // can input if not full
    input_ready  <= (next_state != FULL);
    
    // can output if not empty
    output_valid <= (next_state != EMPTY);
    
    // set output register
    unique if (load || run)
        output_data <= input_data;  // make input available in output register
    else if (unload)
        output_data <= 'd0;         // clear output buffer
    else if (unbuffer)     
        output_data <= data_buffer; // transfer buffer to output register
    else
        output_data <= output_data;  
       
    // set buffer register
    unique if (buffer)
        data_buffer <= input_data;  // buffer the input
    else if (unbuffer)
        data_buffer <= 'd0;         // clear the buffer
    else
        data_buffer <= data_buffer;
    
    if (reset) begin
        // reset to EMPTY state
        state        <= EMPTY;
        input_ready  <= 1'b1;
        output_valid <= 1'b0;
        output_data  <= WORD_ZERO;
        data_buffer  <= WORD_ZERO;
    end 
end

endmodule