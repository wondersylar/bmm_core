
module ctrl (

    input    logic              branch_mispredict_i  ,

    output  logic               flush_if_o           ,
    output  logic               flush_id_o           ,
    output  logic               flush_issue_o        ,
    output  logic               flush_ex_o                
    //output  logic               flush_commit_o         
);


    always_comb begin: gen_flush
        flush_if_o      = 1'b0;
        flush_id_o      = 1'b0;
        flush_issue_o   = 1'b0;
        flush_ex_o      = 1'b0;
        //flush_commit_o  = 1'b0;
        if(branch_mispredict_i) begin
            flush_if_o      = 1'b1;
            flush_id_o      = 1'b1;
            flush_issue_o   = 1'b1;
            flush_ex_o      = 1'b1;
            //flush_commit_o  = 1'b1;
        end
    end

endmodule
        
