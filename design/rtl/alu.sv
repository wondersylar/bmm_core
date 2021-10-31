module alu (

    input    fu_data_t                      instr_issue_i          , 
    output   logic   [31:0]                 alu_wb_data_o          ,
    //branch unit
    output  logic                           is_equal_o              ,
    output  logic                           is_less_than_o          ,
    //to load/store
    output  logic   [31:0]                  ls_addr_o               ,
    output  logic   [31:0]                  ls_store_data_o            
);






    logic [33:0] op_b_neg;
    logic [33:0] op_b_neg_signed;
    logic [33:0] op_a_ext;
    logic [33:0] add_result;
    logic [31:0] op_1    ;
    logic [31:0] op_2    ;
    logic        add_sel ;
    logic [33:0] add_op_a    ;
    logic [33:0] add_op_b    ;


    logic   op_sm4ks   ;
    logic   op_sm4ed   ;
    logic   op_sm3p0   ;
    logic   op_sm3p1   ;
    logic [31:0]  sm4_result ;
    logic [31:0]  sm3_result ;

    // beq bne
    // blt bltu bge bgeu 
    // slt sltu slti sltiu
    // sub 
    assign op_a_ext        = {1'b0, instr_issue_i.operand_1, 1'b1};
    assign op_b_neg        = {1'b0, instr_issue_i.operand_2, 1'b0} ^ 34'h3_ffff_ffff; 

    always_comb begin
        if(add_sel) begin
            add_op_a = {2'b0,op_1};
            add_op_b = {2'b0,op_2};
        //end else if(instr_issue_i.operator inside {SLT, SLTI, BLT, BGE}) begin
        end else begin
            add_op_a = op_a_ext;
            add_op_b = op_b_neg;
        end
    end
    assign add_result = add_op_a + add_op_b;



    always_comb begin
        op_1 = 32'b0;
        op_2 = 32'b0;
        add_sel = 1'b0;
        unique case (instr_issue_i.operator)
            ADD, ADDI,
            LB, LH, LW, LBU, LHU : begin
                op_1 = instr_issue_i.operand_1;
                op_2 = instr_issue_i.operand_2;
                add_sel = 1'b1;
            end
            SB, SH, SW: begin
                op_1 = instr_issue_i.operand_1;
                op_2 = instr_issue_i.imm;
                add_sel = 1'b1;
            end
            JAL, JALR : begin 
                op_1 = instr_issue_i.pc;
                op_2 = 3'h4;
                add_sel = 1'b1;
            end
            AUIPC     : begin
                op_1 = instr_issue_i.operand_1; //PC
                op_2 = instr_issue_i.operand_2; //imm
                add_sel = 1'b1;
            end
            default   : begin
                op_1 = 32'b0;
                op_2 = 32'b0;
                add_sel = 1'b0;
            end
        endcase
    end

    always_comb begin
        is_equal_o     = 1'b0 ;
        is_less_than_o = 1'b0 ;
        ls_addr_o       = 32'b0;
        ls_store_data_o = 32'b0;
        alu_wb_data_o = 32'b0;
        op_sm4ks = 1'b0;
        op_sm4ed = 1'b0;
        op_sm3p0 = 1'b0;
        op_sm3p1 = 1'b0;
        unique case (instr_issue_i.operator)
            XOR, XORI : alu_wb_data_o = alu_xor(instr_issue_i.operand_1, instr_issue_i.operand_2);
            OR , ORI  : alu_wb_data_o =  alu_or(instr_issue_i.operand_1, instr_issue_i.operand_2);
            AND, ANDI : alu_wb_data_o = alu_and(instr_issue_i.operand_1, instr_issue_i.operand_2);
            SLL, SLLI : alu_wb_data_o = alu_sll(instr_issue_i.operand_1, instr_issue_i.operand_2[4:0]);
            LUI       : alu_wb_data_o = instr_issue_i.operand_2;  //imm << 12 , already deal in decode stage (imm extension); 
            SRA, SRAI : alu_wb_data_o = alu_sra(instr_issue_i.operand_1, instr_issue_i.operand_2[4:0]);
            SRL, SRLI : alu_wb_data_o = alu_srl(instr_issue_i.operand_1, instr_issue_i.operand_2[4:0]);
            ADD, ADDI,
            JAL, JALR,  //jal,jalr  rd = alu_wb_data_o                                                    
            AUIPC     : alu_wb_data_o = add_result[31:0];   
            //load addr
            LB, LH, LW, LBU, LHU : 
                        ls_addr_o = add_result[31:0];
            //store addr ,data
            SB, SH, SW: begin
                        ls_addr_o = add_result[31:0];
                        ls_store_data_o = instr_issue_i.operand_2;
            end
            
            //op_b_neg in caculate
            SUB       : alu_wb_data_o = add_result[32:1];
            // compare result
            BEQ, BNE, BLTU, BGEU : begin
                        is_equal_o     = ~|add_result[32:1]  ; 
                        is_less_than_o = add_result[33]  ;
            end
            //signed
            BLT, BGE : begin
                        is_equal_o     = ~|add_result[32:1]  ; 
                        is_less_than_o = (instr_issue_i.operand_1[31] ^ instr_issue_i.operand_2[31])? instr_issue_i.operand_1[31] : add_result[32];
            end
            SLTU, SLTIU : begin
                        alu_wb_data_o = add_result[33]  ;
            end
            //signed
            SLT, SLTI : begin
                        alu_wb_data_o = (instr_issue_i.operand_1[31] ^ instr_issue_i.operand_2[31])? instr_issue_i.operand_1[31] : add_result[32]  ;
            end
            SM4ED: begin
                        alu_wb_data_o = sm4_result  ;
                        op_sm4ed = 1'b1;
            end
            SM4KS: begin
                        alu_wb_data_o = sm4_result  ;
                        op_sm4ks = 1'b1;
            end
            SM3P0: begin 
                        alu_wb_data_o = sm3_result  ;
                        op_sm3p0 = 1'b1;
            end
            SM3P1: begin
                        alu_wb_data_o = sm3_result  ;
                        op_sm3p1 = 1'b1;
            end
            default   : begin
                        is_equal_o     = 1'b0 ;
                        is_less_than_o = 1'b0 ;
                        ls_addr_o       = 32'b0;
                        ls_store_data_o = 32'b0;
                        alu_wb_data_o = 32'b0;
                        op_sm4ks = 1'b0;
                        op_sm4ed = 1'b0;
                        op_sm3p0 = 1'b0;
                        op_sm3p1 = 1'b0;
            end
        endcase
    end




riscv_crypto_fu_ssm4 u_sm4(
    //.valid     (instr_issue_i.valid     ),
    .rs1       (instr_issue_i.operand_1 ),
    .rs2       (instr_issue_i.operand_2 ),
    .bs        (instr_issue_i.imm[5:4]  ),
    .op_ssm4_ks(op_sm4ks                ),
    .op_ssm4_ed(op_sm4ed                ),
    .result    (sm4_result              )
    //.ready     ()
    );

riscv_crypto_fu_ssm3 
#(
    .XLAN       (32 )
)
u_sm3(
    //.g_clk      (),
    //.g_resetn   (),
    //.valid      (instr_issue_i.valid    ),
    .rs1        (instr_issue_i.operand_1),
    .op_ssm3_p0 (op_sm3p0               ),
    .op_ssm3_p1 (op_sm3p1               ),
    .rd         (sm3_result             )
    //.ready      (),
);

        
endmodule
