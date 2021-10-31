module mul_div(

    input    logic                          clk_i                 ,
    input    logic                          rst_ni                ,     

    input    logic                          flush_ex_i            ,     
    input    fu_data_t                      instr_issue_i         , 

    output  wb_port_t                       md_wb_port_o            ,
    output   logic                          md_rdy_o                
    


    
);


    logic   mul_vld ;
    logic   div_vld ;
    logic   div_rdy ;
    logic   [ADDR_BITS-1:0]   div_trans_id ;
    logic   [31:0]  mul_result;
    logic   [31:0]  div_result;
    logic           div_vld_out;


    always_comb begin 
        mul_vld = 1'b0;
        div_vld = 1'b0;
        if(instr_issue_i.valid) begin
            case(instr_issue_i.operator)
                MUL   ,
                MULH  ,
                MULHSU,
                MULHU : begin
                    mul_vld = 1'b1;
                    div_vld = 1'b0;
                    end
                DIV   , 
                DIVU  ,
                REM   , 
                REMU  : begin
                    mul_vld = 1'b0;
                    div_vld = 1'b1;
                    end
                default: begin
                    mul_vld = 1'b0;
                    div_vld = 1'b0;
                    end
            endcase
        end
    end

    always_comb begin 
        case(instr_issue_i.operator)
            MUL   ,
            MULH  ,
            MULHSU,
            MULHU : begin
                md_rdy_o = 1'b1; 
                end
            DIV   , 
            DIVU  ,
            REM   , 
            REMU  : begin
                md_rdy_o = div_rdy;
                end
            default: md_rdy_o = 1'b0;
        endcase
    end

    always_comb begin 
        if(mul_vld) begin
            md_wb_port_o.wb_data  = mul_result;
            md_wb_port_o.wb_vld   = 1'b1   ;
            md_wb_port_o.trans_id = instr_issue_i.trans_id;
        end else if(div_vld_out) begin
            md_wb_port_o.wb_data  = div_result;
            md_wb_port_o.wb_vld   = 1'b1 ;
            md_wb_port_o.trans_id = div_trans_id;
        end else 
            md_wb_port_o = '0 ;
    end



mul u_mul(
    .clk_i       (clk_i                     ),
    .rst_ni      (rst_ni                    ),
    .flush_ex_i  (flush_ex_i                ),
    .op_i        (instr_issue_i.operator    ),
    .op1_i       (instr_issue_i.operand_1   ),
    .op2_i       (instr_issue_i.operand_2   ),
    .mul_vld_i   (mul_vld                   ),
    .mul_result_o(mul_result                )
    );

div u_div(
    .clk_i       (clk_i                  ),
    .rst_ni      (rst_ni                 ),
    .flush_ex_i  (flush_ex_i             ),
    .op_i        (instr_issue_i.operator ),
    .op1_i       (instr_issue_i.operand_1),
    .op2_i       (instr_issue_i.operand_2),
    .trans_id_i  (instr_issue_i.trans_id ),
    .div_vld_i   (div_vld                ),
    .div_rdy_o   (div_rdy                ),
    .trans_id_o  (div_trans_id           ),
    .div_vld_o   (div_vld_out            ),
    .div_result_o(div_result             )
    );



endmodule
