
`timescale 1 ns / 1 ps
module tb_core_region;


    logic clk_i;
    logic rst_ni;
        
    localparam int unsigned CLOCK_PERIOD = 10ns;
    longint unsigned cycles;

    // Clock process
    initial begin
        rst_ni = 1'b0;
        repeat(10) @(posedge clk_i); 
        #3 rst_ni = 1'b1;
    end


    initial begin
        clk_i = 1'b1;
        forever begin
            #(CLOCK_PERIOD/2) clk_i = 1'b0;
            #(CLOCK_PERIOD/2) clk_i = 1'b1;
            if(rst_ni)
            cycles++;
        end
    end

AXI_BUS
#(
    .AXI_ADDR_WIDTH (32  ),
    .AXI_DATA_WIDTH (32  ),
    .AXI_ID_WIDTH   (2   ),
    .AXI_USER_WIDTH (1   )
)slaves[1:0]();

AXI_BUS
#(
    .AXI_ADDR_WIDTH (32  ),
    .AXI_DATA_WIDTH (32  ),
    .AXI_ID_WIDTH   (1   ),
    .AXI_USER_WIDTH (1   )
)masters[0:0]();

core_region
#(
    .AXI_ADDR_WIDTH       (32     ),
    .AXI_DATA_WIDTH       (32     ),
    .AXI_ID_MASTER_WIDTH  (1      ),
    .AXI_ID_SLAVE_WIDTH   (2      ),
    .AXI_USER_WIDTH       (1      ),
    .DATA_RAM_SIZE        (32768  ),
    .INSTR_RAM_SIZE       (32768  )
)                          
core_region_i              
(
    .clk            ( clk_i           ),
    .rst_n          ( rst_ni          ),

    .testmode_i     ( 1'b0              ),
    .boot_addr_i    ( 32'h0             ),

    .core_master    ( masters[0]        ),
    .data_slave     ( slaves[1]         ),
    .instr_slave    ( slaves[0]         )
);


  axi_node_intf_wrap
  #(
    .NB_MASTER      ( 2  ),
    .NB_SLAVE       ( 1  ),
    .AXI_ADDR_WIDTH ( 32 ),
    .AXI_DATA_WIDTH ( 32 ),
    .AXI_ID_WIDTH   ( 2  ),
    .AXI_USER_WIDTH ( 1  )
  )
  axi_interconnect_i
  (
    .clk       ( clk_i    ),
    .rst_n     ( rst_ni   ),
    .test_en_i ( 1'b0     ),

    .master    ( slaves     ),
    .slave     ( masters    ),

    .start_addr_i ( {  32'h0000_2000, 32'h0000_0000 } ),
    .end_addr_i   ( {  32'h0000_FFFF, 32'h0000_1FFF } )
  );


endmodule
