

`ifndef CONFIG_SV
`define CONFIG_SV
`define RISCV

// always define ASIC when we do a synthesis run
`ifndef PULP_FPGA_EMUL
`ifdef SYNTHESIS
`define SMIC55LL
// replace macro ASIC by technology macro SMIC55LL
// `define ASIC
`endif
`endif

// data and instruction RAM address and word width
`define ROM_ADDR_WIDTH      12
`define ROM_START_ADDR      32'h8000

// Simulation only stuff
`ifndef SYNTHESIS
//`define DATA_STALL_RANDOM
//`define INSTR_STALL_RANDOM
`endif

`endif
