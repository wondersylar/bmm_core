// Copyright 2017 ETH Zurich and University of Bologna.
// Copyright and related rights are licensed under the Solderpad Hardware
// License, Version 0.51 (the “License”); you may not use this file except in
// compliance with the License.  You may obtain a copy of the License at
// http://solderpad.org/licenses/SHL-0.51. Unless required by applicable law
// or agreed to in writing, software, hardware and materials distributed under
// this License is distributed on an “AS IS” BASIS, WITHOUT WARRANTIES OR
// CONDITIONS OF ANY KIND, either express or implied. See the License for the
// specific language governing permissions and limitations under the License.


// This module takes data over UART and prints them to the console
// A string is printed to the console as soon as a '\n' character is found

`timescale 1ps/1ps    //fix modelsim and vcs simulation difference, add by frank 
interface uart_bus
  #(
    parameter BAUD_RATE = 115200,
    parameter PARITY_EN = 0
    )
  (
    input  logic rx,
    output logic tx,

    input  logic rx_en
  );

  localparam BIT_PERIOD = (1000000000/BAUD_RATE*1000);

  logic [7:0]       character;
  logic [256*8-1:0] stringa="";
  logic             parity;
  integer           charnum=0;
  integer           file;
  logic             loopback_en=1'b0;
  logic [7:0]       backup=8'h00;
  logic             loop_clk=1'b0;
  logic             echo=1'b1;
  logic             byte_display_en=1'b0;

  initial
  begin
    tx=1'b1;
    byte_display_en=1'b0;
    loopback_en=1'b0;
    loop_clk=1'b0;
    backup=1'b0;
    echo=1'b1;
    file = $fopen("./stdout_uart", "w");
  end

  always
  begin
    if (rx_en)
    begin
      @(negedge rx);
      
      // reset loopback clk
      if (loopback_en)
        loop_clk = 1'b0;

      #(BIT_PERIOD/2) ;

      for (int i=0;i<=7;i++)
      begin
        #BIT_PERIOD character[i] = rx;
      end

      if(loopback_en)
      begin
        backup = character;
        // set loopback clk
        loop_clk = 1'b1;
      end

      if(PARITY_EN == 1)
      begin
        // check parity
        #BIT_PERIOD parity = rx;

        for (int i=7;i>=0;i--)
        begin
          parity = character[i] ^ parity;
        end

        if(parity == 1'b1)
        begin
          $display("Parity error detected");
        end
      end

      // STOP BIT
      #BIT_PERIOD;
      if (echo == 1'b1) begin
        $fwrite(file, "%c", character);
        stringa[(255-charnum)*8 +: 8] = character;
        if(loopback_en == 1'b1) begin
          $fwrite(file, "%c", 8'h0A);
          charnum = 0;
          stringa = "";
        end
        if (character == 8'h0A || charnum == 254) // line feed or max. chars reached
        begin
          if (character == 8'h0A)
            stringa[(255-charnum)*8 +: 8] = 8'h0; // null terminate string, replace line feed
          else
            stringa[(255-charnum-1)*8 +: 8] = 8'h0; // null terminate string

          if(loopback_en == 1'b0) $write("RX string: %s\n",stringa);
          charnum = 0;
          stringa = "";
        end
        else
        begin
          charnum = charnum + 1;
        end
      end
    end
    else
    begin
      charnum = 0;
      stringa = "";
      #10;
    end
  end

  always begin
    @(posedge loop_clk)
    if (loopback_en)
      send_char(backup[7:0]);
  end

  task switch_loopback(input logic back, input logic put=1'b1);
    loopback_en = back;
    echo = put | ~back;
  endtask

  task send_byte_display(input logic sbd);
    byte_display_en = sbd;
  endtask

  task send_char(input logic [7:0] c, input int num=0);
    int i;

    // start bit
    tx = 1'b0;

    for (i = 0; i < 8; i++) begin
      #(BIT_PERIOD);
      tx = c[i];
      if(byte_display_en == 1'b0) $display("[UART] Sent %x at time %t",c[i],$time);
      else $display("[UART] Byte %d[%1d] %x sent at time %t",num,i,c[i],$time);
    end

    // stop bit
    #(BIT_PERIOD);
    tx = 1'b1;
    #(BIT_PERIOD);
  endtask
endinterface
