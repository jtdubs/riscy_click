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
        input  wire logic      mtrap_i,       // is the current instruction an mtrap
        input  wire logic      mret_i,        // is the current instruction an mret

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
localparam csr_t CSR_MSTATUS        = 12'h300; // Implemented
localparam csr_t CSR_MISA           = 12'h301; // Implemented
localparam csr_t CSR_MEDELEG        = 12'h302; // Not Applicable
localparam csr_t CSR_MIDELEG        = 12'h303; // Not Applicable
localparam csr_t CSR_MIE            = 12'h304; // TODO
localparam csr_t CSR_MTVEC          = 12'h305; // Implemented
localparam csr_t CSR_MCOUNTEREN     = 12'h306; // Not Applicable
localparam csr_t CSR_MSTATUSH       = 12'h310; // Implemented

// Machine Trap Handling
localparam csr_t CSR_MSCRATCH       = 12'h340; // Implemented
localparam csr_t CSR_MEPC           = 12'h341; // Implemented
localparam csr_t CSR_MCAUSE         = 12'h342; // Implemented
localparam csr_t CSR_MTVAL          = 12'h343; // Implemented
localparam csr_t CSR_MIP            = 12'h344; // TODO
localparam csr_t CSR_MTINST         = 12'h34A; // Implemented
localparam csr_t CSR_MTVAL2         = 12'h34B; // Implemented

// Machine Memory Protection
localparam csr_t CSR_PMPCFG0        = 12'h3A0; // Implemented
localparam csr_t CSR_PMPCFG15       = 12'h3AF; // Implemented
localparam csr_t CSR_PMPADDR0       = 12'h3B0; // Implemented
localparam csr_t CSR_PMPADDR63      = 12'h3EF; // Implemented

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
localparam csr_t CSR_TIME           = 12'hC01; // Implemented
localparam csr_t CSR_INSTRET        = 12'hC02; // Implemented
localparam csr_t CSR_HPMCOUNTER3    = 12'hC03; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31   = 12'hC1F; // Not Implemented
localparam csr_t CSR_CYCLEH         = 12'hC80; // Implemented
localparam csr_t CSR_TIMEH          = 12'hC81; // Implemented
localparam csr_t CSR_INSTRETH       = 12'hC82; // Implemented
localparam csr_t CSR_HPMCOUNTER3H   = 12'hC83; // Not Implemented
localparam csr_t CSR_HPMCOUNTER31H  = 12'hC9F; // Not Implemented


//
// CSR Structures
//

typedef struct packed {
    logic       reserved_0;
    logic       sie;          // S-mode interrupt enable
    logic       reserved_2;
    logic       mie;          // M-mode interrupt enable
    logic       reserved_4;
    logic       spie;         // S-mode prior interrupt enable
    logic       ube;          // U-mode data endian (0=little-endian, 1=big-endian),
    logic       mpie;         // M-mode prior interrupt enable
    logic       spp;          // S-mode prior privilege level
    logic [1:0] reserved_9;
    logic [1:0] mpp;          // M-mode prior privilege level
    logic [1:0] fs;           // FPU State
    logic [1:0] xs;           // FPU State
    logic       mprv;         // Modify Privilege (0=current, 1=prior)
    logic       sum;          // Supervisor User Memory (N/A)
    logic       mxr;          // Make eXecutable Reader (0=r^x, 1=r|x)
    logic       tvm;          // Trap Virtual Memory
    logic       tw;           // Timeout Wait
    logic       tsr;          // Trap SRET
    logic [7:0] reserved_23;
    logic       sd;           // FPU State
} mstatus_t;

typedef struct packed {
    logic        reserved_0;
    logic        sbe;         // ZERO: S-mode data endian (0=little-endian, 1=big-endian)
    logic        mbe;         // ZERO: M-mode data endian (0=little-endian, 1=big-endian)
    logic [28:0] reserved_6;
} mstatush_t;

typedef enum logic {
    MTVEC_MODE_DIRECT   = 1'b0,
    MTVEC_MODE_VECTORED = 1'b1
} mtvec_mode_t;

typedef struct packed {
    mtvec_mode_t mode;
    logic        reserved_1;
    logic [29:0] base;
} mtvec_t;

typedef struct packed {
    logic [30:0] exception_code;
    logic        is_interrupt;
} mcause_t;

typedef enum logic [1:0] {
    PMPCFG_A_OFF =   2'b00, // Null Region
    PMPCFG_A_TOR   = 2'b01, // Top of Range
    PMPCFG_A_NA4   = 2'b10, // Naturally Aligned Four-Byte Region
    PMPCFG_A_NAPOT = 2'b11  // Naturally Aligned Power-of-Two Region
} matching_mode_t;

typedef struct packed {
    logic [2:0]     rwx;
    matching_mode_t matching_mode;
    logic [1:0]     reserved_5;
    logic           locked;
} pmpcfg_t;

typedef struct packed {
    word_t   addr;
    pmpcfg_t cfg;
} pmp_entry_t;

localparam logic [2:0] R = 3'b001;
localparam logic [2:0] W = 3'b010;
localparam logic [2:0] X = 3'b100;


//
// PMP Config
//

localparam pmp_entry_t [8:0] PMP_CONFIG = '{
    // [00000000, 00001000) - BIOS
    '{ { 32'h00000000 >> 2 }, '{ rwx: R|X, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ { 32'h00001000 >> 2 }, '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    // [10000000, 10001000) - System RAM
    '{ { 32'h10000000 >> 2 }, '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ { 32'h10001000 >> 2 }, '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    // [20000000, 20001000) - Video RAM
    '{ { 32'h20000000 >> 2 }, '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ { 32'h20001000 >> 2 }, '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    //  FF000004            - Seven Segment Display
    '{ { 32'hFF000004 >> 2 }, '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NA4,   default: '0 } },
        //
    //  FF000008            - Switch Bank
    '{ { 32'hFF000008 >> 2 }, '{ rwx: R,   locked: 1'b1, matching_mode: PMPCFG_A_NA4,   default: '0 } },

    // [FF00000C, FFFFFFFF] - UNUSED 
    '{ { 32'hFFFFFFFF >> 2 }, '{           locked: 1'b1, matching_mode: PMPCFG_A_TOR,   default: '0 } }
};


//
// CSR Registers
//

// Counters
dword_t  mcycle_r,   mcycle_w;
dword_t  minstret_r, minstret_w;
dword_t  time_r,     time_w;

// Non-Counters
mtvec_t  mtvec_r;
word_t   mcountinhibit_r;
word_t   mscratch_r;
word_t   mepc_r;
mcause_t mcause_r;
word_t   mtval_r;
word_t   mtval2_r;
word_t   mtinst_r;
word_t   mip_r;
word_t   mie_r;
logic    mstatus_mie_r,  mstatus_mie_w;
logic    mstatus_mpie_r, mstatus_mpie_w;


//
// Updates
//

always_comb begin
    mcycle_w   = mcycle_r + 1;
    time_w     = time_r + 1;
    minstret_w = retired_i ? (minstret_r + 1) : minstret_r;

    if (mcountinhibit_r[0]) mcycle_w   = mcycle_r;
    if (mcountinhibit_r[2]) minstret_w = minstret_r;
end

always_comb begin
    priority if (mtrap_i)
        // on trap, disable interrupts and save previous value
        { mstatus_mie_w, mstatus_mpie_w } = { 1'b0,           mstatus_mie_r  };
    else if (mret_i)
        // on ret, restore previous value
        { mstatus_mie_w, mstatus_mpie_w } = { mstatus_mpie_r, 1'b1           };
    else
        // otherwise, no change
        { mstatus_mie_w, mstatus_mpie_w } = { mstatus_mie_r,  mstatus_mpie_r };
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
localparam word_t  MEPC_DEFAULT          = 32'b0;
localparam word_t  MTVAL_DEFAULT         = 32'b0;
localparam word_t  MTVAL2_DEFAULT        = 32'b0;
localparam word_t  MTINST_DEFAULT        = 32'b0;
localparam dword_t TIME_DEFAULT          = 64'b0;
localparam logic   MSTATUS_MIE_DEFAULT   = 1'b0;
localparam logic   MSTATUS_MPIE_DEFAULT  = 1'b0;

localparam mcause_t MCAUSE_DEFAULT = '{
    exception_code: 31'b0,
    is_interrupt:   1'b0
};


//
// CSR Reads
//

mstatus_t mstatus_o;
always_comb mstatus_o = '{
    mie:         mstatus_mie_r,
    mpie:        mstatus_mpie_r,
    default:     '0
};

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
        CSR_MSTATUS:       csr_read_data_o <= mstatus_o;
        //                                    machine trap-vector base-address
        CSR_MTVEC:         csr_read_data_o <= mtvec_r;
        //                                    counter inhibit
        CSR_MCOUNTINHIBIT: csr_read_data_o <= mcountinhibit_r;
        //                                    scratch
        CSR_MSCRATCH:      csr_read_data_o <= mscratch_r;
        //                                    exception cause
        CSR_MCAUSE:        csr_read_data_o <= mcause_r;
        //                                    exception program counter
        CSR_MEPC:          csr_read_data_o <= mepc_r;
        //                                    exception value
        CSR_MTVAL:         csr_read_data_o <= mtval_r;
        //                                    exception value
        CSR_MTVAL2:        csr_read_data_o <= mtval2_r;
        //                                    exception value
        CSR_MTINST:        csr_read_data_o <= mtinst_r;
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
        //                                    memory config
        (CSR_PMPCFG0+0):   csr_read_data_o <= { PMP_CONFIG[0].cfg, PMP_CONFIG[1].cfg, PMP_CONFIG[2].cfg, PMP_CONFIG[3].cfg };
        (CSR_PMPCFG0+1):   csr_read_data_o <= { PMP_CONFIG[4].cfg, PMP_CONFIG[5].cfg, PMP_CONFIG[6].cfg, PMP_CONFIG[7].cfg };
        //                                    memory address
        (CSR_PMPADDR0+0):  csr_read_data_o <= PMP_CONFIG[0].addr;
        (CSR_PMPADDR0+1):  csr_read_data_o <= PMP_CONFIG[1].addr;
        (CSR_PMPADDR0+2):  csr_read_data_o <= PMP_CONFIG[2].addr;
        (CSR_PMPADDR0+3):  csr_read_data_o <= PMP_CONFIG[3].addr;
        (CSR_PMPADDR0+4):  csr_read_data_o <= PMP_CONFIG[4].addr;
        (CSR_PMPADDR0+5):  csr_read_data_o <= PMP_CONFIG[5].addr;
        (CSR_PMPADDR0+6):  csr_read_data_o <= PMP_CONFIG[6].addr;
        (CSR_PMPADDR0+7):  csr_read_data_o <= PMP_CONFIG[7].addr;
        (CSR_PMPADDR0+8):  csr_read_data_o <= PMP_CONFIG[8].addr;

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

mstatus_t mstatus_i;
always_comb mstatus_i = mstatus_t'(csr_write_data_i);

always_ff @(posedge clk_i) begin
    if (csr_write_enable_i) begin
        case (csr_write_addr_i)
        CSR_MTVEC:          mtvec_r         <= csr_write_data_i;
        CSR_MCOUNTINHIBIT:  mcountinhibit_r <= csr_write_data_i;
        CSR_MSCRATCH:       mscratch_r      <= csr_write_data_i;
        CSR_MCAUSE:         mcause_r        <= csr_write_data_i;
        CSR_MTVAL:          mtval_r         <= csr_write_data_i;
        CSR_MTVAL2:         mtval2_r        <= csr_write_data_i;
        CSR_MTINST:         mtinst_r        <= csr_write_data_i;
        CSR_MEPC:           mepc_r          <= csr_write_data_i;
        CSR_MSTATUS:
            begin
                mstatus_mie_r  <= mstatus_i.mie;
                mstatus_mpie_r <= mstatus_i.mpie;
            end
        CSR_CYCLE:          mcycle_r        <= { mcycle_w  [63:32], csr_write_data_i };
        CSR_TIME:           time_r          <= { time_w    [63:32], csr_write_data_i };
        CSR_INSTRET:        minstret_r      <= { minstret_w[63:32], csr_write_data_i };
        CSR_CYCLEH:         mcycle_r        <= { csr_write_data_i, mcycle_w   [31:0] };
        CSR_TIMEH:          time_r          <= { csr_write_data_i, time_w     [31:0] };
        CSR_INSTRETH:       minstret_r      <= { csr_write_data_i, minstret_w [31:0] };
        endcase
    end else begin
        mcycle_r       <= mcycle_w;
        time_r         <= time_w;
        minstret_r     <= minstret_w;
        mstatus_mie_r  <= mstatus_mie_w;
        mstatus_mpie_r <= mstatus_mpie_w;
    end

    if (reset_i) begin
        mtvec_r         <= MTVEC_DEFAULT;
        mcountinhibit_r <= MCOUNTINHIBIT_DEFAULT;
        mcycle_r        <= MCYCLE_DEFAULT;
        time_r          <= TIME_DEFAULT;
        minstret_r      <= MINSTRET_DEFAULT;
        mstatus_mie_r   <= MSTATUS_MIE_DEFAULT;
        mstatus_mpie_r  <= MSTATUS_MPIE_DEFAULT;
        mscratch_r      <= MSCRATCH_DEFAULT;
        mcause_r        <= MCAUSE_DEFAULT;
        mepc_r          <= MEPC_DEFAULT;
        mtval_r         <= MTVAL_DEFAULT;
        mtval2_r        <= MTVAL2_DEFAULT;
        mtinst_r        <= MTINST_DEFAULT;
        mip_r           <= 32'b0;
        mie_r           <= 32'b0;
    end 
end

endmodule
