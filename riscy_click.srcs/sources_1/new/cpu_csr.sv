`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Control & Status Registers
///

module cpu_csr
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic      clk_i,         // clock
        input  wire logic      reset_i,       // reset_i

        // control port
        input  wire word_t     retired_i,     // did an instruction retire this cycle
        
        // access port
        input  wire csr_t      csr_addr_i,
        input  wire word_t     csr_data_o,
        input  wire word_t     csr_data_i

    );


//
// ALU
//

dword_t csr_cycle_r, csr_cycle_w;
dword_t csr_time_r, csr_time_w;
dword_t csr_instret_r, csr_instret_w;


//
// Updates
//

always_comb begin
    csr_cycle_w = csr_cycle_r + 1;
    csr_time_w  = csr_time_r + 1;
    csr_instret_w = retired_i ? (csr_instret_r + 1) : csr_instret_r;
end

always_ff @(posedge clk_i) begin
    csr_cycle_r <= csr_cycle_w;
    csr_time_r <= csr_time_w;
    csr_instret_r <= csr_instret_w;
end


// rd  == x0 means skip read
// rs1 == x0 means skip write
// CSRRW:  rd <= csr && csr <= rs1
// CSRRS:  rd <= csr && csr <= csr | rs1;
// CSRRC:  rd <= csr && csr <= csr & ~rs1;
// CSRRWI: rd <= csr && csr <= imm_u
// CSRRSI: rd <= csr && csr <= csr | imm_u;
// CSRRCI: rd <= csr && csr <= csr & ~imm_u;

endmodule
