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
        output wire word_t         decode_ra_o,
        output wire word_t         decode_rb_o,
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
// Register File
//

regaddr_t rs1;
regaddr_t rs2;
word_t    ra;
word_t    rb;

always_comb begin
    rs1 = ir[19:15];
    rs2 = ir[24:20];
end

register_file register_file (
    .clk_i           (clk_i),
    .ra_addr_i       (rs1),
    .ra_data_async_o (ra),
    .rb_addr_i       (rs2),
    .rb_data_async_o (rb),
    .wr_enable_i     (1'b1),
    .wr_addr_i       (regaddr_t'(ir[5:1])),
    .wr_data_i       (ir)
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

logic decode_unload;
logic decode_load;

word_t pc;

word_t         decode_pc_r       = '0;
word_t         decode_ir_r       = '0;
control_word_t decode_cw_r;
word_t         decode_ra_r       = '0;
word_t         decode_rb_r       = '0;
logic          decode_valid_r    = '0;

always_ff @(posedge clk_i) begin
    if (decode_unload)
        decode_valid_r <= '0;

    if (decode_load) begin
        decode_pc_r       <= pc;
        decode_ir_r       <= ir;
        decode_cw_r       <= cw;
        decode_ra_r       <= ra;
        decode_rb_r       <= rb;
        decode_valid_r    <= '1;
    end
end

always_comb begin
    decode_unload = decode_valid_o && decode_ready_i;
end

assign decode_pc_o       = decode_pc_r;
assign decode_ir_o       = decode_ir_r;
assign decode_cw_o       = decode_cw_r;
assign decode_ra_o       = decode_ra_r;
assign decode_rb_o       = decode_rb_r;
assign decode_valid_o    = decode_valid_r;


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
    decode_load = !decode_full && (skid_valid_r || fetch_occurs);
    skid_load   = fetch_occurs && (decode_full || skid_valid_r);
    skid_unload = !decode_full && skid_valid_r;
    fetch_ready = !skid_load && (!skid_valid_r || skid_unload);
end

endmodule
