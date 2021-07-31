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
        input  wire logic      clk_i,         // clock
        input  wire logic      reset_i,       // reset_i
        output      logic      halt_o,        // halt

        // pipeline input port
        input  wire word_t     pc_i,          // program counter
        input  wire word_t     ir_i,          // instruction register
        input  wire logic      valid_i,       // fetch stage data is valid
        
        // data hazard port
        input  wire regaddr_t  ex_wb_addr_i,  // hazard write-back register address
        input  wire word_t     ex_wb_data_i,  // hazard write-back register data
        input  wire logic      ex_wb_valid_i, // hazard write-back data valid
        input  wire regaddr_t  ma_wb_addr_i,  // hazard write-back register address
        input  wire word_t     ma_wb_data_i,  // hazard write-back register data
        input  wire logic      ma_wb_valid_i, // hazard write-back data valid
        
        // writeback port
        input  wire regaddr_t  wb_addr_i,     // write-back register address
        input  wire word_t     wb_data_i,     // write-back register data

        // backpressure port
        output      logic      ready_async_o, // stage ready for new inputs
        
        // control flow port
        output      word_t     jmp_addr_o,    // jump address
        output      logic      jmp_valid_o,   // jump address valid

        // pipeline output port
        output      word_t     ir_o,          // instruction register
        output      word_t     alu_op1_o,     // ALU operand 1
        output      word_t     alu_op2_o,     // ALU operand 2
        output      alu_mode_t alu_mode_o,    // ALU mode
        output      ma_mode_t  ma_mode_o,     // memory access mode
        output      ma_size_t  ma_size_o,     // memory access size
        output      word_t     ma_data_o,     // memory access data (for store operations)
        output      wb_src_t   wb_src_o,      // write-back source
        output      word_t     wb_data_o      // write-back data
    );
        

//
// Instruction Unpacking
//

// Instruction
opcode_t  opcode_w;
regaddr_t rs1_w;
regaddr_t rs2_w;
regaddr_t rd_w;
funct3_t  f3_w;
funct7_t  f7_w;

always_comb { f7_w, rs2_w, rs1_w, f3_w, rd_w, opcode_w } = ir_i;

// Immediates
word_t imm_i_w;
word_t imm_s_w;
word_t imm_b_w;
word_t imm_u_w;
word_t imm_j_w;

always_comb begin
    imm_i_w = { {21{ir_i[31]}}, ir_i[30:25], ir_i[24:21], ir_i[20] };
    imm_s_w = { {21{ir_i[31]}}, ir_i[30:25], ir_i[11:8], ir_i[7] };
    imm_b_w = { {20{ir_i[31]}}, ir_i[7], ir_i[30:25], ir_i[11:8], 1'b0 };
    imm_u_w = { ir_i[31], ir_i[30:20], ir_i[19:12], 12'b0 };
    imm_j_w = { {12{ir_i[31]}}, ir_i[19:12], ir_i[20], ir_i[30:25], ir_i[24:21], 1'b0 };
end

// ALU Modes
alu_mode_t alu_mode3_w;
alu_mode_t alu_mode7_w;

always_comb begin
    alu_mode7_w = alu_mode_t'({ f7_w[0], f7_w[5], f3_w });
    alu_mode3_w = alu_mode_t'({ 2'b0, f3_w });
end


//
// Register File
//

// output values from register file
wire word_t ra_w;
wire word_t rb_w;

regfile regfile (
    .clk_i              (clk_i),
    // read from rs1 in the opcode into ra
    .read1_addr_async_i (rs1_w),
    .read1_data_async_o (ra_w),
    // read from rs2 in the opcode into rb
    .read2_addr_async_i (rs2_w),
    .read2_data_async_o (rb_w),
    // let the write-back stage drive the write signals
    .write_addr_i       (wb_addr_i),
    .write_data_i       (wb_data_i),
    .write_enable_i     (1'b1)
);


//
// DATA HAZARD: Register File
//
// Bypass: If writeback pending for register from EX, MA or WB stage, need to respect that value here.
//

// Resolved register values (when possible)
word_t ra_resolved_w;
word_t rb_resolved_w;

// Determine true value for first register access
always_comb begin
    priority if (rs1_w == 5'b00000)
        ra_resolved_w = ra_w;
    else if (rs1_w == wb_addr_i)
        ra_resolved_w = wb_data_i;
    else if (rs1_w == ma_wb_addr_i)
        ra_resolved_w = ma_wb_data_i;
    else if (rs1_w == ex_wb_addr_i)
        ra_resolved_w = ex_wb_data_i;
    else
        ra_resolved_w = ra_w;
end

// Determine true value for second register access
always_comb begin
    priority if (rs2_w == 5'b00000)
        rb_resolved_w = rb_w;
    else if (rs2_w == wb_addr_i)
        rb_resolved_w = wb_data_i;
    else if (rs2_w == ma_wb_addr_i)
        rb_resolved_w = ma_wb_data_i;
    else if (rs2_w == ex_wb_addr_i)
        rb_resolved_w = ex_wb_data_i;
    else
        rb_resolved_w = rb_w;
end


//
// Control Word
//

control_word_t cw_w;

always_comb begin
    casez ({f7_w, f3_w, opcode_w})
    { 7'b0?00000, F3_SRL_SRA, OP_IMM }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode7_w, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP_IMM }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode3_w, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP_LUI }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1,   MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP_AUIPC }:    cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,     MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP }:          cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode7_w, MA_X,     MA_SIZE_W,        WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP_JAL }:      cw_w = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_W,        WB_SRC_PC4 };
    { 7'b???????, 3'b???,     OP_JALR }:     cw_w = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_W,        WB_SRC_PC4 };
    { 7'b???????, F3_BEQ,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, F3_BNE,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SUB,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, F3_BLT,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, F3_BGE,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_SLT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, F3_BLTU,    OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, F3_BGEU,    OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_RS1,  ALU_OP2_RS2,  ALU_ULT,     MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, 3'b???,     OP_LOAD }:     cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,     MA_LOAD,  MA_SIZE_W,        WB_SRC_MEM };
    { 7'b???????, 3'b???,     OP_STORE }:    cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,     MA_STORE, ma_size_t'(f3_w), WB_SRC_ALU };
    { 7'b???????, 3'b???,     OP_MISC_MEM }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    { 7'b???????, 3'b???,     OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    default:                                 cw_w = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,     MA_SIZE_X,        WB_SRC_X   };
    endcase
end


//
// ALU Operands
//

word_t alu_op1_w;
word_t alu_op2_w;

always_comb begin
    unique case (cw_w.alu_op1)
    ALU_OP1_RS1:  alu_op1_w = ra_resolved_w;
    ALU_OP1_IMMU: alu_op1_w = imm_u_w;
    endcase
end

always_comb begin
    unique case (cw_w.alu_op2)
    ALU_OP2_RS2:  alu_op2_w = rb_resolved_w;
    ALU_OP2_IMMI: alu_op2_w = imm_i_w;
    ALU_OP2_IMMS: alu_op2_w = imm_s_w;
    ALU_OP2_PC:   alu_op2_w = pc_i;
    endcase
end


//
// Jumps and Branches
//

logic  jmp_valid_w;
word_t jmp_addr_w;

always_comb begin
    unique case (cw_w.pc_mode)
    PC_NEXT:
        begin
            jmp_valid_w = 1'b0;
            jmp_addr_w  = 32'h00000000;
        end
    PC_JUMP_REL:
        begin
            jmp_valid_w = 1'b1;
            jmp_addr_w  = pc_i + imm_j_w;
        end
    PC_JUMP_ABS:
        begin
            jmp_valid_w = 1'b1;
            jmp_addr_w  = ra_resolved_w + imm_i_w;
        end
    PC_BRANCH:
        begin
//            unique case (f3_w)
//                F3_BEQ:  jmp_valid_w = (        ra_resolved_w  ==         rb_resolved_w)  ? 1'b1 : 1'b0;
//                F3_BNE:  jmp_valid_w = (        ra_resolved_w  ==         rb_resolved_w)  ? 1'b0 : 1'b1;
//                F3_BLT:  jmp_valid_w = (signed'(ra_resolved_w) <  signed'(rb_resolved_w)) ? 1'b1 : 1'b0;
//                F3_BGE:  jmp_valid_w = (signed'(ra_resolved_w) <  signed'(rb_resolved_w)) ? 1'b0 : 1'b1;
//                F3_BLTU: jmp_valid_w = (        ra_resolved_w  <          rb_resolved_w)  ? 1'b1 : 1'b0;
//                F3_BGEU: jmp_valid_w = (        ra_resolved_w  <          rb_resolved_w)  ? 1'b0 : 1'b1;
//            endcase

            unique case (f3_w[2:1])
                2'b00:  jmp_valid_w = (        ra_resolved_w  ==         rb_resolved_w);
                2'b10:  jmp_valid_w = (signed'(ra_resolved_w) <  signed'(rb_resolved_w));
                2'b11:  jmp_valid_w = (        ra_resolved_w  <          rb_resolved_w);
            endcase
            jmp_valid_w = f3_w[0] ? !jmp_valid_w : jmp_valid_w;
            jmp_addr_w  = pc_i + imm_b_w;
        end
    endcase
end


//
// Outputs
//

// Data Hazard: EX stage has a colliding writeback and the data isn't available yet (ex. JALR or LW)
logic data_hazard_w;
always_comb data_hazard_w = ((rs1_w != 5'b00000) && ((ex_wb_addr_i == rs1_w && !ex_wb_valid_i) || (ma_wb_addr_i == rs1_w && !ma_wb_valid_i)))
                         || ((rs2_w != 5'b00000) && ((ex_wb_addr_i == rs2_w && !ex_wb_valid_i) || (ma_wb_addr_i == rs2_w && !ma_wb_valid_i)));

// a bubble needs to be output if we are in a data hazard condition, or if there was no valid instruction to decode
logic bubble_w;
always_comb bubble_w = data_hazard_w | ~valid_i;

// control flow
always_comb begin
    if (valid_i) begin
        // if instruction is valid, so is our jump feedback
        jmp_valid_o = jmp_valid_w;
        jmp_addr_o  = jmp_addr_w;
    end else begin
        // otherwise, it's not
        jmp_valid_o = 1'b0;
        jmp_addr_o  = 32'h00000000;
    end
       
    if (reset_i) begin
        // set initial signal values
        jmp_valid_o = 1'b0;
        jmp_addr_o  = 32'h00000000;
    end    
end

// backpressure
always_comb begin
    if (valid_i) begin
        // if instruction is valid, so is our data hazard determination
        ready_async_o = ~data_hazard_w;
    end else begin
        // otherwise, we are ready for a valid instruction
        ready_async_o = 1'b1;
    end
       
    if (reset_i) begin
        // set initial signal values
        ready_async_o = 1'b1;
    end    
end

// pipeline output
always_ff @(posedge clk_i) begin
    // if a bubble is needed
    if (bubble_w) begin
        // output a NOP (addi x0, x0, 0)
        ir_o       <= NOP_IR;
        alu_op1_o  <= 32'h00000000;
        alu_op2_o  <= 32'h00000000;
        alu_mode_o <= NOP_ALU_MODE;
        ma_mode_o  <= NOP_MA_MODE;
        ma_size_o  <= NOP_MA_SIZE;
        ma_data_o  <= 32'h00000000;
        wb_src_o   <= NOP_WB_SRC;
        wb_data_o  <= 32'h00000000;
        halt_o     <= 1'b0;
    end else begin
        // otherwise, output decoded control signals
        ir_o       <= ir_i;
        alu_op1_o  <= alu_op1_w;
        alu_op2_o  <= alu_op2_w;
        alu_mode_o <= cw_w.alu_mode;
        ma_mode_o  <= cw_w.ma_mode;
        ma_size_o  <= cw_w.ma_size;
        ma_data_o  <= rb_resolved_w;
        wb_src_o   <= cw_w.wb_src;
        wb_data_o  <= pc_i + 4;
        halt_o     <= cw_w.halt;
    end
        
    if (reset_i) begin
        // output a NOP (addi x0, x0, 0)
        ir_o       <= NOP_IR;
        alu_op1_o  <= 32'h00000000;
        alu_op2_o  <= 32'h00000000;
        alu_mode_o <= NOP_ALU_MODE;
        ma_mode_o  <= NOP_MA_MODE;
        ma_size_o  <= NOP_MA_SIZE;
        ma_data_o  <= 32'h00000000;
        wb_src_o   <= NOP_WB_SRC;
        wb_data_o  <= 32'h00000000;
        halt_o     <= 1'b0;
    end
end

endmodule
