
//import bmm_pkg::*;
module branch_unit(
    input  fu_op_t                          operator_i               ,
    input  logic  [REG_DATA_WIDTH-1:0]      operand_1_i              ,
    input  logic  [REG_DATA_WIDTH-1:0]      operand_2_i              ,
    input  logic  [REG_DATA_WIDTH-1:0]      imm_i                    ,
    input  logic  [31:0]                    pc_i                    ,

    input  logic                           is_equal_i              ,
    input  logic                           is_less_than_i          ,

    output  logic                          instr_jump_o              ,
    output  logic   [31:0]                 jump_addr_o            ,
    output  logic                          mispredict_o            //means jump, flush downstream instructions


);

    logic   [REG_DATA_WIDTH-1:0]  op_1;
    logic   [REG_DATA_WIDTH-1:0]  op_2;

    always_comb begin
        unique case (operator_i)
            BEQ, BNE, BLT, BLTU, BGE, BGEU: begin
                op_1 = pc_i;
                op_2 = (mispredict_o)? imm_i : 3'h4;
                instr_jump_o = 1'b0;
            end
            JALR : begin
                op_1 = operand_1_i;                
                op_2 = operand_2_i;
                instr_jump_o = 1'b1;
            end
            JAL  : begin
                op_1 = operand_1_i;                
                op_2 = {operand_2_i[31:1],1'b0};
                instr_jump_o = 1'b1;
            end
            default : begin
                op_1 = 32'b0;
                op_2 = 32'b0;
                instr_jump_o = 1'b0;
            end
        endcase
    end

    assign jump_addr_o = op_1 + op_2;

    always_comb begin
        unique case (operator_i)
            BEQ : mispredict_o =  is_equal_i;
            BNE : mispredict_o = ~is_equal_i;
            BLT, BLTU : mispredict_o =  is_less_than_i;
            BGE, BGEU : mispredict_o = ~is_less_than_i;
            default   : mispredict_o = 1'b0;
        endcase
    end

endmodule
