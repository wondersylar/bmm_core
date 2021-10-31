
module csrfile_and_controller(
    input    logic              clk_i           ,
    input    logic              rst_ni          ,     
    //exception from if
    input    logic [31:0]       if_pc_i               ,
    input    exception_t        if_exception_i        ,
    //exception from id
    input    logic [31:0]       id_pc_i               ,
    input    exception_t        id_exception_i        ,  //ebreak:3   ecall:11  illegal_instruction:2
    input    logic              id_mret_i             ,
    //exception from ex_stage
    input    logic [31:0]       ex_pc_i               ,
    input    exception_t        ex_exception_i        ,

    input    logic              is_mispredict_i       , 
    //interrupt from top
    input    logic [31:0]       fetch_pc_i            ,
    input    logic              soft_irq_i         ,
    input    logic              timer_irq_i        ,
    input    logic              ex_irq_i           ,
    
    output   logic              flush_if_o          ,
    output   logic              flush_id_o          ,
    output   logic              flush_issue_o       ,    
    output   logic              flush_ex_o          ,    
    output   logic [31:0]       fetch_addr_o        ,

    input    logic [31:0]       csr_addr_i         ,
    input    logic              csr_read_i         ,
    input    logic              csr_write_i        ,
    output   logic [31:0]       csr_rdata_o        ,
    input    logic [31:0]       csr_wdata_i        

);


    logic               if_flush        ;
    logic               id_flush        ;
    //logic               mret_flush      ;
    logic               ex_flush        ;
    logic               interrupt_flush ;



csr_file u_csr_file(
    .clk_i            (clk_i         ),
    .rst_ni           (rst_ni        ),     
                      
    .if_pc_i          (if_pc_i       ),
    .if_exception_i   (if_exception_i),
    .if_flush_o       (if_flush      ),
                      
    .id_pc_i          (id_pc_i       ),
    .id_exception_i   (id_exception_i),  
    .id_flush_o       (id_flush      ),
    .id_mret_i        (id_mret_i     ),
                      
    .ex_pc_i          (ex_pc_i       ),
    .ex_exception_i   (ex_exception_i),
    .ex_flush_o       (ex_flush      ),
                      
    .fetch_pc_i       (fetch_pc_i    ),
    .soft_irq_i       (soft_irq_i    ),
    .timer_irq_i      (timer_irq_i   ),
    .ex_irq_i         (ex_irq_i      ),
    .interrupt_flush_o(interrupt_flush),

    .fetch_addr_o     (fetch_addr_o  ),
                      
    .csr_addr_i       (csr_addr_i    ),
    .csr_read_i       (csr_read_i    ),
    .csr_rdata_o      (csr_rdata_o   ),
    .csr_write_i      (csr_write_i   ),
    .csr_wdata_i      (csr_wdata_i   )   
);


    always_comb begin
        if(interrupt_flush) begin
            flush_if_o    = 1'b1;
            flush_id_o    = 1'b1;
            flush_issue_o = 1'b1; 
            flush_ex_o    = 1'b1;
        end else if(ex_flush || is_mispredict_i) begin
            flush_if_o    = 1'b1;
            flush_id_o    = 1'b1;
            flush_issue_o = 1'b1; 
            flush_ex_o    = 1'b1;
        end else if(id_flush || id_mret_i) begin
            flush_if_o    = 1'b1;
            flush_id_o    = 1'b1;
        end else if(if_flush) begin
            flush_if_o    = 1'b1;
        end else begin
            flush_if_o    = 1'b0;
            flush_id_o    = 1'b0;
            flush_issue_o = 1'b0;
            flush_ex_o    = 1'b0;
        end
    end

endmodule
