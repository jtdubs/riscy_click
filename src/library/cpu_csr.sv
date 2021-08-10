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
// CSR Listing
//

// Machine Information Registers
localparam csr_t CSR_MVENDORID      = 12'hF11; // Implemented
localparam csr_t CSR_MARCHID        = 12'hF12; // Implemented
localparam csr_t CSR_MIMPID         = 12'hF13; // Implemented
localparam csr_t CSR_MHARTID        = 12'hF14; // Implemented

// Machine Trap Setup
localparam csr_t CSR_MSTATUS        = 12'h300;
localparam csr_t CSR_MISA           = 12'h301; // Implemented
localparam csr_t CSR_MEDELEG        = 12'h302; // Not Applicable
localparam csr_t CSR_MIDELEG        = 12'h303; // Not Applicable
localparam csr_t CSR_MIE            = 12'h304;
localparam csr_t CSR_MTVEC          = 12'h305; // Implemented
localparam csr_t CSR_MCOUNTEREN     = 12'h306; // Not Applicable
localparam csr_t CSR_MSTATUSH       = 12'h310;

// Machine Trap Handling
localparam csr_t CSR_MSCRATCH       = 12'h340; // Implemented
localparam csr_t CSR_MEPC           = 12'h341;
localparam csr_t CSR_MCAUSE         = 12'h342;
localparam csr_t CSR_MTVAL          = 12'h343;
localparam csr_t CSR_MIP            = 12'h344;
localparam csr_t CSR_MTINST         = 12'h34A;
localparam csr_t CSR_MTVAL2         = 12'h34B;

// Machine Memory Protection
localparam csr_t CSR_PMPCFG0        = 12'h3A0;
localparam csr_t CSR_PMPCFG15       = 12'h3AF;
localparam csr_t CSR_PMPADDR0       = 12'h3B0;
localparam csr_t CSR_PMPADDR63      = 12'h3EF;

// Machine Counters/Timers
localparam csr_t CSR_MCYCLE         = 12'hB00; // Implemented
localparam csr_t CSR_MINSTRET       = 12'hB02; // Implemented
localparam csr_t CSR_MHPMCOUNTER3   = 12'hB03; // Not Implemented
localparam csr_t CSR_MHPMCOUNTER31  = 12'hB1F; // Not Implemented
localparam csr_t CSR_MCYCLEH        = 12'hB80; // Implemented
localparam csr_t CSR_MINSTRETH      = 12'hB82; // Implemented
localparam csr_t CSR_MHPMCOUNTER3H  = 12'hB83; // Not Implemented
localparam csr_t CSR_MHPMCOUNTER31H = 12'hB9F; // Not Implemented

// Machine Counter Setup
localparam csr_t CSR_MCOUNTINHIBIT  = 12'h320; // Implemented
localparam csr_t CSR_MHPMEVENT3     = 12'h323; // Not Implemented
localparam csr_t CSR_MHPMEVENT31    = 12'h33F; // Not Implemented

// Unprivileged Counters/Timers
localparam csr_t CSR_CYCLE          = 12'hC00; // Implemented
localparam csr_t CSR_TIME           = 12'hC01;
localparam csr_t CSR_INSTRET        = 12'hC02; // Implemented
localparam csr_t CSR_HPMCOUNTER3    = 12'hC03; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31   = 12'hC1F; // Not Implemented
localparam csr_t CSR_CYCLEH         = 12'hC80; // Implemented
localparam csr_t CSR_TIMEH          = 12'hC81;
localparam csr_t CSR_INSTRETH       = 12'hC82; // Implemented
localparam csr_t CSR_HPMCOUNTER3H   = 12'hC83; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31H  = 12'hC9F; // Not Implemented


//
// CSR Structures
//

typedef struct packed {
    logic       uie;
    logic       sie;
    logic       reserved_2;
    logic       mie;
    logic       upie;
    logic       spie;
    logic       reserved_6;
    logic       mpie;
    logic       spp;
    logic [1:0] reserved_9;
    logic [1:0] mpp;
    logic [1:0] fs;
    logic [1:0] xs;
    logic       mprv;
    logic       sum;
    logic       mxr;
    logic       tvm;
    logic       tw;
    logic       tsr;
    logic [7:0] reserved_23;
    logic       sd;
} status_t;

typedef struct packed {
    logic        reserved_0;
    logic        sbe;
    logic        mbe;
    logic [28:0] reserved_6;
} statush_t;

typedef enum logic {
    MTVEC_MODE_DIRECT   = 1'b0,
    MTVEC_MODE_VECTORED = 1'b1
} mtvec_mode_t;

typedef struct packed {
    mtvec_mode_t mode;
    logic        reserved_1;
    logic [29:0] base;
} mtvec_t;


//
// CSR Registers
//

status_t mstatus_r;
dword_t  mcycle_r,   mcycle_w;
dword_t  minstret_r, minstret_w;
mtvec_t  mtvec_r;
word_t   mcountinhibit_r;
word_t   mscratch_r;

word_t   mip_r;
word_t   mie_r;
dword_t  time_r,    time_w;


//
// Counter Updates
//

always_comb begin
    mcycle_w   = mcycle_r + 1;
    time_w     = time_r + 1;
    minstret_w = retired_i ? (minstret_r + 1) : minstret_r;

    if (mcountinhibit_r[0]) mcycle_w   = mcycle_r;
    if (mcountinhibit_r[2]) minstret_w = minstret_r;
end


//
// Default Values
//

localparam mtvec_t MTVEC_DEFAULT = '{
    mode:       MTVEC_MODE_DIRECT,
    reserved_1: 1'b0,
    base:       30'b0
};

localparam dword_t MCYCLE_DEFAULT        = 64'b0;
localparam dword_t MINSTRET_DEFAULT      = 64'b0;
localparam word_t  MCOUNTINHIBIT_DEFAULT = 32'b0;
localparam word_t  MSCRATCH_DEFAULT      = 32'b0;

always_ff @(posedge clk_i) begin
    if (reset_i) begin
        mstatus_r <= '{ 
            uie:         1'b0,
            sie:         1'b0,
            reserved_2:  1'b0,
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


//
// CSR Reads
//

always_ff @(posedge clk_i) begin
    if (csr_read_enable_i) begin
        unique case (csr_read_addr_i)
        //                                      MXLEN=32           ZYXWVUTSRQPONMLKJIHGFEDCBA
        CSR_MISA:          csr_read_data_o <= { 2'b01,   4'b0, 26'b00000000000000000100000000 };
        //                                    0 means non-commercial implementation
        CSR_MVENDORID:     csr_read_data_o <= 32'b0; 
        //                                    no assigned architecture ID
        CSR_MARCHID:       csr_read_data_o <= 32'b0; 
        //                                    version 1
        CSR_MIMPID:        csr_read_data_o <= 32'h0001;
        //                                    hardware thread #0
        CSR_MHARTID:       csr_read_data_o <= 32'b0;
        //                                    machine status
        CSR_MSTATUS:       csr_read_data_o <= mstatus_r;
        //                                    machine trap-vector base-address
        CSR_MTVEC:         csr_read_data_o <= mtvec_r;
        //                                    counter inhibit
        CSR_MCOUNTINHIBIT: csr_read_data_o <= mcountinhibit_r;
        //                                    scratch
        CSR_MSCRATCH:      csr_read_data_o <= mscratch_r;
        //                                    machine interrupt pending
        CSR_MIP:           csr_read_data_o <= mip_r;
        //                                    machine interrupt enabled
        CSR_MIE:           csr_read_data_o <= mie_r;
        //                                    cycle counter
        CSR_MCYCLE,
        CSR_CYCLE:         csr_read_data_o <= mcycle_r[31:0];
        //                                    realtime counter
        CSR_TIME:          csr_read_data_o <= time_r[31:0];
        //                                    retired instruction counter
        CSR_MINSTRET,
        CSR_INSTRET:       csr_read_data_o <= minstret_r[31:0];
        //                                    cycle counter (upper half)
        CSR_MCYCLEH,
        CSR_CYCLEH:        csr_read_data_o <= mcycle_r[63:32];
        //                                    realtime counter (upper half)
        CSR_TIMEH:         csr_read_data_o <= time_r[63:32];
        //                                    retired instruction counter (upper half)
        CSR_MINSTRETH,
        CSR_INSTRETH:      csr_read_data_o <= minstret_r[63:32];
        default:           csr_read_data_o <= 32'b0;
        endcase
    end else begin
        csr_read_data_o <= 32'b0;
    end

    if (reset_i) begin
        csr_read_data_o <= 32'b0;
    end
end


//
// CSR Writes
//

always_ff @(posedge clk_i) begin
    if (csr_write_enable_i) begin
        case (csr_write_addr_i)
        CSR_MTVEC:          mtvec_r         <= csr_write_data_i;
        CSR_MCOUNTINHIBIT:  mcountinhibit_r <= csr_write_data_i;
        CSR_MSCRATCH:       mscratch_r      <= csr_write_data_i;
        CSR_CYCLE:          mcycle_r        <= { mcycle_w  [63:32], csr_write_data_i };
        CSR_TIME:           time_r          <= { time_w    [63:32], csr_write_data_i };
        CSR_INSTRET:        minstret_r      <= { minstret_w[63:32], csr_write_data_i };
        CSR_CYCLEH:         mcycle_r        <= { csr_write_data_i, mcycle_w   [31:0] };
        CSR_TIMEH:          time_r          <= { csr_write_data_i, time_w     [31:0] };
        CSR_INSTRETH:       minstret_r      <= { csr_write_data_i, minstret_w [31:0] };
        endcase
    end else begin
        mcycle_r   <= mcycle_w;
        time_r     <= time_w;
        minstret_r <= minstret_w;
    end

    if (reset_i) begin
        mtvec_r         <= MTVEC_DEFAULT;
        mcountinhibit_r <= MCOUNTINHIBIT_DEFAULT;
        mcycle_r        <= MCYCLE_DEFAULT;
        time_r          <= 64'b0;
        minstret_r      <= MINSTRET_DEFAULT;
        mscratch_r      <= MSCRATCH_DEFAULT;
        mip_r           <= 32'b0;
        mie_r           <= 32'b0;
    end 
end

endmodule
