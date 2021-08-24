`timescale 1ns / 1ps
`default_nettype none

package csr_common;

import common::*;
import cpu_common::*;

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
localparam csr_t CSR_MIE            = 12'h304; // Implemented
localparam csr_t CSR_MTVEC          = 12'h305; // Implemented
localparam csr_t CSR_MCOUNTEREN     = 12'h306; // Not Applicable
localparam csr_t CSR_MSTATUSH       = 12'h310; // Implemented

// Machine Trap Handling
localparam csr_t CSR_MSCRATCH       = 12'h340; // Implemented
localparam csr_t CSR_MEPC           = 12'h341; // Implemented
localparam csr_t CSR_MCAUSE         = 12'h342; // Implemented
localparam csr_t CSR_MTVAL          = 12'h343; // Implemented
localparam csr_t CSR_MIP            = 12'h344; // Implemented
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
// Exception Causes
//

typedef logic [30:0] exc_t;

localparam exc_t INT_S_SOFTWARE = 31'd1;
localparam exc_t INT_M_SOFTWARE = 31'd3;
localparam exc_t INT_S_TIMER    = 31'd5;
localparam exc_t INT_M_TIMER    = 31'd7;
localparam exc_t INT_S_EXTERNAL = 31'd9;
localparam exc_t INT_M_EXTERNAL = 31'd11;

localparam exc_t EXC_INSTR_MISALIGNED = 31'd0;
localparam exc_t EXC_INSTR_FAULT      = 31'd1;
localparam exc_t EXC_INSTR_ILLEGAL    = 31'd2;
localparam exc_t EXC_BREAKPOINT       = 31'd3;
localparam exc_t EXC_LOAD_MISALIGNED  = 31'd4;
localparam exc_t EXC_LOAD_FAULT       = 31'd5;
localparam exc_t EXC_STORE_MISALIGNED = 31'd6;
localparam exc_t EXC_STORE_FAULT      = 31'd7;
localparam exc_t ECALL_U              = 31'd8;
localparam exc_t ECALL_S              = 31'd9;
localparam exc_t ECALL_M              = 31'd11;
localparam exc_t EXC_PAGE_FAULT_INSTR = 31'd12;
localparam exc_t EXC_PAGE_FAULT_LOAD  = 31'd13;
localparam exc_t EXC_PAGE_FAULT_STORE = 31'd15;


//
// CSR Structures
//

typedef struct packed {
    logic       sd;           // FPU State
    logic [7:0] reserved_23;
    logic       tsr;          // Trap SRET
    logic       tw;           // Timeout Wait
    logic       tvm;          // Trap Virtual Memory
    logic       mxr;          // Make eXecutable Reader (0=r^x, 1=r|x)
    logic       sum;          // Supervisor User Memory (N/A)
    logic       mprv;         // Modify Privilege (0=current, 1=prior)
    logic [1:0] xs;           // FPU State
    logic [1:0] fs;           // FPU State
    logic [1:0] mpp;          // M-mode prior privilege level
    logic [1:0] reserved_9;
    logic       spp;          // S-mode prior privilege level
    logic       mpie;         // M-mode prior interrupt enable
    logic       ube;          // U-mode data endian (0=little-endian, 1=big-endian),
    logic       spie;         // S-mode prior interrupt enable
    logic       reserved_4;
    logic       mie;          // M-mode interrupt enable
    logic       reserved_2;
    logic       sie;          // S-mode interrupt enable
    logic       reserved_0;
} mstatus_t;

typedef struct packed {
    logic [28:0] reserved_6;
    logic        mbe;         // ZERO: M-mode data endian (0=little-endian, 1=big-endian)
    logic        sbe;         // ZERO: S-mode data endian (0=little-endian, 1=big-endian)
    logic        reserved_0;
} mstatush_t;

typedef enum logic {
    MTVEC_MODE_DIRECT   = 1'b0,
    MTVEC_MODE_VECTORED = 1'b1
} mtvec_mode_t;

typedef struct packed {
    logic [29:0] base;
    logic        reserved_1;
    mtvec_mode_t mode;
} mtvec_t;

typedef struct packed {
    logic        is_interrupt;
    logic [30:0] exception_code;
} mcause_t;

typedef enum logic [1:0] {
    PMPCFG_A_OFF =   2'b00, // Null Region
    PMPCFG_A_TOR   = 2'b01, // Top of Range
    PMPCFG_A_NA4   = 2'b10, // Naturally Aligned Four-Byte Region
    PMPCFG_A_NAPOT = 2'b11  // Naturally Aligned Power-of-Two Region
} matching_mode_t;

typedef struct packed {
    logic           locked;
    logic [1:0]     reserved_5;
    matching_mode_t matching_mode;
    logic [2:0]     rwx;
} pmpcfg_t;

typedef struct packed {
    word_t   addr;
    pmpcfg_t cfg;
} pmp_entry_t;

localparam logic [2:0] R = 3'b001;
localparam logic [2:0] W = 3'b010;
localparam logic [2:0] X = 3'b100;

typedef struct packed {
    logic [15:0] reserved_16;
    logic [ 3:0] reserved_12;
    logic        mei;         // Machine external interrupt
    logic        reserved_10;
    logic        sei;         // System external interrupt
    logic        reserved_8;
    logic        mti;         // Machine timer interrupt
    logic        reserved_6;
    logic        sti;         // System timer interrupt
    logic        reserved_3;
    logic        msi;         // Machine software interrupt
    logic        reserved_2;
    logic        ssi;         // System software interrupt
    logic        reserved_0;
} mi_t;

endpackage
