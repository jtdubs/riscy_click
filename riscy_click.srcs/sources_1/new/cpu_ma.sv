`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Memory Access Stage
///

module cpu_ma
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic       clk_i,            // clock
        input  wire logic       reset_i,         // reset_i

        // data memory port
        output      word_t      dmem_addr_o,   // address
        output      word_t      dmem_write_data_o,   // write data
        output      logic [3:0] dmem_write_mask_o,   // write enable
        
        // pipeline input port
        input  wire word_t      ir_i,       // instruction register
        input  wire word_t      ma_addr_i,     // memoricy access address
        input  wire ma_mode_t   ma_mode_i,     // memory access mode
        input  wire ma_size_t   ma_size_i,     // memory access size
        input  wire word_t      ma_data_i,     // memory access data
        input  wire wb_src_t    writeback_src_i,   // write-back source
        input  wire word_t      writeback_data_i,  // write-back register value
        
        // data hazard port
        output      regaddr_t   ma_writeback_addr_o,  // write-back address
        output      word_t      ma_writeback_data_o,  // write-back value
        output      logic       ma_writeback_valid_o, // write-back value valid

        // pipeline output port
        output      word_t      ir_o,       // instruction register
        output      logic       load_o,  // is this a loan instruction?
        output      word_t      writeback_data_o   // write-back register value
    );
    

//
// Memory Signals
//

always_comb begin
    dmem_addr_o       = ma_addr_i;
    dmem_write_data_o = ma_data_i;
    dmem_write_mask_o = (ma_mode_i == MA_STORE) ? 4'b1111 : 4'b0000;
    // TODO: deal with MA_SIZE values other than W
end 


//
// Hazard Signals
//

always_comb begin
    ma_writeback_addr_o = ir_i[11:7];

    case (writeback_src_i)
    WB_SRC_MEM:
        begin
            ma_writeback_data_o   = 32'b0;
            ma_writeback_valid_o  = 1'b0; // not available yet
        end
    default:  
        begin
            ma_writeback_data_o   = writeback_data_i;
            ma_writeback_valid_o  = 1'b1;
        end  
    endcase
end  


//
// Pass-through Signals to WB stage
//

always_ff @(posedge clk_i) begin
    ir_o   <= ir_i;
    load_o <= (ma_mode_i == MA_LOAD);
    writeback_data_o <= writeback_data_i;
    
    if (reset_i) begin
        ir_o   <= NOP_IR;
        load_o <= 1'b0;
        writeback_data_o <= 32'h00000000;
    end
end

endmodule
