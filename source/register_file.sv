'include "cpu_types_pkg.vh"
'include "register_file_if.vh"

module register_file
import cpu_types_pkg::*;
import register_file_if::*;
(
  input logic CLK, nRST, 
  register_file_if.rf myif
);

  logic [31:0] reg [31:0];
  logic [31:0] nreg [31:0];

  always_ff @(posedge CLK, negedge nRST)
  begin
    if(!nRST)
    begin
      reg <= '0;
    end
    else
    begin
      reg <= nreg;
    end
  end

  always_comb 
  begin
    if(myif.WEN)
    begin 
      nreg[myif.wsel] = myif.wdat; 
    end

    myif.rdat1 = reg[myif.rsel1];
    myif.rdat2 = reg[myif.rsel2];


  end
endmodule
