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
        input  wire logic      clk_i,               // clock
        input  wire logic      reset_i,             // reset_i
        output      logic      halt_o,              // halt

        // pipeline input
        input  wire word_t     pc_i,                // program counter
        input  wire word_t     ir_i,                // instruction register
        
        // async input
        input  wire regaddr_t  ex_wb_addr_async_i,  // ex stage write-back address
        input  wire word_t     ex_wb_data_async_i,  // ex stage write-back data
        input  wire logic      ex_wb_ready_async_i, // ex stage write-back data ready
        input  wire logic      ex_wb_valid_async_i, // ex stage write-back valid
        input  wire logic      ex_empty_async_i,    // ex stage empty
        input  wire regaddr_t  ma_wb_addr_async_i,  // ma stage write-back address
        input  wire word_t     ma_wb_data_async_i,  // ma stage write-back data
        input  wire logic      ma_wb_ready_async_i, // ma stage write-back data ready
        input  wire logic      ma_wb_valid_async_i, // ma stage write-back valid
        input  wire logic      ma_empty_async_i,    // ma stage empty
        input  wire regaddr_t  wb_addr_async_i,     // write-back address
        input  wire word_t     wb_data_async_i,     // write-back data
        input  wire logic      wb_valid_async_i,    // write-back valid
        input  wire logic      wb_empty_async_i,    // wb stage empty

        // async output
        output      logic      ready_async_o,       // stage ready for new inputs
        output      word_t     jmp_addr_async_o,    // jump address
        output      logic      jmp_valid_async_o,   // jump address valid

        // pipeline output
        output      word_t     pc_o,                // program counter
        output      word_t     ir_o,                // instruction register
        output      word_t     alu_op1_o,           // ALU operand 1
        output      word_t     alu_op2_o,           // ALU operand 2
        output      alu_mode_t alu_mode_o,          // ALU mode
        output      ma_mode_t  ma_mode_o,           // memory access mode
        output      ma_size_t  ma_size_o,           // memory access size
        output      word_t     ma_data_o,           // memory access data (for store operations)
        output      wb_src_t   wb_src_o,            // write-back source
        output      word_t     wb_data_async_o,     // write-back data
        output      logic      wb_valid_async_o     // write-back destination
    );

initial start_logging();
final stop_logging();


//
// Instruction Unpacking
//

opcode_t   opcode_w;
regaddr_t  rs1_w;
regaddr_t  rs2_w;
regaddr_t  rd_w;
funct3_t   f3_w;
funct7_t   f7_w;
csr_t      csr_w;
word_t     imm_i_w;
word_t     imm_s_w;
word_t     imm_b_w;
word_t     imm_u_w;
word_t     imm_j_w;
word_t     uimm_w;
alu_mode_t alu_mode3_w;
alu_mode_t alu_mode7_w;

always_comb begin
    { csr_w, rs1_w, f3_w, rd_w, opcode_w } = ir_i;
    { f7_w, rs2_w } = csr_w;

    imm_i_w = { {21{ir_i[31]}}, ir_i[30:25], ir_i[24:21], ir_i[20] };
    imm_s_w = { {21{ir_i[31]}}, ir_i[30:25], ir_i[11:8], ir_i[7] };
    imm_b_w = { {20{ir_i[31]}}, ir_i[7], ir_i[30:25], ir_i[11:8], 1'b0 };
    imm_u_w = { ir_i[31], ir_i[30:20], ir_i[19:12], 12'b0 };
    imm_j_w = { {12{ir_i[31]}}, ir_i[19:12], ir_i[20], ir_i[30:25], ir_i[24:21], 1'b0 };
    uimm_w  = { 26'b0, ir_i[19:15] };
    
    alu_mode7_w = alu_mode_t'({ f7_w[0], f7_w[5], f3_w });
    alu_mode3_w = alu_mode_t'({ 2'b0, f3_w });
end


//
// Instruction Decoding
//

control_word_t cw_w;

always_comb begin
    casez ({f7_w, f3_w, opcode_w})
    //                                                 Halt  PC Mode      Alu Op #1     Alu Op #1     Alu Mode     Memory Mode  Memory Size       Writeback Source  RA Used?  RB Used?  CSR Used?
    //                                                 ----  -----------  ------------  ------------  -----------  -----------  ----------------  ----------------  --------  --------  ---------
    { 7'b0?00000, F3_SRL_SRA, OP_IMM }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode7_w, MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b1,     1'b0,     1'b0 };
    { 7'b???????, 3'b???,     OP_IMM }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, alu_mode3_w, MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b1,     1'b0,     1'b0 };
    { 7'b???????, 3'b???,     OP_LUI }:      cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_RS2,  ALU_COPY1,   MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,     1'b1,     1'b0 };
    { 7'b???????, 3'b???,     OP_AUIPC }:    cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_IMMU, ALU_OP2_PC,   ALU_ADD,     MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b0,     1'b0,     1'b0 };
    { 7'b???????, 3'b???,     OP }:          cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_RS2,  alu_mode7_w, MA_X,        MA_SIZE_W,        WB_SRC_ALU,       1'b1,     1'b1,     1'b0 };
    { 7'b???????, 3'b???,     OP_JAL }:      cw_w = '{ 1'b0, PC_JUMP_REL, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_W,        WB_SRC_PC4,       1'b0,     1'b0,     1'b0 };
    { 7'b???????, 3'b???,     OP_JALR }:     cw_w = '{ 1'b0, PC_JUMP_ABS, ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_W,        WB_SRC_PC4,       1'b1,     1'b0,     1'b0 };
    { 7'b???????, F3_BEQ,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, F3_BNE,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, F3_BLT,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, F3_BGE,     OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, F3_BLTU,    OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, F3_BGEU,    OP_BRANCH }:   cw_w = '{ 1'b0, PC_BRANCH,   ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, 3'b???,     OP_LOAD }:     cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMI, ALU_ADD,     MA_LOAD,     MA_SIZE_W,        WB_SRC_MEM,       1'b1,     1'b1,     1'b0 };
    { 7'b???????, 3'b???,     OP_STORE }:    cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_RS1,  ALU_OP2_IMMS, ALU_ADD,     MA_STORE,    ma_size_t'(f3_w), WB_SRC_X,         1'b1,     1'b1,     1'b0 };
    { 7'b???????, 3'b???,     OP_MISC_MEM }: cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b0 };
    { 7'b???????, F3_PRIV,    OP_SYSTEM }:   cw_w = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b0 };
    { 7'b???????, F3_CSRRW,   OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b0,     1'b1 };
    { 7'b???????, F3_CSRRS,   OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b0,     1'b1 };
    { 7'b???????, F3_CSRRC,   OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b1,     1'b0,     1'b1 };
    { 7'b???????, F3_CSRRWI,  OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b1 };
    { 7'b???????, F3_CSRRSI,  OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b1 };
    { 7'b???????, F3_CSRRCI,  OP_SYSTEM }:   cw_w = '{ 1'b0, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b1 };
    default:                                 cw_w = '{ 1'b1, PC_NEXT,     ALU_OP1_X,    ALU_OP2_X,    ALU_X,       MA_X,        MA_SIZE_X,        WB_SRC_X,         1'b0,     1'b0,     1'b0 };
    endcase
end

logic wb_valid_w;
logic ra_used_w;
logic rb_used_w;

always_comb begin
    wb_valid_w = (cw_w.wb_src != WB_SRC_X) && (rd_w != 5'b0);
    ra_used_w  = cw_w.ra_used && (rs1_w != 5'b0);
    rb_used_w  = cw_w.rb_used && (rs2_w != 5'b0);
end


//
// Register File Access
//

// output values from register file
wire word_t ra_w;
wire word_t rb_w;
regaddr_t wb_addr_w;
word_t wb_data_w;
logic  wb_enable_w;

regfile regfile (
    .clk_i              (clk_i),
    // read from rs1 in the opcode into ra
    .read1_addr_async_i (rs1_w),
    .read1_data_async_o (ra_w),
    // read from rs2 in the opcode into rb
    .read2_addr_async_i (rs2_w),
    .read2_data_async_o (rb_w),
    // let the write-back stage drive the write signals
    .write_addr_i       (wb_addr_w),
    .write_data_i       (wb_data_w),
    .write_enable_i     (wb_enable_w)
);



//
// CSR File Access
//

csr_t  csr_read_addr_w;
logic  csr_read_enable_w;
word_t csr_read_data_w;
csr_t  csr_write_addr_w;
word_t csr_write_data_w;
logic  csr_write_enable_w;

cpu_csr csr (
    .clk_i              (clk_i),
    .reset_i            (reset_i),
    .retired_i          (!wb_empty_async_i || csr_state_r == CSR_STATE_EXECUTING),
    // read port
    .csr_read_addr_i    (csr_read_addr_w),
    .csr_read_enable_i  (csr_read_enable_w),
    .csr_read_data_o    (csr_read_data_w),
    // write port
    .csr_write_addr_i   (csr_write_addr_w),
    .csr_write_data_i   (csr_write_data_w),
    .csr_write_enable_i (csr_write_enable_w)
);


//
// Writeback Bypass
//

// Bypassed Values
word_t ra_bypassed_w;
word_t rb_bypassed_w;

// determine true value for first register access
always_comb begin
    priority if (rs1_w == 5'b00000)
        ra_bypassed_w = ra_w;
    else if (ex_wb_valid_async_i && rs1_w == ex_wb_addr_async_i)
        ra_bypassed_w = ex_wb_data_async_i;
    else if (ma_wb_valid_async_i && rs1_w == ma_wb_addr_async_i)
        ra_bypassed_w = ma_wb_data_async_i;
    else if (wb_valid_async_i && rs1_w == wb_addr_async_i)
        ra_bypassed_w = wb_data_async_i;
    else
        ra_bypassed_w = ra_w;
end

// Determine true value for second register access
always_comb begin
    priority if (rs2_w == 5'b00000)
        rb_bypassed_w = rb_w;
    else if (ex_wb_valid_async_i && rs2_w == ex_wb_addr_async_i)
        rb_bypassed_w = ex_wb_data_async_i;
    else if (ma_wb_valid_async_i && rs2_w == ma_wb_addr_async_i)
        rb_bypassed_w = ma_wb_data_async_i;
    else if (wb_valid_async_i && rs2_w == wb_addr_async_i)
        rb_bypassed_w = wb_data_async_i;
    else
        rb_bypassed_w = rb_w;
end


//
// ALU Operands
//

word_t alu_op1_w;
word_t alu_op2_w;

always_comb begin
    unique case (cw_w.alu_op1)
    ALU_OP1_X:    alu_op1_w = 32'b0;
    ALU_OP1_RS1:  alu_op1_w = ra_bypassed_w;
    ALU_OP1_IMMU: alu_op1_w = imm_u_w;
    endcase
end

always_comb begin
    unique case (cw_w.alu_op2)
    ALU_OP2_X:    alu_op2_w = 32'b0;
    ALU_OP2_RS2:  alu_op2_w = rb_bypassed_w;
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
            jmp_addr_w  = ra_bypassed_w + imm_i_w;
        end
    PC_BRANCH:
        begin
            unique case (f3_w[2:1])
                2'b00:  jmp_valid_w = (        ra_bypassed_w  ==         rb_bypassed_w);
                2'b10:  jmp_valid_w = (signed'(ra_bypassed_w) <  signed'(rb_bypassed_w));
                2'b11:  jmp_valid_w = (        ra_bypassed_w  <          rb_bypassed_w);
            endcase
            jmp_valid_w = f3_w[0] ? !jmp_valid_w : jmp_valid_w;
            jmp_addr_w  = pc_i + imm_b_w;
        end
    endcase
end


//
// Outputs
//

// data hazard
logic data_hazard_w, ra_collision_w, rb_collision_w;

always_comb begin
    ra_collision_w = ra_used_w && ((ex_wb_valid_async_i && ex_wb_addr_async_i == rs1_w && !ex_wb_ready_async_i) || (ma_wb_valid_async_i && ma_wb_addr_async_i == rs1_w && !ma_wb_ready_async_i));
    rb_collision_w = rb_used_w && ((ex_wb_valid_async_i && ex_wb_addr_async_i == rs2_w && !ex_wb_ready_async_i) || (ma_wb_valid_async_i && ma_wb_addr_async_i == rs2_w && !ma_wb_ready_async_i));
    data_hazard_w  = ra_collision_w || rb_collision_w;
end


// control flow
always_comb begin
    $fstrobe(log_fd, "{ \"stage\": \"ID\", \"time\": \"%0t\", \"pc\": \"%0d\", \"jmp_valid\": \"%0d\", \"jmp_addr\": \"%0d\" },", $time, pc_i, jmp_valid_async_o, jmp_addr_async_o);

    jmp_valid_async_o = jmp_valid_w;
    jmp_addr_async_o  = jmp_addr_w;
       
    if (reset_i) begin
        // set initial signal values
        jmp_valid_async_o = 1'b0;
        jmp_addr_async_o  = 32'h00000000;
    end    
end


// CSR state machine
typedef enum logic [1:0] {
    CSR_STATE_IDLE      = 2'b00,
    CSR_STATE_FLUSHING  = 2'b01,
    CSR_STATE_EXECUTING = 2'b10
} csr_state_t;

csr_state_t csr_state_r, csr_state_w;
logic csr_idle_action_w;
logic csr_flush_action_w;
logic csr_wait_action_w;
logic csr_read_action_w;
logic csr_write_action_w;

always_comb begin
    csr_idle_action_w  = (csr_state_r == CSR_STATE_IDLE)     && ~cw_w.csr_used;
    csr_flush_action_w = (csr_state_r == CSR_STATE_IDLE)     &&  cw_w.csr_used;
    csr_wait_action_w  = (csr_state_r == CSR_STATE_FLUSHING) && ~(ex_empty_async_i && ma_empty_async_i && wb_empty_async_i);
    csr_read_action_w  = (csr_state_r == CSR_STATE_FLUSHING) &&  (ex_empty_async_i && ma_empty_async_i && wb_empty_async_i);
    csr_write_action_w = (csr_state_r == CSR_STATE_EXECUTING);
end

always_comb begin
    unique if (csr_idle_action_w | csr_write_action_w)
        csr_state_w = CSR_STATE_IDLE;
    else if (csr_flush_action_w | csr_wait_action_w)
        csr_state_w = CSR_STATE_FLUSHING;
    else
        csr_state_w = CSR_STATE_EXECUTING;
end

// TODO: actually do the register writebacks lol...
always_comb begin
    // always read and write from the CSR specified in the instruction
    csr_read_addr_w  <= csr_w;
    csr_write_addr_w <= csr_w;
    
    // read on read action unless there's nowhere to put it
    csr_read_enable_w  = csr_read_action_w && rd_w != 5'b0;
   
    unique case (f3_w)
    F3_CSRRW,  // the RW variations always write on exec action
    F3_CSRRWI: csr_write_enable_w = csr_write_action_w;
    F3_CSRRS,  // the Set/Clear variations write on exec action unless x0 is specified
    F3_CSRRC:  csr_write_enable_w = csr_write_action_w && (rs1_w != 5'b0);
    F3_CSRRSI, // the Set/Clear Immediate variations write on exec action unless the immediate value is 0
    F3_CSRRCI: csr_write_enable_w = csr_write_action_w && (uimm_w != 32'b0);
    default:   csr_write_enable_w = 1'b0;
    endcase
    
    unique case (f3_w)
    F3_CSRRW:  csr_write_data_w = ra_bypassed_w;                    // 
    F3_CSRRWI: csr_write_data_w = uimm_w;
    F3_CSRRS:  csr_write_data_w = csr_read_data_w | ra_bypassed_w;
    F3_CSRRSI: csr_write_data_w = csr_read_data_w | uimm_w;
    F3_CSRRC:  csr_write_data_w = csr_read_data_w & ~ra_bypassed_w;
    F3_CSRRCI: csr_write_data_w = csr_read_data_w & ~uimm_w;
    default:   csr_write_data_w = 32'b0;
    endcase
end

always_comb begin
    // If CSR is writing, it owns the register file's write port
    if (csr_write_action_w) begin
        wb_addr_w   = rd_w;
        wb_data_w   = csr_read_data_w;
        wb_enable_w = csr_write_action_w && rd_w != 5'b0;
    // Otherwise, it comes from the writeback stage
    end else begin
        wb_addr_w   = wb_addr_async_i;
        wb_data_w   = wb_data_async_i;
        wb_enable_w = wb_valid_async_i;
    end  
end

always_ff @(posedge clk_i) begin
    $fdisplay(log_fd, "{ \"stage\": \"ID\", \"time\": \"%0t\", \"pc\": \"%0d\", \"csr_addr\": \"%0d\", \"csr_state\": \"%0d\", \"csr_read_data\": \"%0d\", \"csr_write_data\": \"%0d\", \"csr_wb_addr\": \"%0d\", \"csr_wb_enable\": \"%0d\", \"csr_write_enable\": \"%0d\" },", $time, pc_i, csr_w, csr_state_r, csr_read_data_w, csr_write_data_w, wb_addr_w, wb_enable_w, csr_write_enable_w);
    
    csr_state_r <= csr_state_w;
end


// backpressure
always_comb begin
    $fstrobe(log_fd, "{ \"stage\": \"ID\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ready\": \"%0d\" },", $time, pc_i, ready_async_o);

    // we only want a new instruction if we aren't dealing with a datac hazard, and we aren't going to be dealing with a CSR instruction
    ready_async_o = ~data_hazard_w && (csr_state_w == CSR_STATE_IDLE);
          
    if (reset_i) begin
        // set initial signal values
        ready_async_o = 1'b1;
    end    
end


// pipeline output
always_ff @(posedge clk_i) begin
    $fstrobe(log_fd, "{ \"stage\": \"ID\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"alu_op1\": \"%0d\", \"alu_op2\": \"%0d\", \"alu_mode\": \"%0d\", \"ma_mode\": \"%0d\", \"ma_size\": \"%0d\", \"ma_data\": \"%0d\", \"wb_src\": \"%0d\", \"wb_data\": \"%0d\", \"wb_dst\": \"%0d\", \"halt\": \"%0d\" },", $time, pc_o, ir_o, alu_op1_o, alu_op2_o, alu_mode_o, ma_mode_o, ma_size_o, ma_data_o, wb_src_o, wb_data_async_o, wb_valid_async_o, halt_o);
    
    // if a bubble is needed
    if (data_hazard_w || csr_flush_action_w || csr_wait_action_w || csr_read_action_w || csr_write_action_w) begin
        // output a NOP (addi x0, x0, 0)
        pc_o       <= NOP_PC;
        ir_o       <= NOP_IR;
        alu_op1_o  <= 32'b0;
        alu_op2_o  <= 32'b0;
        alu_mode_o <= NOP_ALU_MODE;
        ma_mode_o  <= NOP_MA_MODE;
        ma_size_o  <= NOP_MA_SIZE;
        ma_data_o  <= 32'b0;
        wb_src_o   <= NOP_WB_SRC;
        wb_data_async_o  <= 32'b0;
        wb_valid_async_o <= NOP_WB_VALID;
        halt_o     <= 1'b0;
    end else begin
        // otherwise, output decoded control signals
        pc_o       <= pc_i;
        ir_o       <= ir_i;
        alu_op1_o  <= alu_op1_w;
        alu_op2_o  <= alu_op2_w;
        alu_mode_o <= cw_w.alu_mode;
        ma_mode_o  <= cw_w.ma_mode;
        ma_size_o  <= cw_w.ma_size;
        ma_data_o  <= rb_bypassed_w;
        wb_src_o   <= cw_w.wb_src;
        wb_data_async_o  <= pc_i + 4;
        wb_valid_async_o <= wb_valid_w;
        halt_o     <= cw_w.halt;
    end
        
    if (reset_i) begin
        // output a NOP (addi x0, x0, 0)
        pc_o       <= NOP_PC;
        ir_o       <= NOP_IR;
        alu_op1_o  <= 32'b0;
        alu_op2_o  <= 32'b0;
        alu_mode_o <= NOP_ALU_MODE;
        ma_mode_o  <= NOP_MA_MODE;
        ma_size_o  <= NOP_MA_SIZE;
        ma_data_o  <= 32'b0;
        wb_src_o   <= NOP_WB_SRC;
        wb_data_async_o  <= 32'b0;
        wb_valid_async_o <= NOP_WB_VALID;
        halt_o     <= 1'b0;
    end
end

endmodule
