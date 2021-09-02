`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decoder
///

module decoder
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        input  wire word_t         ir_i,       // instruction register
        output wire control_word_t cw_async_o  // control word
    );

initial start_logging();
final stop_logging();


//
// Instruction Unpacking
//

opcode_t     opcode;
regaddr_t    rd;
funct3_t     f3;
regaddr_t    rs1;
regaddr_t    rs2;
funct7_t     f7;
alu_mode_t   alu_mode;

always_comb begin
    { f7, rs2, rs1, f3, rd, opcode } = ir_i;
    alu_mode = alu_mode_t'({ f7[5], f3 });
end


//
// Instruction Decoding
//

control_word_t cw;
assign         cw_async_o = cw;

always_comb begin
    unique casez ({f3, opcode})
    //                                   Halt  PC Mode      Alu Op #1     Alu Op #2     Alu Mode   Memory Mode  Memory Size     Writeback Source  WB Valid?  RA Used?  RB Used?  CSR Used?  Priv?
    //                                   ----  -----------  ------------  ------------  ---------  -----------  --------------  ----------------  ---------  --------  --------  ---------  -----
    { 3'b???,     OP_IMM      }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode,  MA_X,        MA_SIZE_W,      WB_SRC_ALU,       1'b0,      1'b1,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP_LUI      }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1, MA_X,        MA_SIZE_W,      WB_SRC_ALU,       1'b0,      1'b0,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_AUIPC    }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,   MA_X,        MA_SIZE_W,      WB_SRC_ALU,       1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP          }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode,  MA_X,        MA_SIZE_W,      WB_SRC_ALU,       1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_JAL      }: cw = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_W,      WB_SRC_PC4,       1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP_JALR     }: cw = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_W,      WB_SRC_PC4,       1'b0,      1'b1,     1'b0,     1'b0,      1'b0  };
    { F3_BEQ,     OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BNE,     OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BLT,     OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BGE,     OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BLTU,    OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BGEU,    OP_BRANCH   }: cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_LOAD     }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,   MA_LOAD,     ma_size_t'(f3), WB_SRC_MEM,       1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_STORE    }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,   MA_STORE,    ma_size_t'(f3), WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_MISC_MEM }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { F3_PRIV,    OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b1  };
    { F3_CSRRW,   OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRS,   OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRC,   OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRWI,  OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRSI,  OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRCI,  OP_SYSTEM   }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    default:                     cw = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,        MA_SIZE_X,      WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    endcase

    if (opcode == OP_IMM && f3 != F3_SRL_SRA && f3 != F3_SLL)
        cw.alu_mode[3] = 1'b0;

    cw.ra_used  = cw.ra_used && (rs1 != 5'b0);
    cw.rb_used  = cw.rb_used && (rs2 != 5'b0);
    cw.wb_valid = (cw.wb_src != WB_SRC_X) && (rd != 5'b0);
end

endmodule
