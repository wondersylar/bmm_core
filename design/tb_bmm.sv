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
  
  
  string test_name;

`ifdef ISA_TEST_ONE_RAM

    localparam MEM_DP = 16384;
    logic [7:0] init_mem  [0:MEM_DP-1] ;

    initial begin
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-breakpoint.verilog", init_mem);        test_name = "rv32mi-p-breakpoint.verilog"  ;        //pass, but what's the meaning?
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-csr.verilog", init_mem);               test_name = "rv32mi-p-csr.verilog"  ;             //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-illegal.verilog", init_mem);           test_name = "rv32mi-p-illegal.verilog"  ;         //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-mcsr.verilog", init_mem);              test_name = "rv32mi-p-mcsr.verilog"  ;              //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-sbreak.verilog", init_mem);            test_name = "rv32mi-p-sbreak.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-scall.verilog", init_mem);             test_name = "rv32mi-p-scall.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32mi-p-shamt.verilog", init_mem);             test_name = "rv32mi-p-shamt.verilog"  ;             //fall
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32si-p-csr.verilog", init_mem);               test_name = "rv32si-p-csr.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32si-p-dirty.verilog", init_mem);             test_name = "rv32si-p-dirty.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32si-p-sbreak.verilog", init_mem);            test_name = "rv32si-p-sbreak.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32si-p-scall.verilog", init_mem);             test_name = "rv32si-p-scall.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32si-p-wfi.verilog", init_mem);               test_name = "rv32si-p-wfi.verilog"  ;
        
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-addi.verilog", init_mem);              test_name = "rv32ui-p-addi.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-add.verilog", init_mem);               test_name = "rv32ui-p-add.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-andi.verilog", init_mem);              test_name = "rv32ui-p-andi.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-and.verilog", init_mem);               test_name = "rv32ui-p-and.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-auipc.verilog", init_mem);             test_name = "rv32ui-p-auipc.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lui.verilog", init_mem);               test_name = "rv32ui-p-lui.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-beq.verilog", init_mem);               test_name = "rv32ui-p-beq.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-bgeu.verilog", init_mem);              test_name = "rv32ui-p-bgeu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-bge.verilog", init_mem);               test_name = "rv32ui-p-bge.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-bltu.verilog", init_mem);              test_name = "rv32ui-p-bltu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-blt.verilog", init_mem);               test_name = "rv32ui-p-blt.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-bne.verilog", init_mem);               test_name = "rv32ui-p-bne.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-jalr.verilog", init_mem);              test_name = "rv32ui-p-jalr.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-jal.verilog", init_mem);               test_name = "rv32ui-p-jal.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-fence_i.verilog", init_mem);           test_name = "rv32ui-p-fence_i.verilog"  ;     //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lbu.verilog", init_mem);               test_name = "rv32ui-p-lbu.verilog"  ;           //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lb.verilog", init_mem);                test_name = "rv32ui-p-lb.verilog"  ;            //pass
        $readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lhu.verilog", init_mem);               test_name = "rv32ui-p-lhu.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lh.verilog", init_mem);                test_name = "rv32ui-p-lh.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-lw.verilog", init_mem);                test_name = "rv32ui-p-lw.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sb.verilog", init_mem);                test_name = "rv32ui-p-sb.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sh.verilog", init_mem);                test_name = "rv32ui-p-sh.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sw.verilog", init_mem);                test_name = "rv32ui-p-sw.verilog"  ;          //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-simple.verilog", init_mem);            test_name = "rv32ui-p-simple.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-slli.verilog", init_mem);              test_name = "rv32ui-p-slli.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sll.verilog", init_mem);               test_name = "rv32ui-p-sll.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sltiu.verilog", init_mem);             test_name = "rv32ui-p-sltiu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-slti.verilog", init_mem);              test_name = "rv32ui-p-slti.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sltu.verilog", init_mem);              test_name = "rv32ui-p-sltu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-slt.verilog", init_mem);               test_name = "rv32ui-p-slt.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-srai.verilog", init_mem);              test_name = "rv32ui-p-srai.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sra.verilog", init_mem);               test_name = "rv32ui-p-sra.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-srli.verilog", init_mem);              test_name = "rv32ui-p-srli.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-srl.verilog", init_mem);               test_name = "rv32ui-p-srl.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-sub.verilog", init_mem);               test_name = "rv32ui-p-sub.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-xori.verilog", init_mem);              test_name = "rv32ui-p-xori.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-xor.verilog", init_mem);               test_name = "rv32ui-p-xor.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-ori.verilog", init_mem);               test_name = "rv32ui-p-ori.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32ui-p-or.verilog", init_mem);                test_name = "rv32ui-p-or.verilog"  ;
        
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-divu.verilog", init_mem);              test_name = "rv32um-p-divu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-div.verilog", init_mem);               test_name = "rv32um-p-div.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-remu.verilog", init_mem);              test_name = "rv32um-p-remu.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-rem.verilog", init_mem);               test_name = "rv32um-p-rem.verilog"  ;
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-mulhsu.verilog", init_mem);            test_name = "rv32um-p-mulhsu.verilog"  ;    //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-mulhu.verilog", init_mem);             test_name = "rv32um-p-mulhu.verilog"  ; //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-mulh.verilog", init_mem);              test_name = "rv32um-p-mulh.verilog"  ;  //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/isa_csr_00_init/rv32um-p-mul.verilog", init_mem);               test_name = "rv32um-p-mul.verilog"  ;     //pass


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
  
  initial begin
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-add.init", u_iram.mem);        test_name = "rv32ui-p-add.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-addi.init", u_iram.mem);       test_name = "rv32ui-p-addi.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-and.init", u_iram.mem);          test_name = "rv32ui-p-and.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-andi.init", u_iram.mem);       test_name = "rv32ui-p-andi.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-auipc.init", u_iram.mem);      test_name = "rv32ui-p-auipc.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-beq.init", u_iram.mem);        test_name = "rv32ui-p-beq.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-bge.init", u_iram.mem);        test_name = "rv32ui-p-bge.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-bgeu.init", u_iram.mem);       test_name = "rv32ui-p-bgeu.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-blt.init", u_iram.mem);        test_name = "rv32ui-p-blt.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-bltu.init", u_iram.mem);       test_name = "rv32ui-p-bltu.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-bne.init", u_iram.mem);        test_name = "rv32ui-p-bne.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-fence_i.init", u_iram.mem);    test_name = "rv32ui-p-fence_i.init";    //no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-jal.init", u_iram.mem);        test_name = "rv32ui-p-jal.init";         
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-jalr.init", u_iram.mem);       test_name = "rv32ui-p-jalr.init";        
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-or.init", u_iram.mem);         test_name = "rv32ui-p-or.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-ori.init", u_iram.mem);        test_name = "rv32ui-p-ori.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lb.init", u_iram.mem);         test_name = "rv32ui-p-lb.init";          // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lbu.init", u_iram.mem);        test_name = "rv32ui-p-lbu.init";         // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lh.init", u_iram.mem);         test_name = "rv32ui-p-lh.init";          // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lhu.init", u_iram.mem);        test_name = "rv32ui-p-lhu.init";         // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lui.init", u_iram.mem);        test_name = "rv32ui-p-lui.init";         // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-lw.init", u_iram.mem);         test_name = "rv32ui-p-lw.init";          // no init load data in dram
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sb.init", u_iram.mem);         test_name = "rv32ui-p-sb.init";         // pass test4 sb lh 
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sh.init", u_iram.mem);         test_name = "rv32ui-p-sh.init";         // pass test4 sh lw   
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sw.init", u_iram.mem);         test_name = "rv32ui-p-sw.init";         //pass
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-simple.init", u_iram.mem);     test_name = "rv32ui-p-simple.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sll.init", u_iram.mem);        test_name = "rv32ui-p-sll.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-slli.init", u_iram.mem);       test_name = "rv32ui-p-slli.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-slt.init", u_iram.mem);        test_name = "rv32ui-p-slt.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-slti.init", u_iram.mem);       test_name = "rv32ui-p-slti.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sltiu.init", u_iram.mem);      test_name = "rv32ui-p-sltiu.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sltu.init", u_iram.mem);       test_name = "rv32ui-p-sltu.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sra.init", u_iram.mem);        test_name = "rv32ui-p-sra.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-srai.init", u_iram.mem);       test_name = "rv32ui-p-srai.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-srl.init", u_iram.mem);        test_name = "rv32ui-p-srl.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-srli.init", u_iram.mem);       test_name = "rv32ui-p-srli.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-sub.init", u_iram.mem);        test_name = "rv32ui-p-sub.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-xor.init", u_iram.mem);        test_name = "rv32ui-p-xor.init";
        //$readmemh("/home/songxue/pcl_mcu_20210423/pcl_mcu/tests/init_test/rv32ui-p-xori.init", u_iram.mem);       test_name = "rv32ui-p-xori.init";
  end

    logic   [31:0]   s10_x26;
    logic   [31:0]   s11_x27;
    logic   [31:0]   gp_x3;

    assign s10_x26 = u_bmm.u_commit.u_register_file.mem[26][31:0];
    assign s11_x27 = u_bmm.u_commit.u_register_file.mem[27][31:0];
    assign gp_x3   = u_bmm.u_commit.u_register_file.mem[3][31:0];

    initial begin
        wait(s10_x26 == 32'b1)   // wait sim end, when x26 == 1
        #100
        if (s11_x27 == 32'b1) begin
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
            //for (r = 0; r < 32; r = r + 1)
                //$display("x%2d = 0x%x", r, tinyriscv_soc_top_0.u_tinyriscv.u_regs.regs[r]);
                //$display("x%2d = 0x%x", r, u_bmm.u_commit.u_register_file.mem[r]); 
        end
    end

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
    assign instr_gnt = instr_req;
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
        $fsdbDumpfile(tb_bmm);
        $fsdbDumpvars("+all");
        $fsdbDumpMDA(0, tb_bmm);
        $fsdbDumpflush;
        #100000 $finish();

    end

endmodule
