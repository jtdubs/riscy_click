`timescale 1ns / 1ps
`default_nettype none

module skid_buffer
    #(
        parameter int unsigned WORD_WIDTH = 0
    )
    (
        input  wire logic                  clk_i,
        input  wire logic                  reset_i,
    
        // write port
        output      logic                  write_ready_o,
        input  wire logic                  write_valid_i,
        input  wire logic [WORD_WIDTH-1:0] write_data_i,
    
        // read port
        input  wire logic                  read_ready_i,
        output      logic                  read_valid_o,
        output      logic [WORD_WIDTH-1:0] read_data_o
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
state_t state_r, state_w;

// which buffer operations will occur
logic insert_w, remove_w;
always_comb begin
    insert_w = write_valid_i && write_ready_o; // insert will occur if input can be accepted, and is provided
    remove_w =  read_valid_o &&  read_ready_i; // remove will occur if output can be accepted, and is provided
end

// which state transition is occuring
logic load_w, unload_w, buffer_w, unbuffer_w, run_w;
always_comb begin
    load_w     = (state_r == EMPTY)   &&  insert_w;              // inserting into an empty output register
    unload_w   = (state_r == RUNNING) && !insert_w &&  remove_w; // output register consumed; now empty
    buffer_w   = (state_r == RUNNING) &&  insert_w && !remove_w; // inserting but output register full; new data stored in buffer
    unbuffer_w = (state_r == FULL)                 &&  remove_w; // output register consumed; reload from buffer
    run_w      = (state_r == RUNNING) &&  insert_w &&  remove_w; // inserting into an just emptied output register
end

// what will the next state be
always_comb begin
    priority if (load_w || unbuffer_w)
        state_w = RUNNING;
    else if (buffer_w)
        state_w = FULL;
    else if (unload_w)
        state_w = EMPTY;
    else
        state_w = state_r;
end


//
// Register Updates
//

logic [WORD_WIDTH-1:0] data_buffer_r;

always_ff @(posedge clk_i) begin
    // advance to next state
    state_r <= state_w; 
    
    // input port ready if not full
    write_ready_o <= (state_w != FULL);
    
    // output port valid if not empty
    read_valid_o <= (state_w != EMPTY);
    
    // set output register
    // TODO: is 'unique if' appropriate here, or should I leave off the 'else' because I want to infer a flip-flop anyway
    unique if (load_w || run_w)
        read_data_o <= write_data_i;  // make input available in output register
    else if (unload_w)
        read_data_o <= WORD_ZERO;     // clear output buffer
    else if (unbuffer_w)     
        read_data_o <= data_buffer_r; // transfer buffer to output register
    else
        read_data_o <= read_data_o;  
       
    // set buffer register
    // TODO: is 'unique if' appropriate here, or should I leave off the 'else' because I want to infer a flip-flop anyway
    unique if (buffer_w)
        data_buffer_r <= write_data_i; // buffer the input
    else if (unbuffer_w)
        data_buffer_r <= WORD_ZERO;    // clear the buffer
    else
        data_buffer_r <= data_buffer_r;
    
    if (reset_i) begin
        // reset_i to EMPTY state
        state_r       <= EMPTY;
        write_ready_o <= 1'b1;
        read_valid_o  <= 1'b0;
        read_data_o   <= WORD_ZERO;
        data_buffer_r <= WORD_ZERO;
    end 
end

endmodule