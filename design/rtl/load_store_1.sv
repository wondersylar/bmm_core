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

    fu_op_t                     ls_operator_q   ;
    logic   [ADDR_BITS-1:0]     trans_id_q      ;
    logic   [31:0]              ls_addr_q       ;
    logic   [31:0]              store_data_q    ;
    logic                       alu_vld_q       ;
    logic                       sign_ext        ;
    
    
    //req channel        
    logic   [1:0]               data_offset     ;
    logic   [31:0]              base_addr       ;
    logic                       two_req         ;
    logic                       second_req      ;
    logic                       req_done        ;

    logic   [31:0]              addr_1         ;
    logic   [31:0]              addr_2         ;
    logic   [31:0]              wdata_1         ;
    logic   [31:0]              wdata_2         ;
    logic   [31:0]              wdata_2_q       ;
    logic   [3:0]               data_be_1       ;
    logic   [3:0]               data_be_2       ;
    logic   [3:0]               data_be_2_q     ;


    //read back channel        
    fu_op_t                     read_operator_q ;
    fu_op_t                     operator        ;
    logic   [1:0]               read_data_offset;
    logic   [1:0]               offset          ;
    logic   [ADDR_BITS-1:0]     read_trans_id   ;
    logic                       two_read        ;
    logic                       second_read_back;

    logic   [31:0]              rdata_1_q       ;
    logic   [31:0]              rdata           ;





    localparam      IDLE            = 2'b00;
    localparam      FRIST_ACCESS    = 2'b01;
    localparam      SECOND_ACCESS   = 2'b10;

    //input reg
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
            wdata_2_q     <= '0 ;
            data_be_2_q   <= '0 ;
        end else if(flush_ex_i) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
            wdata_2_q     <= '0 ;
            data_be_2_q   <= '0 ;
        end else if(alu_vld_i && ls_rdy_o) begin
            ls_operator_q <= ls_operator_i ;
            trans_id_q    <= trans_id_i    ;
            ls_addr_q     <= ls_addr_i     ;
            store_data_q  <= store_data_i  ;
            alu_vld_q     <= alu_vld_i     ;   
            wdata_2_q     <= wdata_2       ;
            data_be_2_q   <= data_be_2     ;
        end else if(req_done) begin
            ls_operator_q <= NONE_OP ;
            trans_id_q    <= '0 ;
            ls_addr_q     <= '0 ;
            store_data_q  <= '0 ;
            alu_vld_q     <= '0 ;
            wdata_2_q     <= '0 ;
            data_be_2_q   <= '0 ;
        end
    end

//###############################################################
//##############          req channel        
//###############################################################
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


//if store addr isn't aliagn, split into two req 
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            second_req <= 1'b0;
        else if(two_req && data_gnt_i)
            second_req <= 1'b1;
        else if(data_gnt_i && second_req)
            second_req <= 1'b0;
    end

    always_comb begin 
        data_wdata_o = 32'b0;
        data_be_o    = 4'b0;
        if(data_req_o && ~second_req) begin
            data_wdata_o = wdata_1  ;
            data_be_o    = data_be_1;
            data_addr_o  = addr_1   ;
        end else if(data_req_o && second_req) begin
            data_wdata_o = wdata_2_q  ;
            data_be_o    = data_be_2_q;
            data_addr_o  = addr_2     ;
        end
    end


    assign data_offset = ls_addr_q[1:0];
    assign base_addr   = {ls_addr_q[31:2],2'b0};
    //check wether we need two req, utilize the data_offset
    assign two_req    = (data_offset != 2'b00 & (ls_operator_q == SW | ls_operator_q == LW)) |
                        (data_offset == 2'b11 & (ls_operator_q == SH | ls_operator_q == LH | ls_operator_q == LHU)) ;
    assign req_done = (data_gnt_i & ~two_req) | (data_gnt_i & second_req);

    always_comb begin 
        addr_1    = base_addr;
        addr_2    = base_addr;
        wdata_1   = 32'b0;
        wdata_2   = 32'b0;
        data_be_1 = 4'b0;
        data_be_2 = 4'b0;
        case(ls_operator_q)
        SW,LW: begin
            case(data_offset)
            2'b00: begin
                wdata_1 = store_data_q;
                data_be_1 = 4'hf;
            end
            2'b01: begin
                wdata_1 = {store_data_q[23:0],8'b0};
                wdata_2 = {24'b0,store_data_q[31:24]};
                data_be_1 = 4'b1110;
                data_be_2 = 4'b0001;
                addr_2    = base_addr + 3'b100;
            end
            2'b10: begin
                wdata_1 = {store_data_q[15:0],16'b0};
                wdata_2 = {16'b0,store_data_q[31:16]};
                data_be_1 = 4'b1100;
                data_be_2 = 4'b0011;
                addr_2    = base_addr + 3'b100;
            end
            2'b11: begin
                wdata_1 = {store_data_q[7:0],24'b0};
                wdata_2 = {24'b0,store_data_q[31:8]};
                data_be_1 = 4'b1000;
                data_be_2 = 4'b0111;
                addr_2    = base_addr + 3'b100;
            end
            endcase
        end
        SH,LH,LHU: begin
            case(data_offset)
            2'b00: begin
                wdata_1 = store_data_q;
                data_be_1 = 4'b0011;
            end
            2'b01: begin
                wdata_1 = {8'b0,store_data_q[15:0],8'b0};
                data_be_1 = 4'b0110;
            end
            2'b10: begin
                wdata_1 = {store_data_q[15:0],16'b0};
                data_be_1 = 4'b1100;
            end
            2'b11: begin
                wdata_1 = {store_data_q[7:0],24'b0};
                data_be_1 = 4'b1000;
                wdata_2 = {24'b0,store_data_q[15:8]};
                data_be_2 = 4'b0001;
                addr_2    = base_addr + 3'b100;
            end
            endcase
        end
        SB,LB,LBU: begin
            case(data_offset)
            2'b00: begin
                wdata_1 = store_data_q;
                data_be_1 = 4'b0001;
            end
            2'b01: begin
                wdata_1 = {16'b0,store_data_q[7:0],8'b0};
                data_be_1 = 4'b0010;
            end
            2'b10: begin
                wdata_1 = {8'b0,store_data_q[7:0],16'b0};
                data_be_1 = 4'b0100;
            end
            2'b11: begin
                wdata_1 = {store_data_q[7:0],24'b0};
                data_be_1 = 4'b1000;
            end
            endcase
        end
        endcase
    end

                
//###############################################################
//###########          read back channel        
//###############################################################
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            two_read <= 1'b0;
            read_operator_q <= NONE_OP;
            read_data_offset <= 2'b0;
            read_trans_id <= '0;
        end else if(req_done && two_req && ~data_we_o) begin
            two_read <= 1'b1;
            read_operator_q <= ls_operator_q;
            read_data_offset <= ls_addr_q[1:0];
            read_trans_id <= trans_id_q;
        end else if(second_read_back && data_rvalid_i) begin
            two_read <= 1'b0;
            read_operator_q <= NONE_OP;
            read_data_offset <= 2'b0;
            read_trans_id <= '0;
        end
    end
    
    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            second_read_back <= 1'b0;
        else if(two_read && data_rvalid_i)
            second_read_back <= 1'b1;
        else if(second_read_back && data_rvalid_i)
            second_read_back <= 1'b0;
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            rdata_1_q <= 32'b0;
        else if(data_rvalid_i)
            rdata_1_q <= data_rdata_i;
    end

    assign sign_ext = (operator == LH | operator == LB);
    //either of ls_operator_q or read_operator_q is 0, need the non-zero value
    assign operator = (two_read)? read_operator_q: ls_operator_q ;
    //either of data_offset or read_data_offset is 0, need the non-zero value
    assign offset   = (two_read)? read_data_offset : data_offset;
    always_comb begin 
        rdata     = 32'b0;
        case(operator)
        LW: begin
            case(offset)
            2'b00: rdata   = data_rdata_i;
            2'b01: rdata   = {data_rdata_i[7:0],rdata_1_q[31:8]};
            2'b10: rdata   = {data_rdata_i[15:0],rdata_1_q[31:16]};
            2'b11: rdata   = {data_rdata_i[23:0],rdata_1_q[31:24]};
            endcase
        end
        LH,LHU: begin
            case(offset)
            2'b00: rdata   = (sign_ext)? {{16{data_rdata_i[15]}},data_rdata_i[15:0]} : {16'b0,data_rdata_i[15:0]};
            2'b01: rdata   = (sign_ext)? {{16{data_rdata_i[23]}},data_rdata_i[23:8]} : {16'b0,data_rdata_i[23:8]};
            2'b10: rdata   = (sign_ext)? {{16{data_rdata_i[31]}},data_rdata_i[31:16]} : {16'b0,data_rdata_i[31:16]};
            2'b11: rdata   = (sign_ext)? {{16{data_rdata_i[7]}},data_rdata_i[7:0],rdata_1_q[31:24]} : {16'b0,data_rdata_i[7:0],rdata_1_q[31:24]};
            endcase
        end
        LB,LBU: begin
            case(offset)
            2'b00: rdata   = (sign_ext)? {{24{data_rdata_i[7]}} ,data_rdata_i[7:0]} : data_rdata_i[7:0];
            2'b01: rdata   = (sign_ext)? {{24{data_rdata_i[15]}},data_rdata_i[15:8]} : data_rdata_i[15:8];
            2'b10: rdata   = (sign_ext)? {{24{data_rdata_i[23]}},data_rdata_i[23:16]} : data_rdata_i[23:16];
            2'b11: rdata   = (sign_ext)? {{24{data_rdata_i[31]}},data_rdata_i[31:24]} : data_rdata_i[31:24];
            endcase
        end
        endcase
    end


// output
    always_comb begin 
        if((data_rvalid_i && ~data_err_i && ~two_read) || 
           (data_rvalid_i && ~data_err_i && second_read_back)) begin
            ls_wb_port_o.wb_data  = rdata       ;
            ls_wb_port_o.wb_vld   = 1'b1        ;
            ls_wb_port_o.trans_id = (two_read)? read_trans_id : trans_id_q ;
        end else if((data_we_o && data_gnt_i && ~two_req) || 
                    (data_we_o && data_gnt_i && second_req)) begin
            ls_wb_port_o.wb_data  = 32'b0       ;
            ls_wb_port_o.wb_vld   = 1'b1        ;
            ls_wb_port_o.trans_id = trans_id_q  ;
        end else begin
            ls_wb_port_o.wb_data  = 32'b0;
            ls_wb_port_o.wb_vld   = 1'b0 ;
            ls_wb_port_o.trans_id = 5'b0 ;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) 
            ls_rdy_o <= 1'b1;
        else if(flush_ex_i)
            ls_rdy_o <= 1'b1;
        else if((data_gnt_i && ~two_req  ) || 
                (data_gnt_i && second_req)) 
            ls_rdy_o <= 1'b1;
        else if(data_req_o)
            ls_rdy_o <= 1'b0;
    end





endmodule
