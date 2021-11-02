   
package bmm_pkg;  
   
    localparam      REG_ADDR_SIZE  = 5;
    localparam      REG_DATA_WIDTH = 32;
    localparam      ADDR_BITS      = 3;
    localparam      NR_WB_PORTS    = 4;
    localparam      MEM_DEPTH      = 8;
    // --------------------
    // Privilege Spec
    // --------------------
    typedef enum logic[1:0] {
      PRIV_LVL_M = 2'b11,
      PRIV_LVL_S = 2'b01,
      PRIV_LVL_U = 2'b00
    } priv_lvl_t;

    // ----------------------
    // Exception Cause Codes
    // ----------------------
    typedef enum logic [3:0] {
        INSTR_ADDR_MISALIGNED = 0,
        INSTR_ACCESS_FAULT    = 1,
        ILLEGAL_INSTR         = 2,  //support
        BREAKPOINT            = 3,  //support
        LD_ADDR_MISALIGNED    = 4,
        LD_ACCESS_FAULT       = 5,
        ST_ADDR_MISALIGNED    = 6,
        ST_ACCESS_FAULT       = 7,
        ENV_CALL_UMODE        = 8,  
        ENV_CALL_SMODE        = 9,  
        ENV_CALL_MMODE        = 11,   //support
        INSTR_PAGE_FAULT      = 12, 
        LOAD_PAGE_FAULT       = 13, 
        STORE_PAGE_FAULT      = 15 
        //DEBUG_REQUEST         = 24 
    }ex_cause_t;

    localparam logic [3:0] IRQ_M_SOFT            = 3;  //support
    localparam logic [3:0] IRQ_M_TIMER           = 7;  //support
    localparam logic [3:0] IRQ_M_EXT             = 11;  //support

    // --------------------
    //  csr addr define
    // --------------------
    typedef enum logic [11:0] {
        // Machine Mode CSRs
        CSR_MSTATUS        = 12'h300,
        CSR_MISA           = 12'h301,
        CSR_MIE            = 12'h304,
        CSR_MTVEC          = 12'h305,
        CSR_MCOUNTEREN     = 12'h306,
        CSR_MSCRATCH       = 12'h340,
        CSR_MEPC           = 12'h341,
        CSR_MCAUSE         = 12'h342,
        CSR_MTVAL          = 12'h343,
        CSR_MIP            = 12'h344,
        CSR_MVENDORID      = 12'hF11,
        CSR_MARCHID        = 12'hF12,
        CSR_MIMPID         = 12'hF13,
        CSR_MHARTID        = 12'hF14,
        CSR_MCYCLE         = 12'hB00,
        CSR_MINSTRET       = 12'hB02
    }csr_reg_t;

    // --------------------
    // Instruction Types
    // --------------------
    typedef struct packed {
        logic [31:25] funct7;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } rtype_t;

    typedef struct packed {
        logic [31:20] imm;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } itype_t;

    typedef struct packed {
        logic [31:25] imm;
        logic [24:20] rs2;
        logic [19:15] rs1;
        logic [14:12] funct3;
        logic [11:7]  imm0;
        logic [6:0]   opcode;
    } stype_t;

    typedef struct packed {
        logic [31:12] imm;
        logic [11:7]  rd;
        logic [6:0]   opcode;
    } utype_t;


    typedef union packed {
        logic [31:0]   instr;
        rtype_t        rtype;
        itype_t        itype;  //jalr
        stype_t        stype;  //btype
        utype_t        utype;  //jal
    } instruction_t;



    // --------------------
    // Opcodes
    // --------------------

    typedef enum logic [6:0] {
      OPCODE_LOAD     = 7'b000_0011, //h03,
      OPCODE_STORE    = 7'b010_0011, //h23,
      OPCODE_AUIPC    = 7'b001_0111, //h17,
      OPCODE_LUI      = 7'b011_0111, //h37,
      OPCODE_OP       = 7'b011_0011, //h33,
      OPCODE_OP_IMM   = 7'b001_0011, //h13,
      OPCODE_BRANCH   = 7'b110_0011, //h63,
      OPCODE_JALR     = 7'b110_0111, //h67,
      OPCODE_JAL      = 7'b110_1111, //h6f,
      OPCODE_MISC_MEM = 7'b000_1111, //h0f,//FENCE
      OPCODE_SYSTEM   = 7'b111_0011  //h73  //ecall ebreak
    } opcode_e;

    
    // --------------------
    // EX stage option type 
    // --------------------
    
    // I set only
    typedef enum logic [5:0] { NONE_OP,
                               // basic ALU op
                               ADD, SUB, ADDI,                          //+
                               XOR, OR, AND, XORI, ORI, ANDI,           // logic operations
                               SRA, SRL, SLL, SRLI, SLLI, SRAI,         // shifts
                               LUI,                                     //simm << 12
                               AUIPC,                                   //simm << 12 + PC 
                               SLT, SLTU, SLTI, SLTIU,                  // comparisons

                               //branch unit
                               BEQ, BNE, BLT, BGE, BLTU, BGEU, //branch  comparisons
                               JAL,             // simm*2+pc 
                               JALR,            // simm+rs1 

                               // LSU functions  compute addr 
                               LB, LH, LW, LHU, LBU,
                               SB, SH, SW,   

                               MUL, MULH, MULHSU, MULHU,
                               DIV, DIVU, REM, REMU,

                               SM4ED, SM4KS, SM3P0, SM3P1,

                               FENCE_I, FENCE,
                               ECALL, EBREAK, 
                               CSRRW, CSRRS, CSRRC, CSRRWI, CSRRSI, CSRRCI,
                               MRET
                             } fu_op_t;

    typedef enum logic[3:0] {
        NONE,      // 0
        LOAD,      // 1
        STORE,     // 2
        ALU,       // 3
        CTRL_FLOW, // 4
        MULT,      // 5
        CSR       // 6
        //FPU,       // 7
        //FPU_VEC    // 8
    } fu_t;

    typedef struct packed {
         ex_cause_t  cause; // cause of exception
         logic [31:0] tval;  // additional information of causing exception (e.g.: instruction causing it),
                             // address of LD/ST fault
         logic        vld;
    } exception_t;

    

    typedef struct packed {
        logic           vld;
        logic [31:0]    ras_data;
    } ras_t;

    typedef struct packed {
        logic               is_mispredict ;     
        logic               instr_jump    ;     
        logic [31:0]        jump_address; 
    } branch_t;

    typedef struct packed {
        logic                     	    valid;        
        logic [31:0]   		            pc;           
        fu_t                      	    fu;           
        fu_op_t                     	op;           
        
        logic [REG_ADDR_SIZE-1:0]		rs1;          
        logic [REG_ADDR_SIZE-1:0] 		rs2;          
        logic [REG_ADDR_SIZE-1:0] 		rd;           
        logic [31:0]    	            imm;
    
        logic                           csr_instr;
    } instruction_entry_t;

    //typedef struct packed {
    //    logic [31:0]                pc;            // PC of instruction
    //    logic [ADDR_BITS-1:0]       trans_id;      // this can potentially be simplified, we could index the scoreboard entry
    //                                             // with the transaction id in any case make the width more generic
    //    fu_t                        fu;            // functional unit to use
    //    fu_op_t                     op;            // operation to perform in each functional unit
    //    logic [31:0]    	        imm;
    //    logic                       csr_instr;

    //    logic [REG_ADDR_SIZE:0]     rs1;           // register source address 1
    //    logic [REG_ADDR_SIZE:0]     rs2;           // register source address 2
    //    logic [REG_ADDR_SIZE-1:0]   rd;            // register destination address

    //    logic [REG_DATA_WIDTH-1:0]  rs1_data;
    //    logic                       rs1_rdy;        
    //    logic [REG_DATA_WIDTH-1:0]  rs2_data;
    //    logic                       rs2_rdy;        
    //    logic [REG_DATA_WIDTH-1:0]  result;        // result write back to 
    //    logic                       rd_vld;
    //    branch_t                    branch;        //branch or call/return jump addr    
    //    exception_t                 ex    ;
    //} scoreboard_entry_t;

    typedef struct packed {
        logic [31:0]                pc;            // PC of instruction
        logic [ADDR_BITS-1:0]       trans_id;      // this can potentially be simplified, we could index the scoreboard entry
                                                 // with the transaction id in any case make the width more generic
        fu_t                        fu;            // functional unit to use
        fu_op_t                     op;            // operation to perform in each functional unit
        logic [31:0]    	        imm;
        logic                       csr_instr;

        logic [REG_ADDR_SIZE:0]     rs1;           // register source address 1
        logic [REG_ADDR_SIZE:0]     rs2;           // register source address 2
        logic [REG_ADDR_SIZE-1:0]   rd;            // register destination address
    } sbd_entry_t;

    typedef struct packed {
        logic [REG_DATA_WIDTH-1:0]  rs1_data;
        logic                       rs1_rdy;        
    } sbd_rs1_t;

    typedef struct packed {
        logic [REG_DATA_WIDTH-1:0]  rs2_data;
        logic                       rs2_rdy;        
    } sbd_rs2_t;


    typedef struct packed {
        logic [REG_DATA_WIDTH-1:0]  result;        // result write back to 
        logic                       rd_vld;
        branch_t                    branch;        //branch or call/return jump addr    
        exception_t                 ex    ;
    } sbd_wb_t;


    typedef struct packed {
        logic  [REG_DATA_WIDTH-1:0]         wb_data ;
        logic                               wb_vld  ;
        logic  [ADDR_BITS-1:0]              trans_id;
    } wb_port_t;

    typedef struct packed {
        fu_t                            fu          ;
        fu_op_t                         operator    ;
        logic [31:0]                    pc          ;

        logic [REG_DATA_WIDTH-1:0]      operand_1   ;
        logic [REG_DATA_WIDTH-1:0]      operand_2   ;
        logic [REG_DATA_WIDTH-1:0]      imm         ;
        logic [ADDR_BITS-1:0]           trans_id    ;

        logic                           valid       ;
    } fu_data_t;



    //and andi
    function automatic logic [31:0] alu_and (logic [31:0] op_a, logic [31:0] op_b ); 
        alu_and = op_a & op_b;
    endfunction
    //or ori
    function automatic logic [31:0] alu_or  (logic [31:0] op_a, logic [31:0] op_b ); 
        alu_or = op_a | op_b;
    endfunction
    //xor xori
    function automatic logic [31:0] alu_xor (logic [31:0] op_a, logic [31:0] op_b ); 
        alu_xor = op_a ^ op_b;
    endfunction
    //sll slli
    function automatic logic [31:0] alu_sll (logic [31:0] op_a, logic [4:0] op_b ); 
        alu_sll = op_a << op_b;
    endfunction
    //srl srli
    function automatic logic [31:0] alu_srl (logic [31:0] op_a, logic [4:0] op_b ); 
        alu_srl = op_a >> op_b;
    endfunction
    //sra srai
    function automatic logic [31:0] alu_sra (logic [31:0] op_a, logic [4:0] op_b ); 
        alu_sra = $signed(op_a) >>> op_b;
    endfunction



endpackage
