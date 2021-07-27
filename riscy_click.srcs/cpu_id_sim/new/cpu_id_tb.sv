`timescale 1ns / 1ps
`default_nettype none

module cpu_id_tb
    // Import Constants
    import consts::*;
    ();

// cpu signals
logic       clk;            // clock
logic       reset;          // reset
logic       halt;           // halt

// IF memory access
word        imem_addr;      // address
word        imem_data;      // data

// ID stage inputs
word        if_pc;          // program counter
word        if_ir;          // instruction register
logic       if_valid;       // fetch stage data is valid

// ID stage inputs (data hazards)
regaddr     hz_ex_wb_addr;     // write-back register address
word        hz_ex_wb_data;     // write-back register value
logic       hz_ex_wb_valid;    // write-back data valid
regaddr     hz_ma_wb_addr;     // write-back register address
word        hz_ma_wb_data;     // write-back register value
logic       hz_ma_wb_valid;    // write-back data valid
regaddr     hz_wb_addr;        // write-back register address
word        hz_wb_data;        // write-back register value

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
ma_size     id_ma_size;     // memory access size
wb_src      id_wb_src;      // write-back register address
regaddr     id_wb_addr;     // write-back register address


// Instruction Memory
block_rom #(.CONTENTS("d:/dev/riscy_click/bios/bios.coe")) rom (
    .clk(clk),
    .reset(reset),
    .addr_a(imem_addr),
    .data_a(imem_data),
    .addr_b(32'h00000000),
    .data_b()
);

// Fetch Stage
cpu_if cpu_if (.*);

// Decode Stage
cpu_id cpu_id (.id_halt(halt), .*);

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
    hz_ex_wb_addr = 5'b00000;
    hz_ex_wb_data = 32'h00000000;
    hz_ex_wb_valid = 1'b1;
    
    hz_ma_wb_addr = 5'b00000;
    hz_ma_wb_data = 32'h00000000;
    hz_ma_wb_valid = 1'b1;
    
    hz_wb_addr = 5'b00000;
    hz_wb_data = 32'h00000000;
end

endmodule
