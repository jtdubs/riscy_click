`timescale 1ns / 1ps
`default_nettype none

module cpu_wb_tb
    // Import Constants
    import common::*;
    ();

// cpu signals
logic       clk;            // clock
logic       reset;          // reset
logic       halt;           // halt

// IF memory access
word_t      imem_addr;      // address
word_t      imem_data;      // data

// ID stage inputs
word_t      if_pc;          // program counter
word_t      if_ir;          // instruction register
logic       if_valid;       // fetch stage data is valid

// ID stage inputs (data hazards)
regaddr_t     hz_ex_wb_addr;     // write-back register address
word_t      hz_ex_wb_data;     // write-back register value
logic       hz_ex_wb_valid;    // write-back data valid
regaddr_t     hz_ma_wb_addr;     // write-back register address
word_t      hz_ma_wb_data;     // write-back register value
logic       hz_ma_wb_valid;    // write-back data valid
regaddr_t     hz_wb_addr;        // write-back register address
word_t      hz_wb_data;        // write-back register value

// ID stage outputs (to IF)
logic       id_ready;       // stage ready for new inputs
word_t      id_jmp_addr;    // jump address
logic       id_jmp_valid;   // jump address valid

// ID stage outputs (to EX)
word_t      id_ir;          // instruction register
word_t      id_alu_op1;     // ALU operand 1
word_t      id_alu_op2;     // ALU operand 2
alu_mode_t  id_alu_mode;    // ALU mode
ma_mode_t   id_ma_mode;     // memory access mode
ma_size_t   id_ma_size;     // memory access size
word_t      id_ma_data;     // memory access data
wb_src_t    id_wb_src;      // write-back register address

// EX stage outputs (to MA)
word_t      ex_ir;          // instruction register
word_t      ex_alu_result;  // alu result
ma_mode_t   ex_ma_mode;     // memory access mode
ma_size_t   ex_ma_size;     // memory access size
word_t      ex_ma_data;     // memory access data
wb_src_t    ex_wb_src;      // write-back source
word_t      ex_wb_data;     // write-back register value

// MA stage outputs (to WB)
word_t      ma_ir;          // instruction register
word_t      ma_wb_data;     // write-back register value

// MA memory access
word_t      dmem_addr;       // address
word_t      dmem_read_data;  // data
word_t      dmem_write_data; // data
logic [3:0] dmem_write_mask; // write mask

// Instruction Memory
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Data Memory
block_ram ram (
    .clk(clk),
    .reset(reset),
    .addr(dmem_addr),
    .read_data(dmem_read_data),
    .write_data(dmem_write_data),
    .write_mask(dmem_write_mask)
);

// Fetch Stage
cpu_if cpu_if (.*);

// Decode Stage
cpu_id cpu_id (.id_halt(halt), .*);

// Execute Stage
cpu_ex cpu_ex (.*);

// Memory Access Stage
cpu_ma cpu_ma (.*);

// Write Back Stage
cpu_wb cpu_wb (.*);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse
initial begin
    reset = 1;
    #250 reset = 0;
end

endmodule
