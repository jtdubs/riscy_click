`timescale 1ns / 1ps
`default_nettype none

module skid_buffer
    #(
        parameter int unsigned WORD_WIDTH = 0
    )
    (
        input  wire logic                  clk,
        input  wire logic                  ic_rst,
    
        // input / producer port
        output      logic                  oc_in_ready,
        input  wire logic                  ic_in_valid,
        input  wire logic [WORD_WIDTH-1:0] ic_in_data,
    
        // output / consumer port
        input  wire logic                  ic_out_ready,
        output      logic                  oc_out_valid,
        output      logic [WORD_WIDTH-1:0] oc_out_data
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
// TODO: does it do a better job synthesizing if I leave these values out?
typedef enum logic [1:0] {
    EMPTY   = 2'b00, // buffer empty; no output available
    RUNNING = 2'b01, // buffer input and output both possible
    FULL    = 2'b10  // buffer full; no input available
} state_t;

// current and next state
state_t c_state, a_state_next;

// which buffer operations will occur
logic a_insert, a_remove;
always_comb begin
    a_insert = ic_in_valid && oc_in_ready;   // insert will occur if input can be accepted, and is provided
    a_remove = oc_out_valid && ic_out_ready; // remove will occur if output can be accepted, and is provided
end

// which state transition is occuring
logic a_load, a_unload, a_buffer, a_unbuffer, a_run;
always_comb begin
    a_load     = (c_state == EMPTY)   &&  a_insert;              // inserting into an empty output register
    a_unload   = (c_state == RUNNING) && !a_insert &&  a_remove; // output register consumed; now empty
    a_buffer   = (c_state == RUNNING) &&  a_insert && !a_remove; // inserting but output register full; new data stored in buffer
    a_unbuffer = (c_state == FULL)                 &&  a_remove; // output register consumed; reload from buffer
    a_run      = (c_state == RUNNING) &&  a_insert &&  a_remove; // inserting into an just emptied output register
end

// what will the next state be
always_comb begin
    priority if (a_load || a_unbuffer)
        a_state_next = RUNNING;
    else if (a_buffer)
        a_state_next = FULL;
    else if (a_unload)
        a_state_next = EMPTY;
    else
        a_state_next = c_state;
end


//
// Register Updates
//

logic [WORD_WIDTH-1:0] c_buffer;

always_ff @(posedge clk) begin
    // advance to next state
    c_state <= a_state_next; 
    
    // input port ready if not full
    oc_in_ready <= (a_state_next != FULL);
    
    // output port valid if not empty
    oc_out_valid <= (a_state_next != EMPTY);
    
    // set output register
    // TODO: is 'unique if' appropriate here, or should I leave off the 'else' because I want to infer a flip-flop anyway
    unique if (a_load || a_run)
        oc_out_data <= ic_in_data;  // make input available in output register
    else if (a_unload)
        oc_out_data <= WORD_ZERO;   // clear output buffer
    else if (a_unbuffer)     
        oc_out_data <= c_buffer;   // transfer buffer to output register
    else
        oc_out_data <= oc_out_data;  
       
    // set buffer register
    // TODO: is 'unique if' appropriate here, or should I leave off the 'else' because I want to infer a flip-flop anyway
    unique if (a_buffer)
        c_buffer <= ic_in_data;  // buffer the input
    else if (a_unbuffer)
        c_buffer <= WORD_ZERO;   // clear the buffer
    else
        c_buffer <= c_buffer;
    
    if (ic_rst) begin
        // reset to EMPTY state
        c_state      <= EMPTY;
        oc_in_ready  <= 1'b1;
        oc_out_valid <= 1'b0;
        oc_out_data  <= WORD_ZERO;
        c_buffer     <= WORD_ZERO;
    end 
end

endmodule