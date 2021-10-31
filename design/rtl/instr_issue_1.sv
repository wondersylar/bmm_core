module instr_issue
(
    input    logic                          clk_i                       ,
    input    logic                          rst_ni                      ,     
    input    logic                          flush_issue_i               ,     

    input   instruction_entry_t             instr_decode_i              , 
    output  logic                           issue_sbe_rdy_o             , 
    //read rs from regfile 
    output  logic   [REG_ADDR_SIZE-1:0]     regfile_raddr_a_o           ,
    output  logic   [REG_ADDR_SIZE-1:0]     regfile_raddr_b_o           ,
    input   logic   [REG_DATA_WIDTH-1:0]    regfile_rdata_a_i           ,
    input   logic   [REG_DATA_WIDTH-1:0]    regfile_rdata_b_i           ,
    //commit to regfile
    input   logic                           commit_ack_i                ,
    output  logic                           commit_regfile_we_o       ,
    output  logic   [REG_ADDR_SIZE-1:0]     commit_regfile_waddr_o    ,
    output  logic   [REG_DATA_WIDTH-1:0]    commit_regfile_wdata_o    ,
    output  branch_t                        commit_branch_o           ,
    output  exception_t                     commit_ex_o               ,
    output  logic   [31:0]                  commit_pc_o               ,

    output  fu_data_t                       instr_issue_o             , 
    input                                   ex_rdy_i                  ,

    input   exception_t                     wb_ex_exception_i         ,
    input   branch_t                        wb_branch_i               ,
    input   wb_port_t   [NR_WB_PORTS-1:0]   wb_port_i                   
    );



    struct packed {
        logic                            rename_vld     ;    
        logic   [REG_ADDR_SIZE-1:0]      physical_name  ;   // sbe id
    } map_table_q[31:0] , map_table_d[31:0] ;               //x0 is no need to map

    struct packed {
        logic                   writed   ; // this bit indicates whether occupied the entry
        sbd_entry_t             sbe      ; // this is the score board entry we will send to ex
    } sbd_entry_q [MEM_DEPTH-1:0], sbd_entry_d [MEM_DEPTH-1:0];

    sbd_wb_t  [MEM_DEPTH-1:0]   sbd_wb_q        , sbd_wb_d ;
    sbd_rs1_t [MEM_DEPTH-1:0]   sbd_rs1_q       , sbd_rs1_d;
    sbd_rs2_t [MEM_DEPTH-1:0]   sbd_rs2_q       , sbd_rs2_d;
    logic     [MEM_DEPTH-1:0]   sbd_issue_q     , sbd_issue_d;

    logic   [ADDR_BITS-1:0]     cnt_d           , cnt_q;
    logic   [ADDR_BITS-1:0]     wptr_d          , wptr_q;
    logic   [ADDR_BITS-1:0]     issue_ptr_d     , issue_ptr_q;
    logic   [ADDR_BITS-1:0]     commit_ptr_d    , commit_ptr_q;
    logic                       full          ;
    logic                       empty;
    logic                       commit;
    logic   [MEM_DEPTH-1:0]     csr_cmp;
    logic                       csr_inflight;
    logic   [MEM_DEPTH-1:0]     rd_cmp;
    logic                       same_rd;
    logic   [31:0]              regfile_rdata_a;
    logic   [31:0]              regfile_rdata_b;

    logic                       fence_stall   ;
    logic                       fence_instr         ;
    logic                       pre_fence_done;

    logic   [MEM_DEPTH-1:0]     wb_comp_rs1_vld;
    logic   [MEM_DEPTH-1:0]     wb_comp_rs2_vld;
    logic   [NR_WB_PORTS-1:0]   wb_port_vld    ;

    struct packed {
        logic           rs1_cmp_rdy;
        logic           rs2_cmp_rdy;
        logic   [31:0] rs1_data;
        logic   [31:0] rs2_data;
    } wb_comp_matrix  [MEM_DEPTH:0], input_comp; //


    always_comb begin :write_back_compare
        wb_comp_matrix = '{(MEM_DEPTH+1){'{1'b0, 1'b0, 32'b0, 32'b0}}};//'{default: 0};
        for(int unsigned i = 0; i < NR_WB_PORTS; i++) begin
            if(wb_port_i[i].wb_vld) begin
                for(int unsigned j = 0; j < MEM_DEPTH; j++) begin
                    if(sbd_entry_q[j].writed) begin
                        if((~sbd_rs1_q[j].rs1_rdy) & sbd_entry_q[j].sbe.rs1[REG_ADDR_SIZE] & (sbd_entry_q[j].sbe.rs1[REG_ADDR_SIZE-1:0] == wb_port_i[i].trans_id)) begin
                            wb_comp_matrix[j].rs1_cmp_rdy = 1'b1;
                            wb_comp_matrix[j].rs1_data = wb_port_i[i].wb_data;
                        end
                        if((~sbd_rs2_q[j].rs2_rdy) & sbd_entry_q[j].sbe.rs2[REG_ADDR_SIZE] & (sbd_entry_q[j].sbe.rs2[REG_ADDR_SIZE-1:0] == wb_port_i[i].trans_id)) begin
                            wb_comp_matrix[j].rs2_cmp_rdy = 1'b1;
                            wb_comp_matrix[j].rs2_data = wb_port_i[i].wb_data;
                        end
                    end
                end
                //compare input instr.rs with wb,  forward data
                if(sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE-1:0] == wb_port_i[i].trans_id && sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE]) begin
                    wb_comp_matrix[MEM_DEPTH].rs1_cmp_rdy = 1'b1;
                    wb_comp_matrix[MEM_DEPTH].rs1_data    = wb_port_i[i].wb_data;
                end
                if(sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE-1:0] == wb_port_i[i].trans_id && sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE]) begin
                    wb_comp_matrix[MEM_DEPTH].rs2_cmp_rdy = 1'b1;
                    wb_comp_matrix[MEM_DEPTH].rs2_data    = wb_port_i[i].wb_data;
                end
            end
        end
    end


    
    //input <---> sbe
    always_comb begin :input_compare_sbe
        input_comp = '{default: 0};
        for(int unsigned j = 0; j < MEM_DEPTH ; j++) begin
            if(sbd_wb_q[j].rd_vld && sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE] && (sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE-1:0] == unsigned'(j))) begin
                input_comp.rs1_cmp_rdy   = 1'b1;
                input_comp.rs1_data      = sbd_wb_q[j].result;
            end
            if(sbd_wb_q[j].rd_vld && sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE] && (sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE-1:0] == unsigned'(j))) begin
                input_comp.rs2_cmp_rdy   = 1'b1;
                input_comp.rs2_data      = sbd_wb_q[j].result;
            end
        end
    end

    always_comb begin : csr_compare
        for(int unsigned i = 0; i < MEM_DEPTH; i++) begin
            if(sbd_issue_q[i])
                csr_cmp[i] = sbd_entry_q[i].sbe.csr_instr;
            else
                csr_cmp[i] = 1'b0;
        end
    end
    assign csr_inflight = |csr_cmp ;

    always_comb begin : rd_map_compare
        for(int unsigned i = 0; i < MEM_DEPTH; i++) begin
            if(sbd_entry_q[i].writed && (commit_ptr_q != unsigned'(i)))
                rd_cmp[i] = (sbd_entry_q[commit_ptr_q].sbe.rd == sbd_entry_q[i].sbe.rd);
            else
                rd_cmp[i] = 1'b0;
        end
    end
    assign same_rd = |rd_cmp ;

    always_comb begin : map_table
        map_table_d = map_table_q ;
        if(commit && ~same_rd) begin
            map_table_d[sbd_entry_q[commit_ptr_q].sbe.rd].physical_name = 5'b0;
            map_table_d[sbd_entry_q[commit_ptr_q].sbe.rd].rename_vld    = 1'b0;
        end 
        if(instr_decode_i.valid && issue_sbe_rdy_o) begin
            if(instr_decode_i.rd == 5'b0) begin
                map_table_d[0].physical_name = 5'b0;
                map_table_d[0].rename_vld    = 1'b0;
            end else begin 
                map_table_d[instr_decode_i.rd].physical_name = wptr_q ;
                map_table_d[instr_decode_i.rd].rename_vld    = 1'b1   ;
            end
        end 
        if(flush_issue_i) 
            map_table_d = '{32{'{1'b0, 5'b0}}} ;//'{default: 0};
    end


    always_comb begin : issue 
        sbd_issue_d = sbd_issue_q;
        if((sbd_rs1_d[issue_ptr_q].rs1_rdy && sbd_rs2_d[issue_ptr_q].rs2_rdy && ex_rdy_i) ||
           //if previous csr instructions in sbe not commit, this csr instruction can't be issued to ex_stage,
           //ex_stage will read csrfile only when previous csrfile read/write options are done, and write back result to sbd_wb_q.rd.
           (sbd_rs1_d[issue_ptr_q].rs1_rdy && sbd_entry_d[issue_ptr_q].sbe.csr_instr && ~csr_inflight && ex_rdy_i)) 
            sbd_issue_d[issue_ptr_q] = 1'b1;
        if(commit) 
            sbd_issue_d[commit_ptr_q] = 1'b0;
        if(flush_issue_i) 
            sbd_issue_d = '0;
    end

    always_comb begin : commit_out 
        if(flush_issue_i) 
            commit = 1'b0;
        else if(commit_ack_i && sbd_wb_q[commit_ptr_q].rd_vld) 
            commit = 1'b1;
        else
            commit = 1'b0;
    end

    
    
    always_comb begin : sbd_entry
        sbd_entry_d = sbd_entry_q;
        //write from decode
        if(instr_decode_i.valid && issue_sbe_rdy_o) begin
            sbd_entry_d[wptr_q].sbe.pc           = instr_decode_i.pc           ;
            sbd_entry_d[wptr_q].sbe.trans_id     = wptr_q     ;//to be modify
            sbd_entry_d[wptr_q].sbe.fu           = instr_decode_i.fu           ;
            sbd_entry_d[wptr_q].sbe.op           = instr_decode_i.op           ;
            sbd_entry_d[wptr_q].sbe.imm          = instr_decode_i.imm          ;
            sbd_entry_d[wptr_q].sbe.csr_instr    = instr_decode_i.csr_instr    ;//to be modify

            sbd_entry_d[wptr_q].sbe.rs1          = map_table_q[instr_decode_i.rs1].rename_vld? {1'b1,map_table_q[instr_decode_i.rs1].physical_name}:{1'b0,instr_decode_i.rs1} ;
            sbd_entry_d[wptr_q].sbe.rs2          = map_table_q[instr_decode_i.rs2].rename_vld? {1'b1,map_table_q[instr_decode_i.rs2].physical_name}:{1'b0,instr_decode_i.rs2} ;
            sbd_entry_d[wptr_q].sbe.rd           = instr_decode_i.rd           ;

            sbd_entry_d[wptr_q].writed           = 1'b1       ;
        end 
        if(commit) begin
            sbd_entry_d[commit_ptr_q].sbe    = '0   ;
            sbd_entry_d[commit_ptr_q].writed = 1'b0 ;
        end
        if(flush_issue_i) 
            sbd_entry_d = '{default: 0};
    end
            

    //always_comb begin 
    //    for(int unsigned m = 0; m < NR_WB_PORTS; m++) begin
    //        if(wb_port_i[m].wb_vld) 
    //            wb_port_vld[m] = 1'b1;
    //    end
    //end

        
    //write back 
    always_comb begin : sbd_wb
        sbd_wb_d = sbd_wb_q;
        //if(|wb_port_vld) begin
        for(int unsigned m = 0; m < NR_WB_PORTS; m++) begin
            if(wb_port_i[m].wb_vld) begin
                sbd_wb_d[wb_port_i[m].trans_id].result = wb_port_i[m].wb_data;
                sbd_wb_d[wb_port_i[m].trans_id].rd_vld = 1'b1 ;
                sbd_wb_d[wb_port_i[m].trans_id].branch = (wb_branch_i.is_mispredict || wb_branch_i.instr_jump)? wb_branch_i : '0 ;
                sbd_wb_d[wb_port_i[m].trans_id].ex     = wb_ex_exception_i ;
            end
        end
        //end 
        if(commit) 
            sbd_wb_d[commit_ptr_q] = '{default: 0};
        if(flush_issue_i) 
            sbd_wb_d = '{default: 0};
    end

    always_comb begin : sbd_rs1
        sbd_rs1_d = sbd_rs1_q;
        if(instr_decode_i.valid && issue_sbe_rdy_o) begin
            if(instr_decode_i.op inside {CSRRWI, CSRRSI, CSRRCI}) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1  ;
                sbd_rs1_d[wptr_q].rs1_data = instr_decode_i.rs1  ;
            end else if(instr_decode_i.op inside {FENCE, FENCE_I}) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1  ;
                sbd_rs1_d[wptr_q].rs1_data = 32'b0;
            end else if(instr_decode_i.op inside {AUIPC, LUI, JAL}) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1  ;
                sbd_rs1_d[wptr_q].rs1_data = instr_decode_i.pc  ;
            end
            //rs not map to physical name, read from regfile
            else if(~sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE]) begin
            //else if( ~map_table_q[instr_decode_i.rs1].rename_vld) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1;
                sbd_rs1_d[wptr_q].rs1_data = regfile_rdata_a_i;
            //compare input instr.rs with wb,  
            end else if(wb_comp_matrix[MEM_DEPTH].rs1_cmp_rdy) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1;
                sbd_rs1_d[wptr_q].rs1_data = wb_comp_matrix[MEM_DEPTH].rs1_data;
            //compare input instr.rs with rd,  
            end else if(input_comp.rs1_cmp_rdy) begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b1;
                sbd_rs1_d[wptr_q].rs1_data = input_comp.rs1_data;
            end else begin
                sbd_rs1_d[wptr_q].rs1_rdy  = 1'b0;
                sbd_rs1_d[wptr_q].rs1_data = 32'b0;
            end
        end 
        //if(|wb_comp_rs1_vld) begin
        for(int unsigned k = 0; k < MEM_DEPTH; k++) begin
            if(wb_comp_matrix[k].rs1_cmp_rdy) begin
                sbd_rs1_d[k].rs1_data = wb_comp_matrix[k].rs1_data;
                sbd_rs1_d[k].rs1_rdy  = 1'b1  ;
            end
        end
        //end 
        if(commit) 
            sbd_rs1_d[commit_ptr_q] = '{default: 0};
        if(flush_issue_i) 
            sbd_rs1_d = '{default: 0};
    end

    always_comb begin : sbd_rs2
        sbd_rs2_d = sbd_rs2_q;
        if(instr_decode_i.valid && issue_sbe_rdy_o) begin
            if(instr_decode_i.op inside {ADDI, SLTI, SLTIU, XORI, ORI, ANDI, LB, LH, LW, LBU, LHU, JALR, 
                                         AUIPC, LUI, JAL, SM3P0, SM3P1}) begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1  ;
                sbd_rs2_d[wptr_q].rs2_data = instr_decode_i.imm ;
            end else if(instr_decode_i.op inside {SRAI, SLLI, SRLI}) begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1  ;
                sbd_rs2_d[wptr_q].rs2_data = instr_decode_i.rs2 ; //rs2 is shamt
            //end else if(instr_decode_i.op inside {AUIPC, LUI, JAL}) begin
            //    sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1  ;
            //    sbd_rs2_d[wptr_q].rs2_data = instr_decode_i.imm ;
            end
            //rs not map to physical name, read from regfile
            else if(~sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE]) begin
            //else if( ~map_table_q[instr_decode_i.rs2].rename_vld) begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1;
                sbd_rs2_d[wptr_q].rs2_data = regfile_rdata_b_i;
            //compare input instr.rs with wb,  
            end else if(wb_comp_matrix[MEM_DEPTH].rs2_cmp_rdy) begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1;
                sbd_rs2_d[wptr_q].rs2_data = wb_comp_matrix[MEM_DEPTH].rs2_data;
            //compare input instr.rs with rd,  
            end else if(input_comp.rs2_cmp_rdy) begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b1;
                sbd_rs2_d[wptr_q].rs2_data = input_comp.rs2_data;
            end else begin
                sbd_rs2_d[wptr_q].rs2_rdy  = 1'b0;
                sbd_rs2_d[wptr_q].rs2_data = 32'b0;
            end
        end 
        //if(|wb_comp_rs2_vld) begin
        for(int unsigned k = 0; k < MEM_DEPTH; k++) begin
            if(wb_comp_matrix[k].rs2_cmp_rdy) begin
                sbd_rs2_d[k].rs2_data = wb_comp_matrix[k].rs2_data;
                sbd_rs2_d[k].rs2_rdy  = 1'b1  ;
            end
        end
        //end 
        if(commit) begin
            sbd_rs2_d[commit_ptr_q] = '{default: 0};
        end
        if(flush_issue_i) 
            sbd_rs2_d = '{default: 0};
    end



    //always_comb begin
    //    for(int unsigned k = 0; k < MEM_DEPTH; k++) begin
    //        wb_comp_rs1_vld[k] = wb_comp_matrix[k].rs1_cmp_rdy;
    //        wb_comp_rs2_vld[k] = wb_comp_matrix[k].rs2_cmp_rdy;
    //    end
    //end


                


//pointer
    //sbd_entry_d[wptr_q].writed = write_en, commit = read_en
    assign cnt_d = (flush_issue_i)? '0 : cnt_q + (sbd_entry_d[wptr_q].writed & ~full) - commit;
    assign full = & cnt_q;
    assign empty = ~(|cnt_q);

    always_comb begin : wptr
        if(flush_issue_i)
            wptr_d = '0;
        else if(instr_decode_i.valid && ~full)
            wptr_d = wptr_q + 1'b1 ;
        else
            wptr_d = wptr_q ;
    end

    //sbd_entry_d is for save one cycle, issue_stage is 0/1 cycle
    always_comb begin : issue_ptr
        if(flush_issue_i)
            issue_ptr_d = '0;
        //else if(sbd_entry_d[issue_ptr_q].issued)
        else if(sbd_issue_d[issue_ptr_q]&& ~fence_stall)
            issue_ptr_d = issue_ptr_q + 1'b1 ;
        else
            issue_ptr_d = issue_ptr_q ;
    end

    always_comb begin : commit_ptr
        if(flush_issue_i)
            commit_ptr_d = '0;
        else if(commit && ~empty)
            commit_ptr_d = commit_ptr_q + 1'b1 ;
        else
            commit_ptr_d = commit_ptr_q ;
    end




    assign regfile_raddr_a_o = sbd_entry_d[wptr_q].sbe.rs1[REG_ADDR_SIZE-1:0] ;
    assign regfile_raddr_b_o = sbd_entry_d[wptr_q].sbe.rs2[REG_ADDR_SIZE-1:0] ;
    assign commit_regfile_we_o      = commit ;//to be modify some instruction no need to write regfile
    assign commit_regfile_waddr_o   = sbd_entry_q[commit_ptr_q].sbe.rd ;
    assign commit_regfile_wdata_o   = sbd_wb_q[commit_ptr_q].result ;
    assign commit_branch_o          = sbd_wb_q[commit_ptr_q].branch ;
    assign commit_ex_o              = sbd_wb_q[commit_ptr_q].ex     ;
    assign commit_pc_o              = sbd_entry_q[commit_ptr_q].sbe.pc;


    assign fence_stall    = fence_instr && ~pre_fence_done;
    assign fence_instr    = sbd_entry_d[issue_ptr_q].sbe.op == FENCE || sbd_entry_d[issue_ptr_q].sbe.op == FENCE_I ; 
    assign pre_fence_done = issue_ptr_q == commit_ptr_d;


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            cnt_q       <= '0;
            wptr_q      <= '0;
            issue_ptr_q <= '0;
            commit_ptr_q<= '0;
            map_table_q <= '{default: 0};
            sbd_entry_q <= '{default: 0};
            //sbd_entry_q <= '{MEM_DEPTH{'{1'b0,1'b0,'{default: 0}}}};
            sbd_wb_q    <= '{default: 0};
            sbd_rs1_q   <= '{default: 0};
            sbd_rs2_q   <= '{default: 0};
            sbd_issue_q <= 1'b0         ;
        end else begin
            cnt_q       <= cnt_d       ;
            wptr_q      <= wptr_d      ;
            issue_ptr_q <= issue_ptr_d ;
            commit_ptr_q<= commit_ptr_d;
            map_table_q <= map_table_d ;
            sbd_entry_q <= sbd_entry_d ;
            sbd_wb_q    <= sbd_wb_d    ;
            sbd_rs1_q   <= sbd_rs1_d   ;
            sbd_rs2_q   <= sbd_rs2_d   ;
            sbd_issue_q <= sbd_issue_d ;
        end
    end

    assign issue_sbe_rdy_o = ~full;

    always_comb begin: out_put
        instr_issue_o.fu           = sbd_entry_d[issue_ptr_q].sbe.fu          ;
        instr_issue_o.operator     = sbd_entry_d[issue_ptr_q].sbe.op          ;
        instr_issue_o.pc           = sbd_entry_d[issue_ptr_q].sbe.pc           ;
        instr_issue_o.imm          = sbd_entry_d[issue_ptr_q].sbe.imm          ;
        instr_issue_o.trans_id     = sbd_entry_d[issue_ptr_q].sbe.trans_id     ;

        instr_issue_o.operand_1    = sbd_rs1_d[issue_ptr_q].rs1_data    ;
        instr_issue_o.operand_2    = sbd_rs2_d[issue_ptr_q].rs2_data    ;

        if(sbd_issue_d[issue_ptr_q]) 
            instr_issue_o.valid    = 1'b1          ;
        else
            instr_issue_o.valid    = 1'b0          ;
    end

endmodule


