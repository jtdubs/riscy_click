`timescale 1ns / 1ps
`default_nettype none

module stage_fetch_tb
    // Import Constants
    import common::*;
    import cpu_common::*;
    ();
    
    
logic     clk;
logic     flush;
memaddr_t req_addr;
logic     req_valid;
logic     req_ready;
memaddr_t resp_addr;
word_t    resp_data;
logic     resp_valid;
logic     resp_ready;
logic     halt;
word_t    jmp_addr;
logic     jmp_valid;
word_t    fetch_pc;
word_t    fetch_ir;
word_t    fetch_pc_next;
logic     fetch_valid;
logic     fetch_ready;

instruction_cache cache (
    .clk_i        (clk),
    .flush_i      (flush),
    .req_addr_i   (req_addr),
    .req_valid_i  (req_valid),
    .req_ready_o  (req_ready),
    .resp_addr_o  (resp_addr),
    .resp_data_o  (resp_data),
    .resp_valid_o (resp_valid),
    .resp_ready_i (resp_ready)
);

stage_fetch stage_fetch (
    .clk_i               (clk),
    .halt_i              (halt),
    .icache_flush_o      (flush),
    .icache_req_addr_o   (req_addr),
    .icache_req_valid_o  (req_valid),
    .icache_req_ready_i  (req_ready),
    .icache_resp_addr_i  (resp_addr),
    .icache_resp_data_i  (resp_data),
    .icache_resp_valid_i (resp_valid),
    .icache_resp_ready_o (resp_ready),
    .jmp_addr_i          (jmp_addr),
    .jmp_valid_i         (jmp_valid),
    .fetch_pc_o          (fetch_pc),
    .fetch_ir_o          (fetch_ir),
    .fetch_pc_next_o     (fetch_pc_next),
    .fetch_valid_o       (fetch_valid),
    .fetch_ready_i       (fetch_ready)
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
    fetch_ready <= 1'b1;

    forever begin
        #1000
        @(posedge clk) fetch_ready <= 1'b0;
        @(posedge clk) fetch_ready <= 1'b1;
        #1000
        @(posedge clk) fetch_ready <= 1'b0;
        #40
        @(posedge clk) fetch_ready <= 1'b1;
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
