`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decoder
///

module decoder
    // Import Constants
    import common::*;
    import logging::*;
    (
        input  wire word_t         ir_i,       // instruction register
        output      control_word_t cw_async_o  // control word
    );

initial start_logging();
final stop_logging();


//
// Instruction Unpacking
//

opcode_t     opcode_w;
regaddr_t    rd_w;
funct3_t     f3_w;
regaddr_t    rs1_w;
regaddr_t    rs2_w;
funct7_t     f7_w;
alu_mode_t   alu_mode_w;

always_comb begin
    { f7_w, rs2_w, rs1_w, f3_w, rd_w, opcode_w } = ir_i;
    alu_mode_w = alu_mode_t'({ f7_w[5], f3_w });
end


//
// Instruction Decoding
//

control_word_t cw_w;

always_comb begin
    unique casez ({f3_w, opcode_w})
    //                                     Halt  PC Mode      Alu Op #1     Alu Op #2     Alu Mode     Memory Mode  Memory Size       Writeback Source  WB Valid?  RA Used?  RB Used?  CSR Used?  Priv?
    //                                     ----  -----------  ------------  ------------  -----------  -----------  ----------------  ----------------  ---------  --------  --------  ---------  -----
    { 3'b???,     OP_IMM      }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode_w,  MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,      1'b1,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP_LUI      }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1,   MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,      1'b0,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_AUIPC    }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,     MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP          }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode_w,  MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_JAL      }: cw_w = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_W,        WB_SRC_PC4,       1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { 3'b???,     OP_JALR     }: cw_w = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_W,        WB_SRC_PC4,       1'b0,      1'b1,     1'b0,     1'b0,      1'b0  };
    { F3_BEQ,     OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BNE,     OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BLT,     OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BGE,     OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BLTU,    OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { F3_BGEU,    OP_BRANCH   }: cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_LOAD     }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,     MA_LOAD,     ma_size_t'(f3_w), WB_SRC_MEM,       1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_STORE    }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,     MA_STORE,    ma_size_t'(f3_w), WB_SRC_X,         1'b0,      1'b1,     1'b1,     1'b0,      1'b0  };
    { 3'b???,     OP_MISC_MEM }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    { F3_PRIV,    OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b1  };
    { F3_CSRRW,   OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRS,   OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRC,   OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b1,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRWI,  OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRSI,  OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    { F3_CSRRCI,  OP_SYSTEM   }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b1,      1'b0  };
    default:                     cw_w = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,      1'b0,     1'b0,     1'b0,      1'b0  };
    endcase

    if (opcode_w == OP_IMM && f3_w != F3_SRL_SRA && f3_w != F3_SLL)
        cw_w.alu_mode[3] = 1'b0;

    cw_w.ra_used  = cw_w.ra_used && (rs1_w != 5'b0);
    cw_w.rb_used  = cw_w.rb_used && (rs2_w != 5'b0);
    cw_w.wb_valid = (cw_w.wb_src != WB_SRC_X) && (rd_w != 5'b0);
end

assign cw_async_o = cw_w;

endmodule
