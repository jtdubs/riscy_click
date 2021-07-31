`timescale 1ns / 1ps
`default_nettype none

///
/// Risc-V CPU Write Back Stage
///

module cpu_wb
    // Import Constants
    import common::*;
    (
        // cpu signals
        input  wire logic     clk_i,            // clock
        
        // data memory port
        input  wire word_t    dmem_read_data_i, // memory data

        // pipeline input port
        input  wire word_t    ir_i,             // instruction register
        input  wire logic     load_i,           // is this a load instruction?
        input  wire ma_size_t ma_size_i,        // memory access size
        input  wire word_t    wb_data_i,        // write-back register value
        
        // pipeline output port
        output      regaddr_t wb_addr_o,        // write-back address
        output      word_t    wb_data_o         // write-back value
    );
    

//
// Write Back Signals
//

always_comb begin
    wb_addr_o = ir_i[11:7];
    wb_data_o = wb_data_i;
    
    if (load_i) begin
        unique case (ma_size_i)
        MA_SIZE_B:   wb_data_o = { {24{dmem_read_data_i[ 7]}},  dmem_read_data_i[ 7:0] };
        MA_SIZE_H:   wb_data_o = { {16{dmem_read_data_i[15]}},  dmem_read_data_i[15:0] };
        MA_SIZE_BU:  wb_data_o = { 24'b0,                       dmem_read_data_i[ 7:0] };
        MA_SIZE_HU:  wb_data_o = { 16'b0,                       dmem_read_data_i[15:0] };
        MA_SIZE_W:   wb_data_o = dmem_read_data_i;
        endcase
    end
end 

endmodule
