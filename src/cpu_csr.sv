`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Control & Status Registers
///

module cpu_csr
    // Import Constants
    import common::*;
    import logging::*;
    (
        // cpu signals
        input  wire logic       clk_i,               // clock

        // control port
        input  wire logic       retired_i,           // did an instruction retire this cycle
        input  wire logic       interrupt_i,         // external interrupt indicator
        input  wire word_t      trap_pc_i,           // trap location
        input  wire mcause_t    mcause_i,            // trap cause
        input  wire logic       mtrap_i,             // trap valid
        input  wire logic       mret_i,              // ret valid

        // pipeline control
        output      word_t      jmp_addr_async_o,    // jump address (driven by interrupts/trap/etc.)
        output      logic       jmp_request_async_o, // jump request
        input  wire logic       jmp_accept_i,        // accept jump request

        // CSR read port
        input  wire csr_t       read_addr_i,
        input  wire logic       read_enable_i,
        output wire word_t      read_data_o,

        // CSR write port
        input  wire csr_t       write_addr_i,
        input  wire word_t      write_data_i,
        input  wire logic       write_enable_i,

        // PMP lookup port 1
        input  wire word_t      lookup1_addr_i,
        output      logic [2:0] lookup1_rwx_async_o,

        // PMP lookup port 2
        input  wire word_t      lookup2_addr_i,
        output      logic [2:0] lookup2_rwx_async_o
    );

initial start_logging();
final stop_logging();


//
// PMP Config
//

localparam pmp_entry_t [0:8] PMP_CONFIG = '{
    // [00000000, 00001000) - BIOS
    '{ (32'h00000000 >> 2), '{ rwx: R|X, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ (32'h00001000 >> 2), '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    // [10000000, 10001000) - System RAM
    '{ (32'h10000000 >> 2), '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ (32'h10001000 >> 2), '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    // [20000000, 20001000) - Video RAM
    '{ (32'h20000000 >> 2), '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NAPOT, default: '0 } },
    '{ (32'h20001000 >> 2), '{           locked: 1'b1, matching_mode: PMPCFG_A_OFF,   default: '0 } },

    //  FF000004            - Seven Segment Display
    '{ (32'hFF000004 >> 2), '{ rwx: R|W, locked: 1'b1, matching_mode: PMPCFG_A_NA4,   default: '0 } },
        //
    //  FF000008            - Switch Bank
    '{ (32'hFF000008 >> 2), '{ rwx: R,   locked: 1'b1, matching_mode: PMPCFG_A_NA4,   default: '0 } },

    // [FF00000C, FFFFFFFF] - UNUSED 
    '{ (32'hFFFFFFFF >> 2), '{           locked: 1'b1, matching_mode: PMPCFG_A_TOR,   default: '0 } }
};


//
// PMP Lookup
//

always_comb begin
    priority if (lookup1_addr_i < PMP_CONFIG[1].addr)
        lookup1_rwx_async_o = PMP_CONFIG[0].cfg.rwx;
    else if (lookup1_addr_i < PMP_CONFIG[2].addr)
        lookup1_rwx_async_o = PMP_CONFIG[1].cfg.rwx;
    else if (lookup1_addr_i < PMP_CONFIG[3].addr)
        lookup1_rwx_async_o = PMP_CONFIG[2].cfg.rwx;
    else if (lookup1_addr_i < PMP_CONFIG[4].addr)
        lookup1_rwx_async_o = PMP_CONFIG[3].cfg.rwx;
    else if (lookup1_addr_i < PMP_CONFIG[5].addr)
        lookup1_rwx_async_o = PMP_CONFIG[4].cfg.rwx;
    else if (lookup1_addr_i < PMP_CONFIG[6].addr)
        lookup1_rwx_async_o = PMP_CONFIG[5].cfg.rwx;
    else if (lookup1_addr_i == PMP_CONFIG[6].addr)
        lookup1_rwx_async_o = PMP_CONFIG[6].cfg.rwx;
    else if (lookup1_addr_i == PMP_CONFIG[7].addr)
        lookup1_rwx_async_o = PMP_CONFIG[7].cfg.rwx;
    else
        lookup1_rwx_async_o = PMP_CONFIG[8].cfg.rwx;
end

always_comb begin
    priority if (lookup2_addr_i < PMP_CONFIG[1].addr)
        lookup2_rwx_async_o = PMP_CONFIG[0].cfg.rwx;
    else if (lookup2_addr_i < PMP_CONFIG[2].addr)
        lookup2_rwx_async_o = PMP_CONFIG[1].cfg.rwx;
    else if (lookup2_addr_i < PMP_CONFIG[3].addr)
        lookup2_rwx_async_o = PMP_CONFIG[2].cfg.rwx;
    else if (lookup2_addr_i < PMP_CONFIG[4].addr)
        lookup2_rwx_async_o = PMP_CONFIG[3].cfg.rwx;
    else if (lookup2_addr_i < PMP_CONFIG[5].addr)
        lookup2_rwx_async_o = PMP_CONFIG[4].cfg.rwx;
    else if (lookup2_addr_i < PMP_CONFIG[6].addr)
        lookup2_rwx_async_o = PMP_CONFIG[5].cfg.rwx;
    else if (lookup2_addr_i == PMP_CONFIG[6].addr)
        lookup2_rwx_async_o = PMP_CONFIG[6].cfg.rwx;
    else if (lookup2_addr_i == PMP_CONFIG[7].addr)
        lookup2_rwx_async_o = PMP_CONFIG[7].cfg.rwx;
    else
        lookup2_rwx_async_o = PMP_CONFIG[8].cfg.rwx;
end


//
// Default Values
//

localparam mtvec_t MTVEC_DEFAULT = '{
    base:       30'b0,
    reserved_1: 1'b0,
    mode:       MTVEC_MODE_DIRECT
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

localparam mcause_t MCAUSE_DEFAULT = '{
    is_interrupt:   1'b0,
    exception_code: 31'b0
};


//
// CSR Registers
//

// Counters
dword_t  mcycle_r,   mcycle_w;            // cycle counter
dword_t  minstret_r, minstret_w;          // retired instruction counter
dword_t  time_r,     time_w;              // time counter

// Non-Counters
mtvec_t  mtvec_r         = MTVEC_DEFAULT;         // trap vector
word_t   mcountinhibit_r = MCOUNTINHIBIT_DEFAULT; // counter inhibitor
word_t   mscratch_r      = MSCRATCH_DEFAULT;      // scratch buffer
word_t   mepc_r          = MEPC_DEFAULT;          // exception program counter
mcause_t mcause_r        = MCAUSE_DEFAULT;        // exception cause
word_t   mtval_r         = MTVAL_DEFAULT;         // exception val
word_t   mtval2_r        = MTVAL2_DEFAULT;        // exception val2
word_t   mtinst_r        = MTINST_DEFAULT;        // exception instruction
logic    mstatus_mie_r   = 1'b0;                  // global interrupt enabled
logic    mstatus_mie_w;                           // global interrupt enabled
logic    mstatus_mpie_r  = 1'b0;                  // global interrupt enabled (prior)
logic    mstatus_mpie_w;                          // global interrupt enabled (prior)
logic    meip_w;                                  // machine external interrupt pending
logic    mtip_r          = 1'b0;                  // machine timer    interrupt pending
logic    msip_r          = 1'b0;                  // machine software interrupt pending
logic    meie_r          = 1'b0;                  // machine external interrupt enabled
logic    mtie_r          = 1'b0;                  // machine timer    interrupt enabled
logic    msie_r          = 1'b0;                  // machine software interrupt enabled


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
// Trap Handling
//

// interrupt pending
always_comb begin
    meip_w = interrupt_i;
end

// interrupt enablement
logic interrupt_w;
always_comb begin
    // interrupt if interrupt is pending, enabled, and globally enabled
    interrupt_w = meip_w && meie_r && mstatus_mie_r;
end

// jump requests
always_comb begin
    // request jump on interrupt, mtrap or mret
    jmp_request_async_o = interrupt_w || mtrap_i || mret_i;

    priority if (mret_i) begin
        // mret jumps to mepc
        jmp_addr_async_o = mepc_r;
    end else if (mtrap_i || interrupt_w) begin
        // mtrap and interrtupt jump to mtvec
        unique case (mtvec_r.mode)
        MTVEC_MODE_DIRECT:
            jmp_addr_async_o = { mtvec_r.base, 2'b00 };
        MTVEC_MODE_VECTORED:
            unique if (interrupt_i)
                jmp_addr_async_o = { mtvec_r.base + INT_M_EXTERNAL[29:0], 2'b00 };
            else
                jmp_addr_async_o = { mtvec_r.base,                        2'b00 };
        endcase
    end else begin
        jmp_addr_async_o = 32'b0;
    end
end

always_ff @(posedge clk_i) begin
    `log_strobe(("{ \"stage\": \"CSR\", \"pc\": \"%0d\", \"jmp_addr\": \"%0d\", \"jmp_request\": \"%0d\", \"jmp_accept\": \"%0d\", \"interrupt\": \"%0d\" }", trap_pc_i, jmp_addr_async_o, jmp_request_async_o, jmp_accept_i, interrupt_i));
end


// manage intererupt enablement stack
always_ff @(posedge clk_i) begin
    if (write_enable_i && write_addr_i == CSR_MSTATUS)
        // respect CSR write
        { mstatus_mie_r, mstatus_mpie_r } <= { mstatus_i.mie, mstatus_i.mpie };
    else if (jmp_accept_i && (interrupt_w || mtrap_i))
        // on accepted mtrap or interrupt, disable interrupts and save previous value
        { mstatus_mie_r, mstatus_mpie_r } <= { 1'b0,           mstatus_mie_r  };
    else if (jmp_accept_i && mret_i)
        // on accepted mret, restore previous value
        { mstatus_mie_r, mstatus_mpie_r } <= { mstatus_mpie_r, 1'b1           };
end

// update trap metadata
always_ff @(posedge clk_i) begin
    if (jmp_accept_i && mtrap_i)
        // trap causes are provided
        mcause_r <= mcause_i;
    else if (jmp_accept_i && interrupt_w)
        // interrupt cause is always the same
        mcause_r <= { 1'b1, INT_M_EXTERNAL };
    else if (jmp_accept_i && mret_i)
        // on return, cause is set back to default
        mcause_r <= MCAUSE_DEFAULT;
end

// execption program counter
always_ff @(posedge clk_i) begin
    if (write_enable_i && write_addr_i == CSR_MEPC)
        // respect CSR writes
        mepc_r <= write_data_i;
    else if (jmp_accept_i && (interrupt_w || mtrap_i))
        // on accepted mtrap or interrupt, disable interrupts and save previous value
        mepc_r <= trap_pc_i;
    else if (jmp_accept_i && mret_i)
        // on accepted mret, restore previous value
        mepc_r <= MEPC_DEFAULT;
end


//
// CSR Reads
//

mstatus_t mstatus_o;
always_comb mstatus_o = '{
    mie:         mstatus_mie_r,
    mpie:        mstatus_mpie_r,
    default:     '0
};

mi_t mie_o;
always_comb mie_o = '{
    mei:     meie_r,
    mti:     mtie_r,
    msi:     msie_r,
    default: '0
};

mi_t mip_o;
always_comb mip_o = '{
    mei:     meip_w,
    mti:     mtip_r,
    msi:     msip_r,
    default: '0
};

word_t read_data_r = '0;

always_ff @(posedge clk_i) begin
    if (read_enable_i) begin
        unique case (read_addr_i)
        //                                  MXLEN=32           ZYXWVUTSRQPONMLKJIHGFEDCBA
        CSR_MISA:          read_data_r <= { 2'b01,   4'b0, 26'b00000000000000000100000000 };
        CSR_MVENDORID:     read_data_r <= 32'b0;
        CSR_MARCHID:       read_data_r <= 32'b0;
        CSR_MIMPID:        read_data_r <= 32'h0001;
        CSR_MHARTID:       read_data_r <= 32'b0;
        CSR_MSTATUS:       read_data_r <= mstatus_o;
        CSR_MTVEC:         read_data_r <= mtvec_r;
        CSR_MCOUNTINHIBIT: read_data_r <= mcountinhibit_r;
        CSR_MSCRATCH:      read_data_r <= mscratch_r;
        CSR_MCAUSE:        read_data_r <= mcause_r;
        CSR_MEPC:          read_data_r <= mepc_r;
        CSR_MTVAL:         read_data_r <= mtval_r;
        CSR_MTVAL2:        read_data_r <= mtval2_r;
        CSR_MTINST:        read_data_r <= mtinst_r;
        CSR_MIP:           read_data_r <= mip_o;
        CSR_MIE:           read_data_r <= mie_o;
        CSR_MCYCLE,
        CSR_CYCLE:         read_data_r <= mcycle_r[31:0];
        CSR_TIME:          read_data_r <= time_r[31:0];
        CSR_MINSTRET,
        CSR_INSTRET:       read_data_r <= minstret_r[31:0];
        CSR_MCYCLEH,
        CSR_CYCLEH:        read_data_r <= mcycle_r[63:32];
        CSR_TIMEH:         read_data_r <= time_r[63:32];
        CSR_MINSTRETH,
        CSR_INSTRETH:      read_data_r <= minstret_r[63:32];
        (CSR_PMPCFG0+0):   read_data_r <= { PMP_CONFIG[3].cfg, PMP_CONFIG[2].cfg, PMP_CONFIG[1].cfg, PMP_CONFIG[0].cfg };
        (CSR_PMPCFG0+1):   read_data_r <= { PMP_CONFIG[7].cfg, PMP_CONFIG[6].cfg, PMP_CONFIG[5].cfg, PMP_CONFIG[4].cfg };
        (CSR_PMPCFG0+2):   read_data_r <= { 8'b0,              8'b0,              8'b0,              PMP_CONFIG[8].cfg };
        (CSR_PMPADDR0+0):  read_data_r <= PMP_CONFIG[0].addr;
        (CSR_PMPADDR0+1):  read_data_r <= PMP_CONFIG[1].addr;
        (CSR_PMPADDR0+2):  read_data_r <= PMP_CONFIG[2].addr;
        (CSR_PMPADDR0+3):  read_data_r <= PMP_CONFIG[3].addr;
        (CSR_PMPADDR0+4):  read_data_r <= PMP_CONFIG[4].addr;
        (CSR_PMPADDR0+5):  read_data_r <= PMP_CONFIG[5].addr;
        (CSR_PMPADDR0+6):  read_data_r <= PMP_CONFIG[6].addr;
        (CSR_PMPADDR0+7):  read_data_r <= PMP_CONFIG[7].addr;
        (CSR_PMPADDR0+8):  read_data_r <= PMP_CONFIG[8].addr;
        default:           read_data_r <= 32'b0;
        endcase
    end else begin
        read_data_r <= 32'b0;
    end
end

assign read_data_o = read_data_r;


//
// CSR Writes
//

mstatus_t mstatus_i;
always_comb mstatus_i = mstatus_t'(write_data_i);

mi_t mie_i;
always_comb mie_i = mi_t'(write_data_i[15:0]);

always_ff @(posedge clk_i) begin
    if (write_enable_i) begin
        case (write_addr_i)
        CSR_MTVEC:          mtvec_r         <= write_data_i;
        CSR_MCOUNTINHIBIT:  mcountinhibit_r <= write_data_i;
        CSR_MSCRATCH:       mscratch_r      <= write_data_i;
        CSR_CYCLE:          mcycle_r        <= { mcycle_w  [63:32], write_data_i };
        CSR_TIME:           time_r          <= { time_w    [63:32], write_data_i };
        CSR_INSTRET:        minstret_r      <= { minstret_w[63:32], write_data_i };
        CSR_CYCLEH:         mcycle_r        <= { write_data_i, mcycle_w   [31:0] };
        CSR_TIMEH:          time_r          <= { write_data_i, time_w     [31:0] };
        CSR_INSTRETH:       minstret_r      <= { write_data_i, minstret_w [31:0] };
        CSR_MIE:
            begin
                meie_r <= mie_i.mei;
                mtie_r <= mie_i.mti;
                msie_r <= mie_i.msi;
            end
        endcase
    end else begin
        mcycle_r       <= mcycle_w;
        time_r         <= time_w;
        minstret_r     <= minstret_w;
    end
end

endmodule
