
module commit (
    input    logic                           clk_i                       ,
    input    logic                           rst_ni                      ,     
    //register read/write
    input    logic   [REG_ADDR_SIZE-1:0]     regfile_raddr_a_i           ,
    input    logic   [REG_ADDR_SIZE-1:0]     regfile_raddr_b_i           ,
    output   logic   [REG_DATA_WIDTH-1:0]    regfile_rdata_a_o           ,
    output   logic   [REG_DATA_WIDTH-1:0]    regfile_rdata_b_o           ,
    
    output   logic                           commit_ack_o               ,
    input    logic                           commit_regfile_we_i       ,
    input    logic   [REG_ADDR_SIZE-1:0]     commit_regfile_waddr_i    ,
    input    logic   [REG_DATA_WIDTH-1:0]    commit_regfile_wdata_i    
    ////mispredict 
    //input    branch_t                        commit_branch_i             ,
    ////ctrl
    //output   logic                           flush_if_o             ,
    //output   logic                           flush_id_o             ,
    //output   logic                           flush_issue_o          ,
    //output   logic                           flush_ex_o               
    

);


    logic   [REG_DATA_WIDTH-1:0]    rdata_c_nc;
    
//ctrl u_ctrl(
//   .branch_mispredict_i  (commit_branch_i.is_mispredict),
//   .flush_if_o           (flush_if_o   ),
//   .flush_id_o           (flush_id_o   ),
//   .flush_issue_o        (flush_issue_o),
//   .flush_ex_o           (flush_ex_o   )
//   //.flush_commit_o       (flush_commit)
//);
    assign commit_ack_o = 1'b1; //to be modify

register_file
#(
    .ADDR_WIDTH   (6),
    .DATA_WIDTH   (32),
    .FPU          (0)
)
u_register_file
(
    .clk          ( clk_i            ),
    .rst_n        ( rst_ni          ),
    .test_en_i    ( 1'b0            ),
    // Read port a
    .raddr_a_i    ( {1'b0,regfile_raddr_a_i} ),
    .rdata_a_o    ( regfile_rdata_a_o        ),
    // Read port b
    .raddr_b_i    ( {1'b0,regfile_raddr_b_i} ),
    .rdata_b_o    ( regfile_rdata_b_o        ),
    // Read port c
    .raddr_c_i    ( 6'b0        ),
    .rdata_c_o    ( rdata_c_nc  ),
    // Write port a
    .waddr_a_i    ( {1'b0,commit_regfile_waddr_i} ),
    .wdata_a_i    ( commit_regfile_wdata_i        ),
    .we_a_i       ( commit_regfile_we_i           ),
    // Write port b
    .waddr_b_i    ( 6'b0    ),
    .wdata_b_i    ( 32'b0   ),
    .we_b_i       ( 1'b0    )
);



endmodule

