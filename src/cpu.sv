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
        input  wire logic       clk_i,
        input  wire logic       reset_i,
        output wire logic       halt_o,

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
// Signals
//


wire word_t     if_pc_w;
wire word_t     if_ir_w;
wire word_t     id_jmp_addr_async_w;
wire logic      id_jmp_valid_async_w;
wire logic      id_ready_async_w;
wire word_t     id_pc_w;
wire word_t     id_ir_w;
wire word_t     id_alu_op1_w;
wire word_t     id_alu_op2_w;
wire alu_mode_t id_alu_mode_w;
wire ma_mode_t  id_ma_mode_w;
wire ma_size_t  id_ma_size_w;
wire word_t     id_ma_data_w;
wire wb_src_t   id_wb_src_w;
wire word_t     id_wb_data_w;
wire logic      id_wb_valid_w;
wire word_t     ex_pc_w;
wire word_t     ex_ir_w;
wire word_t     ex_ma_addr_w;
wire ma_mode_t  ex_ma_mode_w;
wire ma_size_t  ex_ma_size_w;
wire word_t     ex_ma_data_w;
wire wb_src_t   ex_wb_src_w;
wire word_t     ex_wb_data_w;
wire logic      ex_wb_valid_w;
wire regaddr_t  ex_wb_addr_async_w;
wire word_t     ex_wb_data_async_w;
wire logic      ex_wb_ready_async_w;
wire logic      ex_wb_valid_async_w;
wire logic      ex_empty_async_w;
wire regaddr_t  ma_wb_addr_async_w;
wire word_t     ma_wb_data_async_w;
wire logic      ma_wb_ready_async_w;
wire logic      ma_wb_valid_async_w;
wire logic      ma_empty_async_w;
wire word_t     ma_pc_w;
wire word_t     ma_ir_w;
wire logic      ma_load_w;
wire word_t     ma_wb_data_w;
wire logic      ma_wb_valid_w;
wire ma_size_t  ma_size_w;
wire regaddr_t  wb_addr_async_w;
wire word_t     wb_data_async_w;
wire logic      wb_valid_async_w;
wire logic      wb_empty_async_w;

//
// CPU Stages
//

// Instruction Fetch
cpu_if cpu_if (
    .clk_i             (clk_i),
    .reset_i           (reset_i),
    .halt_i            (halt_o),
    .imem_addr_o       (imem_addr_o),
    .imem_data_i       (imem_data_i),
    .jmp_addr_async_i  (id_jmp_addr_async_w),
    .jmp_valid_async_i (id_jmp_valid_async_w),
    .ready_async_i     (id_ready_async_w),
    .pc_o              (if_pc_w),
    .ir_o              (if_ir_w)
);

// Instruction Decode
cpu_id cpu_id (
    .clk_i               (clk_i),
    .reset_i             (reset_i),
    .pc_i                (if_pc_w),
    .ir_i                (if_ir_w),
    .ex_wb_addr_async_i  (ex_wb_addr_async_w),
    .ex_wb_data_async_i  (ex_wb_data_async_w),
    .ex_wb_ready_async_i (ex_wb_ready_async_w),
    .ex_wb_valid_async_i (ex_wb_valid_async_w),
    .ex_empty_async_i    (ex_empty_async_w),
    .ma_wb_addr_async_i  (ma_wb_addr_async_w),
    .ma_wb_data_async_i  (ma_wb_data_async_w),
    .ma_wb_ready_async_i (ma_wb_ready_async_w),
    .ma_wb_valid_async_i (ma_wb_valid_async_w),
    .ma_empty_async_i    (ma_empty_async_w),
    .wb_addr_async_i     (wb_addr_async_w),
    .wb_data_async_i     (wb_data_async_w),
    .wb_valid_async_i    (wb_valid_async_w),
    .wb_empty_async_i    (wb_empty_async_w),
    .ready_async_o       (id_ready_async_w),
    .jmp_addr_async_o    (id_jmp_addr_async_w),
    .jmp_valid_async_o   (id_jmp_valid_async_w),
    .halt_o              (halt_o),
    .pc_o                (id_pc_w),
    .ir_o                (id_ir_w),
    .alu_op1_o           (id_alu_op1_w),
    .alu_op2_o           (id_alu_op2_w),
    .alu_mode_o          (id_alu_mode_w),
    .ma_mode_o           (id_ma_mode_w),
    .ma_size_o           (id_ma_size_w),
    .ma_data_o           (id_ma_data_w),
    .wb_src_o            (id_wb_src_w),
    .wb_data_async_o     (id_wb_data_w),
    .wb_valid_async_o    (id_wb_valid_w)
);

// Execute
cpu_ex cpu_ex (
    .clk_i            (clk_i),
    .reset_i          (reset_i),
    .pc_i             (id_pc_w),
    .ir_i             (id_ir_w),
    .alu_op1_i        (id_alu_op1_w),
    .alu_op2_i        (id_alu_op2_w),
    .alu_mode_i       (id_alu_mode_w),
    .ma_mode_i        (id_ma_mode_w),
    .ma_size_i        (id_ma_size_w),
    .ma_data_i        (id_ma_data_w),
    .wb_src_i         (id_wb_src_w),
    .wb_data_i        (id_wb_data_w),
    .wb_valid_i       (id_wb_valid_w),
    .wb_addr_async_o  (ex_wb_addr_async_w),
    .wb_data_async_o  (ex_wb_data_async_w),
    .wb_ready_async_o (ex_wb_ready_async_w),
    .wb_valid_async_o (ex_wb_valid_async_w),
    .empty_async_o    (ex_empty_async_w),
    .pc_o             (ex_pc_w),
    .ir_o             (ex_ir_w),
    .ma_addr_o        (ex_ma_addr_w),
    .ma_mode_o        (ex_ma_mode_w),
    .ma_size_o        (ex_ma_size_w),
    .ma_data_o        (ex_ma_data_w),
    .wb_src_o         (ex_wb_src_w),
    .wb_data_o        (ex_wb_data_w),
    .wb_valid_o       (ex_wb_valid_w)
);

// Memory Access
cpu_ma cpu_ma (
    .clk_i             (clk_i),
    .reset_i           (reset_i),
    .dmem_addr_o       (dmem_addr_o),
    .dmem_write_data_o (dmem_write_data_o),
    .dmem_write_mask_o (dmem_write_mask_o),
    .pc_i              (ex_pc_w),
    .ir_i              (ex_ir_w),
    .ma_addr_i         (ex_ma_addr_w),
    .ma_mode_i         (ex_ma_mode_w),
    .ma_size_i         (ex_ma_size_w),
    .ma_data_i         (ex_ma_data_w),
    .wb_src_i          (ex_wb_src_w),
    .wb_data_i         (ex_wb_data_w),
    .wb_valid_i        (ex_wb_valid_w),
    .wb_addr_async_o   (ma_wb_addr_async_w),
    .wb_data_async_o   (ma_wb_data_async_w),
    .wb_ready_async_o  (ma_wb_ready_async_w),
    .wb_valid_async_o  (ma_wb_valid_async_w),
    .empty_async_o     (ma_empty_async_w),
    .pc_o              (ma_pc_w),
    .ir_o              (ma_ir_w),
    .load_o            (ma_load_w),
    .ma_size_o         (ma_size_w),
    .wb_data_o         (ma_wb_data_w),
    .wb_valid_o        (ma_wb_valid_w)
);

// Write Back
cpu_wb cpu_wb (
    .clk_i            (clk_i),
    .reset_i          (reset_i),
    .dmem_read_data_i (dmem_read_data_i),
    .pc_i             (ma_pc_w),
    .ir_i             (ma_ir_w),
    .load_i           (ma_load_w),
    .ma_size_i        (ma_size_w),
    .wb_data_i        (ma_wb_data_w),
    .wb_valid_i       (ma_wb_valid_w),
    .wb_addr_async_o  (wb_addr_async_w),
    .wb_data_async_o  (wb_data_async_w),
    .wb_valid_async_o (wb_valid_async_w),
    .empty_async_o    (wb_empty_async_w)
);

endmodule
