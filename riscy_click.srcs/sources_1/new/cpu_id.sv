`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decode Stage
///

module cpu_id
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic      clk,            // clock
        input  wire logic      ia_rst,         // reset

        // pipeline input port
        input  wire word_t     ic_id_pc,          // program counter
        input  wire word_t     ic_id_ir,          // instruction register
        input  wire logic      ic_id_valid,       // fetch stage data is valid
        
        // data hazard port
        input  wire regaddr_t  ia_hz_ex_addr,     // hazard write-back register address
        input  wire word_t     ia_hz_ex_data,     // hazard write-back register data
        input  wire logic      ia_hz_ex_valid,    // hazard write-back data valid
        input  wire regaddr_t  ia_hz_ma_addr,     // hazard write-back register address
        input  wire word_t     ia_hz_ma_data,     // hazard write-back register data
        input  wire logic      ia_hz_ma_valid,    // hazard write-back data valid
        
        // writeback port
        input  wire regaddr_t  ia_wb_addr,        // write-back register address
        input  wire word_t     ia_wb_data,        // write-back register data

        // backpressure port
        output      logic      oa_ready,       // stage ready for new inputs
        
        // control flow port
        output      word_t     oa_jmp_addr,    // jump address
        output      logic      oa_jmp_valid,   // jump address valid

        // pipeline output port
        output      logic      oc_halt,        // halt
        output      word_t     oc_id_ir,          // instruction register
        output      word_t     oc_id_alu_op1,     // ALU operand 1
        output      word_t     oc_id_alu_op2,     // ALU operand 2
        output      alu_mode_t oc_id_alu_mode,    // ALU mode
        output      ma_mode_t  oc_id_ma_mode,     // memory access mode
        output      ma_size_t  oc_id_ma_size,     // memory access size
        output      word_t     oc_id_ma_data,     // memory access data (for store operations)
        output      wb_src_t   oc_id_wb_src,      // write-back source
        output      word_t     oc_id_wb_data      // write-back data
    );
        

//
// Instruction Unpacking
//

// Instruction
opcode_t  a_opcode;
regaddr_t a_rs1, a_rs2, a_rd;
funct3_t  a_f3;
funct7_t  a_f7;

always_comb { a_f7, a_rs2, a_rs1, a_f3, a_rd, a_opcode } = ic_id_ir;

// Immediates
word_t a_imm_i, a_imm_s, a_imm_b, a_imm_u, a_imm_j;

always_comb begin
    a_imm_i = { {21{ic_id_ir[31]}}, ic_id_ir[30:25], ic_id_ir[24:21], ic_id_ir[20] };
    a_imm_s = { {21{ic_id_ir[31]}}, ic_id_ir[30:25], ic_id_ir[11:8], ic_id_ir[7] };
    a_imm_b = { {20{ic_id_ir[31]}}, ic_id_ir[7], ic_id_ir[30:25], ic_id_ir[11:8], 1'b0 };
    a_imm_u = { ic_id_ir[31], ic_id_ir[30:20], ic_id_ir[19:12], 12'b0 };
    a_imm_j = { {12{ic_id_ir[31]}}, ic_id_ir[19:12], ic_id_ir[20], ic_id_ir[30:25], ic_id_ir[24:21], 1'b0 };
end

// ALU Modes
alu_mode_t a_alu_mode3, a_alu_mode7;

always_comb begin
    a_alu_mode7 = alu_mode_t'({ a_f7[0], a_f7[5], a_f3 });
    a_alu_mode3 = alu_mode_t'({ 2'b0, a_f3 });
end


//
// Register File
//

// output values from register file
wire word_t a_ra, a_rb;

regfile regfile (
    .clk(clk),
    // read from rs1 in the opcode into ra
    .ia_ra_addr(a_rs1),
    .oa_ra_data(a_ra),
    // read from rs2 in the opcode into rb
    .ia_rb_addr(a_rs2),
    .oa_rb_data(a_rb),
    // let the write-back stage drive the write signals
    .ic_wr_addr(ia_wb_addr),
    .ic_wr_data(ia_wb_data),
    .ic_wr_en(1'b1)
);


//
// DATA HAZARD: Register File
//
// Bypass: If writeback pending for register from EX, MA or WB stage, need to respect that value here.
//

// Resolved register values (when possible)
word_t a_ra_resolved, a_rb_resolved;

// Determine true value for first register access
always_comb begin
    priority if (a_rs1 == 5'b00000)
        a_ra_resolved = a_ra;
    else if (a_rs1 == ia_wb_addr)
        a_ra_resolved = ia_wb_data;
    else if (a_rs1 == ia_hz_ma_addr)
        a_ra_resolved = ia_hz_ma_data;
    else if (a_rs1 == ia_hz_ex_addr)
        a_ra_resolved = ia_hz_ex_data;
    else
        a_ra_resolved = a_ra;
end

// Determine true value for second register access
always_comb begin
    priority if (a_rs2 == 5'b00000)
        a_rb_resolved = a_rb;
    else if (a_rs2 == ia_wb_addr)
        a_rb_resolved = ia_wb_data;
    else if (a_rs2 == ia_hz_ma_addr)
        a_rb_resolved = ia_hz_ma_data;
    else if (a_rs2 == ia_hz_ex_addr)
        a_rb_resolved = ia_hz_ex_data;
    else
        a_rb_resolved = a_rb;
end


//
// Control Word
//

control_word_t a_cw;

always_comb begin
    casez ({ia_rst, a_f7, a_f3, a_opcode})
    { 1'b1, 7'b???????, 3'b???,     7'b??????? }:  a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b0?00000, F3_SRL_SRA, OP_IMM }:      a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, a_alu_mode7, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_IMM }:      a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, a_alu_mode3, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_LUI }:      a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1,   MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_AUIPC }:    a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,     MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP }:          a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  a_alu_mode7, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_JAL }:      a_cw = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_W,        WB_SRC_PC4 };
    { 1'b?, 7'b???????, 3'b???,     OP_JALR }:     a_cw = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_W,        WB_SRC_PC4 };
    { 1'b?, 7'b???????, F3_BEQ,     OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BNE,     OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BLT,     OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BGE,     OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BLTU,    OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BGEU,    OP_BRANCH }:   a_cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, 3'b???,     OP_LOAD }:     a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,     MA_LOAD,  MA_SIZE_W,        WB_SRC_MEM };
    { 1'b?, 7'b???????, 3'b???,     OP_STORE }:    a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,     MA_STORE, ma_size_t'(a_f3), WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_MISC_MEM }: a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 1'b?, 7'b???????, 3'b???,     OP_SYSTEM }:   a_cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    default:                                       a_cw = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    endcase
end


//
// ALU Operand #1
//

word_t a_alu_op1_next;

always_comb begin
    unique case (a_cw.alu_op1)
    ALU_OP1_RS1:  a_alu_op1_next = a_ra_resolved;
    ALU_OP1_IMMU: a_alu_op1_next = a_imm_u;
    endcase
end


//
// ALU Operand #2
//

word_t a_alu_op2_next;

always_comb begin
    unique case (a_cw.alu_op2)
    ALU_OP2_RS2:  a_alu_op2_next = a_rb_resolved;
    ALU_OP2_IMMI: a_alu_op2_next = a_imm_i;
    ALU_OP2_IMMS: a_alu_op2_next = a_imm_s;
    ALU_OP2_PC:   a_alu_op2_next = ic_id_pc;
    endcase
end


//
// Jumps and Branches
//

logic  a_jmp_valid_next;
word_t a_jmp_addr_next;

always_comb begin
    unique case (a_cw.pc_mode)
    PC_NEXT:
        begin
            a_jmp_valid_next = 1'b0;
            a_jmp_addr_next  = 32'h00000000;
        end
    PC_JUMP_REL:
        begin
            a_jmp_valid_next = 1'b1;
            a_jmp_addr_next  = ic_id_pc + a_imm_j;
        end
    PC_JUMP_ABS:
        begin
            a_jmp_valid_next = 1'b1;
            a_jmp_addr_next  = a_ra_resolved + a_imm_i;
        end
    PC_BRANCH:
        begin
//            unique case (a_f3)
//                F3_BEQ:  a_jmp_valid_next = (        a_ra_resolved  ==         a_rb_resolved)  ? 1'b1 : 1'b0;
//                F3_BNE:  a_jmp_valid_next = (        a_ra_resolved  ==         a_rb_resolved)  ? 1'b0 : 1'b1;
//                F3_BLT:  a_jmp_valid_next = (signed'(a_ra_resolved) <  signed'(a_rb_resolved)) ? 1'b1 : 1'b0;
//                F3_BGE:  a_jmp_valid_next = (signed'(a_ra_resolved) <  signed'(a_rb_resolved)) ? 1'b0 : 1'b1;
//                F3_BLTU: a_jmp_valid_next = (        a_ra_resolved  <          a_rb_resolved)  ? 1'b1 : 1'b0;
//                F3_BGEU: a_jmp_valid_next = (        a_ra_resolved  <          a_rb_resolved)  ? 1'b0 : 1'b1;
//            endcase

            unique case (a_f3[2:1])
                2'b00:  a_jmp_valid_next = (        a_ra_resolved  ==         a_rb_resolved);
                2'b10:  a_jmp_valid_next = (signed'(a_ra_resolved) <  signed'(a_rb_resolved));
                2'b11:  a_jmp_valid_next = (        a_ra_resolved  <          a_rb_resolved);
            endcase
            a_jmp_valid_next = a_f3[0] ? !a_jmp_valid_next : a_jmp_valid_next;
            a_jmp_addr_next = ic_id_pc + a_imm_b;
        end
    endcase
end


//
// Outputs
//

// Data Hazard: EX stage has a colliding writeback and the data isn't available yet (ex. JALR or LW)
logic a_data_hazard;
always_comb a_data_hazard = ((a_rs1 != 5'b00000) && ((ia_hz_ex_addr == a_rs1 && !ia_hz_ex_valid) || (ia_hz_ma_addr == a_rs1 && !ia_hz_ma_valid)))
                         || ((a_rs2 != 5'b00000) && ((ia_hz_ex_addr == a_rs2 && !ia_hz_ex_valid) || (ia_hz_ma_addr == a_rs2 && !ia_hz_ma_valid)));

// a bubble needs to be output if we are in a data hazard condition, or if there was no valid instruction to decode
logic a_bubble;
always_comb a_bubble = a_data_hazard | ~ic_id_valid;

// control flow
always_comb begin
    if (ic_id_valid) begin
        // if instruction is valid, so is our jump feedback
        oa_jmp_valid = a_jmp_valid_next;
        oa_jmp_addr  = a_jmp_addr_next;
    end else begin
        // otherwise, it's not
        oa_jmp_valid = 1'b0;
        oa_jmp_addr  = 32'h00000000;
    end
       
    if (ia_rst) begin
        // set initial signal values
        oa_jmp_valid = 1'b0;
        oa_jmp_addr  = 32'h00000000;
    end    
end

// backpressure
always_comb begin
    if (ic_id_valid) begin
        // if instruction is valid, so is our data hazard determination
        oa_ready = ~a_data_hazard;
    end else begin
        // otherwise, we are ready for a valid instruction
        oa_ready = 1'b1;
    end
       
    if (ia_rst) begin
        // set initial signal values
        oa_ready = 1'b1;
    end    
end

// pipeline output
always_ff @(posedge clk) begin
    // if a bubble is needed
    if (a_bubble) begin
        // output a NOP (addi x0, x0, 0)
        oc_id_ir       <= NOP_IR;
        oc_id_alu_op1  <= 32'h00000000;
        oc_id_alu_op2  <= 32'h00000000;
        oc_id_alu_mode <= NOP_ALU_MODE;
        oc_id_ma_mode  <= NOP_MA_MODE;
        oc_id_ma_size  <= NOP_MA_SIZE;
        oc_id_ma_data  <= 32'h00000000;
        oc_id_wb_src   <= NOP_WB_SRC;
        oc_id_wb_data  <= 32'h00000000;
        oc_halt        <= 1'b0;
    end else begin
        // otherwise, output decoded control signals
        oc_id_ir       <= ic_id_ir;
        oc_id_alu_op1  <= a_alu_op1_next;
        oc_id_alu_op2  <= a_alu_op2_next;
        oc_id_alu_mode <= a_cw.alu_mode;
        oc_id_ma_mode  <= a_cw.ma_mode;
        oc_id_ma_size  <= a_cw.ma_size;
        oc_id_ma_data  <= a_rb_resolved;
        oc_id_wb_src   <= a_cw.wb_src;
        oc_id_wb_data  <= (a_cw.wb_src == WB_SRC_PC4) ? (ic_id_pc + 4) : 32'h00000000;
        oc_halt        <= a_cw.halt;
    end
        
    if (ia_rst) begin
        // output a NOP (addi x0, x0, 0)
        oc_id_ir       <= NOP_IR;
        oc_id_alu_op1  <= 32'h00000000;
        oc_id_alu_op2  <= 32'h00000000;
        oc_id_alu_mode <= NOP_ALU_MODE;
        oc_id_ma_mode  <= NOP_MA_MODE;
        oc_id_ma_size  <= NOP_MA_SIZE;
        oc_id_ma_data  <= 32'h00000000;
        oc_id_wb_src   <= NOP_WB_SRC;
        oc_id_wb_data  <= 32'h00000000;
        oc_halt        <= 1'b0;
    end
end

endmodule
