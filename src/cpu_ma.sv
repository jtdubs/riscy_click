`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Memory Access Stage
///

module cpu_ma
    // Import Constants
    import common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic       clk_i,             // clock
        input  wire logic       reset_i,           // reset_i

        // data memory
        output      word_t      dmem_addr_o,       // address
        output      word_t      dmem_write_data_o, // write data
        output      logic [3:0] dmem_write_mask_o, // write enable

        // pipeline input
        input  wire word_t      pc_i,              // program counter
        input  wire word_t      ir_i,              // instruction register
        input  wire word_t      ma_addr_i,         // memoricy access address
        input  wire ma_mode_t   ma_mode_i,         // memory access mode
        input  wire ma_size_t   ma_size_i,         // memory access size
        input  wire word_t      ma_data_i,         // memory access data
        input  wire wb_src_t    wb_src_i,          // write-back source
        input  wire word_t      wb_data_i,         // write-back data
        input  wire logic       wb_valid_i,        // write-back valid

        // async output
        output      regaddr_t   wb_addr_async_o,   // write-back address
        output      word_t      wb_data_async_o,   // write-back data
        output      logic       wb_ready_async_o,  // write-back ready
        output      logic       wb_valid_async_o,  // write-back valid
        output      logic       empty_async_o,     // stage empty

        // pipeline output
        output      word_t      pc_o,              // program counter
        output      word_t      ir_o,              // instruction register
        output      logic       load_o,            // is this a load instruction?
        output      ma_size_t   ma_size_o,         // memory access size
        output      logic [1:0] ma_alignment_o,    // memory access alignment
        output      word_t      wb_data_o,         // write-back data
        output      logic       wb_valid_o         // write-back valid
    );

initial start_logging();
final stop_logging();

//
// Memory Signals
//

always_comb begin
    dmem_addr_o       = { ma_addr_i[31:2], 2'b0 };
    dmem_write_mask_o = 4'b0000;

    // shift data left based on address lower bits
    unique case (ma_addr_i[1:0])
    2'b00: dmem_write_data_o = { ma_data_i[31:0]        };
    2'b01: dmem_write_data_o = { ma_data_i[23:0],  8'b0 };
    2'b10: dmem_write_data_o = { ma_data_i[15:0], 16'b0 };
    2'b11: dmem_write_data_o = { ma_data_i[ 7:0], 24'b0 };
    endcase

    // choose write mask based on operation, size and alignment
    unique case ({ ma_mode_i, ma_size_i, ma_addr_i[1:0] })
    { MA_STORE, MA_SIZE_B, 2'b00 }: dmem_write_mask_o = 4'b0001;
    { MA_STORE, MA_SIZE_B, 2'b01 }: dmem_write_mask_o = 4'b0010;
    { MA_STORE, MA_SIZE_B, 2'b10 }: dmem_write_mask_o = 4'b0100;
    { MA_STORE, MA_SIZE_B, 2'b11 }: dmem_write_mask_o = 4'b1000;
    { MA_STORE, MA_SIZE_H, 2'b00 }: dmem_write_mask_o = 4'b0011;
    { MA_STORE, MA_SIZE_H, 2'b10 }: dmem_write_mask_o = 4'b1100;
    { MA_STORE, MA_SIZE_W, 2'b00 }: dmem_write_mask_o = 4'b1111;
    default:                        dmem_write_mask_o = 4'b0000;
    endcase

    `log_display(("{ \"stage\": \"MA\", \"pc\": \"%0d\", \"ma_mode\": \"%0d\", \"dmem_addr\": \"%0d\", \"dmem_write_data\": \"%0d\", \"dmem_write_mask\": \"%0d\" }", pc_i, ma_mode_i, dmem_addr_o, dmem_write_data_o, dmem_write_mask_o));
end



//
// Async Outputs
//

always_comb begin
    wb_addr_async_o  = ir_i[11:7];
    wb_data_async_o  = wb_data_i;
    wb_ready_async_o = (wb_src_i != WB_SRC_MEM);
    wb_valid_async_o = wb_valid_i;
    empty_async_o    = pc_i == NOP_PC;

    `log_display(("{ \"stage\": \"MA\", \"pc\": \"%0d\", \"ma_wb_addr\": \"%0d\", \"ma_wb_data\": \"%0d\", \"ma_wb_valid\": \"%0d\" }", pc_i, wb_addr_async_o, wb_data_async_o, wb_valid_async_o));
end


//
// Pipeline Output
//

always_ff @(posedge clk_i) begin
    pc_o           <= pc_i;
    ir_o           <= ir_i;
    load_o         <= (ma_mode_i == MA_LOAD);
    ma_size_o      <= (ma_mode_i == MA_X) ? MA_SIZE_W : ma_size_i;
    ma_alignment_o <= ma_addr_i[1:0];
    wb_data_o      <= wb_data_i;
    wb_valid_o     <= wb_valid_i;

    if (reset_i) begin
        pc_o           <= NOP_PC;
        ir_o           <= NOP_IR;
        load_o         <= 1'b0;
        ma_size_o      <= NOP_MA_SIZE;
        ma_alignment_o <= 2'b00;
        wb_data_o      <= 32'b0;
        wb_valid_o     <= NOP_WB_VALID;
    end

    `log_strobe(("{ \"stage\": \"MA\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"load\": \"%0d\", \"ma_size\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" }", pc_o, ir_o, load_o, ma_size_o, wb_data_o, wb_valid_o));
end

endmodule
