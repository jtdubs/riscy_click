`timescale 1ns/1ps

///
/// Risc-V CPU (Single Cycle Design)
///

module cpu
    // Import Constants
    import consts::*;
    (
        // board signals
        input       logic       clk,   // clock
        input       logic       reset, // reset
        output wire logic       halt,  // halt

        // instruction memory bus
        output      word        ibus_addr,
        input       word        ibus_read_data,

        // data memory bus
        output wire word        dbus_addr,
        input       word        dbus_read_data,
        output      word        dbus_write_data,
        output      logic       dbus_write_enable,
        output      logic [3:0] dbus_write_mask
    );


///
/// Registers
///

wire word ir;        // instruction register
word pc;             // program counter
word pc_next;        // next program counter
wire word pc_plus_4; // incremented program counter

/// Instruction Decoding
wire logic [6:0] opcode = ir[ 6: 0];
wire logic [4:0] rd     = ir[11: 7];
wire funct3      f3     = ir[14:12];
wire logic [4:0] rs1    = ir[19:15];
wire logic [4:0] rs2    = ir[24:20];
wire logic [6:0] f7     = ir[31:25];

wire word imm_i = { {21{ir[31]}}, ir[30:25], ir[24:21], ir[20] };
wire word imm_s = { {21{ir[31]}}, ir[30:25], ir[11:8], ir[7] };
wire word imm_b = { {20{ir[31]}}, ir[7], ir[30:25], ir[11:8], 1'b0 };
wire word imm_u = { ir[31], ir[30:20], ir[19:12], 12'b0 };
wire word imm_j = { {12{ir[31]}}, ir[19:12], ir[20], ir[30:25], ir[24:21], 1'b0 };



///
/// CPU Components
///


//
// Register File
//

// Signals
wire logic [4:0] reg_read_addr1;
wire logic [4:0] reg_read_addr2;
wire word        reg_read_data1;
wire word        reg_read_data2;
wire logic [4:0] reg_write_addr;
word             reg_write_data;
logic            reg_write_enable;

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


//
// ALU
//

// Signals
word          alu_operand1;
word          alu_operand2;
wire word     alu_result;
wire logic    alu_zero;

// Component
alu alu (
    .operand1(alu_operand1),
    .operand2(alu_operand2),
    .mode(cw.alu_mode_sel),
    .result(alu_result),
    .zero(alu_zero)
);


//
// Controller
//

// Signals
wire control_word cw;

// Component
ctl ctl (
    .clk(clk),
    .reset(reset),
    .opcode(opcode),
    .f3(f3),
    .f7(f7),
    .cw(cw)
);


///
/// Fixed Signal Routing
///

// Registers
assign ir = ibus_read_data; // always read into the instruction register

// Register File
assign reg_read_addr1 = rs1; // always read from the decoded register selector
assign reg_read_addr2 = rs2; // always read from the decoded register selector
assign reg_write_addr = rd;  // always write to the decoded register selector

// Instruction Memory
assign ibus_addr = pc; // always read from the location of the current instruction

// Data Memory
assign dbus_addr = alu_result; // always read/write from the ALU alu

// Board
assign halt = cw.halt;



///
/// Selection Logic
///


//
// Register Write-Back
//

always_comb begin
    case (cw.wb_src_sel)
    WB_SRC_PC4:
        begin
            reg_write_data <= pc_plus_4;
        end
    WB_SRC_MEM:
        begin
            case (cw.wb_mode_sel)
            WB_MODE_B:  reg_write_data <= { {24{dbus_read_data[7]}},  dbus_read_data[ 7:0] };
            WB_MODE_H:  reg_write_data <= { {16{dbus_read_data[15]}}, dbus_read_data[15:0] };
            WB_MODE_BU: reg_write_data <= { 24'b0, dbus_read_data[ 7:0] };
            WB_MODE_HU: reg_write_data <= { 16'b0, dbus_read_data[15:0] };
            default:    reg_write_data <= dbus_read_data;
            endcase
        end
    default: // WB_SRC_ALU:
        begin
            reg_write_data <= alu_result;
        end
    endcase
end


//
// ALU Operation
//

// Operand 1
always_comb begin
    case (cw.alu_op1_sel)
    ALU_OP1_RS1:  alu_operand1 <= reg_read_data1;
    ALU_OP1_IMMU: alu_operand1 <= imm_u;
    endcase
end

// Operand 2
always_comb begin
    case (cw.alu_op2_sel)
    ALU_OP2_RS2:  alu_operand2 <= reg_read_data2;
    ALU_OP2_IMMI: alu_operand2 <= imm_i;
    ALU_OP2_IMMS: alu_operand2 <= imm_s;
    ALU_OP2_PC:   alu_operand2 <= pc;
    endcase
end


//
// Data Memory Operation
//

// Write Data & Mask
always_comb begin
    case (cw.wb_mode_sel)
    WB_MODE_B:
        begin
            case (alu_result[1:0])
            2'b00: dbus_write_mask <= 4'b0001;
            2'b01: dbus_write_mask <= 4'b0010;
            2'b10: dbus_write_mask <= 4'b0100;
            2'b11: dbus_write_mask <= 4'b1000;
            endcase
            dbus_write_data <= { 4{reg_read_data2[ 7:0]} };
        end
    WB_MODE_H:
        begin
            case (alu_result[1:0])
            2'b00:   dbus_write_mask <= 4'b0011;
            2'b10:   dbus_write_mask <= 4'b1100;
            default: dbus_write_mask <= 4'b0000;
            endcase
            dbus_write_data <= { 2{reg_read_data2[15:0]} };
        end
    default: // WB_MODE_W:
        begin
            dbus_write_mask <= 4'b1111;
            dbus_write_data <= reg_read_data2;
        end
    endcase
end


//
// Program Counter Operation
//

// Registers and Signals
assign pc_plus_4 = pc + 4;

// Next PC Logic
always_comb begin
    if (reset)
        begin
            pc_next <= 0;
        end
    else if (cw.halt)
        begin
            pc_next <= pc;
        end
    else
        begin
            case (cw.pc_mode_sel)
            PC_NEXT:
                begin
                    pc_next <= pc_plus_4;
                end
            PC_JUMP_REL:
                begin
                    pc_next <= pc + imm_j;
                end
            PC_JUMP_ABS:
                begin
                    pc_next <= reg_read_data1 + imm_i;
                end
            PC_BRANCH:
                begin
                    if (alu_zero == cw.pc_branch_zero)
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
always_ff @(posedge clk) begin
    pc <= pc_next;
end



//
// Write-Back Operation
//

// Logic
always_comb begin
    reg_write_enable  <= cw.wb_dst_sel[0];
    dbus_write_enable <= cw.wb_dst_sel[1];
end

endmodule
