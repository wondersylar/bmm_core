
module csr_file(
    input    logic              clk_i           ,
    input    logic              rst_ni          ,     
    //exception from if
    input    logic [31:0]       if_pc_i               ,
    input    exception_t        if_exception_i        ,
    output   logic              if_flush_o            ,
    //exception from id
    input    logic [31:0]       id_pc_i               ,
    input    exception_t        id_exception_i        ,  //ebreak:3   ecall:11  illegal_instruction:2
    output   logic              id_flush_o            ,
    input    logic              id_mret_i             ,
    //exception from ex_stage
    input    logic [31:0]       ex_pc_i               ,
    input    exception_t        ex_exception_i        ,
    output   logic              ex_flush_o            ,
    //interrupt from top
    input    logic [31:0]       fetch_pc_i            ,
    input    logic              soft_irq_i         ,
    input    logic              timer_irq_i        ,
    input    logic              ex_irq_i           ,
    output   logic              interrupt_flush_o  ,

    output   logic [31:0]       fetch_addr_o          ,
    
    input    logic [31:0]       csr_addr_i         ,
    input    logic              csr_read_i         ,
    output   logic [31:0]       csr_rdata_o        ,
    input    logic              csr_write_i        ,
    input    logic [31:0]       csr_wdata_i        

);

    localparam logic [31:0] MISA_VALUE = 
                                          (1 << 30) //RV32
                                        | (1 << 12) //M
                                        | (1 << 10) //K
                                        | (1 << 8 ) //I     
                                        | (1 << 1 ); //B
                                    

    typedef struct packed {
        logic [18:0]   rsv3 ; //[31:13]//[31:31]sd,[22:22]tsr,[21:21]tw,[20:20]tvm,[19:19]mxr,[18:18]sum,[17:17]mprv,[16:15]xs,[14:13]fs,
        logic [1:0 ]   mpp  ; //[12:11]
        logic [2:0 ]   rsv2 ; //[10:8] 
        logic [0:0 ]   mpie ; //[7:7]  
        logic [2:0 ]   rsv1 ; //[6:4]  
        logic [0:0 ]   mie  ; //[3:3]  
        logic [2:0 ]   rsv0 ; //[2:0]  
    } mstatus_t;

    typedef struct packed {
        logic [0:0 ]   ex_type       ;    //[31:31]
        logic [30:0]   exception_code;    //[30:0 ]
    } mcause_t;

    typedef struct packed {
        logic [29:0]    base; //[31:2]
        logic [1:0 ]    mode; //[1:0 ]
    } mtvec_t;

    typedef struct packed {
        logic  [19:0]   rsv3   ;  //[31:12]
        logic  [0:0 ]   meip   ;  //[11:11]
        logic  [2:0 ]   rsv2   ;  //[10:8 ]
        logic  [0:0 ]   mtip   ;  //[7 :7 ]
        logic  [2:0 ]   rsv1   ;  //[6 :4 ]
        logic  [0:0 ]   msip   ;  //[3 :3 ]
        logic  [2:0 ]   rsv0   ;  //[2 :0 ]
    } mip_t;

    typedef struct packed {
        logic  [19:0]   rsv3   ;
        logic  [0:0 ]   meie   ;
        logic  [2:0 ]   rsv2   ;
        logic  [0:0 ]   mtie   ;
        logic  [2:0 ]   rsv1   ;
        logic  [0:0 ]   msie   ;
        logic  [2:0 ]   rsv0   ;
    } mie_t;

    typedef union packed {
        logic [31:0]   wdata    ;
        mstatus_t      mstatus  ;  
        mcause_t       mcause   ;  
        mtvec_t        mtvec    ;  
        mip_t          mip      ;  
        mie_t          mie      ;
    } csr_wdata_t;

    mstatus_t       mstatus_d , mstatus_q ;
    mcause_t        mcause_d  , mcause_q  ; 
    mtvec_t         mtvec_d   , mtvec_q   ;
    mip_t           mip_d     , mip_q     ;
    mie_t           mie_d     , mie_q     ;
    logic [31:0]    mscratch_d, mscratch_q;
    logic [31:0]    mepc_d    , mepc_q    ;
    logic [31:0]    mtval_d   , mtval_q   ;
    logic [1:0]     priv_lvl_d, priv_lvl_q;

    csr_wdata_t  csr_wdata_in     ;
    logic        csr_write_illegal;
    logic        csr_read_illegal ;
    logic [31:0] jump_addr        ;

    
    struct packed {
        logic       timer;
        logic       softw;
        logic       ex   ;
    } interrupt;

    struct packed {
        logic       if_vld;
        logic       id_vld;
        logic       ex_vld;
    } exception;
    

    //csr read
    always_comb begin
        if(csr_read_i) begin
            case(csr_addr_i)
            CSR_MSTATUS    :  csr_rdata_o = mstatus_q   ;
            CSR_MISA       :  csr_rdata_o = MISA_VALUE  ;
            CSR_MIE        :  csr_rdata_o = mie_q       ;
            CSR_MTVEC      :  csr_rdata_o = mtvec_q     ;
            CSR_MSCRATCH   :  csr_rdata_o = mscratch_q  ;
            CSR_MEPC       :  csr_rdata_o = mepc_q      ;
            CSR_MCAUSE     :  csr_rdata_o = mcause_q    ;
            CSR_MTVAL      :  csr_rdata_o = mtval_q     ;
            CSR_MIP        :  csr_rdata_o = mip_q       ;
            CSR_MVENDORID  :  csr_rdata_o = 32'b0       ;
            CSR_MARCHID    :  csr_rdata_o = 32'b0       ;
            CSR_MIMPID     :  csr_rdata_o = 32'b0       ;
            CSR_MHARTID    :  csr_rdata_o = 32'b0       ;
            //CSR_MCYCLE     :  csr_rdata_o = mcycle_q    ;
            //CSR_MINSTRET   :  csr_rdata_o = minstret_q  ;
            default        :  begin
                              csr_rdata_o       = 32'b0       ;
                              csr_read_illegal  = 1'b1        ;
            end
            endcase
        end
    end


    assign csr_wdata_in = csr_wdata_t'(csr_wdata_i);
    //assign jump_addr    = (mtvec_q.mode == 2'b0)? mtvec_q.base : (mtvec_q.base + {mcause_d.exception_code[29:0],2'b0});
    assign jump_addr    = (mtvec_q.mode == 2'b0)? {mtvec_q.base, 2'b0} : ({mtvec_q.base, 2'b0} + {mcause_d.exception_code[29:0],2'b0});

    always_comb begin
        exception.if_vld = if_exception_i.vld;
        exception.id_vld = id_exception_i.vld;
        exception.ex_vld = ex_exception_i.vld;
    end
    always_comb begin
        interrupt.timer = mip_q.mtip & mie_q.mtie;
        interrupt.softw = mip_q.msip & mie_q.msie;
        interrupt.ex    = mip_q.meip & mie_q.meie;
    end
    //csr  write
    always_comb begin
        mstatus_d.mpp  = PRIV_LVL_M       ;
        mstatus_d.rsv3 = mstatus_q.rsv3   ;
        mstatus_d.rsv2 = mstatus_q.rsv2   ;
        mstatus_d.mpie = mstatus_q.mpie   ;
        mstatus_d.rsv1 = mstatus_q.rsv1   ;
        mstatus_d.mie  = mstatus_q.mie    ;
        mstatus_d.rsv0 = mstatus_q.rsv0   ;
        mie_d       = mie_q       ;
        mtvec_d     = mtvec_q     ;
        mscratch_d  = mscratch_q  ;
        mepc_d      = mepc_q      ;
        mcause_d    = mcause_q    ;
        mtval_d     = mtval_q     ;
        priv_lvl_d  = PRIV_LVL_M  ;
        //mcycle_d    = mcycle_q    ;
        //minstret_d  = minstret_q  ;

        mip_d.meip  = ex_irq_i   ;
        mip_d.mtip  = timer_irq_i;
        mip_d.msip  = soft_irq_i ;
        mip_d.rsv0  = '0;
        mip_d.rsv1  = '0;
        mip_d.rsv2  = '0;
        mip_d.rsv3  = '0;

        fetch_addr_o = 32'b0    ;
        ex_flush_o   = 1'b0     ;
        id_flush_o   = 1'b0     ;
        if_flush_o   = 1'b0     ;
        if(csr_write_i) begin
            case(csr_addr_i)
            CSR_MSTATUS    :  begin
                              mstatus_d.mpp  = csr_wdata_in.mstatus.mpp ;
                              mstatus_d.mpie = csr_wdata_in.mstatus.mpie;
                              mstatus_d.mie  = csr_wdata_in.mstatus.mie ;
            end
            CSR_MIE        :  begin
                              mie_d.meie = csr_wdata_in.mie.meie ;
                              mie_d.mtie = csr_wdata_in.mie.mtie ;
                              mie_d.msie = csr_wdata_in.mie.msie ;
            end
            CSR_MTVEC      :  mtvec_d    = csr_wdata_in;
            CSR_MSCRATCH   :  mscratch_d = csr_wdata_in;
            CSR_MEPC       :  mepc_d     = csr_wdata_in;
            //CSR_MCYCLE     :  mcycle_d   = csr_wdata_in ;
            //CSR_MINSTRET   :  minstret_d = csr_wdata_in ;
            default        :  csr_write_illegal = 1'b1  ;
            endcase
        end

        if(id_mret_i) begin
            mstatus_d.mpie = 1'b1                   ;
            mstatus_d.mie  = mstatus_q.mpie         ;
            priv_lvl_d     = mstatus_q.mpp          ;
            fetch_addr_o   = mepc_q                 ;
        end

        if(|exception) begin
            mcause_d.ex_type = 1'b0          ;
            mstatus_d.mpie = mstatus_q.mie          ;
            mstatus_d.mie  = 1'b0                   ;
            mstatus_d.mpp  = priv_lvl_q             ;
            fetch_addr_o   = jump_addr              ;
            if(exception.ex_vld) begin
                mcause_d.exception_code = ex_exception_i.cause;
                mepc_d         = ex_pc_i                  ;
                mtval_d        = ex_exception_i.tval      ;
                ex_flush_o     = 1'b1                     ;
            end else if(exception.id_vld) begin
                mcause_d.exception_code = id_exception_i.cause;
                mepc_d         = (id_exception_i.cause == BREAKPOINT || id_exception_i.cause == ENV_CALL_MMODE )? id_pc_i + 4'd4 : id_pc_i;
                mtval_d        = id_exception_i.tval        ;
                id_flush_o     = 1'b1                     ;
            end else if(exception.if_vld) begin
                mcause_d.exception_code = if_exception_i.cause;
                mepc_d         = if_pc_i                    ;
                mtval_d        = if_exception_i.tval        ;
                if_flush_o     = 1'b1                     ;
            end
        end

        if(|interrupt) begin
            mcause_d.ex_type = 1'b1          ;
            mepc_d         = fetch_pc_i + 32'd4      ;
            mstatus_d.mpie = mstatus_q.mie          ;
            mstatus_d.mie  = 1'b0                   ;
            mstatus_d.mpp  = priv_lvl_q             ;
            fetch_addr_o   = jump_addr              ;
            interrupt_flush_o = 1'b1                ;
            if(interrupt.ex) 
                mcause_d.exception_code = IRQ_M_EXT     ;
            else if(interrupt.softw) 
                mcause_d.exception_code = IRQ_M_SOFT    ;
            else if(interrupt.timer) 
                mcause_d.exception_code = IRQ_M_TIMER   ;
        end
    end


    always_ff @(posedge clk_i or negedge rst_ni) begin
        if (!rst_ni) begin
            mstatus_q  <= '0;
            mcause_q   <= '0;
            mtvec_q    <= '0;
            mip_q      <= '0;
            mie_q      <= '0;
            mscratch_q <= '0;
            mepc_q     <= '0;
            mtval_q    <= '0;
            priv_lvl_q <= PRIV_LVL_M;
        end else begin
            mstatus_q  <= mstatus_d ;
            mcause_q   <= mcause_d  ;
            mtvec_q    <= mtvec_d   ;
            mip_q      <= mip_d     ;
            mie_q      <= mie_d     ;
            mscratch_q <= mscratch_d;
            mepc_q     <= mepc_d    ;
            mtval_q    <= mtval_d   ;
            priv_lvl_q <= priv_lvl_d;
        end
    end






endmodule
