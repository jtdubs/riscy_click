`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU
///

module cpu
    // Import Constants
    import common::*;
    (
        // board signals
        input  wire logic       clk_i,    // clock
        input  wire logic       reset_i,  // reset_i
        output wire logic       halt_o,   // halt

        // instruction memory bus
        output      word_t      imem_addr_o,
        input  wire word_t      imem_data_i,

        // data memory bus
        output wire word_t      dmem_addr_o,
        input  wire word_t      dmem_read_data_i,
        output      logic [3:0] dmem_write_mask_o,
        output      word_t      dmem_write_data_o
    );

//
// CPU Stages
//

// Instruction Fetch
wire word_t jmp_addr_w;
wire logic  jmp_valid_w;
wire logic  ready_w;
wire word_t if_pc_w;
wire word_t if_ir_w;
wire logic  if_valid_w;

cpu_if cpu_if (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .halt_i(halt_o),
    .imem_addr_o(imem_addr_o),
    .imem_data_i(imem_data_i),
    .jmp_addr_i(jmp_addr_w),
    .jmp_valid_i(jmp_valid_w),
    .ready_i(ready_w),
    .pc_o(if_pc_w),
    .ir_o(if_ir_w),
    .valid_o(if_valid_w)
);

// Instruction Decode
wire regaddr_t  id_ex_writeback_addr_w;
wire word_t     id_ex_writeback_data_w;
wire logic      id_ex_writeback_valid_w;
wire regaddr_t  id_ma_writeback_addr_w;
wire word_t     id_ma_writeback_data_w;
wire logic      id_ma_writeback_valid_w;
wire regaddr_t  writeback_addr_w;
wire word_t     writeback_data_w;
wire word_t     id_ir_w;
wire word_t     id_alu_op1_w;
wire word_t     id_alu_op2_w;
wire alu_mode_t id_alu_mode_w;
wire ma_mode_t  id_ma_mode_w;
wire ma_size_t  id_ma_size_w;
wire word_t     id_ma_data_w;
wire wb_src_t   id_writeback_src_w;
wire word_t     id_writeback_data_w;
        
cpu_id cpu_id (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .pc_i(if_pc_w),
    .ir_i(if_ir_w),
    .valid_i(if_valid_w),
    .ex_writeback_addr_i(id_ex_writeback_addr_w),
    .ex_writeback_data_i(id_ex_writeback_data_w),
    .ex_writeback_valid_i(id_ex_writeback_valid_w),
    .ma_writeback_addr_i(id_ma_writeback_addr_w),
    .ma_writeback_data_i(id_ma_writeback_data_w),
    .ma_writeback_valid_i(id_ma_writeback_valid_w),
    .writeback_addr_i(writeback_addr_w),
    .writeback_data_i(writeback_data_w),
    .ready_async_o(ready_w),
    .jmp_addr_o(jmp_addr_w),
    .jmp_valid_o(jmp_valid_w),
    .halt_o(halt_o),
    .ir_o(id_ir_w),
    .alu_op1_o(id_alu_op1_w),
    .alu_op2_o(id_alu_op2_w),
    .alu_mode_o(id_alu_mode_w),
    .ma_mode_o(id_ma_mode_w),
    .ma_size_o(id_ma_size_w),
    .ma_data_o(id_ma_data_w),
    .writeback_src_o(id_writeback_src_w),
    .writeback_data_o(id_writeback_data_w)
);

// Execute    
wire word_t     ex_ir_w;
wire word_t     ex_ma_addr_w;
wire ma_mode_t  ex_ma_mode_w;
wire ma_size_t  ex_ma_size_w;
wire word_t     ex_ma_data_w;
wire wb_src_t   ex_writeback_src_w;
wire word_t     ex_writeback_data_w;

cpu_ex cpu_ex (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .ir_i(id_ir_w),
    .alu_op1_i(id_alu_op1_w),
    .alu_op2_i(id_alu_op2_w),
    .alu_mode_i(id_alu_mode_w),
    .ma_mode_i(id_ma_mode_w),
    .ma_size_i(id_ma_size_w),
    .ma_data_i(id_ma_data_w),
    .writeback_src_i(id_writeback_src_w),
    .writeback_data_i(id_writeback_data_w),
    .ex_writeback_addr_o(id_ex_writeback_addr_w),
    .ex_writeback_data_o(id_ex_writeback_data_w),
    .ex_writeback_valid_o(id_ex_writeback_valid_w),
    .ir_o(ex_ir_w),
    .ma_addr_o(ex_ma_addr_w),
    .ma_mode_o(ex_ma_mode_w),
    .ma_size_o(ex_ma_size_w),
    .ma_data_o(ex_ma_data_w),
    .writeback_src_o(ex_writeback_src_w),
    .writeback_data_o(ex_writeback_data_w)
);

// Memory Access
wire word_t      ma_ir_w;
wire logic       ma_load_w;
wire word_t      ma_writeback_data_w;
        
cpu_ma cpu_ma (
    .clk_i(clk_i),
    .reset_i(reset_i),
    .dmem_addr_o(dmem_addr_o),
    .dmem_write_data_o(dmem_write_data_o),
    .dmem_write_mask_o(dmem_write_mask_o),
    .ir_i(ex_ir_w),
    .ma_addr_i(ex_ma_addr_w),
    .ma_mode_i(ex_ma_mode_w),
    .ma_size_i(ex_ma_size_w),
    .ma_data_i(ex_ma_data_w),
    .writeback_src_i(ex_writeback_src_w),
    .writeback_data_i(ex_writeback_data_w),
    .ma_writeback_addr_o(id_ma_writeback_addr_w),
    .ma_writeback_data_o(id_ma_writeback_data_w),
    .ma_writeback_valid_o(id_ma_writeback_valid_w),
    .ir_o(ma_ir_w),
    .load_o(ma_load_w),
    .writeback_data_o(ma_writeback_data_w)
);

// Write Back
cpu_wb cpu_wb (
    .clk_i(clk_i),
    .dmem_read_data_i(dmem_read_data_i),
    .ir_i(ma_ir_w),
    .load_i(ma_load_w),
    .writeback_data_i(ma_writeback_data_w),
    .writeback_addr_o(writeback_addr_w),
    .writeback_data_o(writeback_data_w)
);

endmodule