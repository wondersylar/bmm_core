
import bmm_pkg::*;

module bmm (
    input    logic                          clk_i                   ,
    input    logic                          rst_ni                  ,     
    input    logic  [31:0]                  instr_boot_addr_i,
    
    input    logic                          soft_irq_i      ,
    input    logic                          timer_irq_i     ,
    input    logic                          ex_irq_i        ,
    //read instruction from iram            
    input    logic                          instr_rvld_i    ,
    input    logic                          instr_gnt_i     ,
    input    logic  [31:0]                  instr_rdata_i   ,
    output   logic  [31:0]                  instr_addr_o    ,     
    output   logic                          instr_req_o     ,     
    //output   logic                          instr_gnt_i,     
    //read data from dram
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

    logic   [31:0]                          instr    ;
    logic   [31:0]                          instr_pc ;
    instruction_entry_t                     instr_decode;
    logic                                   issue_sbe_rdy;
    logic                                   instr_decode_rdy;
    logic                                   instr_fetch_vld;

    logic                                   commit_ack           ;
    logic                                   commit_regfile_we    ;
    logic   [REG_ADDR_SIZE-1:0]             commit_regfile_waddr ;
    logic   [REG_DATA_WIDTH-1:0]            commit_regfile_wdata ;
    branch_t                                commit_branch        ;
    logic   [REG_ADDR_SIZE-1:0]             regfile_raddr_a      ;
    logic   [REG_ADDR_SIZE-1:0]             regfile_raddr_b      ;
    logic   [REG_DATA_WIDTH-1:0]            regfile_rdata_a      ;
    logic   [REG_DATA_WIDTH-1:0]            regfile_rdata_b      ;

    fu_data_t                               instr_issue         ;
    logic                                   ex_rdy              ;

    exception_t                             wb_ex_exception     ;
    branch_t                                wb_branch           ;
    wb_port_t   [NR_WB_PORTS-1:0]           wb_port             ;


    exception_t                             if_exception        ;
    exception_t                             id_exception        ;
    exception_t                             commit_ex           ;
    logic   [31:0]                          commit_pc           ;
    logic                                   id_mret             ;

    logic                                   flush_if            ;
    logic                                   flush_id            ;
    logic                                   flush_issue         ;
    logic                                   flush_ex            ;
    logic   [31:0]                          fetch_addr          ;

    logic [31:0]                            csr_addr            ;
    logic                                   csr_read            ;
    logic                                   csr_write           ;
    logic [31:0]                            csr_rdata           ;
    logic [31:0]                            csr_wdata           ;



instr_fetch u_instr_fetch
(
    .clk_i                   (clk_i                 ), 
    .rst_ni                  (rst_ni                ),
    .instr_boot_addr_i       (instr_boot_addr_i     ),

    .flush_if_i              (flush_if          ),
    .fetch_addr_i            (fetch_addr        ),
    .if_exception_o          (if_exception      ),

    .branch_i                (commit_branch    ),
   
    .instr_rvld_i            (instr_rvld_i ),
    .instr_gnt_i             (instr_gnt_i  ),
    .instr_rdata_i           (instr_rdata_i),
    .instr_raddr_o           (instr_addr_o ),
    .instr_req_o             (instr_req_o  ),
    
    .instr_decode_rdy_i      (instr_decode_rdy   ),
    .instr_vld_o             (instr_fetch_vld    ),
    .instr_o                 (instr    ),
    .instr_pc_o              (instr_pc )
);



instr_decode u_instr_decode
(
    .clk_i                  (clk_i              ),
    .rst_ni                 (rst_ni             ),
    .flush_id_i             (flush_id           ),
    .id_exception_o         (id_exception       ),
    .id_mret_o              (id_mret            ),
   
    .instr_vld_i            (instr_fetch_vld    ),
    .instr_decode_rdy_o     (instr_decode_rdy   ),
    .instr_i                (instr              ),
    .instr_pc_i             (instr_pc           ),
    
    .instr_decode_o         (instr_decode        ),
    .issue_sbe_rdy_i        (issue_sbe_rdy       )
);


instr_issue u_instr_issue
(
    .clk_i                      (clk_i                 ),
    .rst_ni                     (rst_ni                ),
    .flush_issue_i              (flush_issue           ),
    
    .instr_decode_i             (instr_decode           ),
    .issue_sbe_rdy_o            (issue_sbe_rdy          ),
    
    .regfile_raddr_a_o          (regfile_raddr_a     ),
    .regfile_raddr_b_o          (regfile_raddr_b     ),
    .regfile_rdata_a_i          (regfile_rdata_a     ),
    .regfile_rdata_b_i          (regfile_rdata_b     ),
    
    .commit_ack_i               (commit_ack          ),
    .commit_regfile_we_o        (commit_regfile_we   ),
    .commit_regfile_waddr_o     (commit_regfile_waddr),
    .commit_regfile_wdata_o     (commit_regfile_wdata),
    //to controller
    .commit_branch_o            (commit_branch       ),  
    .commit_ex_o                (commit_ex           ),
    .commit_pc_o                (commit_pc           ),

    .instr_issue_o              (instr_issue        ),
    .ex_rdy_i                   (ex_rdy             ),
    .wb_ex_exception_i          (wb_ex_exception    ),
    .wb_branch_i                (wb_branch          ),
    .wb_port_i                  (wb_port            )
);


ex u_ex(
    .clk_i              (clk_i        ),
    .rst_ni             (rst_ni       ),
    .flush_ex_i         (flush_ex     ),

    .instr_issue_i      (instr_issue    ),
    .ex_rdy_o           (ex_rdy         ),
    
    .wb_ex_exception_o  (wb_ex_exception),
    .wb_branch_o        (wb_branch      ),
    .wb_port_o          (wb_port        ),

    .csr_addr_o         (csr_addr       ),
    .csr_read_o         (csr_read       ),
    .csr_write_o        (csr_write      ),
    .csr_rdata_i        (csr_rdata      ),
    .csr_wdata_o        (csr_wdata      ),

    .data_gnt_i         (data_gnt_i        ),
    .data_addr_o        (data_addr_o       ),
    .data_req_o         (data_req_o        ),
    .data_rvalid_i      (data_rvalid_i     ),
    .data_rdata_i       (data_rdata_i      ),
    .data_err_i         (data_err_i        ),
    .data_we_o          (data_we_o         ),
    .data_be_o          (data_be_o         ),
    .data_wdata_o       (data_wdata_o      )
    );

commit u_commit(
    .clk_i                      (clk_i                 ),
    .rst_ni                     (rst_ni                ),
    
    .regfile_raddr_a_i          (regfile_raddr_a     ),
    .regfile_raddr_b_i          (regfile_raddr_b     ),
    .regfile_rdata_a_o          (regfile_rdata_a     ),
    .regfile_rdata_b_o          (regfile_rdata_b     ),
    
    .commit_ack_o               (commit_ack          ),
    .commit_regfile_we_i        (commit_regfile_we   ),
    .commit_regfile_waddr_i     (commit_regfile_waddr),
    .commit_regfile_wdata_i     (commit_regfile_wdata)
    
    //.commit_branch_i            (commit_branch       ),
    
    //.flush_if_o                 (flush_if            ),
    //.flush_id_o                 (flush_id            ),
    //.flush_issue_o              (flush_issue         ),
    //.flush_ex_o                 (flush_ex            )
);



csrfile_and_controller u_csrfile_and_controller(
    .clk_i              (clk_i                 ),
    .rst_ni             (rst_ni                ),
    
    .if_pc_i            (instr_pc               ),
    .if_exception_i     (if_exception           ),
    
    .id_pc_i            (instr_decode.pc            ),
    .id_exception_i     (id_exception               ),
    .id_mret_i          (id_mret                    ),
    
    .ex_pc_i            (commit_pc                  ),
    .ex_exception_i     (commit_ex                  ),
    
    .is_mispredict_i    (commit_branch.is_mispredict),
    
    .fetch_pc_i         (instr_addr_o               ),
    .soft_irq_i         (soft_irq_i                 ),
    .timer_irq_i        (timer_irq_i                ),
    .ex_irq_i           (ex_irq_i                   ),
    
    .flush_if_o         (flush_if                   ),
    .flush_id_o         (flush_id                   ),
    .flush_issue_o      (flush_issue                ),
    .flush_ex_o         (flush_ex                   ),
    .fetch_addr_o       (fetch_addr                 ),
    
    .csr_addr_i         (csr_addr                   ),
    .csr_read_i         (csr_read                   ),
    .csr_write_i        (csr_write                  ),
    .csr_rdata_o        (csr_rdata                  ),
    .csr_wdata_i        (csr_wdata                  )
);


endmodule







