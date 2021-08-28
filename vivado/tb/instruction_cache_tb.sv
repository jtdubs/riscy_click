`timescale 1ns / 1ps
`default_nettype none

module instruction_cache_tb
    // Import Constants
    import common::*;
    import cpu_common::*;
    ();

logic     clk_i;
memaddr_t req_addr_i = '0;
logic     req_valid_i;
logic     req_ready_o;
memaddr_t resp_addr_o;
word_t    resp_data_o;
logic     resp_valid_o;
logic     resp_ready_i;

instruction_cache cache (.*);

// clock generator
initial begin
    clk_i <= 0;
    forever begin
        #5 clk_i <= ~clk_i;
    end
end

// request stream
always_ff @(posedge clk_i) begin
    if (req_valid_i && req_ready_o)
        req_addr_i <= req_addr_i + 1;
end

// request valid
initial begin
    req_valid_i <= 1'b0;
    @(posedge clk_i) req_valid_i <= !req_valid_i;
    forever begin
        #900
        @(posedge clk_i) req_valid_i <= !req_valid_i;
    end
end

// response ready
initial begin
    resp_ready_i <= 1'b1;
    forever begin
        #200
        @(posedge clk_i) resp_ready_i <= !resp_ready_i;
    end
end

endmodule
