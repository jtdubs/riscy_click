`timescale 1ns / 1ps
`default_nettype none

module skid_buffer
    #(
        parameter int unsigned WORD_WIDTH = 0
    )
    (
        input  wire logic                  clk_i,

        // write port
        output      logic                  write_ready_o,
        input  wire logic                  write_valid_i,
        input  wire logic [WORD_WIDTH-1:0] write_data_i,

        // read port
        input  wire logic                  read_ready_i,
        output      logic                  read_valid_o,
        output      logic [WORD_WIDTH-1:0] read_data_o
    );

typedef logic [WORD_WIDTH-1:0] word_t;

localparam word_t WORD_ZERO = {WORD_WIDTH{1'b0}};

//                      |--run--|
//                      |       v
// [EMPTY]  ---load---> [RUNNING]  ---buffer---> [FULL]
// [EMPTY] <--unload--  [RUNNING] <--unbuffer--  [FULL]


// state definitions
typedef enum logic [1:0] {
    EMPTY   = 2'b00, // buffer empty; no output available
    RUNNING = 2'b01, // buffer input and output both possible
    FULL    = 2'b10  // buffer full; no input available
} state_t;

// current and next state
state_t state_r = EMPTY;
state_t state_next;

// which buffer operations will occur
logic insert;
logic remove;

always_comb begin
    insert = write_valid_i && write_ready_o; // insert will occur if input can be accepted, and is provided
    remove =  read_valid_o &&  read_ready_i; // remove will occur if output can be accepted, and is provided
end

// which state transition is occuring
logic load;
logic unload;
logic buffer;
logic unbuffer;
logic run;

always_comb begin
    load     = (state_r == EMPTY)   &&  insert;            // inserting into an empty output register
    unload   = (state_r == RUNNING) && !insert &&  remove; // output register consumed; now empty
    buffer   = (state_r == RUNNING) &&  insert && !remove; // inserting but output register full; new data stored in buffer
    unbuffer = (state_r == FULL)               &&  remove; // output register consumed; reload from buffer
    run      = (state_r == RUNNING) &&  insert &&  remove; // inserting into an just emptied output register
end

// what will the next state be
always_comb begin
    priority if (load || unbuffer)
        state_next = RUNNING;
    else if (buffer)
        state_next = FULL;
    else if (unload)
        state_next = EMPTY;
    else
        state_next = state_r;
end

// advance to next state
always_ff @(posedge clk_i) begin
    state_r <= state_next; 
end


//
// update outputs
//

word_t data_buffer_r = WORD_ZERO;

logic  write_ready_r = 1'b1;
assign write_ready_o = write_ready_r;

logic  read_valid_r  = 1'b0;
assign read_valid_o  = read_valid_r;

word_t read_data_r   = WORD_ZERO;
assign read_data_o   = read_data_r;

always_ff @(posedge clk_i) begin
    // input port ready if not full
    write_ready_r <= (state_next != FULL);

    // output port valid if not empty
    read_valid_r <= (state_next != EMPTY);

    // set output register
    if (load || run)
        read_data_r <= write_data_i;  // make input available in output register
    else if (unload)
        read_data_r <= WORD_ZERO;     // clear output buffer
    else if (unbuffer)
        read_data_r <= data_buffer_r; // transfer buffer to output register

    // set buffer register
    if (buffer)
        data_buffer_r <= write_data_i; // buffer the input
    else if (unbuffer)
        data_buffer_r <= WORD_ZERO;    // clear the buffer
end

endmodule
