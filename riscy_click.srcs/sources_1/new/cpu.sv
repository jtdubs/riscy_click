`timescale 1ns/1ps

///
/// Risc-V CPU (Single Cycle Design)
///

module cpu
    (
        input  clk,   // clock
        input  reset, // reset
        output halt   // halt
    );


// Import Constants
consts c ();



///
/// Registers
///

wire [31:0] ir; // instruction register
assign ir = iram_read_data; // always read into the instruction register

/// Instruction Decoding
wire [6:0] opcode = ir[ 6: 0];
wire [4:0] rd     = ir[11: 7];
wire [2:0] funct3 = ir[14:12];
wire [4:0] rs1    = ir[19:15];
wire [4:0] rs2    = ir[24:20];
wire [6:0] funct7 = ir[31:25];

wire [31:0] imm_i = { {21{ir[31]}}, ir[30:25], ir[24:21], ir[20] };
wire [31:0] imm_s = { {21{ir[31]}}, ir[30:25], ir[11:8], ir[7] };
wire [31:0] imm_b = { {20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0 };
wire [31:0] imm_u = { ir[31], ir[30:20], ir[19:12], 12'b0 };
wire [31:0] imm_j = { {12{ir[31]}}, ir[19:12], ir[20], ir[30:25], ir[24:21], 1'b0 };



///
/// CPU Components
///


//
// Register File
//

// Signals
wire [ 4:0] reg_read_addr1;
wire [ 4:0] reg_read_addr2;
wire [31:0] reg_read_data1;
wire [31:0] reg_read_data2;
wire [ 4:0] reg_write_addr;
reg  [31:0] reg_write_data;
reg         reg_write_enable;

// Component
regfile regfile (
    .read_addr1(reg_read_addr1),
    .read_data1(reg_read_data1),
    .read_addr2(reg_read_addr2),
    .read_data2(reg_read_data2),
    .write_addr(reg_write_addr),
    .write_data(reg_write_data),
    .write_enable(reg_write_enable),
    .clk(clk)
);

// Assignments
assign reg_read_addr1 = rs1; // always read from the decoded register selector
assign reg_read_addr2 = rs2; // always read from the decoded register selector
assign reg_write_addr = rd;  // always write to the decoded register selector


//
// ALU
//

// Signals
reg  [31:0] alu_operand1;
reg  [31:0] alu_operand2;
wire [ 4:0] alu_mode;
wire [31:0] alu_result;
wire        alu_zero;

// Component
alu alu (
    .operand1(alu_operand1),
    .operand2(alu_operand2),
    .mode(alu_mode),
    .result(alu_result),
    .zero(alu_zero)
);


//
// Instruction Memory
//

// Signals
wire [31:0] iram_addr;
wire [31:0] iram_read_data;

// Component
ram #(.MEMORY_IMAGE_FILE("img/iram.mem")) iram (
    .addr(iram_addr[31:2]),
    .read_data(iram_read_data),
    .write_data(32'b0),
    .write_mask(4'b1111),
    .write_enable(1'b0),
    .clk(clk)
);

// Assignments
assign iram_addr = pc; // always read from the location of the current instruction


//
// Data RAM
//

// Signals
wire [31:0] dram_addr;
wire [31:0] dram_read_data;
reg  [31:0] dram_write_data;
reg  [ 3:0] dram_write_mask;
reg         dram_write_enable;

// Component
ram #(.MEMORY_IMAGE_FILE("img/dram.mem")) dram (
    .addr(dram_addr[31:2]),
    .read_data(dram_read_data),
    .write_data(dram_write_data),
    .write_mask(dram_write_mask),
    .write_enable(dram_write_enable),
    .clk(clk)
);

// Assignments
assign dram_addr = alu_result; // always read/write from the ALU result 


//
// Controller
//

// Signals
wire       alu_op1_sel;
wire [1:0] alu_op2_sel;
wire [1:0] wb_src_sel;
wire [1:0] wb_dst_sel;
wire [2:0] wb_mode;
wire [1:0] pc_mode_sel;
wire       pc_branch_zero;

// Component
ctl ctl (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .alu_op1_sel(alu_op1_sel),
    .alu_op2_sel(alu_op2_sel),
    .alu_mode(alu_mode),
    .wb_src_sel(wb_src_sel),
    .wb_dst_sel(wb_dst_sel),
    .wb_mode(wb_mode),
    .pc_mode_sel(pc_mode_sel),
    .pc_branch_zero(pc_branch_zero)
);



///
/// Selection Logic
///


//
// Register Write-Back
//

always @(*) begin
    case (wb_src_sel)
    c.WB_SRC_PC4:
        begin
            reg_write_data <= pc_plus_4;
        end
    c.WB_SRC_MEM:
        begin
            case (wb_mode)
            c.WB_MODE_B:  reg_write_data <= { {24{dram_read_data[7]}},  dram_read_data[ 7:0] };
            c.WB_MODE_H:  reg_write_data <= { {16{dram_read_data[15]}}, dram_read_data[15:0] };
            c.WB_MODE_BU: reg_write_data <= { 24'b0, dram_read_data[ 7:0] };
            c.WB_MODE_HU: reg_write_data <= { 16'b0, dram_read_data[15:0] };
            default:      reg_write_data <= dram_read_data;
            endcase
        end
    default: // c.WB_SRC_ALU:
        begin
            reg_write_data <= alu_result;
        end
    endcase
end


//
// ALU Operation
//

// Operand 1
always @(*) begin
    case (alu_op1_sel)
    c.ALU_OP1_RS1:  alu_operand1 <= reg_read_data1;
    c.ALU_OP1_IMMU: alu_operand1 <= imm_u;
    endcase
end

// Operand 2
always @(*) begin
    case (alu_op2_sel)
    c.ALU_OP2_RS2:  alu_operand2 <= reg_read_data2;
    c.ALU_OP2_IMMI: alu_operand2 <= imm_i;
    c.ALU_OP2_IMMS: alu_operand2 <= imm_s;
    c.ALU_OP2_PC:   alu_operand2 <= pc;
    endcase
end


//
// Data Memory Operation
//

// Write Data & Mask
always @(*) begin
    case (wb_mode)
    c.WB_MODE_B:
        begin
            case (alu_result[1:0])
            2'b00: dram_write_mask <= 4'b0001;
            2'b01: dram_write_mask <= 4'b0010;
            2'b10: dram_write_mask <= 4'b0100;
            2'b11: dram_write_mask <= 4'b1000;
            endcase
            dram_write_data <= { 4{reg_read_data2[ 7:0]} };
        end
    c.WB_MODE_H:
        begin
            case (alu_result[1:0])
            2'b00:   dram_write_mask <= 4'b0011;
            2'b10:   dram_write_mask <= 4'b1100;
            default: dram_write_mask <= 4'b0000;
            endcase
            dram_write_data <= { 2{reg_read_data2[15:0]} };
        end
    default: // c.WB_MODE_W:
        begin
            dram_write_mask <= 4'b1111;
            dram_write_data <= reg_read_data2;
        end
    endcase
end


//
// Program Counter Operation
//

// Registers and Signals
reg  [31:0] pc;
reg  [31:0] pc_next;
wire [31:0] pc_plus_4 = pc + 4;

// Next PC Logic
always @* begin
    if (reset)
        begin
            pc_next <= 0;
        end
    else if (halt)
        begin
            pc_next <= pc;
        end
    else
        begin
            case (pc_mode_sel)
            c.PC_NEXT:
                begin
                    pc_next <= pc_plus_4;
                end
            c.PC_JUMP_REL:
                begin
                    pc_next <= pc + imm_j;
                end
            c.PC_JUMP_ABS:
                begin
                    pc_next <= reg_read_data1 + imm_i;
                end
            c.PC_BRANCH:
                begin
                    if (alu_zero == pc_branch_zero)
                        begin
                            pc_next <= pc + imm_b;
                        end
                    else
                        begin
                            pc_next <= pc_plus_4;
                        end
                end
            endcase
        end
end 

// PC Clocked Assignment
always @(posedge clk) begin
    pc <= pc_next;
end



//
// Write-Back Operation
//

// Logic
always @(*) begin
    reg_write_enable  <= wb_dst_sel[0];
    dram_write_enable <= wb_dst_sel[1];
end

endmodule