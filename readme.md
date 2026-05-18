# scr1-gowin
scr1 risc-v processor (syntacore) port for Tang Mega 138k pro board

This repository contains a bare-metal, single-core port of the open-source SCR1 RISC-V processor for the Gowin GW5AST FPGA, featuring a custom AHB-Lite bridge and a memory-mapped CP866 VGA/LCD driver.

Syntacore source: https://github.com/syntacore/scr1

> **Note:** Check out the [`multicore`](https://github.com/Ivanvet31/scr1-gowin/tree/multicore) branch for the  multiprocessing implementation. It features multiple SCR1 cores running independently with their own TCM memories while sharing the LCD screen via a custom hardware AHB bus arbiter.

## Modified and Added Files (Single-core)

### Hardware (RTL)
* **`src/includes/scr1_arch_custom.svh`**: Configured the reset vector to boot directly from TCM, set the clock frequency to 50 MHz, and disabled Xilinx/Intel vendor-specific macros.
* **`src/includes/scr1_arch_description.svh`**: Uncommented the `SCR1_ARCH_CUSTOM` macro to forcefully apply board-specific configurations during synthesis.
* **`src/top/scr1_dp_memory.sv`**: Replaced asynchronous read conditions with blocking assignments to properly infer Gowin BSRAM and added the `$readmemh` firmware initialization command.
* **`src/cp866_drv/`**: My screen driver. (https://github.com/Ivanvet31/cp866_screen_drv)
* **`src/top/scr1_top_gowin.sv` (Added)**: Instantiates the single SCR1 AHB core, implements an AHB-Lite to SRAM bridge, and maps the CP866 LCD driver to address `0xFF100000`. *(In the `multicore` branch, this file also includes second core instantiation and the AHB arbiter).*
* **`constraints.cst` (Added)**: Defines the physical pin constraints for the 50MHz clock, the active-low reset button, and the RGB LCD interface.

### Software (C/Assembly)
* **`sw/main.c` (Added)**: Contains the bare-metal C application that interacts with the memory-mapped LCD driver to draw text on the screen. *(In the `multicore` branch, it uses the `mhartid` CSR register to split tasks between cores).*
* **`sw/crt0.S` (Added)**: Provides the minimal RISC-V assembly startup code to initialize the stack pointer, clear the BSS section, and jump to `main`.
* **`sw/tcm.ld` (Added)**: Defines the linker memory layout to place all code, data, and the stack strictly into the 64KB TCM starting at `0xF0000000`.
* **`sw/bin2hex.py` (Added)**: Converts the compiled raw binary file into a plain hex text format compatible with the Verilog `$readmemh` function.
* **`sw/Makefile` (Added)**: Compiles the C and assembly sources into an ELF binary using the 32-bit RISC-V toolchain (`riscv32-none-elf-gcc`) and triggers the HEX conversion.

## How to Build the Firmware and FPGA Bitstream

1. **Setup the Toolchain:**
   Ensure you have a 32-bit RISC-V embedded toolchain installed (e.g., `riscv32-none-elf-gcc`). Note: Use `-march=rv32imc_zicsr` flag for newer GCC versions.

2. **Compile the Software:**
   Navigate to the `sw` directory and run `make`:
   ```bash
   cd sw
   make
   ```
   This will compile the code and generate the `firmware.hex` file.

3. **Synthesize the FPGA Design:**
   * Open the project in **Gowin EDA**.
   * Make sure the generated `firmware.hex` is located in the path specified within `src/top/scr1_dp_memory.sv`.
   * Synthesize the firmware for FPGA. The synthesizer will automatically read `firmware.hex` and embed your compiled C program directly into the FPGA's Block RAM (TCM).

4. **Program the Board:**
   Open the Gowin programmer (or use openFPGAloader) and upload the generated `.fs` bitstream to the Sipeed Tang Mega 138K Pro board. Press the physical reset button if the CPU does not start automatically.
