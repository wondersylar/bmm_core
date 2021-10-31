module load_store(

    input    logic                          clk_i                   ,
    input    logic                          rst_ni                  ,     
    input    logic                          flush_ex_i              ,     
    //from alu
    input  fu_op_t                          ls_operator_i           ,
    input  logic   [ADDR_BITS-1:0]          trans_id_i              ,
    input  logic   [31:0]                   ls_addr_i               ,
    input  logic   [31:0]                   store_data_i            ,

    input  logic                            alu_vld_i               ,
    output logic                            ls_rdy_o                ,
    //wb ports
    output  wb_port_t                       ls_wb_port_o            ,

    // data interface
    input  logic                            data_gnt_i              ,
    output logic                            data_req_o              ,   //req_o and addr_o are valid, both store and load.
    output logic [31:0]                     data_addr_o             ,
    output logic                            data_we_o               ,

    input  logic                            data_rvalid_i           ,
    input  logic [31:0]                     data_rdata_i            ,
    input  logic                            data_err_i              ,
                                                                    
    output logic [3:0]                      data_be_o               ,
    output logic [31:0]                     data_wdata_o            
    

);

    //logic   [1:0]               be, be_d, be_q      ; //01:byte   10:half word  11:word
    logic   [31:0]              data_sext       ; 
    fu_op_t                     ls_operator_q   ;
    logic   [ADDR_BITS-1:0]     trans_id_q      ;
    logic   [31:0]              ls_addr_q       ;
    logic   [31:0]              store_data_q    ;
    logic                       alu_vld_q       ;
    //logic                       data_req_q      ;


    assign data_wdata_o = store_data_q;
    assign data_addr_o  = ls_addr_q   ;

    always_comb begin : gen_be
        unique case(ls_operator_q)
            LB, LBU, SB : data_be_o = 4'b0001   ;
            LH, LHU, SH : data_be_o = 4'b0011   ;
            LW, SW      : data_be_o = 4'b1111   ;
            default     : data_be_o = 4'b0000   ;
        endcase
    end

    always_comb begin 
        if(alu_vld_q) begin
            unique case(ls_operator_q)
                LB, LH, LW, LBU, LHU : begin
                    data_we_o = 1'b0;
                    data_req_o= 1'b1;
                end
                SB, SH, SW: begin   
                    data_we_o = 1'b1;
                    data_req_o= 1'b1;
                end
                default   : begin           
                    data_we_o = 1'b0;
                    data_req_o= 1'b1;
                end
            endcase
        end else begin
            data_we_o = 1'b0;
            data_req_o= 1'b0;
        end
    end
        
    always_comb begin 
        unique case(ls_operator_q)
            LB : data_sext = {{24{data_rdata_i[7]}}, data_rdata_i[7:0]};
            LH : data_sext = {{16{data_rdata_i[15]}}, data_rdata_i[15:0]};
            default: data_sext = data_rdata_i;
        endcase
    end

    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
        end else if(flush_ex_i) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
        end else if(alu_vld_i && ls_rdy_o) begin
            ls_operator_q <= ls_operator_i ;
            trans_id_q    <= trans_id_i    ;
            ls_addr_q     <= ls_addr_i     ;
            store_data_q  <= store_data_i  ;
            alu_vld_q     <= alu_vld_i     ;   
        end else if(data_gnt_i) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
        end
    end



    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            ls_rdy_o <= 1'b1;
        else if(flush_ex_i)
            ls_rdy_o <= 1'b1;
        else if(data_gnt_i)
            ls_rdy_o <= 1'b1;
        else if(data_req_o)
            ls_rdy_o <= 1'b0;
    end




    always_comb begin 
        if(data_rvalid_i && ~data_err_i) begin
            ls_wb_port_o.wb_data  = data_sext   ;
            ls_wb_port_o.wb_vld   = 1'b1        ;
            ls_wb_port_o.trans_id = trans_id_q  ;
        end else if(data_we_o && data_gnt_i) begin
            ls_wb_port_o.wb_data  = 32'b0       ;
            ls_wb_port_o.wb_vld   = 1'b1        ;
            ls_wb_port_o.trans_id = trans_id_q  ;
        end else begin
            ls_wb_port_o.wb_data  = 32'b0;
            ls_wb_port_o.wb_vld   = 1'b0 ;
            ls_wb_port_o.trans_id = 5'b0 ;
        end
    end


endmodule
