module div(

    input    logic                          clk_i                 ,
    input    logic                          rst_ni                ,     

    input    logic                          flush_ex_i            ,     

    input    fu_op_t                        op_i                    ,
    input    logic  [31:0]                  op1_i                   ,
    input    logic  [31:0]                  op2_i                   ,
    input    logic  [ADDR_BITS-1:0]         trans_id_i              ,
    input    logic                          div_vld_i               ,

    output   logic                          div_rdy_o               ,
    output   logic  [ADDR_BITS-1:0]         trans_id_o              ,
    output   logic                          div_vld_o               ,
    output   logic  [31:0]                  div_result_o        

);

    logic   a_sign, a_sign_q, a_sign_d ;
    logic   b_sign, b_sign_q, b_sign_d ;
    logic   [31:0]  op_a    ;
    logic   [31:0]  op_b    ;
    logic   [63:0]  lzc_a_input   ;
    logic   [63:0]  lzc_b_input_q ;
    logic   [63:0]  lzc_b_input   ;
    logic   [5 :0]  lzc_a_result  ;
    logic   [5 :0]  lzc_b_result  ;
    logic           empty_a_nc    ;
    logic           empty_b_nc    ;

    logic   a_lt_b      ;
    logic   div_by_zero ;
    logic   div_by_one  ;
    logic   overflow    ;
    logic   shift_stop  ;
    logic   input_hsk   ;
    logic   enable      ;
    logic   div_rdy_q   ;
    fu_op_t op_q        ;
    logic   [ADDR_BITS-1:0] trans_id_q  ;

    logic           last_shift  ;
    logic           a_gt_b      ;
    logic   [6:0]   lzc_minus;
    logic   [5:0]   smt_0; 
    logic   [5:0]   smt_1;
    
    logic   [31:0]  quotient        ;
    logic   [31:0]  remainder       ;
    logic   [31:0]  sign_quotient   ;
    logic   [31:0]  sign_remainder  ;

    logic   [5:0 ]  shift_cnt_q, shift_cnt_d ;
    logic   [63:0]  dividend_a_q, dividend_a_d ;


    assign input_hsk = div_vld_i & div_rdy_o;
    
    //output assign
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            div_rdy_q <= 1'b1;
        else if(flush_ex_i) 
            div_rdy_q <= 1'b1;
        else if(a_lt_b | div_by_zero | overflow | div_by_one)
            div_rdy_q <= 1'b1;
        else if(input_hsk) 
            div_rdy_q <= 1'b0;
        else if(shift_stop)
            div_rdy_q <= 1'b1;
    end
    assign div_rdy_o = div_rdy_q | shift_stop;
    
    assign div_vld_o = shift_stop | a_lt_b | div_by_zero | overflow | div_by_one;
    always_comb begin 
        case(op_q)
        DIV, DIVU : div_result_o = sign_quotient;
        REM, REMU : div_result_o = sign_remainder;
        default   : div_result_o = 32'b0;
        endcase
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            trans_id_q <= '0;
            op_q       <= NONE_OP;
        end else if(flush_ex_i) begin
            trans_id_q <= '0;
            op_q       <= NONE_OP;
        end else if(input_hsk) begin
            trans_id_q <= trans_id_i;
            op_q       <= op_i;
        end
    end

    assign trans_id_o = (a_lt_b | div_by_zero | overflow | div_by_one)? trans_id_i : trans_id_q;



    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            a_sign_q <= 1'b0;
            b_sign_q <= 1'b0;
        end else if(input_hsk) begin
            a_sign_q <= op1_i[31] & (op_i == DIV | op_i == REM );
            b_sign_q <= op2_i[31] & (op_i == DIV | op_i == REM );
        end
    end

    assign a_sign = op1_i[31] & (op_i == DIV | op_i == REM );
    assign b_sign = op2_i[31] & (op_i == DIV | op_i == REM );
    assign op_a = (a_sign)? ~(op1_i - 1'b1) : op1_i;
    assign op_b = (b_sign)? ~(op2_i - 1'b1) : op2_i;
    
    //|a| < |b|
    assign a_lt_b = input_hsk & (op_a < op_b) ;
    assign div_by_zero = input_hsk & (~|op2_i) ;
    //divide by 1 or -1
    assign div_by_one  = input_hsk & (op_b == 32'b1);
    //32bit signed number can not represent +128, -128~+127
    assign overflow = input_hsk & (op1_i == 32'h8000_0000) & (op2_i == 32'hffff_ffff) & (op_i == DIV | op_i == REM );


    assign quotient       = (shift_stop)? dividend_a_q[31:0 ] : 32'b0;
    assign remainder      = (shift_stop)? dividend_a_q[63:32] : 32'b0;
    always_comb begin
        if(a_lt_b) begin
            sign_remainder = op1_i;
            sign_quotient  = 32'b0;
        end else if(div_by_zero) begin
            sign_remainder = op1_i;
            sign_quotient  = 32'hffff_ffff;
        end else if(overflow) begin
            sign_remainder = 32'b0;
            sign_quotient  = 32'h8000_0000;
        end else if(div_by_one) begin
            sign_remainder = 32'b0;
            sign_quotient  = (op2_i == 32'b1)? op1_i : (~op1_i + 1'b1);
        end else if(a_sign_q ^ b_sign_q) begin
            sign_quotient  =  (~quotient + 1'b1) ;
            sign_remainder =  (~remainder + 1'b1);
        end else begin
            sign_quotient  =  quotient;
            sign_remainder =  remainder;
        end
    end


    assign lzc_a_input = enable? {32'b0, dividend_a_q} : 64'b0;
    assign lzc_b_input = enable? lzc_b_input_q : 64'b0;

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            lzc_b_input_q <= 64'b0;
        else if(flush_ex_i) 
            lzc_b_input_q <= 64'b0;
        else if(input_hsk)
            lzc_b_input_q <= {op_b, 32'b0} ;
    end
    
    //enable for caculate lzc
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            enable <= 1'b0;
        else if(a_lt_b|div_by_zero|overflow|div_by_one)
            enable <= 1'b0;
        else if(input_hsk)
            enable <= 1'b1;
        else if(shift_stop)
            enable <= 1'b0;
    end

        
    
    //shift amount caculate
    assign lzc_minus  = lzc_a_result - lzc_b_result;
    assign last_shift = (shift_cnt_q < smt_1) |
                        ((shift_cnt_q == smt_1) & ((dividend_a_q << shift_cnt_q) < lzc_b_input));
    assign a_gt_b     = (dividend_a_q << smt_0) > lzc_b_input;
    
    assign smt_0 = (lzc_minus[6])? 6'b0  : lzc_minus;
    assign smt_1 = (a_gt_b      )? smt_0 : smt_0 + 1'b1;
    //assign smt_2 = (last_shift  )? shift_cnt_q : smt_1 ;


    always_comb begin
        if(flush_ex_i) 
            dividend_a_d = 64'b0;
        else if(input_hsk) 
            dividend_a_d = op_a;
        else if(last_shift)
            dividend_a_d = dividend_a_q << shift_cnt_q;
        else if(enable)
            dividend_a_d = (dividend_a_q << smt_1) - lzc_b_input + 1'b1;
        else 
            dividend_a_d = dividend_a_q;
    end


    assign shift_stop = ~|shift_cnt_q ;
    //up to 32bits can be shifted
    always_comb begin
        if(flush_ex_i) 
            shift_cnt_d = 6'd32;
        else if(shift_stop)
            shift_cnt_d = 6'd32;
        else if(~shift_stop & enable )
            shift_cnt_d = shift_cnt_q - smt_1;
        else
            shift_cnt_d = shift_cnt_q ;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin 
            dividend_a_q <= 64'b0;
            shift_cnt_q  <= 6'd32;
        end else begin
            dividend_a_q <= dividend_a_d;
            shift_cnt_q  <= shift_cnt_d;
        end
    end

    lzc #(
      .MODE    ( 1          ), // count leading zeros
      .WIDTH   ( 64         )
    ) i_lzc_a (
      .in_i    ( lzc_a_input  ),
      .cnt_o   ( lzc_a_result ),
      .empty_o ( empty_a_nc   )
    );

    lzc #(
      .MODE    ( 1          ), // count leading zeros
      .WIDTH   ( 64         )
    ) i_lzc_b (
      .in_i    ( lzc_b_input  ),
      .cnt_o   ( lzc_b_result ),
      .empty_o ( empty_b_nc   )
    );









endmodule
