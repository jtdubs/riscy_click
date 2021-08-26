`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU
///

module cpu
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    (
        // board signals
        input  wire logic       clk_i,
        input  wire logic       interrupt_i,
        output wire logic       halt_o,

        // instruction memory bus
        output wire word_t      imem_addr_o,
        input  wire word_t      imem_data_i,

        // data memory bus
        output wire word_t      dmem_addr_o,
        input  wire word_t      dmem_read_data_i,
        output wire logic       dmem_read_enable_o,
        output wire logic [3:0] dmem_write_mask_o,
        output wire word_t      dmem_write_data_o
    );

//
// Signals
//

wire word_t      if_pc;
wire word_t      if_ir;
wire word_t      if_pc_next;
wire word_t      id_jmp_addr;
wire logic       id_jmp_valid;
wire logic       id_ready;
wire word_t      id_pc;
wire word_t      id_ir;
wire word_t      id_alu_op1;
wire word_t      id_alu_op2;
wire alu_mode_t  id_alu_mode;
wire ma_mode_t   id_ma_mode;
wire ma_size_t   id_ma_size;
wire word_t      id_ma_data;
wire wb_src_t    id_wb_src;
wire word_t      id_wb_data;
wire logic       id_wb_valid;
wire word_t      ex_pc;
wire word_t      ex_ir;
wire word_t      ex_ma_addr;
wire ma_mode_t   ex_ma_mode;
wire ma_size_t   ex_ma_size;
wire word_t      ex_ma_data;
wire wb_src_t    ex_wb_src;
wire regaddr_t   ex_wb_addr;
wire word_t      ex_wb_data;
wire logic       ex_wb_ready;
wire logic       ex_wb_valid;
wire logic       ex_empty;
wire logic       ma_empty;
wire word_t      ma_pc;
wire word_t      ma_ir;
wire logic       ma_load;
wire logic [1:0] ma_alignment;
wire regaddr_t   ma_wb_addr;
wire word_t      ma_wb_data;
wire logic       ma_wb_ready;
wire logic       ma_wb_valid;
wire ma_size_t   ma_size;
wire regaddr_t   wb_addr;
wire word_t      wb_data;
wire logic       wb_valid;
wire logic       wb_empty;
wire logic       csr_retired;
wire word_t      csr_trap_pc;
wire mcause_t    csr_mcause;
wire logic       csr_mtrap;
wire logic       csr_mret;
wire word_t      csr_jmp_addr;
wire logic       csr_jmp_request;
wire logic       csr_jmp_accept;
wire csr_t       csr_read_addr;
wire logic       csr_read_enable;
wire word_t      csr_read_data;
wire csr_t       csr_write_addr;
wire word_t      csr_write_data;
wire logic       csr_write_enable;


//
// CPU Stages
//

// Instruction Fetch
stage_fetch fetch (
    .clk_i               (clk_i),
    .halt_i              (halt_o),
    .imem_addr_o         (imem_addr_o),
    .imem_data_i         (imem_data_i),
    .jmp_addr_i          (id_jmp_addr),
    .jmp_valid_i         (id_jmp_valid),
    .ready_i             (id_ready),
    .pc_o                (if_pc),
    .ir_o                (if_ir),
    .pc_next_o           (if_pc_next)
);

// Instruction Decode
stage_decode decode (
    .clk_i               (clk_i),
    .pc_i                (if_pc),
    .pc_next_i           (if_pc_next),
    .ir_i                (if_ir),
    .ex_wb_addr_i        (ex_wb_addr),
    .ex_wb_data_i        (ex_wb_data),
    .ex_wb_ready_i       (ex_wb_ready),
    .ex_wb_valid_i       (ex_wb_valid),
    .ex_empty_i          (ex_empty),
    .ma_wb_addr_i        (ma_wb_addr),
    .ma_wb_data_i        (ma_wb_data),
    .ma_wb_ready_i       (ma_wb_ready),
    .ma_wb_valid_i       (ma_wb_valid),
    .ma_empty_i          (ma_empty),
    .wb_addr_i           (wb_addr),
    .wb_data_i           (wb_data),
    .wb_valid_i          (wb_valid),
    .wb_empty_i          (wb_empty),
    .ready_async_o       (id_ready),
    .jmp_addr_o          (id_jmp_addr),
    .jmp_valid_o         (id_jmp_valid),
    .csr_retired_o       (csr_retired),
    .csr_trap_pc_o       (csr_trap_pc),
    .csr_mtrap_o         (csr_mtrap),
    .csr_mret_o          (csr_mret),
    .csr_mcause_o        (csr_mcause),
    .csr_jmp_addr_i      (csr_jmp_addr),
    .csr_jmp_request_i   (csr_jmp_request),
    .csr_jmp_accept_o    (csr_jmp_accept),
    .csr_read_addr_o     (csr_read_addr),
    .csr_read_enable_o   (csr_read_enable),
    .csr_read_data_i     (csr_read_data),
    .csr_write_addr_o    (csr_write_addr),
    .csr_write_data_o    (csr_write_data),
    .csr_write_enable_o  (csr_write_enable),
    .halt_o              (halt_o),
    .pc_o                (id_pc),
    .ir_o                (id_ir),
    .alu_op1_o           (id_alu_op1),
    .alu_op2_o           (id_alu_op2),
    .alu_mode_o          (id_alu_mode),
    .ma_mode_o           (id_ma_mode),
    .ma_size_o           (id_ma_size),
    .ma_data_o           (id_ma_data),
    .wb_src_o            (id_wb_src),
    .wb_data_o           (id_wb_data),
    .wb_valid_o          (id_wb_valid)
);

// Execute
stage_execute execute (
    .clk_i               (clk_i),
    .pc_i                (id_pc),
    .ir_i                (id_ir),
    .alu_op1_i           (id_alu_op1),
    .alu_op2_i           (id_alu_op2),
    .alu_mode_i          (id_alu_mode),
    .ma_mode_i           (id_ma_mode),
    .ma_size_i           (id_ma_size),
    .ma_data_i           (id_ma_data),
    .wb_src_i            (id_wb_src),
    .wb_data_i           (id_wb_data),
    .wb_valid_i          (id_wb_valid),
    .empty_async_o       (ex_empty),
    .pc_o                (ex_pc),
    .ir_o                (ex_ir),
    .ma_addr_o           (ex_ma_addr),
    .ma_mode_o           (ex_ma_mode),
    .ma_size_o           (ex_ma_size),
    .ma_data_o           (ex_ma_data),
    .wb_src_o            (ex_wb_src),
    .wb_addr_o           (ex_wb_addr),
    .wb_data_o           (ex_wb_data),
    .wb_ready_o          (ex_wb_ready),
    .wb_valid_o          (ex_wb_valid)
);

// Memory Access
stage_memory memory_access (
    .clk_i               (clk_i),
    .dmem_addr_o         (dmem_addr_o),
    .dmem_read_enable_o  (dmem_read_enable_o),
    .dmem_write_data_o   (dmem_write_data_o),
    .dmem_write_mask_o   (dmem_write_mask_o),
    .pc_i                (ex_pc),
    .ir_i                (ex_ir),
    .ma_addr_i           (ex_ma_addr),
    .ma_mode_i           (ex_ma_mode),
    .ma_size_i           (ex_ma_size),
    .ma_data_i           (ex_ma_data),
    .wb_src_i            (ex_wb_src),
    .wb_data_i           (ex_wb_data),
    .wb_valid_i          (ex_wb_valid),
    .empty_async_o       (ma_empty),
    .pc_o                (ma_pc),
    .ir_o                (ma_ir),
    .load_o              (ma_load),
    .ma_size_o           (ma_size),
    .ma_alignment_o      (ma_alignment),
    .wb_addr_o           (ma_wb_addr),
    .wb_data_o           (ma_wb_data),
    .wb_ready_o          (ma_wb_ready),
    .wb_valid_o          (ma_wb_valid)
);

// Write Back
stage_writeback writeback (
    .clk_i               (clk_i),
    .dmem_read_data_i    (dmem_read_data_i),
    .pc_i                (ma_pc),
    .ir_i                (ma_ir),
    .load_i              (ma_load),
    .ma_size_i           (ma_size),
    .ma_alignment_i      (ma_alignment),
    .wb_data_i           (ma_wb_data),
    .wb_valid_i          (ma_wb_valid),
    .wb_addr_o           (wb_addr),
    .wb_data_o           (wb_data),
    .wb_valid_o          (wb_valid),
    .empty_async_o       (wb_empty)
);


//
// CSRs
//

csr csr (
    .clk_i               (clk_i),
    .retired_i           (csr_retired),
    .interrupt_i         (interrupt_i),
    .trap_pc_i           (csr_trap_pc),
    .mcause_i            (csr_mcause),
    .mtrap_i             (csr_mtrap),
    .mret_i              (csr_mret),
    .jmp_addr_async_o    (csr_jmp_addr),
    .jmp_request_async_o (csr_jmp_request),
    .jmp_accept_i        (csr_jmp_accept),
    .read_addr_i         (csr_read_addr),
    .read_enable_i       (csr_read_enable),
    .read_data_o         (csr_read_data),
    .write_addr_i        (csr_write_addr),
    .write_data_i        (csr_write_data),
    .write_enable_i      (csr_write_enable),
    .lookup1_addr_i      (32'b0),
    .lookup1_rwx_async_o (),
    .lookup2_addr_i      (32'b0),
    .lookup2_rwx_async_o ()
);

endmodule
