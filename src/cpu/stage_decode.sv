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

decoder decoder (
    .ir_i       (fetch_ir_i),
    .cw_async_o (cw)
);


//
// Register File
//

regaddr_t rs1;
regaddr_t rs2;

always_comb begin
    rs1 = fetch_ir_i[19:15];
    rs2 = fetch_ir_i[24:20];
end

register_file register_file (
    .clk_i           (clk_i),
    .ra_addr_i       (rs1),
    .ra_data_async_o (ra),
    .rb_addr_i       (rs2),
    .rb_data_async_o (rb),
    .wr_enable_i     (1'b1),
    .wr_addr_i       (regaddr_t'(fetch_ir_i[5:1])),
    .wr_data_i       (fetch_ir_i)
);


//
// Bypass Buffer
//

word_t         pc;
word_t         ir;
control_word_t cw;
word_t         ra;
word_t         rb;

bypass_buffer #(
    .WIDTH       (152)
) bypass_buffer (
    .clk_i       (clk_i),
    .wr_data_i   ({ fetch_pc_i, fetch_ir_i, cw, ra, rb }),
    .wr_valid_i  (fetch_valid_i),
    .wr_ready_o  (fetch_ready_o),
    .rd_data_o   ({ decode_pc_o, decode_ir_o, decode_cw_o, decode_ra_o, decode_rb_o }),
    .rd_valid_o  (decode_valid_o),
    .rd_ready_i  (decode_ready_i)
);

endmodule
