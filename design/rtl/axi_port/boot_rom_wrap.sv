

`include "config.sv"

module boot_rom_wrap
  #(
    parameter ADDR_WIDTH = `ROM_ADDR_WIDTH,
    parameter DATA_WIDTH = 32
  )(
    // Clock and Reset
    input  logic                  clk,
    input  logic                  rst_n,
    input  logic                  en_i,
    input  logic [ADDR_WIDTH-1:0] addr_i,
    output logic [DATA_WIDTH-1:0] rdata_o
  );

`ifdef SMIC55LL
  // TODO replace memory here
  S55NLLGVMH_X128Y8D32 
  boot_rom_i
  (
    .Q   ( rdata_o                ),
    .A   ( addr_i[ADDR_WIDTH-1:2] ),
    .CLK ( clk                    ),
    .CEN ( ~en_i                  )  
  );

`elsif PULP_FPGA_EMUL
 xilinx_rom_1024x32 
 boot_rom_i 
 (
  .clka(clk),    // input wire clka
  .ena(en_i),      // input wire ena
  .addra(addr_i[ADDR_WIDTH-1:2]),  // input wire [9 : 0] addra
  .douta(rdata_o)  // output wire [31 : 0] douta
 );

`else
  boot_code
  boot_code_i
  (
    .CLK   ( clk                    ),
    .RSTN  ( rst_n                  ),
    .CSN   ( ~en_i                  ),
    .A     ( addr_i[ADDR_WIDTH-1:2] ),
    .Q     ( rdata_o                )
  );
`endif
endmodule
