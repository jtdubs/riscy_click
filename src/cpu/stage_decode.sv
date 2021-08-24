`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Decode Stage
///

module stage_decode
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic      clk_i,               // clock
        output      logic      halt_o,              // halt

        // pipeline input
        input  wire word_t     pc_i,                // program counter
        input  wire word_t     ir_i,                // instruction register
        input  wire word_t     pc_next_i,           // next program counter
        input  wire regaddr_t  ex_wb_addr_i,        // ex stage write-back address
        input  wire word_t     ex_wb_data_i,        // ex stage write-back data
        input  wire logic      ex_wb_ready_i,       // ex stage write-back data ready
        input  wire logic      ex_wb_valid_i,       // ex stage write-back valid
        input  wire logic      ex_empty_i,          // ex stage empty
        input  wire regaddr_t  ma_wb_addr_i,        // ma stage write-back address
        input  wire word_t     ma_wb_data_i,        // ma stage write-back data
        input  wire logic      ma_wb_ready_i,       // ma stage write-back data ready
        input  wire logic      ma_wb_valid_i,       // ma stage write-back valid
        input  wire logic      ma_empty_i,          // ma stage empty
        input  wire regaddr_t  wb_addr_i,           // write-back address
        input  wire word_t     wb_data_i,           // write-back data
        input  wire logic      wb_valid_i,          // write-back valid
        input  wire logic      wb_empty_i,          // wb stage empty

        // async output
        output      logic      ready_async_o,       // stage ready for new inputs
        output      word_t     jmp_addr_async_o,    // jump address
        output      logic      jmp_valid_async_o,   // jump address valid

        // csr interface
        output      logic      csr_retired_o,       // instruction retirement indicator
        output      word_t     csr_trap_pc_o,       // trap program counter
        output      mcause_t   csr_mcause_o,        // trap cause
        output      logic      csr_mtrap_o,         // trap needed
        output      logic      csr_mret_o,          // trap return needed
        input  wire word_t     csr_jmp_addr_i,      // trap addr to jump to
        input  wire logic      csr_jmp_request_i,   // trap addr valid
        output      logic      csr_jmp_accept_o,    // jump accept
        output      csr_t      csr_read_addr_o,     // csr read address
        output      logic      csr_read_enable_o,   // csr read enable
        input  wire word_t     csr_read_data_i,     // csr read data
        output      csr_t      csr_write_addr_o,    // csr write address
        output      word_t     csr_write_data_o,    // csr write data
        output      logic      csr_write_enable_o,  // csr write enable

        // pipeline output
        output wire word_t     pc_o,                // program counter
        output wire word_t     ir_o,                // instruction register
        output wire word_t     alu_op1_o,           // ALU operand 1
        output wire word_t     alu_op2_o,           // ALU operand 2
        output wire alu_mode_t alu_mode_o,          // ALU mode
        output wire ma_mode_t  ma_mode_o,           // memory access mode
        output wire ma_size_t  ma_size_o,           // memory access size
        output wire word_t     ma_data_o,           // memory access data (for store operations)
        output wire wb_src_t   wb_src_o,            // write-back source
        output wire word_t     wb_data_o,           // write-back data
        output wire logic      wb_valid_o           // write-back destination
    );

initial start_logging();
final stop_logging();


//
// Instruction Unpacking
//

regaddr_t    rs1;
regaddr_t    rs2;
regaddr_t    rd;
funct3_t     f3;
funct12_t    f12;
csr_t        csr;
word_t       imm_i;
word_t       imm_s;
word_t       imm_b;
word_t       imm_u;
word_t       imm_j;
word_t       uimm;
logic [11:0] f12_bits;

always_comb begin
    { f12_bits, rs1, f3, rd } = ir_i[31:7];
    rs2 = f12_bits[4:0];
    csr = f12_bits;
    f12 = f12_bits;

    imm_i = { {21{ir_i[31]}}, ir_i[30:25], ir_i[24:21], ir_i[20] };
    imm_s = { {21{ir_i[31]}}, ir_i[30:25], ir_i[11:8], ir_i[7] };
    imm_b = { {20{ir_i[31]}}, ir_i[7], ir_i[30:25], ir_i[11:8], 1'b0 };
    imm_u = { ir_i[31], ir_i[30:20], ir_i[19:12], 12'b0 };
    imm_j = { {12{ir_i[31]}}, ir_i[19:12], ir_i[20], ir_i[30:25], ir_i[24:21], 1'b0 };
    uimm  = { 27'b0, ir_i[19:15] };
end


//
// Instruction Decoding
//

wire control_word_t cw;

decoder decoder (
    .ir_i       (ir_i),
    .cw_async_o (cw)
);


//
// Privileged Operations
//

// gating jump requests
always_comb begin
    csr_jmp_accept_o = csr_jmp_request_i && (pc_i != NOP_PC) && ready_async_o;
end

// traps and returns
logic wfi;
always_comb begin
    csr_trap_pc_o = pc_i;
    csr_mtrap_o   = 1'b0;
    csr_mret_o    = 1'b0;
    csr_mcause_o  = '{ 1'b0, 31'b0 };
    wfi           = 1'b0;

    if (cw.priv) begin
        unique case (f12)
        F12_ECALL:
            begin
                csr_mtrap_o  = 1'b1;
                csr_mcause_o = '{ 1'b0, ECALL_M        };
            end
        F12_EBREAK:
            begin
                csr_mtrap_o  = 1'b1;
                csr_mcause_o = '{ 1'b0, EXC_BREAKPOINT };
            end
        F12_MRET,
        F12_SRET:
            begin
                csr_mret_o   = 1'b1;
            end
        F12_WFI:
            begin
                csr_trap_pc_o = pc_next_i;
                wfi           = !csr_jmp_request_i;
            end
        endcase
    end
end


//
// Data Hazard Detection
//

logic data_hazard, ra_collision, rb_collision;

always_comb begin
    ra_collision = cw.ra_used && ((ex_wb_valid_i && ex_wb_addr_i == rs1 && !ex_wb_ready_i) || (ma_wb_valid_i && ma_wb_addr_i == rs1 && !ma_wb_ready_i));
    rb_collision = cw.rb_used && ((ex_wb_valid_i && ex_wb_addr_i == rs2 && !ex_wb_ready_i) || (ma_wb_valid_i && ma_wb_addr_i == rs2 && !ma_wb_ready_i));
    data_hazard  = ra_collision || rb_collision;
end


//
// Register File Access
//

// output values from register file
wire word_t    ra;
wire word_t    rb;
     regaddr_t wb_addr;
     word_t    wb_data;
     logic     wb_enable;

regfile regfile (
    .clk_i              (clk_i),
    .read1_addr_i       (rs1),
    .read1_data_async_o (ra),
    .read2_addr_i       (rs2),
    .read2_data_async_o (rb),
    .write_addr_i       (wb_addr),
    .write_data_i       (wb_data),
    .write_enable_i     (wb_enable)
);


//
// Register File Bypass
//

// Bypassed Values
word_t ra_bypassed;
word_t rb_bypassed;

// determine bypassed value for first register access
always_comb begin
    priority if (ex_wb_valid_i && rs1 == ex_wb_addr_i)
        ra_bypassed = ex_wb_data_i;
    else if (ma_wb_valid_i && rs1 == ma_wb_addr_i)
        ra_bypassed = ma_wb_data_i;
    else if (wb_valid_i && rs1 == wb_addr_i)
        ra_bypassed = wb_data_i;
    else
        ra_bypassed = ra;
end

// Determine bypassed value for second register access
always_comb begin
    priority if (ex_wb_valid_i && rs2 == ex_wb_addr_i)
        rb_bypassed = ex_wb_data_i;
    else if (ma_wb_valid_i && rs2 == ma_wb_addr_i)
        rb_bypassed = ma_wb_data_i;
    else if (wb_valid_i && rs2 == wb_addr_i)
        rb_bypassed = wb_data_i;
    else
        rb_bypassed = rb;
end


//
// ALU Operands
//

word_t alu_op1_next;
word_t alu_op2_next;

always_comb begin
    unique case (cw.alu_op1)
    ALU_OP1_X:    alu_op1_next = 32'b0;
    ALU_OP1_RS1:  alu_op1_next = ra_bypassed;
    ALU_OP1_IMMU: alu_op1_next = imm_u;
    endcase
end

always_comb begin
    unique case (cw.alu_op2)
    ALU_OP2_X:    alu_op2_next = 32'b0;
    ALU_OP2_RS2:  alu_op2_next = rb_bypassed;
    ALU_OP2_IMMI: alu_op2_next = imm_i;
    ALU_OP2_IMMS: alu_op2_next = imm_s;
    ALU_OP2_PC:   alu_op2_next = pc_i;
    endcase
end


//
// CSR Read/Write State Machine
//

// states
typedef enum logic [1:0] {
    CSR_STATE_IDLE      = 2'b00,
    CSR_STATE_FLUSHING  = 2'b01,
    CSR_STATE_EXECUTING = 2'b10
} csr_state_t;

// transitions
csr_state_t csr_state_r = CSR_STATE_IDLE;
csr_state_t csr_state_next;
logic csr_idle_action;   // normal idle transition
logic csr_flush_action;  // start processing a CSR by flushing the pipeline
logic csr_wait_action;   // continuing to flush pipeline
logic csr_read_action;   // reading current CSR value
logic csr_write_action;  // writing new CSR value and performing register write-back

// determine transition
always_comb begin
    csr_idle_action  = (csr_state_r == CSR_STATE_IDLE)     && ~cw.csr_used;
    csr_flush_action = (csr_state_r == CSR_STATE_IDLE)     &&  cw.csr_used;
    csr_wait_action  = (csr_state_r == CSR_STATE_FLUSHING) && ~(ex_empty_i && ma_empty_i && wb_empty_i);
    csr_read_action  = (csr_state_r == CSR_STATE_FLUSHING) &&  (ex_empty_i && ma_empty_i && wb_empty_i);
    csr_write_action = (csr_state_r == CSR_STATE_EXECUTING);
end

// determine next state
/* verilator lint_off LATCH */
always_comb begin
    unique if (csr_idle_action || csr_write_action)
        csr_state_next = CSR_STATE_IDLE;
    else if (csr_flush_action || csr_wait_action)
        csr_state_next = CSR_STATE_FLUSHING;
    else if (csr_read_action)
        csr_state_next = CSR_STATE_EXECUTING;
end
/* verilator lint_on LATCH */

// update CSR control signals
always_comb begin
    // always read and write from the CSR specified in the instruction
    csr_read_addr_o  = csr;
    csr_write_addr_o = csr;

    // read on read action unless there's nowhere to put it
    csr_read_enable_o  = csr_read_action && rd != 5'b0;

    unique case (f3)
    F3_CSRRW,  // the RW variations always write on exec action
    F3_CSRRWI: csr_write_enable_o = csr_write_action;
    F3_CSRRS,  // the Set/Clear variations write on exec action unless x0 is specified
    F3_CSRRC:  csr_write_enable_o = csr_write_action && (rs1 != 5'b0);
    F3_CSRRSI, // the Set/Clear Immediate variations write on exec action unless the immediate value is 0
    F3_CSRRCI: csr_write_enable_o = csr_write_action && (uimm != 32'b0);
    default:   csr_write_enable_o = 1'b0;
    endcase

    unique case (f3)
    F3_CSRRW:  csr_write_data_o = ra_bypassed;                    // 
    F3_CSRRWI: csr_write_data_o = uimm;
    F3_CSRRS:  csr_write_data_o = csr_read_data_i | ra_bypassed;
    F3_CSRRSI: csr_write_data_o = csr_read_data_i | uimm;
    F3_CSRRC:  csr_write_data_o = csr_read_data_i & ~ra_bypassed;
    F3_CSRRCI: csr_write_data_o = csr_read_data_i & ~uimm;
    default:   csr_write_data_o = 32'b0;
    endcase

    // consider this an instruction retirement if writeback stage is retiring OR we are
    csr_retired_o = !wb_empty_i || csr_state_r == CSR_STATE_EXECUTING;
end

// update regfile writeback control siganls
always_comb begin
    // If CSR is writing, it owns the register file's write port
    unique if (csr_write_action) begin
        wb_addr   = rd;
        wb_data   = csr_read_data_i;
        wb_enable = csr_write_action && rd != 5'b0;
    // Otherwise, it comes from the writeback stage
    end else begin
        wb_addr   = wb_addr_i;
        wb_data   = wb_data_i;
        wb_enable = wb_valid_i;
    end
end

// advance to next state
always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"ID\", \"pc\": \"%0d\", \"csr_addr\": \"%0d\", \"csr_state\": \"%0d\", \"csr_read_data\": \"%0d\", \"csr_write_data\": \"%0d\", \"csr_wb_addr\": \"%0d\", \"csr_wb_enable\": \"%0d\", \"csr_write_enable\": \"%0d\" }", pc_i, csr, csr_state_r, csr_read_data_i, csr_write_data_o, wb_addr, wb_enable, csr_write_enable_o));

    csr_state_r <= csr_state_next;
end


//
// Async Output
//

logic branch_condition;
always_comb begin
    unique case (f3[2:1])
        2'b00: branch_condition = (        ra_bypassed  ==         rb_bypassed);
        2'b10: branch_condition = (signed'(ra_bypassed) <  signed'(rb_bypassed));
        2'b11: branch_condition = (        ra_bypassed  <          rb_bypassed);
        2'b01: branch_condition = 1'b0;
    endcase
    branch_condition = f3[0] ? !branch_condition : branch_condition;
end

always_comb begin
    // jump signals
    unique if (csr_jmp_request_i && csr_jmp_accept_o) begin
        jmp_valid_async_o = 1'b1;
        jmp_addr_async_o  = csr_jmp_addr_i;
    end else begin
        unique case (cw.pc_mode)
        PC_NEXT:
            begin
                jmp_valid_async_o = 1'b0;
                jmp_addr_async_o  = 32'h00000000;
            end
        PC_JUMP_REL:
            begin
                jmp_valid_async_o = 1'b1;
                jmp_addr_async_o  = pc_i + imm_j;
            end
        PC_JUMP_ABS:
            begin
                jmp_valid_async_o = !data_hazard;
                jmp_addr_async_o  = ra_bypassed + imm_i;
            end
        PC_BRANCH:
            begin
                jmp_valid_async_o = branch_condition && !data_hazard;
                jmp_addr_async_o  = pc_i + imm_b;
            end
        endcase
    end
end

always_comb begin
    // we only want a new instruction if we aren't dealing with a data hazard, and we aren't going to be dealing with a CSR instruction
    ready_async_o = !data_hazard && (csr_state_next == CSR_STATE_IDLE) && !wfi;

    `log_display(("{ \"stage\": \"ID\", \"pc\": \"%0d\", \"jmp_valid\": \"%0d\", \"jmp_addr\": \"%0d\", \"ready\": \"%0d\" }", pc_i, jmp_valid_async_o, jmp_addr_async_o, ready_async_o));
end


//
// Pipeline Output
//

word_t     pc_r       = NOP_PC;
assign     pc_o       = pc_r;

word_t     ir_r       = NOP_IR;
assign     ir_o       = ir_r;

word_t     alu_op1_r  = 32'b0;
assign     alu_op1_o  = alu_op1_r;

word_t     alu_op2_r  = 32'b0;
assign     alu_op2_o  = alu_op2_r;

alu_mode_t alu_mode_r = NOP_ALU_MODE;
assign     alu_mode_o = alu_mode_r;

ma_mode_t  ma_mode_r  = NOP_MA_MODE;
assign     ma_mode_o  = ma_mode_r;

ma_size_t  ma_size_r  = NOP_MA_SIZE;
assign     ma_size_o  = ma_size_r;

word_t     ma_data_r  = 32'b0;
assign     ma_data_o  = ma_data_r;

wb_src_t   wb_src_r   = NOP_WB_SRC;
assign     wb_src_o   = wb_src_r;

word_t     wb_data_r  = 32'b0;
assign     wb_data_o  = wb_data_r;

logic      wb_valid_r = NOP_WB_VALID;
assign     wb_valid_o = wb_valid_r;

logic      halt_r     = 1'b0;
assign     halt_o     = halt_r;

always_ff @(posedge clk_i) begin
    // if a bubble is needed
    if (data_hazard || !csr_idle_action || wfi) begin
        // output a NOP (addi x0, x0, 0)
        pc_r       <= NOP_PC;
        ir_r       <= NOP_IR;
        alu_op1_r  <= 32'b0;
        alu_op2_r  <= 32'b0;
        alu_mode_r <= NOP_ALU_MODE;
        ma_mode_r  <= NOP_MA_MODE;
        ma_size_r  <= NOP_MA_SIZE;
        ma_data_r  <= 32'b0;
        wb_src_r   <= NOP_WB_SRC;
        wb_data_r  <= 32'b0;
        wb_valid_r <= NOP_WB_VALID;
        halt_r     <= 1'b0;
    end else begin
        // otherwise, output decoded control signals
        pc_r       <= pc_i;
        ir_r       <= ir_i;
        alu_op1_r  <= alu_op1_next;
        alu_op2_r  <= alu_op2_next;
        alu_mode_r <= cw.alu_mode;
        ma_mode_r  <= cw.ma_mode;
        ma_size_r  <= cw.ma_size;
        ma_data_r  <= rb_bypassed;
        wb_src_r   <= cw.wb_src;
        wb_data_r  <= pc_next_i;
        wb_valid_r <= cw.wb_valid;
        halt_r     <= cw.halt;
    end

    // $display("[ID (%x)] PC=%x, IR=%x | JMP=%x, %x | CSR JMP=%x, %x, %x | PC=%x, IR=%x", ready_async_o, pc_i, ir_i, jmp_addr_async_o, jmp_valid_async_o, csr_jmp_request_i, csr_jmp_addr_i, csr_jmp_accept_o, pc_o, ir_o);
    `log_strobe(("{ \"stage\": \"ID\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"alu_op1\": \"%0d\", \"alu_op2\": \"%0d\", \"alu_mode\": \"%0d\", \"ma_mode\": \"%0d\", \"ma_size\": \"%0d\", \"ma_data\": \"%0d\", \"wb_src\": \"%0d\", \"wb_data\": \"%0d\", \"wb_dst\": \"%0d\", \"halt\": \"%0d\" }", pc_r, ir_r, alu_op1_r, alu_op2_r, alu_mode_r, ma_mode_r, ma_size_r, ma_data_r, wb_src_r, wb_data_r, wb_valid_r, halt_r));
end

endmodule
