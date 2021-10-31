module csr_ctrl(
    input  fu_op_t                           operator_i         ,
    input  logic [31:0]                      csr_addr_i         ,
    input  logic [31:0]                      rs1_data_i         ,
    output logic [31:0]                      csr_wb_data_o      ,
    //csrfile 
    output logic [31:0]                      csr_addr_o         ,
    output logic                             csr_read_o         ,
    output logic                             csr_write_o         ,
    input  logic [31:0]                      csr_rdata_i        ,
    output logic [31:0]                      csr_wdata_o
    //exception ports to be modify

);

    logic   [31:0]  zimm;
    logic   [31:0]  op_1;
    logic   [31:0]  op_2;
    logic   [31:0]  set_one;
    logic   [31:0]  clr_zero;

    assign zimm = rs1_data_i;
    assign set_one = op_1 | op_2 ;
    assign clr_zero = op_1 & op_2 ; 

    always_comb begin
        op_2 = csr_rdata_i;
        unique case (operator_i)
            CSRRS : op_1 = rs1_data_i;
            CSRRC : op_1 = ~rs1_data_i;
            CSRRSI: op_1 = zimm;
            CSRRCI: op_1 = ~zimm;
            default:op_1 = 32'b0;
        endcase
    end

    always_comb begin
        csr_addr_o    = csr_addr_i ;
        csr_wb_data_o = csr_rdata_i;
        unique case (operator_i)
            CSRRW : csr_wdata_o =  rs1_data_i;
            CSRRWI: csr_wdata_o =  zimm;
            CSRRS, CSRRSI: csr_wdata_o = set_one;
            CSRRC, CSRRCI: csr_wdata_o = clr_zero;
            default: csr_wdata_o = 32'b0;
        endcase
    end

    always_comb begin
        if(operator_i inside{CSRRW, CSRRWI, CSRRS, CSRRSI, CSRRC, CSRRCI}) begin
            csr_read_o  = 1'b1;
            csr_write_o = 1'b1;
        end else begin
            csr_read_o  = 1'b0;
            csr_write_o = 1'b0;
        end
    end

endmodule
