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
        input  wire logic       clk_i,             // clock
        input  wire logic       reset_i,           // reset_i

        // data memory port
        output      word_t      dmem_addr_o,       // address
        output      word_t      dmem_write_data_o, // write data
        output      logic [3:0] dmem_write_mask_o, // write enable
        
        // pipeline input port
        input  wire word_t      ir_i,              // instruction register
        input  wire word_t      ma_addr_i,         // memoricy access address
        input  wire ma_mode_t   ma_mode_i,         // memory access mode
        input  wire ma_size_t   ma_size_i,         // memory access size
        input  wire word_t      ma_data_i,         // memory access data
        input  wire wb_src_t    wb_src_i,          // write-back source
        input  wire word_t      wb_data_i,         // write-back register value
        
        // data hazard port
        output      regaddr_t   ma_wb_addr_o,      // write-back address
        output      word_t      ma_wb_data_o,      // write-back value
        output      logic       ma_wb_valid_o,     // write-back value valid

        // pipeline output port
        output      word_t      ir_o,              // instruction register
        output      logic       load_o,            // is this a loan instruction?
        output      ma_size_t   ma_size_o,         // memory access size
        output      word_t      wb_data_o          // write-back register value
    );
    

//
// Memory Signals
//

always_comb begin
    dmem_addr_o       = ma_addr_i;
    dmem_write_data_o = ma_data_i;
    dmem_write_mask_o = 4'b0000;
    
    if (ma_mode_i == MA_STORE) begin
        unique case (ma_size_i)
        MA_SIZE_B:
            begin
                dmem_write_data_o = { 4{ma_data_i[ 7:0]} };
                unique case (ma_addr_i[1:0])
                2'b00: dmem_write_mask_o = 4'b0001;
                2'b01: dmem_write_mask_o = 4'b0010;
                2'b10: dmem_write_mask_o = 4'b0100;
                2'b11: dmem_write_mask_o = 4'b1000;
                endcase
            end
        MA_SIZE_H:
            begin
                dmem_write_data_o = { 2{ma_data_i[15:0]} };
                begin
                    unique case (ma_addr_i[1:0])
                    2'b00:   dmem_write_mask_o = 4'b0011;
                    2'b10:   dmem_write_mask_o = 4'b1100;
                    default: dmem_write_mask_o = 4'b0000;
                endcase
            end
        end
        MA_SIZE_W:
            begin
                dmem_write_data_o = ma_data_i;
                dmem_write_mask_o = 4'b1111;
            end
        endcase
    end  
end 



//
// Hazard Signals
//

always_comb begin
    ma_wb_addr_o  = ir_i[11:7];
    ma_wb_data_o  = wb_data_i;
    ma_wb_valid_o = (wb_src_i != WB_SRC_MEM); 
end  


//
// Pass-through Signals to WB stage
//

always_ff @(posedge clk_i) begin
    ir_o      <= ir_i;
    load_o    <= (ma_mode_i == MA_LOAD);
    ma_size_o <= ma_size_i;
    wb_data_o <= wb_data_i;
    
    if (reset_i) begin
        ir_o      <= NOP_IR;
        load_o    <= 1'b0;
        ma_size_o <= NOP_MA_SIZE;
        wb_data_o <= 32'h00000000;
    end
end

endmodule
