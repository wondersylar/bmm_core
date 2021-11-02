


module data_ram
  #(
    parameter ADDR_WIDTH = 8,
    parameter DATA_WIDTH = 32,
    parameter NUM_BYTES  = 256
  )(
    // Clock and Reset
    input  logic                    clk_i,
    input  logic                    rst_ni,

    input  logic                    en_i,
    input  logic [ADDR_WIDTH-1:0]   addr_i,
    input  logic [DATA_WIDTH-1:0]   wdata_i,
    output logic [DATA_WIDTH-1:0]   rdata_o,
    input  logic                    we_i,
    input  logic [DATA_WIDTH/8-1:0] be_i
  );


    reg[DATA_WIDTH-1:0] mem[NUM_BYTES/4];

    logic [29:0] addr;
    assign addr = addr_i[31:2];

    always @ (posedge clk_i or negedge rst_ni) begin
        if(!rst_ni)
            mem <= '{default:0};
        else if (we_i && en_i) begin
            mem[addr] <= wdata_i;
            //mem[addr_i[31:2]] <= wdata_i;
        end
    end

    assign rdata_o = mem[addr_i[31:2]];

endmodule
