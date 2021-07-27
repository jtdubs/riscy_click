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
        input  wire ma_mode     id_ma_mode,     // memory access mode
        input  wire wb_src      id_wb_src,      // write-back source
        input  wire regaddr     id_wb_addr,     // write-back address
        input  wire wb_mode     id_wb_mode,     // write-back enable
        
        // stage outputs (data hazards)
        output      logic       hz_ex_wb_enable,   // write-back enabled
        output      regaddr     hz_ex_wb_addr,     // write-back address
        output      word        hz_ex_wb_data,     // write-back value
        output      logic       hz_ex_wb_valid,    // write-back value valid

        // stage outputs (to MA)
        output      word        ex_pc,          // program counter
        output      word        ex_ir,          // instruction register
        output      word        ex_alu_result,  // alu result
        output      ma_mode     ex_ma_mode,     // memory access mode
        output      wb_src      ex_wb_src,      // write-back source
        output      regaddr     ex_wb_addr,     // write-back register address
        output      word        ex_wb_data,     // write-back register value
        output      wb_mode     ex_wb_mode      // write-back mode
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


//
// Hazard Signals
//

always_comb begin
    hz_ex_wb_enable = (id_wb_mode == WB_MODE_X) ? 1'b0 : 1'b1;
    
    case (id_wb_src)
    WB_SRC_ALU:
        begin
            hz_ex_wb_addr   = id_wb_addr;
            hz_ex_wb_data   = alu_result;
            hz_ex_wb_valid  = 1'b1;
        end  
    WB_SRC_PC4:
        begin
            hz_ex_wb_addr   = id_wb_addr;
            hz_ex_wb_data   = id_pc + 4; // NOTE: could have come from ID directly
            hz_ex_wb_valid  = 1'b1;
        end
    WB_SRC_MEM:
        begin
            hz_ex_wb_addr   = id_wb_addr;
            hz_ex_wb_data   = 32'b0;
            hz_ex_wb_valid  = 1'b0; // will come from MA stage
        end
    endcase
end  


//
// Pass-through Signals to MA stage
//

always_ff @(posedge clk) begin
    ex_pc         <= id_pc;
    ex_ir         <= id_ir;
    ex_alu_result <= alu_result;
    ex_ma_mode    <= id_ma_mode;
    ex_wb_src     <= id_wb_src;
    ex_wb_addr    <= id_wb_addr;
    ex_wb_data    <= hz_ex_wb_data;
    ex_wb_mode    <= id_wb_mode;
end

endmodule
