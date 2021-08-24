`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Compress Instruction Decompressor
///

module decompressor
    // Import Constants
    import common::*;
    import cpu_common::*;
    import logging::*;
    (
        // instruction
        input  wire word_t ir_i,         // instruction register

        // async input
        output wire word_t ir_o,         // decompressed instruction register
        output wire logic  compressed_o  // indicates whether or not the input was compressed
    );

initial start_logging();
final stop_logging();

// output signals
word_t ir;
assign ir_o = ir;

logic  compressed;
assign compressed_o = compressed;

// unpacking
regaddr_t    rs1;
regaddr_t    rs1s;
regaddr_t    rs2;
regaddr_t    rs2s;
logic [11:0] imm_ciw;
logic [11:0] imm_cl;
logic [19:0] imm_ci;
logic [20:1] imm_cj;
logic [12:1] imm_cb;
logic [11:0] imm_lwsp;
logic [11:0] imm_swsp;
logic [19:0] jump_target;
logic [ 4:0] shamt;

always_comb begin
    rs1         = ir_i[11: 7];
    rs2         = ir_i[ 6: 2];
    rs1s        = { 2'b01, ir_i[9:7] };
    rs2s        = { 2'b01, ir_i[4:2] };
    imm_ciw     = { 2'b00, ir_i[10:7], ir_i[12:11], ir_i[5], ir_i[6], 2'b00 };
    imm_cl      = { 5'b0, ir_i[5], ir_i[12:10], ir_i[6], 2'b0 };
    imm_ci      = { {15{ir_i[12]}}, ir_i[6:2] };
    imm_cj      = { {10{ir_i[12]}}, ir_i[8], ir_i[10:9], ir_i[6], ir_i[7], ir_i[2], ir_i[11], ir_i[5:3] };
    imm_cb      = { {5{ir_i[12]}}, ir_i[6:5], ir_i[2], ir_i[11:10], ir_i[4:3] };
    imm_lwsp    = { 4'b0, ir_i[3:2], ir_i[12], ir_i[6:4], 2'b00 };
    imm_swsp    = { 4'b0, ir_i[8:7], ir_i[12:9], 2'b00 };
    jump_target = { imm_cj[20], imm_cj[10:1], imm_cj[11], imm_cj[19:12] };
    shamt       = imm_ci[4:0];
end

// decompressing
always_comb begin
    compressed = ir_i[1:0] != 2'b11;

    priority casez (ir_i[15:0])
        //
        // QUADRANT 0
        //

        // C.ADDI4SPN -> addi rd', x2, nzuimm
        16'b00000000000???00: ir = NOP_IR;
        16'b000???????????00: ir = { imm_ciw, 5'b00010, F3_ADD_SUB, rs2s, OP_IMM };

        // C.LW -> lw rd', offset(rs1')
        16'b010???????????00: ir = { imm_cl, rs1s, F3_LW, rs2s, OP_LOAD };

        // C.SW -> sw rs2', offset(rs1')
        16'b110???????????00: ir = { imm_cl[11:5], rs2s, rs1s, F3_SW, imm_cl[4:0], OP_STORE };

        //
        // QUADRANT 1
        //

        // C.NOP -> nop
        16'b0000000000000001: ir = NOP_IR;
        16'b000?00000?????01: ir = NOP_IR;

        // C.ADDI -> addi rd, rd, nzimm
        16'b0000?????0000001: ir = NOP_IR;
        // 16'b000?00000?????01: ir = NOP_IR;
        16'b000???????????01: ir = { imm_ci[11:0], rs1, F3_ADD_SUB, rs1, OP_IMM };

        // C.JAL -> jal x1, offset
        16'b001???????????01: ir = { jump_target, 5'b00001, OP_JAL };

        // C.LI -> addi rd, x0, imm
        16'b010?00000?????01: ir = NOP_IR;
        16'b010???????????01: ir = { imm_ci[11:0], 5'b00000, F3_ADD_SUB, rs1, OP_IMM };

        // C.ADDI16SP -> addi x2, x2, nzimm
        16'b0110?????0000001: ir = NOP_IR;
        16'b011?00010?????01: ir = { { {3{ir_i[12]}}, ir_i[4:3], ir_i[5], ir_i[2], ir_i[6], 4'b000 }, 5'b00010, F3_ADD_SUB, 5'b00010, OP_IMM };

        // C.LUI -> lui rd, nzimm
        16'b011?000?0?????01: ir = NOP_IR;
        16'b011???????????01: ir = { imm_ci, rs1, OP_LUI };

        // C.SRLI -> srli rd', rd', shamt
        16'b100000???0000001: ir = NOP_IR;
        16'b100?00????????01: ir = { 7'b0000000, shamt, rs1s, F3_SRL_SRA, rs1s, OP_IMM };

        // C.SRAI -> srai rd', rd', shamt
        16'b100?01???0000001: ir = NOP_IR;
        16'b100?01????????01: ir = { 7'b0100000, shamt, rs1s, F3_SRL_SRA, rs1s, OP_IMM };

        // C.ANDI -> andi rd', rd', imm
        16'b100?10????????01: ir = { imm_ci[11:0], rs1s, F3_AND, rs1s, OP_IMM };

        // C.SUB -> sub rd', rd', rs2'
        16'b100011???00???01: ir = { 7'b0100000, rs2s, rs1s, F3_ADD_SUB, rs1s, OP };

        // C.XOR -> xor rd', rd', rs2'
        16'b100011???01???01: ir = { 7'b0000000, rs2s, rs1s, F3_XOR, rs1s, OP };

        // C.OR -> or rd', rd', rs2'
        16'b100011???10???01: ir = { 7'b0000000, rs2s, rs1s, F3_OR, rs1s, OP };

        // C.AND -> and rd', rd', rs2'
        16'b100011???11???01: ir = { 7'b0000000, rs2s, rs1s, F3_AND, rs1s, OP };

        // Reserved
        16'b100111???1????01: ir = NOP_IR;

        // C.J -> jal x0, offset
        16'b101???????????01: ir = { jump_target, 5'b00000, OP_JAL };

        // C.BEQZ -> beq rs1', x0, offset
        16'b110???????????01: ir = { imm_cb[12], imm_cb[10:5], 5'b0000, rs1s, F3_BEQ, imm_cb[4:1], imm_cb[11], OP_BRANCH };

        // C.BNEZ -> bne rs1', x0, offset
        16'b111???????????01: ir = { imm_cb[12], imm_cb[10:5], 5'b0000, rs1s, F3_BNE, imm_cb[4:1], imm_cb[11], OP_BRANCH };

        //
        // QUADRANT 2
        //

        // C.SLLI -> slli rd, rd, shamt
        16'b0000?????0000010: ir = NOP_IR;
        16'b000?00000?????10: ir = NOP_IR;
        16'b000???????????10: ir =  { 7'b0, shamt, rs1, F3_SLL, rs1, OP_IMM };

        // C.LWSP -> lw rd, offset(x2)
        16'b010?00000?????10: ir = NOP_IR;
        16'b010???????????10: ir = { imm_lwsp[11:0], 5'b00010, F3_LW, rs1, OP_LOAD };

        // C.JR -> jalr x0, 0(rs1)
        16'b1000000000000010: ir = NOP_IR;
        16'b1000?????0000010: ir = { 12'b000000000000, rs1, 3'b000, 5'b00000, OP_JALR };

        // C.MV -> add rd, x0, rs2
        // 16'b1000?????0000010: ir = NOP_IR;
        16'b100000000?????10: ir = NOP_IR;
        16'b1000??????????10: ir = { 7'b0, rs2, 5'b00000, F3_ADD_SUB, rs1, OP };

        // C.EBREAK -> ebreak
        16'b1001000000000010: ir = { 12'b000000000001, 5'b00000, 3'b000, 5'b00000, OP_SYSTEM };

        // C.JALR -> jalr x1, 0(rs1)
        // 16'b1001000000000010: ir = NOP_IR;
        16'b1001?????0000010: ir = { 12'b000000000000, rs1, 3'b000, 5'b00001, OP_JALR };

        // C.ADD -> add rd, rd, rs2
        // 16'b1001?????0000010: ir = NOP_IR;
        16'b100100000?????10: ir = NOP_IR;
        16'b1001??????????10: ir = { 7'b0, rs2, rs1, F3_ADD_SUB, rs1, OP };

        // C.SWSP -> sw rs2, offset(x2)
        16'b110???????????10: ir = { imm_swsp[11:5], rs2, 5'b00010, F3_SW, imm_swsp[4:0], OP_STORE };

        // Otherwise, it wasn't compressed
        default:              ir = ir_i;
    endcase

    // $display("DECOMP: In=%h, Out=%h [%d]", ir_i[15:0], ir, compressed);
end

endmodule
