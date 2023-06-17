
`include "config.sv"

module sp_ram_wrap
  #(
    parameter RAM_SIZE   = 32768,              // in bytes
    parameter ADDR_WIDTH = $clog2(RAM_SIZE),
    parameter DATA_WIDTH = 32
  )(
    // Clock and Reset
    input  logic                    clk,
    input  logic                    rstn_i,
    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i,
    input  logic                    bypass_en_i
  );
  
  logic  [31:0]       bwen;

`ifdef SMIC55LL
  // replace macro ASIC by SMIC55LL
  // TODO replace memory here
    S55NLLGSPH_X512Y16D32_BW
  sp_ram_i
  (
                     .Q  ( rdata_o                 ),
			  .CLK( clk                     ),
			  .CEN( ~en_i                   ),
			  .WEN( (~we_i )  | bypass_en_i  ),
              .BWEN(  bwen   ),
			  .A  ( addr_i[ADDR_WIDTH-1:2]  ),
			  .D  ( wdata_i                 )
  );
  assign bwen = ~{{8{be_i[3]}},{8{be_i[2]}},{8{be_i[1]}},{8{be_i[0]}}} ;
//`elsif ASIC
//   // RAM bypass logic
//   logic [31:0] ram_out_int;
//   // assign rdata_o = (bypass_en_i) ? wdata_i : ram_out_int;
//   assign rdata_o = ram_out_int;
//
//   sp_ram_bank
//   #(
//    .NUM_BANKS  ( RAM_SIZE/4096 ),
//    .BANK_SIZE  ( 1024          )
//   )
//   sp_ram_bank_i
//   (
//    .clk_i   ( clk                     ),
//    .rstn_i  ( rstn_i                  ),
//    .en_i    ( en_i                    ),
//    .addr_i  ( addr_i                  ),
//    .wdata_i ( wdata_i                 ),
//    .rdata_o ( ram_out_int             ),
//    .we_i    ( (we_i & ~bypass_en_i)   ),
//    .be_i    ( be_i                    )
//   );

  // TODO: we should kill synthesis when the ram size is larger than what we
  // have here

`elsif PULP_FPGA_EMUL
  xilinx_mem_8192x32
  sp_ram_i
  (
    .clka   ( clk                    ),
    .rsta   ( 1'b0                   ), // reset is active high

    .ena    ( en_i                   ),
    .addra  ( addr_i[ADDR_WIDTH-1:2] ), 
    .dina   ( wdata_i                ),
    .douta  ( rdata_o                ),
    .wea    ( be_i & {4{we_i}}       )
  );

`else
  sp_ram
  #(
    .ADDR_WIDTH ( ADDR_WIDTH ),
    .DATA_WIDTH ( DATA_WIDTH ),
    .NUM_WORDS  ( RAM_SIZE   )
  )
  sp_ram_i
  (
    .clk_i   ( clk       ),

    .en_i    ( en_i      ),
    .addr_i  ( addr_i    ),
    .wdata_i ( wdata_i   ),
    .rdata_o ( rdata_o   ),
    .we_i    ( we_i      ),
    .be_i    ( be_i      )
  );
`endif

endmodule

