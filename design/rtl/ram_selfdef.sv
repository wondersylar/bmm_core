module ram_selfdef
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_BYTES  = 256
  )(
    // Clock and Reset
    input  logic                    clk_i,

    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [ADDR_WIDTH-1:0]   addr2_i,  //for instr_fetch
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata1_o,
    output logic [DATA_WIDTH-1:0]   rdata2_o, //for instr_fetch
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i
  );

  localparam blocks = NUM_BYTES/(DATA_WIDTH/8);

  logic [DATA_WIDTH/8-1:0][7:0] mem[blocks];            //blocks * (n*8bit)
  logic [DATA_WIDTH/8-1:0][7:0] wdata;                  //n*8bit
  logic [ADDR_WIDTH-1-$clog2(DATA_WIDTH/8):0] addr,addr2;     //addr for blocks, low $clog2(DATA_WIDTH/8) bits are 0



  assign addr = addr_i[ADDR_WIDTH-1:$clog2(DATA_WIDTH/8)];
  assign addr2 = addr2_i[ADDR_WIDTH-1:$clog2(DATA_WIDTH/8)];

  genvar w;
  generate for(w = 0; w < DATA_WIDTH/8; w++)
      assign wdata[w] = wdata_i[(w+1)*8-1:w*8];
  endgenerate

  always @(posedge clk_i) begin
    if (en_i && we_i) begin
      for (int unsigned i = 0; i < DATA_WIDTH/8; i++) begin
        if (be_i[i])
          mem[addr][i] <= wdata[i];
      end
    end
  //rdata_o <= mem[addr];
  end




  assign rdata1_o = mem[addr];
  assign rdata2_o = mem[addr2];


  
endmodule


