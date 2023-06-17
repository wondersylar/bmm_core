

`include "axi_bus.sv"
`include "config.sv"

module core_region
#(
    parameter AXI_ADDR_WIDTH       = 32   ,
    parameter AXI_DATA_WIDTH       = 32   ,
    parameter AXI_ID_MASTER_WIDTH  = 1    ,
    parameter AXI_ID_SLAVE_WIDTH   = 2    ,
    parameter AXI_USER_WIDTH       = 1    ,
    parameter DATA_RAM_SIZE        = 32768, // in bytes 2^15
    parameter INSTR_RAM_SIZE       = 32768 // in bytes
    //parameter USE_ZERO_RISCY       = 0,
    //parameter RISCY_RV32F          = 0,
    //parameter ZERO_RV32M           = 1,
    //parameter ZERO_RV32E           = 0

  )
(
    // Clock and Reset
    input logic         clk,
    input logic         rst_n,

    input  logic        testmode_i,
    //input  logic        fetch_enable_i,
    //input  logic [31:0] irq_i,
    //output logic        core_busy_o,
    //input  logic        clock_gating_i,
    input  logic [31:0] boot_addr_i,

    AXI_BUS.Master      core_master,
    AXI_BUS.Slave       data_slave,
    AXI_BUS.Slave       instr_slave
    //AXI_BUS.Master      dbg_master,
    //DEBUG_BUS.Slave     debug,

    // JTAG signals
    //input  logic        tck_i,
    //input  logic        trstn_i,
    //input  logic        tms_i,
    //input  logic        tdi_i,
    //output logic        tdo_o
  );

  localparam INSTR_ADDR_WIDTH = $clog2(INSTR_RAM_SIZE)+1; // to make space for the boot rom
  localparam DATA_ADDR_WIDTH  = $clog2(DATA_RAM_SIZE);

  localparam AXI_B_WIDTH      = $clog2(AXI_DATA_WIDTH/8); // AXI "Byte" width

  // signals from/to core
  logic         core_instr_req;
  logic         core_instr_gnt;
  logic         core_instr_rvalid;
  logic [31:0]  core_instr_addr;
  logic [31:0]  core_instr_rdata;

  logic         core_lsu_req;
  logic         core_lsu_gnt;
  logic         core_lsu_rvalid;
  logic [31:0]  core_lsu_addr;
  logic         core_lsu_we;
  logic [3:0]   core_lsu_be;
  logic [31:0]  core_lsu_rdata;
  logic [31:0]  core_lsu_wdata;

  logic         core_data_req;
  logic         core_data_gnt;
  logic         core_data_rvalid;
  logic [31:0]  core_data_addr;
  logic         core_data_we;
  logic [3:0]   core_data_be;
  logic [31:0]  core_data_rdata;
  logic [31:0]  core_data_wdata;

  // signals to/from AXI mem
  logic                        is_axi_addr;
  logic                        axi_mem_req;
  logic [DATA_ADDR_WIDTH-1:0]  axi_mem_addr;
  logic                        axi_mem_we;
  logic [AXI_DATA_WIDTH/8-1:0] axi_mem_be;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_rdata;
  logic [AXI_DATA_WIDTH-1:0]   axi_mem_wdata;

  // signals to/from AXI instr
  logic                        axi_instr_req;
  logic [INSTR_ADDR_WIDTH-1:0] axi_instr_addr;
  logic                        axi_instr_we;
  logic [AXI_DATA_WIDTH/8-1:0] axi_instr_be;
  logic [AXI_DATA_WIDTH-1:0]   axi_instr_rdata;
  logic [AXI_DATA_WIDTH-1:0]   axi_instr_wdata;


  // signals to/from instr mem
  logic                        instr_mem_en;
  logic [INSTR_ADDR_WIDTH-1:0] instr_mem_addr;
  logic                        instr_mem_we;
  logic [AXI_DATA_WIDTH/8-1:0] instr_mem_be;
  logic [AXI_DATA_WIDTH-1:0]   instr_mem_rdata;
  logic [AXI_DATA_WIDTH-1:0]   instr_mem_wdata;

  // signals to/from data mem
  logic                        data_mem_en;
  logic [DATA_ADDR_WIDTH-1:0]  data_mem_addr;
  logic                        data_mem_we;
  logic [AXI_DATA_WIDTH/8-1:0] data_mem_be;
  logic [AXI_DATA_WIDTH-1:0]   data_mem_rdata;
  logic [AXI_DATA_WIDTH-1:0]   data_mem_wdata;



  enum logic [0:0] { AXI, RAM } lsu_resp_CS, lsu_resp_NS;

  // signals to/from core2axi
  logic         core_axi_req;
  logic         core_axi_gnt;
  logic         core_axi_rvalid;
  logic [31:0]  core_axi_addr;
  logic         core_axi_we;
  logic [3:0]   core_axi_be;
  logic [31:0]  core_axi_rdata;
  logic [31:0]  core_axi_wdata;

  AXI_BUS
  #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH     ( AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH      )
  )
  core_master_int();

  //----------------------------------------------------------------------------//
  // Core Instantiation
  //----------------------------------------------------------------------------//
bmm u_bmm
(
    .clk_i                  (clk  ),
    .rst_ni                 (rst_n),
    .instr_boot_addr_i      (boot_addr_i),

    .soft_irq_i             (1'b0), 
    .timer_irq_i            (1'b0), 
    .ex_irq_i               (1'b0), 
    
    .instr_rvld_i       (core_instr_rvalid   ),
    .instr_gnt_i        (core_instr_gnt      ),
    .instr_rdata_i      (core_instr_rdata    ),
    .instr_addr_o       (core_instr_addr     ),
    .instr_req_o        (core_instr_req      ),

    .data_gnt_i         (core_lsu_gnt       ),
    .data_addr_o        (core_lsu_addr      ),
    .data_req_o         (core_lsu_req       ),
    .data_rvalid_i      (core_lsu_rvalid    ),
    .data_rdata_i       (core_lsu_rdata     ),
    .data_err_i         (1'b0               ),
    .data_we_o          (core_lsu_we        ),
    .data_be_o          (core_lsu_be        ),
    .data_wdata_o       (core_lsu_wdata     )

);




  core2axi_wrap
  #(
    .AXI_ADDR_WIDTH   ( AXI_ADDR_WIDTH      ),
    .AXI_DATA_WIDTH   ( AXI_DATA_WIDTH      ),
    .AXI_ID_WIDTH     ( AXI_ID_MASTER_WIDTH ),
    .AXI_USER_WIDTH   ( AXI_USER_WIDTH      ),
    .REGISTERED_GRANT ( "FALSE"             )
  )
  core2axi_i
  (
    .clk_i         ( clk             ),
    .rst_ni        ( rst_n           ),

    .data_req_i    ( core_axi_req    ),
    .data_gnt_o    ( core_axi_gnt    ),
    .data_rvalid_o ( core_axi_rvalid ),
    .data_addr_i   ( core_axi_addr   ),
    .data_we_i     ( core_axi_we     ),
    .data_be_i     ( core_axi_be     ),
    .data_rdata_o  ( core_axi_rdata  ),
    .data_wdata_i  ( core_axi_wdata  ),

    .master        ( core_master_int )
  );

  //----------------------------------------------------------------------------//
  // AXI Slices
  //----------------------------------------------------------------------------//

  axi_slice_wrap
  #(
    .AXI_ADDR_WIDTH ( AXI_ADDR_WIDTH       ),
    .AXI_DATA_WIDTH ( AXI_DATA_WIDTH       ),
    .AXI_USER_WIDTH ( AXI_USER_WIDTH       ),
    .AXI_ID_WIDTH   ( AXI_ID_MASTER_WIDTH  ),
    .SLICE_DEPTH    ( 2                    )
  )
  axi_slice_core2axi
  (
    .clk_i      ( clk             ),
    .rst_ni     ( rst_n           ),

    .test_en_i  ( testmode_i      ),

    .axi_slave  ( core_master_int ),
    .axi_master ( core_master     )
  );


  //----------------------------------------------------------------------------//
  // DEMUX
  //----------------------------------------------------------------------------//
  //instr_addr: 0x0000_0000-0x0000_1FFF   data_addr: 0x0000_2000-0x0000_2FFF
  //is_axi_addr means addr except data_mem range
  assign is_axi_addr     = (core_lsu_addr[31:13] != 19'b1);
  assign core_data_req   = (~is_axi_addr) & core_lsu_req;
  assign core_axi_req    =   is_axi_addr  & core_lsu_req;

  assign core_data_addr  = core_lsu_addr;
  assign core_data_we    = core_lsu_we;
  assign core_data_be    = core_lsu_be;
  assign core_data_wdata = core_lsu_wdata;

  assign core_axi_addr   = core_lsu_addr;
  assign core_axi_we     = core_lsu_we;
  assign core_axi_be     = core_lsu_be;
  assign core_axi_wdata  = core_lsu_wdata;

  always_ff @(posedge clk, negedge rst_n)
  begin
    if (rst_n == 1'b0)
      lsu_resp_CS <= RAM;
    else
      lsu_resp_CS <= lsu_resp_NS;
  end

  // figure out where the next response will be coming from
  always_comb begin
    lsu_resp_NS = lsu_resp_CS;
    core_lsu_gnt = 1'b0;
    if (core_axi_req) begin
      core_lsu_gnt = core_axi_gnt;
      lsu_resp_NS = AXI;
    end else if (core_data_req) begin
      core_lsu_gnt = core_data_gnt;
      lsu_resp_NS = RAM;
    end
  end

  // route response back to LSU
  assign core_lsu_rdata  = (lsu_resp_CS == AXI) ? core_axi_rdata : core_data_rdata;
  assign core_lsu_rvalid = core_axi_rvalid | core_data_rvalid;



  //----------------------------------------------------------------------------//
  // Instruction RAM
  //----------------------------------------------------------------------------//

  instr_ram_wrap
  #(
    .RAM_SIZE   ( INSTR_RAM_SIZE ),
    .DATA_WIDTH ( AXI_DATA_WIDTH )
  )
  instr_mem
  (
    .clk         ( clk             ),
    .rst_n       ( rst_n           ),
    .en_i        ( instr_mem_en    ),
    .addr_i      ( instr_mem_addr  ),
    .wdata_i     ( instr_mem_wdata ),
    .rdata_o     ( instr_mem_rdata ),
    .we_i        ( instr_mem_we    ),
    .be_i        ( instr_mem_be    ),
    .bypass_en_i ( testmode_i      )
  );

  axi_mem_if_SP_wrap
  #(
    .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH         ),
    .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH         ),
    .AXI_ID_WIDTH    ( AXI_ID_SLAVE_WIDTH     ),
    .AXI_USER_WIDTH  ( AXI_USER_WIDTH         ),
    .MEM_ADDR_WIDTH  ( INSTR_ADDR_WIDTH       )
  )
  instr_mem_axi_if
  (
    .clk         ( clk               ),
    .rst_n       ( rst_n             ),
    .test_en_i   ( testmode_i        ),

    .mem_req_o   ( axi_instr_req     ),
    .mem_addr_o  ( axi_instr_addr    ),
    .mem_we_o    ( axi_instr_we      ),
    .mem_be_o    ( axi_instr_be      ),
    .mem_rdata_i ( axi_instr_rdata   ),
    .mem_wdata_o ( axi_instr_wdata   ),

    .slave       ( instr_slave       )
  );


  ram_mux
  #(
    .ADDR_WIDTH ( INSTR_ADDR_WIDTH ),
    .IN0_WIDTH  ( AXI_DATA_WIDTH   ),
    .IN1_WIDTH  ( 32               ),
    .OUT_WIDTH  ( AXI_DATA_WIDTH   )
  )
  instr_ram_mux_i
  (
    .clk            ( clk               ),
    .rst_n          ( rst_n             ),

    .port0_req_i    ( axi_instr_req     ),
    .port0_gnt_o    (                   ),
    .port0_rvalid_o (                   ),
    //axi access to instr_mem must align 4 byte?
    .port0_addr_i   ( {axi_instr_addr[INSTR_ADDR_WIDTH-AXI_B_WIDTH-1:0], {AXI_B_WIDTH{1'b0}}} ),
    .port0_we_i     ( axi_instr_we      ),
    .port0_be_i     ( axi_instr_be      ),
    .port0_rdata_o  ( axi_instr_rdata   ),
    .port0_wdata_i  ( axi_instr_wdata   ),

    .port1_req_i    ( core_instr_req    ),
    .port1_gnt_o    ( core_instr_gnt    ),
    .port1_rvalid_o ( core_instr_rvalid ),
    //core access to instr_mem is naturally align 4 byte ?
    .port1_addr_i   ( core_instr_addr[INSTR_ADDR_WIDTH-1:0] ),
    .port1_we_i     ( 1'b0              ),
    .port1_be_i     ( '1                ),
    .port1_rdata_o  ( core_instr_rdata  ),
    .port1_wdata_i  ( '0                ),

    .ram_en_o       ( instr_mem_en      ),
    .ram_addr_o     ( instr_mem_addr    ),
    .ram_we_o       ( instr_mem_we      ),
    .ram_be_o       ( instr_mem_be      ),
    .ram_rdata_i    ( instr_mem_rdata   ),
    .ram_wdata_o    ( instr_mem_wdata   )
  );


  //----------------------------------------------------------------------------//
  // Data RAM
  //----------------------------------------------------------------------------//
  sp_ram_wrap
  #(
    .RAM_SIZE   ( DATA_RAM_SIZE  ),
    .DATA_WIDTH ( AXI_DATA_WIDTH )
  )
  data_mem
  (
    .clk          ( clk            ),
    .rstn_i       ( rst_n          ),
    .en_i         ( data_mem_en    ),
    .addr_i       ( data_mem_addr  ),
    .wdata_i      ( data_mem_wdata ),
    .rdata_o      ( data_mem_rdata ),
    .we_i         ( data_mem_we    ),
    .be_i         ( data_mem_be    ),
    .bypass_en_i  ( testmode_i     )
  );

  axi_mem_if_SP_wrap
  #(
    .AXI_ADDR_WIDTH  ( AXI_ADDR_WIDTH     ),
    .AXI_DATA_WIDTH  ( AXI_DATA_WIDTH     ),
    .AXI_ID_WIDTH    ( AXI_ID_SLAVE_WIDTH ),
    .AXI_USER_WIDTH  ( AXI_USER_WIDTH     ),
    .MEM_ADDR_WIDTH  ( DATA_ADDR_WIDTH    )
  )
  data_mem_axi_if
  (
    .clk         ( clk               ),
    .rst_n       ( rst_n             ),
    .test_en_i   ( testmode_i        ),

    .mem_req_o   ( axi_mem_req       ),
    .mem_addr_o  ( axi_mem_addr      ),
    .mem_we_o    ( axi_mem_we        ),
    .mem_be_o    ( axi_mem_be        ),
    .mem_rdata_i ( axi_mem_rdata     ),
    .mem_wdata_o ( axi_mem_wdata     ),

    .slave       ( data_slave        )
  );


  ram_mux
  #(
    .ADDR_WIDTH ( DATA_ADDR_WIDTH ),
    .IN0_WIDTH  ( AXI_DATA_WIDTH  ),
    .IN1_WIDTH  ( 32              ),
    .OUT_WIDTH  ( AXI_DATA_WIDTH  )
  )
  data_ram_mux_i
  (
    .clk            ( clk              ),
    .rst_n          ( rst_n            ),

    .port0_req_i    ( axi_mem_req      ),
    .port0_gnt_o    (                  ),
    .port0_rvalid_o (                  ),
    .port0_addr_i   ( {axi_mem_addr[DATA_ADDR_WIDTH-AXI_B_WIDTH-1:0], {AXI_B_WIDTH{1'b0}}} ),
    .port0_we_i     ( axi_mem_we       ),
    .port0_be_i     ( axi_mem_be       ),
    .port0_rdata_o  ( axi_mem_rdata    ),
    .port0_wdata_i  ( axi_mem_wdata    ),

    .port1_req_i    ( core_data_req    ),
    .port1_gnt_o    ( core_data_gnt    ),
    .port1_rvalid_o ( core_data_rvalid ),
    .port1_addr_i   ( core_data_addr[DATA_ADDR_WIDTH-1:0] ),
    .port1_we_i     ( core_data_we     ),
    .port1_be_i     ( core_data_be     ),
    .port1_rdata_o  ( core_data_rdata  ),
    .port1_wdata_i  ( core_data_wdata  ),

    .ram_en_o       ( data_mem_en      ),
    .ram_addr_o     ( data_mem_addr    ),
    .ram_we_o       ( data_mem_we      ),
    .ram_be_o       ( data_mem_be      ),
    .ram_rdata_i    ( data_mem_rdata   ),
    .ram_wdata_o    ( data_mem_wdata   )
  );




  //----------------------------------------------------------------------------//
  // Test Code
  //----------------------------------------------------------------------------//

  // introduce random stalls for data access to stress LSU
`ifdef DATA_STALL_RANDOM
  random_stalls data_stalls_i
  (
    .clk           ( clk                     ),

    .core_req_i    ( CORE.RISCV_CORE.data_req_o   ),
    .core_addr_i   ( CORE.RISCV_CORE.data_addr_o  ),
    .core_we_i     ( CORE.RISCV_CORE.data_we_o    ),
    .core_be_i     ( CORE.RISCV_CORE.data_be_o    ),
    .core_wdata_i  ( CORE.RISCV_CORE.data_wdata_o ),
    .core_gnt_o    (                         ),
    .core_rdata_o  (                         ),
    .core_rvalid_o (                         ),

    .data_req_o    (                         ),
    .data_addr_o   (                         ),
    .data_we_o     (                         ),
    .data_be_o     (                         ),
    .data_wdata_o  (                         ),
    .data_gnt_i    ( core_lsu_gnt            ),
    .data_rdata_i  ( core_lsu_rdata          ),
    .data_rvalid_i ( core_lsu_rvalid         )
  );

  initial begin
    force CORE.RISCV_CORE.data_gnt_i    = data_stalls_i.core_gnt_o;
    force CORE.RISCV_CORE.data_rvalid_i = data_stalls_i.core_rvalid_o;
    force CORE.RISCV_CORE.data_rdata_i  = data_stalls_i.core_rdata_o;

    force core_lsu_req   = data_stalls_i.data_req_o;
    force core_lsu_addr  = data_stalls_i.data_addr_o;
    force core_lsu_we    = data_stalls_i.data_we_o;
    force core_lsu_be    = data_stalls_i.data_be_o;
    force core_lsu_wdata = data_stalls_i.data_wdata_o;
  end
`endif

  // introduce random stalls for instruction access to stress instruction
  // fetcher
`ifdef INSTR_STALL_RANDOM
  random_stalls instr_stalls_i
  (
    .clk           ( clk                     ),

    .core_req_i    ( CORE.RISCV_CORE.instr_req_o  ),
    .core_addr_i   ( CORE.RISCV_CORE.instr_addr_o ),
    .core_we_i     (                         ),
    .core_be_i     (                         ),
    .core_wdata_i  (                         ),
    .core_gnt_o    (                         ),
    .core_rdata_o  (                         ),
    .core_rvalid_o (                         ),

    .data_req_o    (                         ),
    .data_addr_o   (                         ),
    .data_we_o     (                         ),
    .data_be_o     (                         ),
    .data_wdata_o  (                         ),
    .data_gnt_i    ( core_instr_gnt          ),
    .data_rdata_i  ( core_instr_rdata        ),
    .data_rvalid_i ( core_instr_rvalid       )
  );

  initial begin
    force CORE.RISCV_CORE.instr_gnt_i    = instr_stalls_i.core_gnt_o;
    force CORE.RISCV_CORE.instr_rvalid_i = instr_stalls_i.core_rvalid_o;
    force CORE.RISCV_CORE.instr_rdata_i  = instr_stalls_i.core_rdata_o;

    force core_instr_req   = instr_stalls_i.data_req_o;
    force core_instr_addr  = instr_stalls_i.data_addr_o;
  end
`endif

endmodule
