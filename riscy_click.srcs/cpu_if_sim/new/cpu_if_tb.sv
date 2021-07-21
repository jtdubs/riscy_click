`timescale 1ns/1ps

module cpu_if_tb 
    // Import Constants
    import consts::*;
    ();

// board
logic clk;
logic reset;
logic halt;

// bus
word mem_addr;
word mem_data;

// in
word ex_jmp;
logic ex_jmp_valid;

// out
word pc;
word ir;

bios_block_rom bios (
    .clka(clk),
    .addra(mem_addr[11:2]),
    .douta(mem_data)
);

cpu_if #(.MEM_ACCESS_CYCLES(2)) cpu_if (
    .clk(clk),
    .reset(reset),
    .halt(halt),
    .mem_addr(mem_addr),
    .mem_data(mem_data),
    .ex_jmp(ex_jmp),
    .ex_jmp_valid(ex_jmp_valid),
    .pc(pc),
    .ir(ir)
);

// clock generator
initial begin
    clk = 1;
    forever begin
        #50 clk <= ~clk;
    end
end

// reset pulse (1 cycle)
initial begin
    reset = 1;
    #150 reset = 0;
end

// halt eventually
initial begin
    halt = 0;
    #2250 halt = 1;
end

// do some jumps
initial begin
    ex_jmp = 32'hXXXX;
    ex_jmp_valid = 1'b0;
    
    #750 begin
        ex_jmp = 32'h0100;
        ex_jmp_valid = 1'b1;
    end
    
    #100 begin
        ex_jmp = 32'hXXXX;
        ex_jmp_valid = 1'b0;
    end
    
    #600 begin
        ex_jmp = 32'h0080;
        ex_jmp_valid = 1'b1;
    end
    
    #100 begin
        ex_jmp = 32'hXXXX;
        ex_jmp_valid = 1'b0;
    end
end

endmodule
