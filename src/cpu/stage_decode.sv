`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decode Stage
///

module stage_decode
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic          clk_i,

        // fetch channel
        input  wire word_t         fetch_pc_i,
        input  wire word_t         fetch_ir_i,
        input  wire word_t         fetch_pc_next_i,
        input  wire logic          fetch_valid_i,
        output wire logic          fetch_ready_o,

        // pipeline output
        output wire word_t         decode_pc_o,
        output wire word_t         decode_ir_o,
        output wire control_word_t decode_cw_o,
        output wire logic          decode_valid_o,
        input  wire logic          decode_ready_i
    );

initial start_logging();
final stop_logging();


//
// Decoding
//

word_t         ir;
control_word_t cw;

decoder decoder (
    .ir_i       (ir),
    .cw_async_o (cw)
);


//
// Fetch Input
//

logic fetch_occurs;
logic fetch_ready;

logic fetch_ready_r = '1;

always_ff @(posedge clk_i) begin
    if (fetch_occurs)
        fetch_ready_r <= '0;

    if (fetch_ready)
        fetch_ready_r <= '1;
end

always_comb begin
    fetch_occurs = fetch_valid_i && fetch_ready_o;
end

assign fetch_ready_o = fetch_ready_r;


//
// Decode Output
//

logic decode_occurs;
logic decode_provide;

word_t pc;

word_t         decode_pc_r    = '0;
word_t         decode_ir_r    = '0;
control_word_t decode_cw_r;
logic          decode_valid_r = '0;

always_ff @(posedge clk_i) begin
    if (decode_occurs)
        decode_valid_r <= '0;

    if (decode_provide) begin
        decode_pc_r      <= pc;
        decode_ir_r      <= ir;
        decode_cw_r      <= cw;
        decode_valid_r   <= '1;
    end
end

always_comb begin
    decode_occurs = decode_valid_o && decode_ready_i;
end

assign decode_pc_o    = decode_pc_r;
assign decode_ir_o    = decode_ir_r;
assign decode_cw_o    = decode_cw_r;
assign decode_valid_o = decode_valid_r;


//
// Skid Buffer
//

logic skid_load;
logic skid_unload;

word_t skid_pc_r    = '0;
word_t skid_ir_r    = '0;
logic  skid_valid_r = '0;

always_ff @(posedge clk_i) begin
    if (skid_unload)
        skid_valid_r <= '0;

    if (skid_load) begin
        skid_pc_r    <= fetch_pc_i;
        skid_ir_r    <= fetch_ir_i;
        skid_valid_r <= '1;
    end
end


//
// Logic
//

logic decode_full;

always_comb begin
    // calculations
    decode_full = decode_valid_r && !decode_ready_i;

    // prefer skid
    if (skid_valid_r) begin
        pc = skid_pc_r;
        ir = skid_ir_r;
    end else begin
        pc = fetch_pc_i;
        ir = fetch_ir_i;
    end

    // choose actions
    decode_provide = (skid_valid_r || fetch_occurs) && !decode_full;
    skid_load      = fetch_occurs && (skid_valid_r || decode_full);
    skid_unload    = skid_valid_r && !decode_full;
    fetch_ready    =
           (!decode_full  && !skid_valid_r)
        || (!decode_full  && !fetch_occurs)
        || (!skid_valid_r && !fetch_occurs);
end

endmodule
