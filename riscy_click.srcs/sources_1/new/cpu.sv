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
        input  wire logic       clk,   // clock
        input  wire logic       reset, // reset
        output wire logic       halt,  // halt

        // instruction memory bus
        output      word_t      imem_addr,
        input  wire word_t      imem_data,

        // data memory bus
        output wire word_t      dmem_addr,
        input  wire word_t      dmem_read_data,
        output      word_t      dmem_write_data,
        output      logic [3:0] dmem_write_mask
    );


//
// CPU Signals
//

// ID stage inputs
wire word_t      if_pc;          // program counter
wire word_t      if_ir;          // instruction register
wire logic       if_valid;       // fetch stage data is valid

// ID stage inputs (data hazards)
wire regaddr_t   hz_ex_wb_addr;     // write-back register address
wire word_t      hz_ex_wb_data;     // write-back register value
wire logic       hz_ex_wb_valid;    // write-back data valid
wire regaddr_t   hz_ma_wb_addr;     // write-back register address
wire word_t      hz_ma_wb_data;     // write-back register value
wire logic       hz_ma_wb_valid;    // write-back data valid
wire regaddr_t   hz_wb_addr;        // write-back register address
wire word_t      hz_wb_data;        // write-back register value

// ID stage outputs (to IF)
wire logic       id_ready;       // stage ready for new inputs
wire word_t      id_jmp_addr;    // jump address
wire logic       id_jmp_valid;   // jump address valid

// ID stage outputs (to EX)
wire word_t      id_ir;          // instruction register
wire word_t      id_alu_op1;     // ALU operand 1
wire word_t      id_alu_op2;     // ALU operand 2
wire alu_mode_t  id_alu_mode;    // ALU mode
wire ma_mode_t   id_ma_mode;     // memory access mode
wire ma_size_t   id_ma_size;     // memory access size
wire word_t      id_ma_data;     // memory access data
wire wb_src_t    id_wb_src;      // write-back register address
wire word_t      id_wb_data;     // write-back data

// EX stage outputs (to MA)
wire word_t      ex_ir;          // instruction register
wire word_t      ex_alu_result;  // alu result
wire word_t      ex_ma_addr;     // memory access address
wire ma_mode_t   ex_ma_mode;     // memory access mode
wire ma_size_t   ex_ma_size;     // memory access size
wire word_t      ex_ma_data;     // memory access data
wire wb_src_t    ex_wb_src;      // write-back source
wire word_t      ex_wb_data;     // write-back register value

// MA stage outputs (to WB)
wire word_t      ma_ir;          // instruction register
wire logic       ma_is_load;     // is a load instruction?
wire word_t      ma_wb_data;     // write-back register value


//
// CPU Stages
//

cpu_if cpu_if (.*);
cpu_id cpu_id (.id_halt(halt), .*);
cpu_ex cpu_ex (.*);
cpu_ma cpu_ma (.*);
cpu_wb cpu_wb (.*);

endmodule
