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

//
// MSTATUS
//

// Status Structure
typedef struct packed {
    logic uie;
    logic sie;
    logic reserved_2;
    logic mie;
    logic upie;
    logic spie;
    logic reserved_6;
    logic mpie;
    logic spp;
    logic [1:0] reserved_9;
    logic [1:0] mpp;
    logic [1:0] fs;
    logic [1:0] xs;
    logic mprv;
    logic sum;
    logic mxr;
    logic tvm;
    logic tw;
    logic tsr;
    logic [7:0] reserved_23;
    logic sd;
} status_t;

status_t mstatus_r, mstatus_w;

always_comb begin
    mstatus_w = mstatus_r;
end

always_ff @(posedge clk_i) begin
    mstatus_r <= mstatus_w;

    if (reset_i) begin
        mstatus_r <= '{ 
            uie:         1'b0,
            sie:         1'b0,
            reserved_2:  2'b0,
            mie:         1'b0,
            upie:        1'b0,
            spie:        1'b0,
            reserved_6:  1'b0,
            mpie:        1'b1,
            spp:         1'b1,
            reserved_9:  2'b00,
            mpp:         2'b00,
            fs:          2'b00,
            xs:          2'b00,
            mprv:        1'b0,
            sum:         1'b0,
            mxr:         1'b0,
            tvm:         1'b0,
            tw:          1'b0,
            tsr:         1'b0,
            reserved_23: 8'b00000000,
            sd:          1'b0
        };
    end
end

// Registers
dword_t csr_cycle_r, csr_cycle_w;
dword_t csr_time_r, csr_time_w;
dword_t csr_instret_r, csr_instret_w;
word_t csr_mtvec_r;
word_t csr_mip_r, csr_mie_r;

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
        //                                  MXLEN=32           ZYXWVUTSRQPONMLKJIHGFEDCBA
        CSR_MISA:      csr_read_data_o <= { 2'b01,   4'b0, 26'b00000000000000000100000001 };
        //                                0 means non-commercial implementation
        CSR_MVENDORID: csr_read_data_o <= 32'b0; 
        //                                no assigned architecture ID
        CSR_MARCHID:   csr_read_data_o <= 32'b0; 
        //                                version 1
        CSR_MIMPID:    csr_read_data_o <= 32'h0001;
        //                                hardware thread #0
        CSR_MHARTID:   csr_read_data_o <= 32'b0;
        //                                machine status register
        CSR_MSTATUS:   csr_read_data_o <= mstatus_r;
        //                                machine trap-vector base-address
        CSR_MTVEC:     csr_read_data_o <= csr_mtvec_r;
        //                                machine exception delegation
        CSR_MEDELEG:   csr_read_data_o <= 32'b0;
        //                                machine interrupt delegation
        CSR_MIDELEG:   csr_read_data_o <= 32'b0;
        //                                machine interrupt pending
        CSR_MIP:       csr_read_data_o <= csr_mip_r;
        //                                machine interrupt enabled
        CSR_MIE:       csr_read_data_o <= csr_mie_r;

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
        CSR_MTVEC:    csr_mtvec_r   <= csr_write_data_i;
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
        csr_mtvec_r   <= 32'b0;
        csr_cycle_r   <= 64'b0;
        csr_time_r    <= 64'b0;
        csr_instret_r <= 64'b0;
    end 
end

endmodule
