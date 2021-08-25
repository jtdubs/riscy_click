`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Write Back Stage
///

module stage_writeback
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic       clk_i,            // clock

        // data memory
        (* MARK_DEBUG="true" *) input  wire word_t      dmem_read_data_i, // memory data

        // pipeline inputs
        (* MARK_DEBUG="true" *) input  wire word_t      pc_i,             // program counter
        (* MARK_DEBUG="true" *) input  wire word_t      ir_i,             // instruction register
        (* MARK_DEBUG="true" *) input  wire logic       load_i,           // is this a load instruction?
        (* MARK_DEBUG="true" *) input  wire ma_size_t   ma_size_i,        // memory access size
        (* MARK_DEBUG="true" *) input  wire logic [1:0] ma_alignment_i,   // memory access alignment
        (* MARK_DEBUG="true" *) input  wire word_t      wb_data_i,        // write-back data
        (* MARK_DEBUG="true" *) input  wire logic       wb_valid_i,       // write-back valid

        // status outputs
        output      logic       empty_async_o,    // stage empty

        // pipline outputs
        (* MARK_DEBUG="true" *) output      regaddr_t   wb_addr_o,        // write-back address
        (* MARK_DEBUG="true" *) output      word_t      wb_data_o,        // write-back data
        (* MARK_DEBUG="true" *) output      logic       wb_valid_o        // write-back valid
    );

initial start_logging();
final stop_logging();


//
// Async Outputs
//

word_t unaligned;
word_t aligned;

always_comb begin
    unaligned = load_i ? dmem_read_data_i : wb_data_i;

    // shift data right based on address lower bits
    unique case (ma_alignment_i)
    2'b00: aligned = {        unaligned[31: 0] };
    2'b01: aligned = {  8'b0, unaligned[31: 8] };
    2'b10: aligned = { 16'b0, unaligned[31:16] };
    2'b11: aligned = { 24'b0, unaligned[31:24] };
    endcase

    empty_async_o = (pc_i == NOP_PC);
end


//
// Debug Logging
//

regaddr_t   wb_addr_r  = 5'b0;
assign      wb_addr_o  = wb_addr_r;

word_t      wb_data_r  = 32'b0;
assign      wb_data_o  = wb_data_r;

logic       wb_valid_r = 1'b0;
assign      wb_valid_o = wb_valid_r;

always_ff @(posedge clk_i) begin
    // should probably be a separate WB_SIZE value???
    unique case (ma_size_i)
    MA_SIZE_B:   wb_data_r <= { {24{aligned[ 7]}},  aligned[ 7:0] };
    MA_SIZE_H:   wb_data_r <= { {16{aligned[15]}},  aligned[15:0] };
    MA_SIZE_BU:  wb_data_r <= { 24'b0,              aligned[ 7:0] };
    MA_SIZE_HU:  wb_data_r <= { 16'b0,              aligned[15:0] };
    MA_SIZE_W:   wb_data_r <= aligned;
    endcase

    wb_addr_r  <= ir_i[11:7];
    wb_valid_r <= wb_valid_i;

    `log_strobe(("{ \"stage\": \"WB\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"wb_addr\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" }", pc_i, ir_i, wb_addr_o, wb_data_o, wb_valid_o));
end

endmodule
