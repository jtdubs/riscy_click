`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Execution phase
///

module cpu_ex
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input  wire logic       clk,            // clock
        input  wire logic       reset,          // reset
        input  wire logic       halt,           // halt

        // stage inputs
        input  wire word        id_pc,          // program counter
        input  wire word        id_ir,          // instruction register
        input  wire word        id_alu_op1,     // ALU operand 1
        input  wire word        id_alu_op2,     // ALU operand 2
        input  wire alu_mode    id_alu_mode,    // ALU mode
        input  wire regaddr     id_wb_rd,       // write-back register address
        input  wire wb_src      id_wb_src_sel,  // write-back register address
        input  wire wb_dst      id_wb_dst_sel,  // write-back register address
        input  wire wb_mode     id_wb_mode,     // write-back enable
        
        // stage outputs (data hazards)
        output      regaddr     ex_wb_addr,     // write-back register address
        output      word        ex_wb_data,     // write-back register value
        output      logic       ex_wb_enable,   // write-back enable
        output      logic       ex_wb_valid,    // write-back data valid

        // stage outputs (to MA)
        output      word        ex_pc,          // program counter
        output      word        ex_ir,          // instruction register
        output      regaddr     ex_wb_rd,       // write-back register address
        output      wb_src      ex_wb_src_sel,  // write-back register address
        output      wb_dst      ex_wb_dst_sel,  // write-back register address
        output      wb_mode     ex_wb_mode      // write-back enable
    );

//
// ALU
//

wire logic alu_zero;
wire word  alu_result;

alu alu (
    .mode(id_alu_mode),
    .operand1(id_alu_op1),
    .operand2(id_alu_op2),
    .zero(alu_zero),
    .result(alu_result)
);


word wb_data;
always_comb begin
    case (id_wb_src_sel)
    WB_SRC_ALU: wb_data = alu_result;
    WB_SRC_PC4: wb_data = id_pc + 4; // could have come from ID directly
    WB_SRC_MEM: wb_data = 32'b0;     // will come from MA stage
    endcase
end  

// TODO: pass alu result to next stage
// TODO: ex_wb_addr should be ex_wb_rd
// TODO: figure out right design for computable hazard signals

// TODO: should hazard signals NOT be clocked?  seems like current design will cost a cycle, or fail to detect hazards.
//       construct a test case and  try it out with the EX stage planning to write a register that ID is reading
//         addi x1, x0, 10
//         addi x2, x1, 10
//       further reading seems to confirm.  do NOT register hazard signals!

//
// Pass-through Signals to MA stage
//

always_ff @(posedge clk) begin
    ex_pc         <= id_pc;
    ex_ir         <= id_ir;
    ex_wb_rd      <= id_wb_rd;
    ex_wb_src_sel <= id_wb_src_sel;
    ex_wb_dst_sel <= id_wb_dst_sel;
    ex_wb_mode    <= id_wb_mode;
end
 
endmodule
