`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Issue Stage
///

module stage_issue
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic           clk_i,

        // decode channel
        input  wire word_t          decode_pc_i,
        input  wire word_t          decode_ir_i,
        input  wire control_word_t  decode_cw_i,
        input  wire word_t          decode_ra_i,
        input  wire word_t          decode_rb_i,
        input  wire logic           decode_valid_i,
        output wire logic           decode_ready_o,

        // bypass channel
        input  wire regaddr_t [3:0] wb_addr_i,
        input  wire word_t    [3:0] wb_data_i,
        input  wire logic     [3:0] wb_valid_i,
        input  wire logic     [3:0] wb_ready_i,

        // pipeline output
        output wire control_word_t  issue_cw_o,
        output wire word_t          issue_ra_o,
        output wire word_t          issue_rb_o,
        output wire logic           issue_valid_o,
        input  wire logic           issue_ready_i
    );

initial start_logging();
final stop_logging();


//
// Bypass Logic
//

word_t bypass_ra;
word_t bypass_rb;
logic  bypass_ra_valid;
logic  bypass_rb_valid;
logic  next_ready;
regaddr_t rs1;
regaddr_t rs2;

always_comb begin
    rs1 = ir[19:15];
    rs2 = ir[24:20];
    
    bypass_ra = ra;
    bypass_ra = (wb_valid_i[3] && wb_addr_i[3] == rs1) ? wb_data_i[3] : bypass_ra;
    bypass_ra = (wb_valid_i[2] && wb_addr_i[2] == rs1) ? wb_data_i[2] : bypass_ra;
    bypass_ra = (wb_valid_i[1] && wb_addr_i[1] == rs1) ? wb_data_i[1] : bypass_ra;
    bypass_ra = (wb_valid_i[0] && wb_addr_i[0] == rs1) ? wb_data_i[0] : bypass_ra;

    bypass_ra_valid = '1;
    bypass_ra_valid = (wb_valid_i[3] && wb_addr_i[3] == rs1) ? wb_ready_i[3] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[2] && wb_addr_i[2] == rs1) ? wb_ready_i[2] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[1] && wb_addr_i[1] == rs1) ? wb_ready_i[1] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[0] && wb_addr_i[0] == rs1) ? wb_ready_i[0] : bypass_ra_valid;

    bypass_rb = rb;
    bypass_rb = (wb_valid_i[3] && wb_addr_i[3] == rs2) ? wb_data_i[3] : bypass_rb;
    bypass_rb = (wb_valid_i[2] && wb_addr_i[2] == rs2) ? wb_data_i[2] : bypass_rb;
    bypass_rb = (wb_valid_i[1] && wb_addr_i[1] == rs2) ? wb_data_i[1] : bypass_rb;
    bypass_rb = (wb_valid_i[0] && wb_addr_i[0] == rs2) ? wb_data_i[0] : bypass_rb;

    bypass_rb_valid = '1;
    bypass_rb_valid = (wb_valid_i[3] && wb_addr_i[3] == rs2) ? wb_ready_i[3] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[2] && wb_addr_i[2] == rs2) ? wb_ready_i[2] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[1] && wb_addr_i[1] == rs2) ? wb_ready_i[1] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[0] && wb_addr_i[0] == rs2) ? wb_ready_i[0] : bypass_rb_valid;

    next_ready =
           (decode_occurs || skid_valid_r)
        && (!cw.ra_used || bypass_ra_valid)
        && (!cw.rb_used || bypass_rb_valid);
end


//
// Decode Input
//

logic decode_occurs;
logic decode_ready;

logic decode_ready_r = '1;

always_ff @(posedge clk_i) begin
    if (decode_occurs)
        decode_ready_r <= '0;

    if (decode_ready)
        decode_ready_r <= '1;
end

always_comb begin
    decode_occurs = decode_valid_i && decode_ready_o;
end

assign decode_ready_o = decode_ready_r;


//
// Issue Output
//

logic issue_unload;
logic issue_load;

word_t         pc;
word_t         ir;
control_word_t cw;
word_t         ra;
word_t         rb;

control_word_t issue_cw_r;
word_t         issue_ra_r       = '0;
word_t         issue_rb_r       = '0;
logic          issue_valid_r    = '0;

always_ff @(posedge clk_i) begin
    if (issue_unload)
        issue_valid_r <= '0;

    if (issue_load) begin
        issue_cw_r       <= cw;
        issue_ra_r       <= bypass_ra;
        issue_rb_r       <= bypass_rb;
        issue_valid_r    <= '1;
    end
end

always_comb begin
    issue_unload = issue_valid_o && issue_ready_i;
end

assign issue_cw_o       = issue_cw_r;
assign issue_ra_o       = issue_ra_r;
assign issue_rb_o       = issue_rb_r;
assign issue_valid_o    = issue_valid_r;


//
// Skid Buffer
//

logic skid_load;
logic skid_unload;

word_t         skid_pc_r    = '0;
word_t         skid_ir_r    = '0;
control_word_t skid_cw_r    = '0;
word_t         skid_ra_r    = '0;
word_t         skid_rb_r    = '0;
logic          skid_valid_r = '0;

always_ff @(posedge clk_i) begin
    if (skid_unload)
        skid_valid_r <= '0;

    if (skid_load) begin
        skid_pc_r    <= decode_pc_i;
        skid_ir_r    <= decode_ir_i;
        skid_cw_r    <= decode_cw_i;
        skid_ra_r    <= decode_ra_i;
        skid_rb_r    <= decode_rb_i;
        skid_valid_r <= '1;
    end
end


//
// Logic
//

logic issue_full;

always_comb begin
    // calculations
    issue_full = issue_valid_r && !issue_ready_i;

    // prefer skid
    if (skid_valid_r) begin
        pc = skid_pc_r;
        ir = skid_ir_r;
        cw = skid_cw_r;
        ra = skid_ra_r;
        rb = skid_rb_r;
    end else begin
        pc = decode_pc_i;
        ir = decode_ir_i;
        cw = decode_cw_i;
        ra = decode_ra_i;
        rb = decode_rb_i;
    end

    // choose actions
    issue_load = !issue_full && next_ready;
    skid_load   = decode_occurs && issue_full;
    skid_unload = !issue_full && next_ready && skid_valid_r;
    decode_ready =
          (!skid_valid_r && !skid_load)
       || (skid_valid_r && skid_unload && !skid_load);
end

endmodule
