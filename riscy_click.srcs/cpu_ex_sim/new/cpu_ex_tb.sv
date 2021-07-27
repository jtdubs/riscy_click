`timescale 1ns / 1ps
`default_nettype none

module cpu_ex_tb
    // Import Constants
    import consts::*;
    ();

// cpu signals
logic       clk;            // clock
logic       reset;          // reset
logic       halt;           // halt

// IF memory access
word        mem_addr;       // address
word        mem_data;       // data

// ID stage inputs
word        if_pc;          // program counter
word        if_ir;          // instruction register
logic       if_valid;       // fetch stage data is valid

// ID stage inputs (data hazards)
regaddr     hz_ex_wb_addr;     // write-back register address
word        hz_ex_wb_data;     // write-back register value
logic       hz_ex_wb_enable;   // write-back enable
logic       hz_ex_wb_valid;    // write-back data valid
regaddr     hz_ma_wb_addr;     // write-back register address
word        hz_ma_wb_data;     // write-back register value
logic       hz_ma_wb_enable;   // write-back enable
regaddr     hz_wb_addr;        // write-back register address
word        hz_wb_data;        // write-back register value
logic       hz_wb_enable;      // write-back enable

// ID stage outputs (to IF)
logic       id_ready;       // stage ready for new inputs
word        id_jmp_addr;    // jump address
logic       id_jmp_valid;   // jump address valid

// ID stage outputs (to EX)
word        id_pc;          // program counter
word        id_ir;          // instruction register
word        id_alu_op1;     // ALU operand 1
word        id_alu_op2;     // ALU operand 2
alu_mode    id_alu_mode;    // ALU mode
ma_mode     id_ma_mode;     // memory access mode
wb_src      id_wb_src;      // write-back register address
regaddr     id_wb_addr;     // write-back register address
wb_mode     id_wb_mode;     // write-back enable

// EX stage outputs (to MA)
word        ex_pc;          // program counter
word        ex_ir;          // instruction register
word        ex_alu_result;  // alu result
ma_mode     ex_ma_mode;     // memory access mode
wb_src      ex_wb_src;      // write-back source
regaddr     ex_wb_addr;     // write-back register address
word        ex_wb_data;     // write-back register value
wb_mode     ex_wb_mode;     // write-back mode


// BIOS
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr_a(mem_addr),
    .data_a(mem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Fetch Stage
cpu_if cpu_if (.*);

// Decode Stage
cpu_id cpu_id (.id_halt(halt), .*);

// Execute Stage
cpu_ex cpu_ex (.*);

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

// write-back logic
initial begin
    hz_ma_wb_addr = 'dX;
    hz_ma_wb_data = 'dX;
    hz_ma_wb_enable = 1'b0;
    
    hz_wb_addr = 'dX;
    hz_wb_data = 'dX;
    hz_wb_enable = 1'b0;
end

endmodule
