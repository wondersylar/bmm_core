`timescale 1 ns / 1 ps

module tb_bmm;

    logic clk_i;
    logic rst_ni;
        
    localparam int unsigned CLOCK_PERIOD = 10ns;
    longint unsigned cycles;

    logic               instr_gnt      ;
    logic               instr_rvld     ;
    logic   [31:0]      instr_rdata    ;
    logic   [31:0]      instr_addr     ;
    logic               instr_req      ;

    logic               data_gnt      ;
    logic   [31:0]      dram_data_addr     ;
    logic   [31:0]      data_addr     ;
    logic               data_req      ;
    logic               data_rvalid   ;
    logic   [31:0]      data_rdata    ;
    logic               data_we       ;
    logic   [3:0]       data_be       ;
    logic   [31:0]      data_wdata    ;
    
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
//=================================================================================

    //logic [3:0][7:0] cc[4:0],dd,ee;
    //logic signed [5:0] aa,bb;
    //`define CC_DATA(h,b,w) cc[``h``][``b``][``w``]
    //initial begin
    //    cc = '{default:0} ;
    //    dd = 4'b0001 ;
    //    ee = 4'b1001 ;
    //    repeat(10) @(posedge clk_i); 
    //    for(int h=0;h<5;h++)begin
    //      for(int b=0;b<4;b++)begin
    //        repeat(1) @(posedge clk_i); 
    //        for(int w=0;w<8;w++)begin
    //            `CC_DATA(h,b,w) = 1'b1;
    //            repeat(1) @(posedge clk_i); 
    //        end
    //      end
    //    end
    //    //force `CC_DATA(1,0) = 1'b0;
    //end
    logic [3:0] tt_data,tt_data_d;
    logic [7:0] tt_cnt;
    initial begin
        tt_data_d = 4'b1;
        repeat(15) @(posedge clk_i); 
        tt_data_d = 4'b11;
        repeat(3) @(posedge clk_i); 
        tt_data_d <= 4'b111;
        # 33;
        tt_data_d = 4'b1111;
    end


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni)  
            tt_data <= 4'b0;
        else //if(tt_cnt == 8'd10)
            tt_data <= tt_data_d;
    end


    always_ff @(posedge clk_i ) begin
        if (!rst_ni)  
            tt_cnt <= 8'b0;
        else
            tt_cnt <= tt_cnt + 1'b1;
    end




//=================================================================================


  
  string test_name;

`ifdef ISA_TEST_ONE_RAM

    localparam MEM_DP = 16384;
    logic [7:0] init_mem  [0:MEM_DP-1] ;

    initial begin
        if($value$plusargs("testcase=%s",test_name)) begin
            $display("test_name=%s",test_name);
            $readmemh(test_name,init_mem);
        end

        for(int unsigned addr = 0; addr < MEM_DP/4; addr++) begin
            for (int unsigned offset = 0; offset < 4; offset++) begin
                u_ram.mem[addr][offset] = init_mem[addr*4 + offset];
            end
        end
    end




    logic   [31:0]   gp_x3;
    logic   [31:0]   a7_x17;
    logic   [31:0]   a0_x10;

        assign gp_x3   = u_bmm.u_commit.u_register_file.mem[3][31:0];
        assign a7_x17  = u_bmm.u_commit.u_register_file.mem[17][31:0];
        assign a0_x10  = u_bmm.u_commit.u_register_file.mem[10][31:0];

    initial begin
        wait(a7_x17 == 32'd93)   // wait sim end, when x17 == 93 
        #100
        if (gp_x3 == 32'b1) begin
            $display("~~~~~~~~~~~~~~~ TEST_PASS %s~~~~~~~~~~~~~~~~~~~", test_name);
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~ #####     ##     ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #    #   #  #   #       #     ~~~~~~~~~");
            $display("~~~~~~~~~ #    #  #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~ #####   ######       #       #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #  #    #  #    #~~~~~~~~~");
            $display("~~~~~~~~~ #       #    #   ####    #### ~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
        end else begin
            $display("~~~~~~~~~~~~~~~ TEST_FAIL %s~~~~~~~~~~~~~~~~~~~~", test_name);
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("~~~~~~~~~~######    ##       #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#        #  #      #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#####   #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       ######     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    #     ~~~~~~~~~~");
            $display("~~~~~~~~~~#       #    #     #    ######~~~~~~~~~~");
            $display("~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~");
            $display("==================================================");
            $display("======= fail testnum = %2d", gp_x3);
            $display("==================================================");
        end
    end
`else
  

`endif



bmm u_bmm
(
    .clk_i                  (clk_i),
    .rst_ni                 (rst_ni),
    .instr_boot_addr_i      (32'h0),

    .soft_irq_i             (1'b0), 
    .timer_irq_i            (1'b0), 
    .ex_irq_i               (1'b0), 
    
    .instr_rvld_i           (instr_rvld     ),
    .instr_gnt_i            (instr_gnt      ),
    .instr_rdata_i          (instr_rdata    ),
    .instr_addr_o           (instr_addr     ),
    .instr_req_o            (instr_req      ),

    .data_gnt_i         (data_gnt       ),
    .data_addr_o        (data_addr      ),
    .data_req_o         (data_req       ),
    .data_rvalid_i      (data_rvalid    ),
    .data_rdata_i       (data_rdata     ),
    .data_err_i         (1'b0           ),
    .data_we_o          (data_we        ),
    .data_be_o          (data_be        ),
    .data_wdata_o       (data_wdata     )

);

    assign data_gnt = data_req;
    assign instr_gnt = 1'b0;//instr_req;
    assign instr_rvld = instr_req & (cycles <= 1300 );
    assign dram_data_addr = data_addr - 32'h1000;
    assign data_rvalid = data_req & ~data_we;
    
    logic iram_en;
    logic dram_en;
    logic allram_en;

    assign iram_en = instr_req;
    assign dram_en = data_req;  //req 
    assign allram_en = data_req | instr_req;  

`ifdef ISA_TEST_ONE_RAM

ram_selfdef 
#(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .NUM_BYTES     (16384)
)
u_ram
(
    .clk_i      (clk_i      ),
    .en_i       (allram_en  ),
    .addr_i     (data_addr  ),
    .addr2_i    (instr_addr ), //for instr_fetch
    .wdata_i    (data_wdata ),
    .rdata1_o   (data_rdata ),
    .rdata2_o   (instr_rdata), //for instr_fetch
    .we_i       (data_we    ), //0 read, 1 write
    .be_i       (data_be    )
);

`else

sp_ram 
#(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .NUM_BYTES     (4096)
)
u_iram 
(
    .clk_i      (clk_i),
    //.rst_ni     (rst_ni),
    .en_i       (iram_en),
    .addr_i     (instr_addr),
    .wdata_i    (32'b0),
    .rdata_o    (instr_rdata),
    .we_i       (~instr_req), //0 read, 1 write
    .be_i       (4'b1111)
);


//data_ram 
sp_ram
#(
    .ADDR_WIDTH    (32),
    .DATA_WIDTH    (32),
    .NUM_BYTES     (12288)
)
u_dram 
(
    .clk_i      (clk_i           ),
    //.rst_ni     (rst_ni         ),
    .en_i       (dram_en         ),
    .addr_i     (dram_data_addr  ),
    .wdata_i    (data_wdata      ),
    .rdata_o    (data_rdata      ),
    .we_i       (data_we         ), //0 & dram_en read, 1 & dram_en write
    .be_i       (data_be         )
);




`endif
    initial begin
        $fsdbDumpfile("tb_bmm");
        $fsdbDumpvars("+all");
        $fsdbDumpMDA(0, tb_bmm);
        $fsdbDumpflush;
        #100000 $finish();

    end

endmodule
