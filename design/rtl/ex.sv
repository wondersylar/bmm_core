

module ex(

    input    logic                          clk_i                 ,
    input    logic                          rst_ni                ,     

    input    logic                          flush_ex_i            ,     

    input    fu_data_t                      instr_issue_i         , 
    output   logic                          ex_rdy_o              ,

    output   exception_t                    wb_ex_exception_o     ,
    output   branch_t                       wb_branch_o           ,
    output   wb_port_t   [NR_WB_PORTS-1:0]  wb_port_o             ,      
    //csrfile port
    output logic [31:0]                     csr_addr_o         ,
    output logic                            csr_read_o         ,
    output logic                            csr_write_o        ,
    input  logic [31:0]                     csr_rdata_i        ,
    output logic [31:0]                     csr_wdata_o        ,

    // data interface
    input  logic                            data_gnt_i              ,
    output logic [31:0]                     data_addr_o             ,
    output logic                            data_req_o              ,
    input  logic                            data_rvalid_i           ,
    input  logic [31:0]                     data_rdata_i            ,
    input  logic                            data_err_i              ,
    output logic                            data_we_o               ,
    output logic [3:0]                      data_be_o               ,
    output logic [31:0]                     data_wdata_o            
    
    );


    wb_port_t [NR_WB_PORTS-1:0]             wb_port_d, wb_port_q;
    branch_t                                wb_branch_d, wb_branch_q;
    logic                                   is_equal    ;
    logic                                   is_less_than;
    logic                                   instr_jump  ;
    logic   [31:0]                          jump_addr   ;
    logic                                   mispredict  ;

    logic                                   ls_rdy      ;
    logic   [31:0]                          ls_addr     ;
    logic   [31:0]                          ls_store_data;
    logic                                   ls_alu_vld      ;

    fu_op_t                                 issue_operator     ;
    logic   [REG_DATA_WIDTH-1:0]            csr_wb_data         ;
    logic   [REG_DATA_WIDTH-1:0]            alu_wb_data         ;
    wb_port_t                               ls_wb_port          ;

    wb_port_t                               md_wb_port;
    logic                                   md_rdy    ;

branch_unit u_branch_unit(
    .operator_i         (instr_issue_i.operator    ),
    .operand_1_i        (instr_issue_i.operand_1   ),
    .operand_2_i        (instr_issue_i.operand_2   ),
    .imm_i              (instr_issue_i.imm         ),
    .pc_i               (instr_issue_i.pc          ),
    .is_equal_i         (is_equal                   ),
    .is_less_than_i     (is_less_than               ),
    .instr_jump_o       (instr_jump               ),
    .jump_addr_o        (jump_addr                ),
    .mispredict_o       (mispredict               )
    );

    always_comb begin
        if(instr_issue_i.valid) begin
            wb_branch_d.instr_jump     = instr_jump ;
            wb_branch_d.jump_address   = jump_addr  ;
            wb_branch_d.is_mispredict  = mispredict ;
        end
    end



csr_ctrl u_csr_ctrl(
    .operator_i         (instr_issue_i.operator   ),
    .csr_addr_i         (instr_issue_i.imm        ),
    .rs1_data_i         (instr_issue_i.operand_1  ),
    .csr_wb_data_o      (csr_wb_data              ),
    //logic output ,no register
    .csr_addr_o         (csr_addr_o ), 
    .csr_read_o         (csr_read_o ),
    .csr_write_o        (csr_write_o),
    .csr_rdata_i        (csr_rdata_i),
    .csr_wdata_o        (csr_wdata_o)
    );

//port[0] for csr
    assign wb_port_d[0].wb_vld   = instr_issue_i.valid && (instr_issue_i.fu == CSR) ;
    assign wb_port_d[0].wb_data  = csr_wb_data ;
    assign wb_port_d[0].trans_id = instr_issue_i.trans_id;

alu u_alu(
    .instr_issue_i          (instr_issue_i  ),
    .alu_wb_data_o          (alu_wb_data    ),
    .is_equal_o             (is_equal       ),
    .is_less_than_o         (is_less_than   ),
    .ls_addr_o              (ls_addr        ),
    .ls_store_data_o        (ls_store_data  )
    );

//port[1] for alu
    assign wb_port_d[1].wb_data  = alu_wb_data ;
    assign wb_port_d[1].wb_vld   = (ls_alu_vld || (instr_issue_i.fu == CSR)|| (instr_issue_i.fu == MULT))? 1'b0 : instr_issue_i.valid  ;
    assign wb_port_d[1].trans_id = instr_issue_i.trans_id;

load_store u_load_store(
    .clk_i              (clk_i          ),
    .rst_ni             (rst_ni         ),
    .flush_ex_i         (flush_ex_i     ),
    .ls_operator_i      (instr_issue_i.operator ),
    .trans_id_i         (instr_issue_i.trans_id ),
    .ls_addr_i          (ls_addr                ),
    .store_data_i       (ls_store_data          ),
    .alu_vld_i          (ls_alu_vld             ),
    .ls_rdy_o           (ls_rdy                 ),
    .ls_wb_port_o       (ls_wb_port             ),
    .data_gnt_i         (data_gnt_i   ),
    .data_addr_o        (data_addr_o  ),
    .data_req_o         (data_req_o   ),
    .data_rvalid_i      (data_rvalid_i),
    .data_rdata_i       (data_rdata_i ),
    .data_err_i         (data_err_i   ),
    .data_we_o          (data_we_o    ),
    .data_be_o          (data_be_o    ),
    .data_wdata_o       (data_wdata_o )
    );

    assign ls_alu_vld = instr_issue_i.valid & ((instr_issue_i.fu == LOAD) | (instr_issue_i.fu == STORE));
//port[2] for lsu
    assign wb_port_d[2] = ls_wb_port;

mul_div u_mul_div(
    .clk_i        (clk_i        ), 
    .rst_ni       (rst_ni       ), 
    .flush_ex_i   (flush_ex_i   ), 
    .instr_issue_i(instr_issue_i), 
    .md_wb_port_o (md_wb_port   ), 
    .md_rdy_o     (md_rdy       ) 

);

//port[3] for lsu
    assign wb_port_d[3] = md_wb_port;


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            wb_port_q   <=  '{default:0};
            wb_branch_q <=  '{default:0};
        end else if(flush_ex_i) begin
            wb_port_q   <=  '{default:0};
            wb_branch_q <=  '{default:0};
        end else begin
            wb_port_q   <=  wb_port_d;
            wb_branch_q <=  wb_branch_d;
        end
    end

    always_comb begin 
        unique case(instr_issue_i.fu)
            LOAD,STORE: ex_rdy_o = ls_rdy;
            MULT      : ex_rdy_o = md_rdy;
            //mult_rdy to be modify
            default   : ex_rdy_o = 1'b1;
        endcase
    end

    assign wb_port_o   = wb_port_q  ;
    assign wb_branch_o = wb_branch_q;
    assign wb_ex_exception_o = '0; //to be modify

endmodule
