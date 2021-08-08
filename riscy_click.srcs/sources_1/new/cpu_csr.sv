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
        input  wire logic      retired_i,     // did an instruction retire this cycle
        
        // read port
        input  wire csr_t      csr_read_addr_i,
        input  wire logic      csr_read_enable_i,
        output      word_t     csr_read_data_o,
        
        // write port
        input  wire csr_t      csr_write_addr_i,
        input  wire word_t     csr_write_data_i,
        input  wire logic      csr_write_enable_i
    );


// Registers
dword_t csr_cycle_r, csr_cycle_w;
dword_t csr_time_r, csr_time_w;
dword_t csr_instret_r, csr_instret_w;

// Calculate next values
always_comb begin
    csr_cycle_w   = csr_cycle_r + 1;
    csr_time_w    = csr_time_r + 1;
    csr_instret_w = retired_i ? (csr_instret_r + 1) : csr_instret_r;
end

// Reads
always_ff @(posedge clk_i) begin
    if (csr_read_enable_i) begin
        unique case (csr_read_addr_i)
        CSR_CYCLE:    csr_read_data_o <= csr_cycle_r[31:0];
        CSR_TIME:     csr_read_data_o <= csr_time_r[31:0];
        CSR_INSTRET:  csr_read_data_o <= csr_instret_r[31:0];
        CSR_CYCLEH:   csr_read_data_o <= csr_cycle_r[63:32];
        CSR_TIMEH:    csr_read_data_o <= csr_time_r[63:32];
        CSR_INSTRETH: csr_read_data_o <= csr_instret_r[63:32];
        default:      csr_read_data_o <= 32'b0;
        endcase
    end else begin
        csr_read_data_o <= 32'b0;
    end
   
    if (reset_i) begin
        csr_read_data_o <= 32'b0;
    end
end

// Writes
always_ff @(posedge clk_i) begin
    if (csr_write_enable_i) begin
        /* verilator lint_off CASEINCOMPLETE */
        case (csr_write_addr_i)
        CSR_CYCLE:    csr_cycle_r   <= { csr_cycle_w  [63:32], csr_write_data_i };
        CSR_TIME:     csr_time_r    <= { csr_time_w   [63:32], csr_write_data_i };
        CSR_INSTRET:  csr_instret_r <= { csr_instret_w[63:32], csr_write_data_i };
        CSR_CYCLEH:   csr_cycle_r   <= { csr_write_data_i, csr_cycle_w   [31:0] };
        CSR_TIMEH:    csr_time_r    <= { csr_write_data_i, csr_time_w    [31:0] };
        CSR_INSTRETH: csr_instret_r <= { csr_write_data_i, csr_instret_w [31:0] };
        endcase
    end else begin
        csr_cycle_r   <= csr_cycle_w;
        csr_time_r    <= csr_time_w;
        csr_instret_r <= csr_instret_w;
    end
    
    if (reset_i) begin
        csr_cycle_r   <= 64'b0;
        csr_time_r    <= 64'b0;
        csr_instret_r <= 64'b0;
    end 
end

endmodule
