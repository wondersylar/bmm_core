module mul(

    input    logic                          clk_i                 ,
    input    logic                          rst_ni                ,     

    input    logic                          flush_ex_i            ,     

    input    fu_op_t                        op_i                    ,
    input    logic  [31:0]                  op1_i                   ,
    input    logic  [31:0]                  op2_i                   ,
    input    logic                          mul_vld_i               ,

    output   logic  [31:0]                  mul_result_o        

);


    logic   [63:0]  op_1;
    logic   [63:0]  op_2;
    logic   [63:0]  mul_result, mul_result_d, mul_result_q;

    //mul_result = $signed(op1_i) * $signed(op2_i) ;
    always_comb begin 
        case(op_i)
        MUL  , 
        MULH : begin
            op_1 = {{32{op1_i[31]}},op1_i};
            op_2 = {{32{op2_i[31]}},op2_i};
            end
        MULHSU: begin
            op_1 = {{32{op1_i[31]}},op1_i};
            op_2 = {32'b0,op2_i};
            end
        MULHU : begin
            op_1 = {32'b0,op1_i};
            op_2 = {32'b0,op2_i};
            end
        default: begin
            op_1 = {32'b0,op1_i};
            op_2 = {32'b0,op2_i};
            end
        endcase
    end

    assign   mul_result = op_1 * op_2 ;


    always_comb begin 
        case(op_i)
            MUL   : mul_result_o = mul_result[31:0 ];
            MULH  ,
            MULHSU, 
            MULHU : mul_result_o = mul_result[63:32];
            default:mul_result_o = mul_result[63:32];
        endcase
    end










endmodule
