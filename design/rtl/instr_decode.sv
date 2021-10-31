
    output   logic              instr_decode_rdy_o     ,
    input    logic              instr_vld_i     ,
    input    logic  [31:0]      instr_i         ,
    input    logic  [31:0]      instr_pc_i      ,
    
    output  instruction_entry_t instr_decode_o  ,
    input   logic               issue_sbe_rdy_i     



);
    
    bmm_pkg::instruction_t instruction;
    assign instruction = bmm_pkg::instruction_t'(instr_i);

    instruction_entry_t  instr_decode_d     ,instr_decode_q    ;
    logic                illegal_instr_d    ,illegal_instr_q   ;
    logic                instr_ecall_d      ,instr_ecall_q     ;
    logic                instr_ebreak_d     ,instr_ebreak_q    ;
    logic                instr_mret_d       ,instr_mret_q      ;
    logic   [31:0]       instr_q;






    always_comb begin:decode
        instr_decode_d            =  instr_decode_q;
        instr_ecall_d                   = 1'b0   ;
        instr_ebreak_d                  = 1'b0   ;
        instr_mret_d                    = 1'b0   ;
        illegal_instr_d                 =  1'b0 ;

        if(flush_id_i) begin
            instr_decode_d   = '0   ;
        end else if(instr_vld_i && instr_decode_rdy_o) begin
            instr_decode_d.pc        = instr_pc_i ; 
            instr_decode_d.valid     = 1'b1 ;
            instr_decode_d.fu        =  NONE   ;
            instr_decode_d.op        =  NONE_OP    ;
            instr_decode_d.rs1       =  'b0    ;
            instr_decode_d.rs2       =  'b0    ;
            instr_decode_d.rd        =  'b0    ;
            instr_decode_d.imm       =  'b0    ;      //sign extend 32bit
            instr_decode_d.csr_instr =  1'b0 ;
            
            case(instruction.instr[6:0])
                //R type
                OPCODE_OP       : begin    
                    instr_decode_d.rs2    =  instruction.rtype.rs2;
                    if(instruction.rtype.funct7 == 7'b000_0001) begin
                        instr_decode_d.fu     =  MULT;
                        instr_decode_d.rs1    =  instruction.rtype.rs1;
                        instr_decode_d.rd     =  instruction.rtype.rd ;
                        case(instruction.rtype.funct3)
                            {3'b000}: instr_decode_d.op = MUL    ;
                            {3'b001}: instr_decode_d.op = MULH   ;
                            {3'b010}: instr_decode_d.op = MULHSU ;
                            {3'b011}: instr_decode_d.op = MULHU  ;
                            {3'b100}: instr_decode_d.op = DIV    ;
                            {3'b101}: instr_decode_d.op = DIVU   ;
                            {3'b110}: instr_decode_d.op = REM    ;
                            {3'b111}: instr_decode_d.op = REMU   ;
                            default : illegal_instr_d   = 1'b1 ;  
                        endcase
                    end else begin
                        instr_decode_d.fu     =  ALU;
                        //rt = rs1
                        if(instruction.rtype.funct3 == 3'b0 && instruction.rtype.rd == 5'b0 && instruction[29:25] == 5'b11000) begin
                            instr_decode_d.op = SM4ED;
                            instr_decode_d.rd = instruction.rtype.rs1 ;
                            instr_decode_d.imm= instruction.rtype.funct7[31:30]; //bs
                        end else if(instruction.rtype.funct3 == 3'b0 && instruction.rtype.rd == 5'b0 && instruction[29:25] == 5'b11010) begin
                            instr_decode_d.op = SM4KS;
                            instr_decode_d.rd = instruction.rtype.rs1 ;
                            instr_decode_d.imm= instruction.rtype.funct7[31:30]; //bs
                        end else begin
                            instr_decode_d.rs1    =  instruction.rtype.rs1;
                            instr_decode_d.rd     =  instruction.rtype.rd ;
                            case({instruction.rtype.funct7,instruction.rtype.funct3})
                                {7'b000_0000, 3'b000}: instr_decode_d.op = ADD  ;
                                {7'b010_0000, 3'b000}: instr_decode_d.op = SUB  ;
                                {7'b000_0000, 3'b001}: instr_decode_d.op = SLL  ;
                                {7'b000_0000, 3'b010}: instr_decode_d.op = SLT  ;
                                {7'b000_0000, 3'b011}: instr_decode_d.op = SLTU ;
                                {7'b000_0000, 3'b100}: instr_decode_d.op = XOR  ;
                                {7'b000_0000, 3'b101}: instr_decode_d.op = SRL  ;
                                {7'b010_0000, 3'b101}: instr_decode_d.op = SRA  ;
                                {7'b000_0000, 3'b110}: instr_decode_d.op = OR   ;
                                {7'b000_0000, 3'b111}: instr_decode_d.op = AND  ;
                                default              : illegal_instr_d   = 1'b1 ;  
                            endcase
                        end
                    end
                end
                //I type
                OPCODE_MISC_MEM : begin
                    // rd rs1 imm are default 0, no illegal_instr
                    instr_decode_d.fu     =  CTRL_FLOW;
                    case(instruction.itype.funct3)
                        3'b000 : instr_decode_d.op = FENCE  ;//not support
                        3'b001 : instr_decode_d.op = FENCE_I;//flush all previous instructions
                        default: illegal_instr_d   = 1'b1 ;
                    endcase
                end
                OPCODE_LOAD     : begin     
                    instr_decode_d.fu     =  LOAD;
                    instr_decode_d.rs1    =  instruction.itype.rs1;
                    instr_decode_d.rd     =  instruction.itype.rd ;
                    instr_decode_d.imm    =  {{20{instruction.itype.imm[31]}}, instruction.itype.imm};
                    case(instruction.itype.funct3)
                        3'b000 : instr_decode_d.op = LB  ;
                        3'b001 : instr_decode_d.op = LH  ;
                        3'b010 : instr_decode_d.op = LW  ;
                        3'b100 : instr_decode_d.op = LBU ;
                        3'b101 : instr_decode_d.op = LHU ;
                        default: illegal_instr_d   = 1'b1 ;
                    endcase
                end
                OPCODE_OP_IMM   : begin
                    instr_decode_d.fu     =  ALU;
                    instr_decode_d.rs1    =  instruction.itype.rs1;
                    instr_decode_d.rd     =  instruction.itype.rd ;
                    instr_decode_d.imm    =  {{20{instruction.itype.imm[31]}}, instruction.itype.imm};
                    if(instruction.rtype.funct7 == 7'b010_0000) begin
                        instr_decode_d.op  = SRAI  ;
                        instr_decode_d.rs2 =  instruction.rtype.rs2;
                    end else begin
                        case(instruction.itype.funct3)
                            3'b000 : instr_decode_d.op = ADDI  ;
                            3'b010 : instr_decode_d.op = SLTI  ;
                            3'b011 : instr_decode_d.op = SLTIU ;
                            3'b100 : instr_decode_d.op = XORI  ;
                            3'b110 : instr_decode_d.op = ORI   ;
                            3'b111 : instr_decode_d.op = ANDI  ;
                            3'b001 : begin
                                if(instruction.itype.imm == 12'b0001_0000_1000)
                                    instr_decode_d.op = SM3P0;
                                else if(instruction.itype.imm == 12'b0001_0000_1001)
                                    instr_decode_d.op = SM3P1;
                                else begin
                                    instr_decode_d.op = SLLI  ;
                                    instr_decode_d.rs2 =  instruction.rtype.rs2;
                                end
                            end
                            3'b101 : begin
                                instr_decode_d.op = SRLI  ;
                                instr_decode_d.rs2 =  instruction.rtype.rs2;
                            end
                            default: illegal_instr_d   = 1'b1  ;
                        endcase
                    end
                end
                OPCODE_JALR     : begin
                    if(instruction.itype.funct3 == 3'b0) begin
                        instr_decode_d.fu     =  CTRL_FLOW;
                        instr_decode_d.rs1    =  instruction.itype.rs1;
                        instr_decode_d.rd     =  instruction.itype.rd ;
                        instr_decode_d.imm    =  {{20{instruction.itype.imm[31]}}, instruction.itype.imm};
                        instr_decode_d.op     =  JALR ;
                    end else
                        illegal_instr_d       = 1'b1  ;
                end
                OPCODE_SYSTEM   : begin
                    instr_decode_d.rd     =  instruction.itype.rd ;
                    instr_decode_d.rs1    =  instruction.itype.rs1;
                    //instr_decode_d.imm    =  {{20{instruction.itype.imm[31]}}, instruction.itype.imm};
                    if(instruction.itype.funct3 == 3'b0) begin
                        instr_decode_d.imm    =  {{20{instruction.itype.imm[31]}}, instruction.itype.imm};
                        instr_decode_d.fu     =  CTRL_FLOW;
                        if(instruction.itype.imm == 12'b0) begin
                            instr_ecall_d     = 1'b1   ;
                            instr_decode_d.op = ECALL  ;
                        end else if(instruction.itype.imm == 12'b1) begin
                            instr_ebreak_d    = 1'b1   ;
                            instr_decode_d.op = EBREAK ;
                        end else if(instruction.itype.imm == 12'h302) begin
                            instr_mret_d      = 1'b1   ;
                            instr_decode_d.op = MRET   ;
                        end else
                            illegal_instr_d   = 1'b1   ;        //not include sret uret
                    end else begin
                        instr_decode_d.imm    =  {20'b0, instruction.itype.imm};
                        instr_decode_d.fu = CSR ;
                        instr_decode_d.csr_instr =  1'b1 ;
                        case(instruction.itype.funct3 ) 
                            3'b001  : instr_decode_d.op = CSRRW  ;  
                            3'b010  : instr_decode_d.op = CSRRS  ;  
                            3'b011  : instr_decode_d.op = CSRRC  ;  
                            3'b101  : instr_decode_d.op = CSRRWI ;  
                            3'b110  : instr_decode_d.op = CSRRSI ;  
                            3'b111  : instr_decode_d.op = CSRRCI ;  
                            default : illegal_instr_d   = 1'b1  ;  
                        endcase
                    end
                end
                //S type
                OPCODE_STORE    : begin
                    instr_decode_d.fu     =  STORE;
                    instr_decode_d.rs1    =  instruction.stype.rs1;
                    instr_decode_d.rs2    =  instruction.stype.rs2;
                    instr_decode_d.imm    =  {{20{instruction.stype.imm[31]}}, instruction.stype.imm, instruction.stype.imm0};//S
                    case(instruction.stype.funct3)
                        3'b000   : instr_decode_d.op = SB  ;
                        3'b001   : instr_decode_d.op = SH  ;
                        3'b010   : instr_decode_d.op = SW  ;
                        default  : illegal_instr_d   = 1'b1  ;  
                    endcase
                end
                //B type    similar to S type, different imm
                OPCODE_BRANCH   : begin
                    instr_decode_d.fu     =  CTRL_FLOW;
                    instr_decode_d.rs1    =  instruction.stype.rs1;
                    instr_decode_d.rs2    =  instruction.stype.rs2;
                    //instr_decode_d.imm    =  {{20{instruction.stype.imm[6]}}, instruction.stype.imm0[0], instruction.stype.imm[5:0], instruction.stype.imm0[4:1], 1'b0};//B
                    instr_decode_d.imm    =  {{20{instruction.stype.imm[31]}}, instruction.stype.imm0[7], instruction.stype.imm[30:25], instruction.stype.imm0[11:8], 1'b0};//B
                    case(instruction.stype.funct3)
                        3'b000 : instr_decode_d.op = BEQ    ;
                        3'b001 : instr_decode_d.op = BNE    ;
                        3'b100 : instr_decode_d.op = BLT    ;
                        3'b101 : instr_decode_d.op = BGE    ;
                        3'b110 : instr_decode_d.op = BLTU   ;
                        3'b111 : instr_decode_d.op = BGEU   ;
                        default  : illegal_instr_d = 1'b1   ;  
                    endcase
                end
                //U type
                OPCODE_AUIPC    : begin
                    instr_decode_d.fu     =  ALU;
                    instr_decode_d.rd     =  instruction.utype.rd ;
                    instr_decode_d.imm    =  {instruction.utype.imm, 12'b0};//U
                    instr_decode_d.op     =  AUIPC;
                end
                OPCODE_LUI      : begin
                    instr_decode_d.fu     =  ALU;
                    instr_decode_d.rd     =  instruction.utype.rd ;
                    instr_decode_d.imm    =  {instruction.utype.imm, 12'b0};//U
                    instr_decode_d.op     =  LUI;
                end
                //J type   similar to U type , different imm
                OPCODE_JAL      : begin
                    instr_decode_d.fu     =  CTRL_FLOW;
                    instr_decode_d.rd     =  instruction.utype.rd ;
                    //instr_decode_d.imm    =  {{12{instruction.utype.imm[19]}}, instruction.utype.imm[7:0], instruction.utype.imm[8], instruction.utype.imm[18:9], 1'b0};//J
                    instr_decode_d.imm    =  {{12{instruction.utype.imm[31]}}, instruction.utype.imm[19:12], instruction.utype.imm[20], instruction.utype.imm[30:21], 1'b0};//J
                    instr_decode_d.op     =  JAL;
                end
                //OPCODE_MISC_MEM : begin
                //end
                default         : illegal_instr_d = 1'b1   ;
                
            endcase
        end else if(issue_sbe_rdy_i && instr_decode_o.valid) begin
            instr_decode_d.valid = 1'b0;
        end
    end


                   
    always_comb begin
        if(instr_ecall_q) begin
            id_exception_o.vld   = 1'b1             ;
            id_exception_o.cause = ENV_CALL_MMODE   ;
            id_exception_o.tval  = 32'b0            ;
        end else if(instr_ebreak_q) begin
            id_exception_o.vld   = 1'b1             ;
            id_exception_o.cause = BREAKPOINT       ;
            id_exception_o.tval  = instr_decode_q.pc;
        end else if(instr_mret_q) begin
            id_mret_o = 1'b1 ;
        end else if(illegal_instr_q) begin
            id_exception_o.vld   = 1'b1             ;
            id_exception_o.cause = ILLEGAL_INSTR    ;
            id_exception_o.tval  = instr_q          ;
        end else begin
            id_exception_o.vld   = 1'b0             ;
            id_exception_o.cause = INSTR_ADDR_MISALIGNED            ;
            id_exception_o.tval  = 32'b0            ;
            id_mret_o = 1'b0 ;
        end
    end

    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            instr_decode_q     <= '0;
            instr_q            <= 32'b0;
            illegal_instr_q    <= 1'b0;
            instr_ecall_q      <= 1'b0;
            instr_ebreak_q     <= 1'b0;
            instr_mret_q       <= 1'b0;
        end else begin
            instr_decode_q     <= instr_decode_d ;
            instr_q            <= instr_i        ;
            illegal_instr_q    <= illegal_instr_d;
            instr_ecall_q      <= instr_ecall_d  ;
            instr_ebreak_q     <= instr_ebreak_d ;
            instr_mret_q       <= instr_mret_d   ;
        end
    end


    assign instr_decode_rdy_o = issue_sbe_rdy_i;
    
    always_comb begin
        instr_decode_o.pc            = instr_decode_q.pc          ;
        instr_decode_o.fu            = instr_decode_q.fu          ;
        instr_decode_o.op            = instr_decode_q.op          ;
        instr_decode_o.rs1           = instr_decode_q.rs1         ;
        instr_decode_o.rs2           = instr_decode_q.rs2         ;
        instr_decode_o.rd            = instr_decode_q.rd          ;
        instr_decode_o.imm           = instr_decode_q.imm         ;
        instr_decode_o.csr_instr     = instr_decode_q.csr_instr   ;
        instr_decode_o.valid         = instr_decode_q.valid & issue_sbe_rdy_i;
        //if(issue_sbe_rdy_i)
        //    instr_decode_o.valid = instr_decode_q.valid & ~flush_id_i;
        //else
        //    instr_decode_o.valid = 1'b0;
    end


endmodule





