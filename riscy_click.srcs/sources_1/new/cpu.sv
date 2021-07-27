`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU
///

module cpu
    // Import Constants
    import consts::*;
    (
        // board signals
        input  wire logic       clk,   // clock
        input  wire logic       reset, // reset
        output wire logic       halt,  // halt

        // instruction memory bus
        output      word        imem_addr,
        input  wire word        imem_data,

        // data memory bus
        output wire word        dmem_addr,
        input  wire word        dmem_read_data,
        output      word        dmem_write_data,
        output      logic [3:0] dmem_write_mask
    );


//
// CPU Signals
//

// ID stage inputs
wire word        if_pc;          // program counter
wire word        if_ir;          // instruction register
wire logic       if_valid;       // fetch stage data is valid

// ID stage inputs (data hazards)
wire regaddr     hz_ex_wb_addr;     // write-back register address
wire word        hz_ex_wb_data;     // write-back register value
wire logic       hz_ex_wb_valid;    // write-back data valid
wire regaddr     hz_ma_wb_addr;     // write-back register address
wire word        hz_ma_wb_data;     // write-back register value
wire logic       hz_ma_wb_valid;    // write-back data valid
wire regaddr     hz_wb_addr;        // write-back register address
wire word        hz_wb_data;        // write-back register value

// ID stage outputs (to IF)
wire logic       id_ready;       // stage ready for new inputs
wire word        id_jmp_addr;    // jump address
wire logic       id_jmp_valid;   // jump address valid

// ID stage outputs (to EX)
wire word        id_pc;          // program counter
wire word        id_ir;          // instruction register
wire word        id_alu_op1;     // ALU operand 1
wire word        id_alu_op2;     // ALU operand 2
wire alu_mode    id_alu_mode;    // ALU mode
wire ma_mode     id_ma_mode;     // memory access mode
wire ma_size     id_ma_size;     // memory access size
wire word        id_ma_data;     // memory access data
wire wb_src      id_wb_src;      // write-back register address
wire regaddr     id_wb_addr;     // write-back register address

// EX stage outputs (to MA)
wire word        ex_pc;          // program counter
wire word        ex_ir;          // instruction register
wire word        ex_alu_result;  // alu result
wire ma_mode     ex_ma_mode;     // memory access mode
wire ma_size     ex_ma_size;     // memory access size
wire word        ex_ma_data;     // memory access data
wire wb_src      ex_wb_src;      // write-back source
wire regaddr     ex_wb_addr;     // write-back register address
wire word        ex_wb_data;     // write-back register value

// MA stage outputs (to WB)
wire word        ma_pc;          // program counter
wire word        ma_ir;          // instruction register
wire regaddr     ma_wb_addr;     // write-back register address
wire word        ma_wb_data;     // write-back register value


//
// CPU Stages
//

cpu_if cpu_if (.*);
cpu_id cpu_id (.id_halt(halt), .*);
cpu_ex cpu_ex (.*);
cpu_ma cpu_ma (.*);
cpu_wb cpu_wb (.*);

endmodule
