/// Copyright by Syntacore LLC © 2016-2020. See LICENSE for details
/// @file       <scr1_dp_memory.sv>
/// @brief      Dual-port synchronous memory with byte enable inputs
///

`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module scr1_dp_memory
#(
    parameter SCR1_WIDTH    = 32,
    parameter SCR1_SIZE     = `SCR1_IMEM_AWIDTH'h00010000,
    parameter SCR1_NBYTES   = SCR1_WIDTH / 8
)
(
    input   logic                           clk,
    // Port A
    input   logic                           rena,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addra,
    output  logic [SCR1_WIDTH-1:0]          qa,
    // Port B
    input   logic                           renb,
    input   logic                           wenb,
    input   logic [SCR1_NBYTES-1:0]         webb,
    input   logic [$clog2(SCR1_SIZE)-1:2]   addrb,
    input   logic [SCR1_WIDTH-1:0]          datab,
    output  logic [SCR1_WIDTH-1:0]          qb
);

`ifdef SCR1_TRGT_FPGA_INTEL
//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_INTEL_MAX10
(* ramstyle = "M9K" *)    logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `elsif SCR1_TRGT_FPGA_INTEL_ARRIAV
(* ramstyle = "M10K" *)   logic [SCR1_NBYTES-1:0][7:0]  memory_array  [0:(SCR1_SIZE/SCR1_NBYTES)-1];
 `endif
logic [3:0] wenbb;
//-------------------------------------------------------------------------------
// Port B memory behavioral description
//-------------------------------------------------------------------------------
assign wenbb = {4{wenb}} & webb;
always_ff @(posedge clk) begin
    if (wenb) begin
        if (wenbb[0]) begin
            memory_array[addrb][0] <= datab[0+:8];
        end
        if (wenbb[1]) begin
            memory_array[addrb][1] <= datab[8+:8];
        end
        if (wenbb[2]) begin
            memory_array[addrb][2] <= datab[16+:8];
        end
        if (wenbb[3]) begin
            memory_array[addrb][3] <= datab[24+:8];
        end
    end
    qb <= memory_array[addrb];
end
//-------------------------------------------------------------------------------
// Port A memory behavioral description
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    qa <= memory_array[addra];
end


`else // SCR1_TRGT_FPGA_INTEL

// CASE: OTHERS - GOWIN, XILINX, SIMULATION, ASIC etc

localparam int unsigned RAM_SIZE_WORDS = SCR1_SIZE/SCR1_NBYTES;

//-------------------------------------------------------------------------------
// Local signal declaration
//-------------------------------------------------------------------------------
 `ifdef SCR1_TRGT_FPGA_XILINX
(* ram_style = "block" *)  logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `else  // ASIC or SIMULATION
logic  [SCR1_WIDTH-1:0]  ram_block  [RAM_SIZE_WORDS-1:0];
 `endif


initial begin
    $readmemh
      ("/home/ivanvet31/works/fpga/projects/scr1-multicore/scr1-multicore/src/sw/firmware.hex", 
       ram_block);
end

// initial begin
//     // for (int i = 0; i < RAM_SIZE_WORDS; i++) begin
//     //     ram_block[i] = 32'h00000000; 
//     // end
    
//     ram_block[0] = 32'hff1002b7; // lui t0, 0xff100
//     ram_block[1] = 32'h04100313; // addi t1, zero, 0x41
//     ram_block[2] = 32'h00628023; // sb t1, 0(t0)
//     ram_block[3] = 32'h04200313; // addi t1, zero, 0x42
//     ram_block[4] = 32'h006280a3; // sb t1, 1(t0)
//     ram_block[5] = 32'h0000006f; // j .
// end


//-------------------------------------------------------------------------------
// Port A memory behavioral description (Instruction Fetch - Read Only)
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    qa <= ram_block[addra];
end

//-------------------------------------------------------------------------------
// Port B memory behavioral description (Data Access - Read/Write)
//-------------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (wenb) begin
        if (webb[0]) ram_block[addrb][ 7: 0] = datab[ 7: 0];
        if (webb[1]) ram_block[addrb][15: 8] = datab[15: 8];
        if (webb[2]) ram_block[addrb][23:16] = datab[23:16];
        if (webb[3]) ram_block[addrb][31:24] = datab[31:24];
    end
    
    qb <= ram_block[addrb];
end

`endif // SCR1_TRGT_FPGA_INTEL  

endmodule : scr1_dp_memory

`endif // SCR1_TCM_EN
