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
        input  wire logic       clk,     // clock
        input  wire logic       ic_rst,  // reset
        output wire logic       oc_halt, // halt

        // instruction memory bus
        output      word_t      oa_imem_addr,
        input  wire word_t      ia_imem_data,

        // data memory bus
        output wire word_t      oa_dmem_addr,
        input  wire word_t      ia_dmem_rddata,
        output      logic [3:0] oa_dmem_wrmask,
        output      word_t      oa_dmem_wrdata
    );

//
// CPU Stages
//

// Instruction Fetch
wire word_t a_jmp_addr;
wire logic  a_jmp_valid;
wire logic  a_ready;
wire word_t c_if_pc;
wire word_t c_if_ir;
wire logic  c_if_valid;

cpu_if cpu_if (
    .clk(clk),
    .ic_rst(ic_rst),
    .ic_halt(oc_halt),
    .oa_imem_addr(oa_imem_addr),
    .ia_imem_data(ia_imem_data),
    .ia_jmp_addr(a_jmp_addr),
    .ia_jmp_valid(a_jmp_valid),
    .ia_ready(a_ready),
    .oc_if_pc(c_if_pc),
    .oc_if_ir(c_if_ir),
    .oc_if_valid(c_if_valid)
);

// Instruction Decode
wire regaddr_t  a_hz_ex_addr;
wire word_t     a_hz_ex_data;
wire logic      a_hz_ex_valid;
wire regaddr_t  a_hz_ma_addr;
wire word_t     a_hz_ma_data;
wire logic      a_hz_ma_valid;
wire regaddr_t  a_wb_addr;
wire word_t     a_wb_data;
wire logic      c_halt;
wire word_t     c_id_ir;
wire word_t     c_id_alu_op1;
wire word_t     c_id_alu_op2;
wire alu_mode_t c_id_alu_mode;
wire ma_mode_t  c_id_ma_mode;
wire ma_size_t  c_id_ma_size;
wire word_t     c_id_ma_data;
wire wb_src_t   c_id_wb_src;
wire word_t     c_id_wb_data;
        
cpu_id cpu_id (
    .clk(clk),
    .ic_rst(ic_rst),
    .ic_id_pc(c_if_pc),
    .ic_id_ir(c_if_ir),
    .ic_id_valid(c_if_valid),
    .ia_hz_ex_addr(a_hz_ex_addr),
    .ia_hz_ex_data(a_hz_ex_data),
    .ia_hz_ex_valid(a_hz_ex_valid),
    .ia_hz_ma_addr(a_hz_ma_addr),
    .ia_hz_ma_data(a_hz_ma_data),
    .ia_hz_ma_valid(a_hz_ma_valid),
    .ia_wb_addr(a_wb_addr),
    .ia_wb_data(a_wb_data),
    .oa_ready(a_ready),
    .oa_jmp_addr(a_jmp_addr),
    .oa_jmp_valid(a_jmp_valid),
    .oc_halt(oc_halt),
    .oc_id_ir(c_id_ir),
    .oc_id_alu_op1(c_id_alu_op1),
    .oc_id_alu_op2(c_id_alu_op2),
    .oc_id_alu_mode(c_id_alu_mode),
    .oc_id_ma_mode(c_id_ma_mode),
    .oc_id_ma_size(c_id_ma_size),
    .oc_id_ma_data(c_id_ma_data),
    .oc_id_wb_src(c_id_wb_src),
    .oc_id_wb_data(c_id_wb_data)
);

// Execute    
wire word_t     c_ex_ir;
wire word_t     c_ex_ma_addr;
wire ma_mode_t  c_ex_ma_mode;
wire ma_size_t  c_ex_ma_size;
wire word_t     c_ex_ma_data;
wire wb_src_t   c_ex_wb_src;
wire word_t     c_ex_wb_data;

cpu_ex cpu_ex (
    .clk(clk),
    .ic_rst(ic_rst),
    .ic_ex_ir(c_id_ir),
    .ic_ex_alu_op1(c_id_alu_op1),
    .ic_ex_alu_op2(c_id_alu_op2),
    .ic_ex_alu_mode(c_id_alu_mode),
    .ic_ex_ma_mode(c_id_ma_mode),
    .ic_ex_ma_size(c_id_ma_size),
    .ic_ex_ma_data(c_id_ma_data),
    .ic_ex_wb_src(c_id_wb_src),
    .ic_ex_wb_data(c_id_wb_data),
    .oa_hz_ex_addr(a_hz_ex_addr),
    .oa_hz_ex_data(a_hz_ex_data),
    .oa_hz_ex_valid(a_hz_ex_valid),
    .oc_ex_ir(c_ex_ir),
    .oc_ex_ma_addr(c_ex_ma_addr),
    .oc_ex_ma_mode(c_ex_ma_mode),
    .oc_ex_ma_size(c_ex_ma_size),
    .oc_ex_ma_data(c_ex_ma_data),
    .oc_ex_wb_src(c_ex_wb_src),
    .oc_ex_wb_data(c_ex_wb_data)
);

// Memory Access
wire word_t      c_ma_ir;
wire logic       c_ma_is_load;
wire word_t      c_ma_wb_data;
        
cpu_ma cpu_ma (
    .clk(clk),
    .ic_rst(ic_rst),
    .oa_dmem_addr(oa_dmem_addr),
    .oa_dmem_wrdata(oa_dmem_wrdata),
    .oa_dmem_wrmask(oa_dmem_wrmask),
    .ic_ma_ir(c_ex_ir),
    .ic_ma_addr(c_ex_ma_addr),
    .ic_ma_mode(c_ex_ma_mode),
    .ic_ma_size(c_ex_ma_size),
    .ic_ma_data(c_ex_ma_data),
    .ic_ma_wb_src(c_ex_wb_src),
    .ic_ma_wb_data(c_ex_wb_data),
    .oa_hz_ma_addr(a_hz_ma_addr),
    .oa_hz_ma_data(a_hz_ma_data),
    .oa_hz_ma_valid(a_hz_ma_valid),
    .oc_ma_ir(c_ma_ir),
    .oc_ma_is_load(c_ma_is_load),
    .oc_ma_wb_data(c_ma_wb_data)
);

// Write Back
cpu_wb cpu_wb (
    .clk(clk),
    .ia_dmem_rddata(ia_dmem_rddata),
    .ic_wb_ir(c_ma_ir),
    .ic_wb_is_load(c_ma_is_load),
    .ic_wb_data(c_ma_wb_data),
    .oa_wb_addr(a_wb_addr),
    .oa_wb_data(a_wb_data)
);

endmodule