`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Instruction Issue Stage
///

module stage_issue
    // Import Constants
    import common::*;
    import cpu_common::*;
    import csr_common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic           clk_i,

        // decode channel
        input  wire word_t          decode_pc_i,
        input  wire word_t          decode_ir_i,
        input  wire control_word_t  decode_cw_i,
        input  wire word_t          decode_ra_i,
        input  wire word_t          decode_rb_i,
        input  wire logic           decode_valid_i,
        output wire logic           decode_ready_o,

        // bypass channel
        input  wire regaddr_t [3:0] wb_addr_i,
        input  wire word_t    [3:0] wb_data_i,
        input  wire logic     [3:0] wb_valid_i,
        input  wire logic     [3:0] wb_ready_i,

        // pipeline output
        output wire control_word_t  issue_cw_o,
        output wire word_t          issue_alu_op1_o,
        output wire word_t          issue_alu_op2_o,
        output wire logic           issue_valid_o,
        input  wire logic           issue_ready_i
    );

initial start_logging();
final stop_logging();


//
// Unpacking
//

word_t imm_i;
word_t imm_s;
word_t imm_b;
word_t imm_u;
word_t imm_j;

always_comb begin
    imm_i = { {21{decode_ir_i[31]}}, decode_ir_i[30:25], decode_ir_i[24:21], decode_ir_i[20] };
    imm_s = { {21{decode_ir_i[31]}}, decode_ir_i[30:25], decode_ir_i[11:8], decode_ir_i[7] };
    imm_b = { {20{decode_ir_i[31]}}, decode_ir_i[7], decode_ir_i[30:25], decode_ir_i[11:8], 1'b0 };
    imm_u = { decode_ir_i[31], decode_ir_i[30:20], decode_ir_i[19:12], 12'b0 };
    imm_j = { {12{decode_ir_i[31]}}, decode_ir_i[19:12], decode_ir_i[20], decode_ir_i[30:25], decode_ir_i[24:21], 1'b0 };
end


//
// Bypass Logic
//

word_t bypass_ra;
word_t bypass_rb;
logic  bypass_ra_valid;
logic  bypass_rb_valid;
regaddr_t rs1;
regaddr_t rs2;
logic valid;

always_comb begin
    rs1 = decode_ir_i[19:15];
    rs2 = decode_ir_i[24:20];

    bypass_ra = decode_ra_i;
    bypass_ra = (wb_valid_i[3] && wb_addr_i[3] == rs1) ? wb_data_i[3] : bypass_ra;
    bypass_ra = (wb_valid_i[2] && wb_addr_i[2] == rs1) ? wb_data_i[2] : bypass_ra;
    bypass_ra = (wb_valid_i[1] && wb_addr_i[1] == rs1) ? wb_data_i[1] : bypass_ra;
    bypass_ra = (wb_valid_i[0] && wb_addr_i[0] == rs1) ? wb_data_i[0] : bypass_ra;

    bypass_ra_valid = '1;
    bypass_ra_valid = (wb_valid_i[3] && wb_addr_i[3] == rs1) ? wb_ready_i[3] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[2] && wb_addr_i[2] == rs1) ? wb_ready_i[2] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[1] && wb_addr_i[1] == rs1) ? wb_ready_i[1] : bypass_ra_valid;
    bypass_ra_valid = (wb_valid_i[0] && wb_addr_i[0] == rs1) ? wb_ready_i[0] : bypass_ra_valid;

    bypass_rb = decode_rb_i;
    bypass_rb = (wb_valid_i[3] && wb_addr_i[3] == rs2) ? wb_data_i[3] : bypass_rb;
    bypass_rb = (wb_valid_i[2] && wb_addr_i[2] == rs2) ? wb_data_i[2] : bypass_rb;
    bypass_rb = (wb_valid_i[1] && wb_addr_i[1] == rs2) ? wb_data_i[1] : bypass_rb;
    bypass_rb = (wb_valid_i[0] && wb_addr_i[0] == rs2) ? wb_data_i[0] : bypass_rb;

    bypass_rb_valid = '1;
    bypass_rb_valid = (wb_valid_i[3] && wb_addr_i[3] == rs2) ? wb_ready_i[3] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[2] && wb_addr_i[2] == rs2) ? wb_ready_i[2] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[1] && wb_addr_i[1] == rs2) ? wb_ready_i[1] : bypass_rb_valid;
    bypass_rb_valid = (wb_valid_i[0] && wb_addr_i[0] == rs2) ? wb_ready_i[0] : bypass_rb_valid;

    valid = decode_valid_i
         && (!decode_cw_i.ra_used || bypass_ra_valid)
         && (!decode_cw_i.rb_used || bypass_rb_valid);
end


//
// ALU Operand Selection
//

word_t alu_op1;
word_t alu_op2;

always_comb begin
    unique case (decode_cw_i.alu_op1)
    ALU_OP1_IMMU: alu_op1 = imm_u;
    default:      alu_op1 = bypass_ra;
    endcase

    unique case (decode_cw_i.alu_op2)
    ALU_OP2_IMMI: alu_op2 = imm_i;
    ALU_OP2_IMMS: alu_op2 = imm_s;
    ALU_OP2_PC:   alu_op2 = decode_pc_i;
    default:      alu_op2 = bypass_rb;
    endcase
end


//
// Bypass Buffer
//

bypass_buffer #(
    .WIDTH       (88)
) bypass_buffer (
    .clk_i       (clk_i),
    .wr_data_i   ({ decode_cw_i, alu_op1, alu_op2 }),
    .wr_valid_i  (valid),
    .wr_ready_o  (decode_ready_o),
    .rd_data_o   ({ issue_cw_o, issue_alu_op1_o, issue_alu_op2_o }),
    .rd_valid_o  (issue_valid_o),
    .rd_ready_i  (issue_ready_i)
);

endmodule
