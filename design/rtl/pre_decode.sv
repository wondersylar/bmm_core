

module pre_decode (

  input  logic [31:0]   instr_data_i,
  input  logic          instr_vld_i,
  output logic          jump_o,
  //output logic          branch_pd_jump_o,
  output logic          call_o,
  output logic          return_o

  );
    
    logic instr_branch ;

    assign instr_branch = (instr_data_i[6:0] == OPCODE_BRANCH);
    //branch predict to jump backward 
    //assign branch_pd_jump_o = instr_vld_i && (instr_branch & instr_data_i[31]); 
    //jump backward or jal/jalr
    //assign jump_o = instr_vld_i && ((instr_branch & instr_data_i[31]) || (instr_data_i[6:0] == OPCODE_JAL) || (instr_data_i[6:0] == OPCODE_JALR));
    assign jump_o = instr_vld_i && ((instr_data_i[6:0] == OPCODE_JAL) || (instr_data_i[6:0] == OPCODE_JALR));
    //assign call_o = instr_vld_i && (instr_data_i[6:0] == OPCODE_JAL || instr_data_i[6:0] == OPCODE_JALR) && (instr_data_i[11:7] == 5'h1 || instr_data_i[11:7] == 5'h5) ;
    //assign return_o = instr_vld_i && (instr_data_i[6:0] == OPCODE_JALR) && (instr_data_i[19:15] == 5'h1 || instr_data_i[19:15] == 5'h5);
    assign call_o = instr_vld_i && 
                   ((instr_data_i[6:0] == OPCODE_JAL) || 
                   (instr_data_i[6:0] == OPCODE_JALR && (instr_data_i[11:7] == 5'h1 || instr_data_i[11:7] == 5'h5))) ;
    assign return_o = instr_vld_i && 
                     (instr_data_i[6:0] == OPCODE_JALR) && 
                     (instr_data_i[19:15] == 5'h1 || instr_data_i[19:15] == 5'h5) && 
                     ~(instr_data_i[11:7] == instr_data_i[19:15]);


endmodule
