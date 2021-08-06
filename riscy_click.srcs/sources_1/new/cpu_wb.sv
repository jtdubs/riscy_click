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
        input  wire logic     reset_i,          // reset
        
        // data memory
        input  wire word_t    dmem_read_data_i, // memory data

        // pipeline inputs
        input  wire word_t    pc_i,             // program counter
        input  wire word_t    ir_i,             // instruction register
        input  wire logic     load_i,           // is this a load instruction?
        input  wire ma_size_t ma_size_i,        // memory access size
        input  wire word_t    wb_data_i,        // write-back data
        input  wire logic     wb_valid_i,       // write-back valid
        
        // async outputs
        output      regaddr_t wb_addr_async_o,  // write-back address
        output      word_t    wb_data_async_o,  // write-back data
        output      logic     wb_valid_async_o, // write-back valid
        output      logic     empty_async_o     // stage empty
    );

initial start_logging();
final stop_logging();

//
// Async Outputs
//

always_comb begin
    if (load_i) begin
        unique case (ma_size_i)
        MA_SIZE_B:   wb_data_async_o = { {24{dmem_read_data_i[ 7]}},  dmem_read_data_i[ 7:0] };
        MA_SIZE_H:   wb_data_async_o = { {16{dmem_read_data_i[15]}},  dmem_read_data_i[15:0] };
        MA_SIZE_BU:  wb_data_async_o = { 24'b0,                       dmem_read_data_i[ 7:0] };
        MA_SIZE_HU:  wb_data_async_o = { 16'b0,                       dmem_read_data_i[15:0] };
        MA_SIZE_W:   wb_data_async_o = dmem_read_data_i;
        endcase
    end else begin
        wb_data_async_o = wb_data_i;
    end
    
    wb_addr_async_o  = ir_i[11:7];
    wb_valid_async_o = wb_valid_i;
    
    if (reset_i) begin
        wb_addr_async_o  = 5'b0;
        wb_data_async_o  = 32'b0;
        wb_valid_async_o = NOP_WB_VALID;
    end
    
    empty_async_o = reset_i || (pc_i == NOP_PC);
end 


//
// Debug Logging
//
always_ff @(posedge clk_i) begin
    $fdisplay(log_fd, "{ \"stage\": \"WB\", \"time\": \"%0t\", \"pc\": \"%0d\", \"ir\": \"%0d\", \"wb_addr\": \"%0d\", \"wb_data\": \"%0d\", \"wb_valid\": \"%0d\" },", $time, pc_i, ir_i, wb_addr_async_o, wb_data_async_o, wb_valid_async_o);
end

endmodule
