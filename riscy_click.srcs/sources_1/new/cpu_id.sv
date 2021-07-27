`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decode Stage
///

module cpu_id
    // Import Constants
    import consts::*;
    (
        // cpu signals
        input  wire logic    clk,            // clock
        input  wire logic    reset,          // reset

        // stage inputs
        input  wire word     if_pc,          // program counter
        input  wire word     if_ir,          // instruction register
        input  wire logic    if_valid,       // fetch stage data is valid
        
        // stage inputs (data hazards)
        input  wire regaddr  hz_ex_wb_addr,     // write-back register address
        input  wire word     hz_ex_wb_data,     // write-back register data
        input  wire logic    hz_ex_wb_valid,    // write-back data valid
        input  wire regaddr  hz_ma_wb_addr,     // write-back register address
        input  wire word     hz_ma_wb_data,     // write-back register data
        input  wire logic    hz_ma_wb_valid,    // write-back data valid
        input  wire regaddr  hz_wb_addr,        // write-back register address
        input  wire word     hz_wb_data,        // write-back register data

        // stage outputs
        output      logic    id_halt,        // halt
                
        // stage outputs (to IF)
        output      logic    id_ready,       // stage ready for new inputs
        output      word     id_jmp_addr,    // jump address
        output      logic    id_jmp_valid,   // jump address valid

        // stage outputs (to EX)
        output      word     id_pc,          // program counter
        output      word     id_ir,          // instruction register
        output      word     id_alu_op1,     // ALU operand 1
        output      word     id_alu_op2,     // ALU operand 2
        output      alu_mode id_alu_mode,    // ALU mode
        output      ma_mode  id_ma_mode,     // memory access mode
        output      ma_size  id_ma_size,     // memory access size
        output      word     id_ma_data,     // memory access data (for store operations)
        output      wb_src   id_wb_src,      // write-back source
        output      regaddr  id_wb_addr      // write-back address (TODO: addr isn't needed.  stages can send back the "rd" bits from IR.)
    );


//
// Instruction Unpacking
//

// Instruction
logic [6:0] opcode;
logic [4:0] rs1, rs2, rd;
funct3      f3;
logic [6:0] f7;

always_comb { f7, rs2, rs1, f3, rd, opcode } = if_ir;

// Immediates
word imm_i, imm_s, imm_b, imm_u, imm_j;

always_comb begin
    imm_i = { {21{if_ir[31]}}, if_ir[30:25], if_ir[24:21], if_ir[20] };
    imm_s = { {21{if_ir[31]}}, if_ir[30:25], if_ir[11:8], if_ir[7] };
    imm_b = { {20{if_ir[31]}}, if_ir[7], if_ir[30:25], if_ir[11:8], 1'b0 };
    imm_u = { if_ir[31], if_ir[30:20], if_ir[19:12], 12'b0 };
    imm_j = { {12{if_ir[31]}}, if_ir[19:12], if_ir[20], if_ir[30:25], if_ir[24:21], 1'b0 };
end

// ALU Modes
alu_mode alu_mode3, alu_mode7;

always_comb begin
    alu_mode7 = alu_mode'({ f7[0], f7[5], f3 });
    alu_mode3 = alu_mode'({ 2'b0, f3 });
end


//
// Register File
//

// output values from register file
wire word ra, rb;

regfile regfile (
    .clk(clk),
    // read from rs1 in the opcode into ra
    .read_addr1(rs1),
    .read_data1(ra),
    // read from rs2 in the opcode into rb
    .read_addr2(rs2),
    .read_data2(rb),
    // let the write-back stage drive the write signals
    .write_addr(hz_wb_addr),
    .write_data(hz_wb_data),
    .write_enable(hz_wb_addr != 5'b00000)
);


//
// DATA HAZARD: Register File
//
// Bypass: If writeback pending for register from EX, MA or WB stage, need to respect that value here.
//

// Resolved register values (when possible)
word ra_resolved, rb_resolved;

// Determine true value for first register access
always_comb begin
    if (rs1 == 5'b00000)
        ra_resolved = ra;
    else if (rs1 == hz_wb_addr)
        ra_resolved = hz_wb_data;
    else if ( rs1 == hz_ma_wb_addr)
        ra_resolved = hz_ma_wb_data;
    else if (rs1 == hz_ex_wb_addr)
        ra_resolved = hz_ex_wb_data;
    else
        ra_resolved = ra;
end

// Determine true value for second register access
always_comb begin
    if (rs2 == 5'b00000)
        rb_resolved = rb;
    else if (rs2 == hz_wb_addr)
        rb_resolved = hz_wb_data;
    else if (rs2 == hz_ma_wb_addr)
        rb_resolved = hz_ma_wb_data;
    else if (rs2 == hz_ex_wb_addr)
        rb_resolved = hz_ex_wb_data;
    else
        rb_resolved = rb;
end


//
// Control Word
//

control_word cw;

always_comb begin
    casez ({reset, f7, f3, opcode})
    { 1'b1, 7'b???????, 3'b???,     7'b??????? }:  cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b0?00000, F3_SRL_SRA, OP_IMM }:      cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode7, MA_X,     MA_SIZE_W,    WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_IMM }:      cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode3, MA_X,     MA_SIZE_W,    WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_LUI }:      cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1, MA_X,     MA_SIZE_W,    WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_AUIPC }:    cw = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,   MA_X,     MA_SIZE_W,    WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP }:          cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode7, MA_X,     MA_SIZE_W,    WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_JAL }:      cw = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_W,    WB_SRC_PC4 };
    { 1'b?, 7'b???????, 3'b???,     OP_JALR }:     cw = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_W,    WB_SRC_PC4 };
    { 1'b?, 7'b???????, F3_BEQ,     OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BNE,     OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BLT,     OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BGE,     OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BLTU,    OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, F3_BGEU,    OP_BRANCH }:   cw = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,   MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, 3'b???,     OP_LOAD }:     cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,   MA_LOAD,  MA_SIZE_W,    WB_SRC_MEM };
    { 1'b?, 7'b???????, 3'b???,     OP_STORE }:    cw = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,   MA_STORE, ma_size'(f3), WB_SRC_ALU };
    { 1'b?, 7'b???????, 3'b???,     OP_MISC_MEM }: cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_X,    WB_SRC_X   };
    { 1'b?, 7'b???????, 3'b???,     OP_SYSTEM }:   cw = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_X,    WB_SRC_X   };
    default:                                       cw = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,     MA_X,     MA_SIZE_X,    WB_SRC_X   };
    endcase
end


//
// ALU Operand #1
//

word next_alu_op1;

always_comb begin
    case (cw.alu_op1_sel)
    ALU_OP1_RS1:                next_alu_op1 = ra_resolved;
    default: /* ALU_OP1_IMMU */ next_alu_op1 = imm_u;
    endcase
end


//
// ALU Operand #2
//

word next_alu_op2;

always_comb begin
    case (cw.alu_op2_sel)
    ALU_OP2_RS2:              next_alu_op2 = rb_resolved;
    ALU_OP2_IMMI:             next_alu_op2 = imm_i;
    ALU_OP2_IMMS:             next_alu_op2 = imm_s;
    default: /* ALU_OP2_PC */ next_alu_op2 = if_pc;
    endcase
end


//
// Jumps and Branches
//

logic next_id_jmp_valid;
word  next_id_jmp_addr;

always_comb begin
    case (cw.pc_mode_sel)
    PC_NEXT:
        begin
            next_id_jmp_valid = 1'b0;
            next_id_jmp_addr  = 32'h00000000;
        end
    PC_JUMP_REL:
        begin
            next_id_jmp_valid = 1'b1;
            next_id_jmp_addr  = if_pc + imm_j;
        end
    PC_JUMP_ABS:
        begin
            next_id_jmp_valid = 1'b1;
            next_id_jmp_addr  = ra_resolved + imm_i;
        end
    default: /* PC_BRANCH */
        begin
            case (f3)
                F3_BEQ:                next_id_jmp_valid = (        ra_resolved  ==         rb_resolved)  ? 1'b1 : 1'b0;
                F3_BNE:                next_id_jmp_valid = (        ra_resolved  ==         rb_resolved)  ? 1'b0 : 1'b1;
                F3_BLT:                next_id_jmp_valid = ($signed(ra_resolved) <  $signed(rb_resolved)) ? 1'b1 : 1'b0;
                F3_BGE:                next_id_jmp_valid = ($signed(ra_resolved) <  $signed(rb_resolved)) ? 1'b0 : 1'b1;
                F3_BLTU:               next_id_jmp_valid = (        ra_resolved  <          rb_resolved)  ? 1'b1 : 1'b0;
                default: /* F3_BGEU */ next_id_jmp_valid = (        ra_resolved  <          rb_resolved)  ? 1'b0 : 1'b1;
            endcase
            next_id_jmp_addr = if_pc + imm_b;
        end
    endcase
end


//
// Outputs
//

// Data Hazard: EX stage has a colliding writeback and the data isn't available yet (ex. JALR or LW)
logic data_hazard_condition;
always_comb data_hazard_condition = ((rs1 != 5'b00000) & ((hz_ex_wb_addr == rs1 & ~hz_ex_wb_valid) | (hz_ma_wb_addr == rs1 & ~hz_ma_wb_valid)))
                                  | ((rs2 != 5'b00000) & ((hz_ex_wb_addr == rs2 & ~hz_ex_wb_valid) | (hz_ma_wb_addr == rs2 & ~hz_ma_wb_valid)));

// a bubble needs to be output if we are in a data hazard condition, or if there was no valid instruction to decode
logic bubble_needed;
always_comb bubble_needed = data_hazard_condition | ~if_valid;

always_comb begin
    if (if_valid) begin
        // otherwise, update based on instruction
        id_jmp_valid = next_id_jmp_valid;
        id_jmp_addr  = next_id_jmp_addr;
        id_ready     = ~data_hazard_condition;
        id_halt      = cw.halt;
    end else begin
        // then indicate we can accept a new one
        id_jmp_valid = 1'b0;
        id_jmp_addr  = 32'h00000000;
        id_ready     = 1'b1;
        id_halt      = 1'b0;
    end
       
    if (reset) begin
        // set initial signal values
        id_jmp_valid = 1'b0;
        id_jmp_addr  = 32'h00000000;
        id_ready     = 1'b1;
        id_halt      = 1'b0;
    end    
end

always_ff @(posedge clk) begin
    // if a bubble is needed
    if (bubble_needed) begin
        // output a NOP to EX stage (addi x0, x0, 0)
        id_pc       <= 32'h00000000;
        id_ir       <= 32'h00000013;
        id_alu_op1  <= 32'h00000000;
        id_alu_op2  <= 32'h00000000;
        id_alu_mode <= ALU_ADD;
        id_ma_mode  <= MA_X;
        id_ma_size  <= MA_SIZE_X;
        id_ma_data  <= 32'h00000000;
        id_wb_addr  <= 5'b00000;
        id_wb_src   <= WB_SRC_ALU;
    end else begin
        // otherwise, output decoded control signals
        id_pc       <= if_pc;
        id_ir       <= if_ir;
        id_alu_op1  <= next_alu_op1;
        id_alu_op2  <= next_alu_op2;
        id_alu_mode <= cw.alu_mode_sel;
        id_ma_mode  <= cw.ma_mode_sel;
        id_ma_size  <= cw.ma_size_sel;
        id_ma_data  <= rb_resolved;
        id_wb_addr  <= rd; // TODO: don't need this.  WB stage can pick it out of IR.
        id_wb_src   <= cw.wb_src_sel;
    end
        
    if (reset) begin
        // output a NOP to EX stage (addi x0, x0, 0)
        id_pc         <= NOP_PC;
        id_ir         <= NOP_IR;
        id_alu_op1    <= 32'h00000000;
        id_alu_op2    <= 32'h00000000;
        id_alu_mode   <= NOP_ALU_MODE;
        id_ma_mode    <= NOP_MA_MODE;
        id_ma_size    <= NOP_MA_SIZE;
        id_ma_data    <= 32'h00000000;
        id_wb_src     <= NOP_WB_SRC;
        id_wb_addr    <= NOP_WB_ADDR;
    end
end

endmodule
