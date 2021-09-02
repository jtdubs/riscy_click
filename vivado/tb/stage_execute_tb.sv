`timescale 1ns / 1ps
`default_nettype none

module stage_execute_tb
    // Import Constants
    import common::*;
    import cpu_common::*;
    ();


logic          clk;
logic          icache_flush;
memaddr_t      icache_req_addr;
logic          icache_req_valid;
logic          icache_req_ready;
memaddr_t      icache_resp_addr;
word_t         icache_resp_data;
logic          icache_resp_valid;
logic          icache_resp_ready;
logic          halt;
word_t         jmp_addr;
logic          jmp_valid;
word_t         fetch_pc;
word_t         fetch_ir;
word_t         fetch_pc_next;
logic          fetch_valid;
logic          fetch_ready;
word_t         decode_pc;
word_t         decode_ir;
control_word_t decode_cw;
word_t         decode_ra;
word_t         decode_rb;
logic          decode_valid;
logic          decode_ready;
control_word_t issue_cw;
word_t         issue_alu_op1;
word_t         issue_alu_op2;
logic          issue_valid;
logic          issue_ready;
word_t         execute_result;
logic          execute_valid;
logic          execute_ready;

instruction_cache cache (
    .clk_i        (clk),
    .flush_i      (icache_flush),
    .req_addr_i   (icache_req_addr),
    .req_valid_i  (icache_req_valid),
    .req_ready_o  (icache_req_ready),
    .resp_addr_o  (icache_resp_addr),
    .resp_data_o  (icache_resp_data),
    .resp_valid_o (icache_resp_valid),
    .resp_ready_i (icache_resp_ready)
);

stage_fetch stage_fetch (
    .clk_i               (clk),
    .halt_i              (halt),
    .icache_flush_o      (icache_flush),
    .icache_req_addr_o   (icache_req_addr),
    .icache_req_valid_o  (icache_req_valid),
    .icache_req_ready_i  (icache_req_ready),
    .icache_resp_addr_i  (icache_resp_addr),
    .icache_resp_data_i  (icache_resp_data),
    .icache_resp_valid_i (icache_resp_valid),
    .icache_resp_ready_o (icache_resp_ready),
    .jmp_addr_i          (jmp_addr),
    .jmp_valid_i         (jmp_valid),
    .fetch_pc_o          (fetch_pc),
    .fetch_ir_o          (fetch_ir),
    .fetch_pc_next_o     (fetch_pc_next),
    .fetch_valid_o       (fetch_valid),
    .fetch_ready_i       (fetch_ready)
);

stage_decode stage_decode (
    .clk_i               (clk),
    .fetch_pc_i          (fetch_pc),
    .fetch_ir_i          (fetch_ir),
    .fetch_pc_next_i     (fetch_pc_next),
    .fetch_valid_i       (fetch_valid),
    .fetch_ready_o       (fetch_ready),
    .decode_pc_o         (decode_pc),
    .decode_ir_o         (decode_ir),
    .decode_cw_o         (decode_cw),
    .decode_ra_o         (decode_ra),
    .decode_rb_o         (decode_rb),
    .decode_valid_o      (decode_valid),
    .decode_ready_i      (decode_ready)
);

stage_issue stage_issue (
    .clk_i               (clk),
    .decode_pc_i         (decode_pc),
    .decode_ir_i         (decode_ir),
    .decode_cw_i         (decode_cw),
    .decode_ra_i         (decode_ra),
    .decode_rb_i         (decode_rb),
    .decode_valid_i      (decode_valid),
    .decode_ready_o      (decode_ready),
    .wb_addr_i           (decode_ir[19:0]),
    .wb_data_i           ({ decode_pc, decode_ir, decode_ra, decode_rb }),
    .wb_valid_i          ({ decode_ir[23:20] }),
    .wb_ready_i          ({ decode_ir[27:24] }),
    .issue_cw_o          (issue_cw),
    .issue_alu_op1_o     (issue_alu_op1),
    .issue_alu_op2_o     (issue_alu_op2),
    .issue_valid_o       (issue_valid),
    .issue_ready_i       (issue_ready)
);

stage_execute stage_execute (
    .clk_i               (clk),
    .issue_cw_i          (issue_cw),
    .issue_alu_op1_i     (issue_alu_op1),
    .issue_alu_op2_i     (issue_alu_op2),
    .issue_valid_i       (issue_valid),
    .issue_ready_o       (issue_ready),
    .execute_result_o    (execute_result),
    .execute_valid_o     (execute_valid),
    .execute_ready_i     (execute_ready)
);

// clock generator
initial begin
    clk <= 0;
    forever begin
        #5 clk <= ~clk;
    end
end

// halt eventually
initial begin
    halt <= 0;
    #10000
    @(posedge clk) halt <= 1;
end

// test backpressure
initial begin
    execute_ready <= 1'b1;

    forever begin
        #1000
        @(posedge clk) execute_ready <= 1'b0;
        @(posedge clk) execute_ready <= 1'b1;
        #1000
        @(posedge clk) execute_ready <= 1'b0;
        #40
        @(posedge clk) execute_ready <= 1'b1;
    end
end

// do some jumps
initial begin
    jmp_addr  <= 8'h00;
    jmp_valid <= 1'b0;
    #500
    forever begin
        #1000
        @(posedge clk) begin
            jmp_addr  <= 8'h80;
            jmp_valid <= 1'b1;
        end
        @(posedge clk) begin
            jmp_addr  <= 8'h00;
            jmp_valid <= 1'b0;
        end
    end
end

endmodule
