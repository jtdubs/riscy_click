# RISCy-Click Toy Computer

A barely tested, barely functional, toy computer being developed as a hobby project to gain better understanding of RISC-V, FPGA's, etc.

## Folder Structure

`compliance/`
Will become RISC-V compliance testing once the `riscv-arch-test` framework is ready for prime-time.

`roms/`
Code to generate the various ROM images required by the board.

`roms/bios/`
The source code for the BIOS ROM.  Compiled using the GCC RISC-V toolchain.

`roms/character_rom/`
Generates a ROM image by rendering the characters of a TTF font (using freetype) to a collection of tiles of the appropriate size for the chosen VGA mode.

`roms/keycode/`
Generates a ROM image that maps keyboard scancodes (set 2) to virtual keycodes.  The virtual keycode values were chosen based on  `/usr/include/linux/input-event-codes.h`.

`sim/`
A basic simulator for the FPGA board using `Verilator`, powered by `imgui`
It supports:
- Rendering the board's VGA output.
- Displaying the board's seven segment display output.
- Providing simulated PS/2 keybaord input.
- Simulating the physical switches on the FPGA board.

`src/`
The SystemVerilog source code for the computer.

`trace/`
A variation of the `sim` simulator that runs heedlessly and outputs a trace of the executed instructions.

`utils/log_analysis/`
Analyzes the `JSON` logs output by the SystemVerilog code to reconstruct a trace of the executed instructions and their results.

`vivado`
Xilinx Vivado project folder.

`vivado/constraints/`
Board constraints file for supported FPGA's.

`vivado/tb/`
Testbench SystemVerilog code.

## Signal Naming Convention

- `clk_i` - Clock (if only one used by module)
- `[id]_clk_i` - Clock (if multiple used by module)
- `reset_i` - Synchronous reset
- `[id]_reset_i` - Synchronous reset (for specified clock domain)
- `*_i` - Input port
- `*_o` - Registered output port
- `*_async_o` - Unregistered output port (varies during clock cycle based on input)
- `*_r` - Registers
- `*_w` - Wires / Combinational Logic

