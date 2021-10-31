    input    logic  [31:0]      fetch_addr_i    ,  //from mtvec   
    output   exception_t        if_exception_o  ,
    //from ex branch_unit
    input    branch_t           branch_i, //mispredict
    
    //read instruction from iram
    input    logic              instr_rvld_i    ,
    input    logic              instr_gnt_i     ,
    input    logic  [31:0]      instr_rdata_i   ,
    output   logic  [31:0]      instr_raddr_o   ,     
    output   logic              instr_req_o     ,     
    //to ID stage
    input    logic              instr_decode_rdy_i,
    output   logic              instr_vld_o     ,
    output   logic  [31:0]      instr_o         ,
    output   logic  [31:0]      instr_pc_o
    );


    logic   [31:0]      fetch_npc_d           ;
    logic   [31:0]      fetch_npc_q           ;
    logic               boot_rstn_q     ; 
    logic               instr_vld_q     ;
    logic   [31:0]      instr_rdata_q   ;
    logic               instr_read_q    ;
    logic               instr_read_d    ;
    logic               predict_jump_q  ;
    logic               predict_jump_d  ;


    logic               instr_req       ;
    logic               input_hsk       ;
    logic               output_hsk       ;
    logic               is_jump         ;
    logic               is_call         ;
    logic               is_return       ;
    logic               ras_push        ;
    logic               ras_pop         ;
    logic   [31:0]      ras_push_addr   ;
    ras_t               ras_pop_addr    ;
    logic               stall, stall_q   ;
    logic   [31:0]      instr_pc_q         ;


//pc gen
    assign input_hsk = instr_rvld_i & instr_req;
    assign output_hsk = instr_vld_o & instr_decode_rdy_i;
  
    always_comb begin: pc_gen
        fetch_npc_d = fetch_npc_q;
        if(boot_rstn_q)
            fetch_npc_d = instr_boot_addr_i;
        else if(flush_if_i && ~branch_i.is_mispredict)
            fetch_npc_d = fetch_addr_i;
        //jump addr from ex
        //when instr_jump we stall the pipeline and stop req, when mispredict we flush the output
        else if(branch_i.instr_jump || branch_i.is_mispredict) 
            fetch_npc_d = branch_i.jump_address;
        else if(stall || ~instr_req) 
            fetch_npc_d = fetch_npc_q;
        else if(is_return & ras_pop_addr.vld) 
            fetch_npc_d = ras_pop_addr.ras_data;
        else if(input_hsk)
            fetch_npc_d = fetch_npc_q + 32'h4;
        else 
            fetch_npc_d = fetch_npc_q;
    end
  
    pre_decode pre_decode(
        .instr_data_i       (instr_rdata_i   ),
        .instr_vld_i        (input_hsk       ),
        .jump_o             (is_jump         ),
        .call_o             (is_call         ),
        .return_o           (is_return       )
        );
    
    assign ras_push      =  is_call ;
    assign ras_pop       =  is_return ;
    assign ras_push_addr =  fetch_npc_q + 32'h4;
    
    
    
    
    ras
    #(
        .STACK_DEPTH    (4)
    )
    u_ras 
    (
        .clk_i     (clk_i        ),
        .rst_ni    (rst_ni       ),
        .flush_i   (flush_if_i   ),
        .pc_i      (ras_push_addr    ),
        .pop_i     (ras_pop      ),
        .push_i    (ras_push     ),
        .pc_o      (ras_pop_addr )
    );


    // stall when instruction is jump or call, or when instruction is return with ras pop unvalid.
    assign stall = is_jump &  ~(is_return & ras_pop_addr.vld); 
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            stall_q <= 1'b0;
        else if(flush_if_i)
            stall_q <= 1'b0;
        else if(stall)
            stall_q <= 1'b1;
        else if(branch_i.instr_jump )
            stall_q <= 1'b0;
        else
            stall_q <= stall_q;
    end


    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        boot_rstn_q   <= 1'b1;
        fetch_npc_q   <= 32'b0;
      end else begin
        boot_rstn_q   <= 1'b0;
        fetch_npc_q   <= fetch_npc_d ;
      end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
      if (!rst_ni) begin
        instr_vld_q   <= 1'b0; 
        instr_rdata_q <= 32'b0;
        instr_pc_q    <= 32'b0;
      end else if(flush_if_i) begin
        instr_vld_q   <= 1'b0; 
        instr_rdata_q <= 32'b0;
        instr_pc_q    <= 32'b0;
      end else if(input_hsk) begin
        instr_vld_q   <= 1'b1;  
        instr_rdata_q <= instr_rdata_i ;
        instr_pc_q    <= fetch_npc_q;
      end else if(output_hsk) begin
        instr_vld_q   <= 1'b0; 
      end
    end
  
    assign instr_o       = instr_rdata_q  ;
    assign instr_pc_o    = instr_pc_q     ;
    assign instr_raddr_o = fetch_npc_q    ;
    assign if_exception_o = '0 ;//to be modify

    assign instr_vld_o   = instr_vld_q & instr_decode_rdy_i ;

    always_comb begin: read_req
        if(stall_q)
            instr_req = 1'b0 ;
        else
            instr_req = instr_decode_rdy_i;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            instr_req_o <= 1'b1;
        end else if(flush_if_i) begin
            instr_req_o <= 1'b1;
        end else if(input_hsk) begin
            instr_req_o <= 1'b1;
        end else if(instr_req_o && instr_gnt_i) begin
            instr_req_o <= 1'b0;
        end
    end



endmodule












    


        


    

