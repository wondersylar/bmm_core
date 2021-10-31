

module ras #(
    parameter int unsigned STACK_DEPTH = 4  //pow of 2 only
) (
    input  logic           clk_i       ,
    input  logic           rst_ni      ,     
    input  logic           flush_i      ,     
    input  logic [31:0]    pc_i  ,
    input  logic           pop_i  ,
    input  logic           push_i ,
    output bmm_pkg::ras_t  pc_o     

);
    
    bmm_pkg::ras_t [STACK_DEPTH-1:0]    ras_stack_q, ras_stack_d;

    always_comb begin
        if(flush_i)
            ras_stack_d = '{default:0};
        else if(push_i && pop_i) begin
            ras_stack_d[STACK_DEPTH-1:1] = ras_stack_q[STACK_DEPTH-1:1];
            ras_stack_d[0].ras_data = pc_i;
            ras_stack_d[0].vld = 1'b1;
        end else if(push_i && ~pop_i) begin
            ras_stack_d[0].ras_data = pc_i;
            ras_stack_d[0].vld = 1'b1;
            ras_stack_d[STACK_DEPTH-1:1] = ras_stack_q[STACK_DEPTH-2:0];
        end else if(~push_i && pop_i) begin
            ras_stack_d[STACK_DEPTH-1].ras_data = 32'b0;
            ras_stack_d[STACK_DEPTH-1].vld = 1'b0;
            ras_stack_d[STACK_DEPTH-2:0] = ras_stack_q[STACK_DEPTH-1:1];
        end else begin
            ras_stack_d = ras_stack_q;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if(!rst_ni) begin
            ras_stack_q <= '{default:0};
        end else begin
            ras_stack_q <= ras_stack_d;
        end
    end
    
    assign pc_o = ras_stack_q[0];
endmodule

