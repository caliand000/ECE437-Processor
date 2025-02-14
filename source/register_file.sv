
`include "cpu_types_pkg.vh"
`include "register_file_if.vh"

module register_file
import cpu_types_pkg::*;
//import register_file_if::*;
(
  input logic CLK, nRST, 
  register_file_if.rf rfif
);

  word_t [31:0] register;

  always_ff @(negedge CLK, negedge nRST)
  begin
    if(!nRST)
    begin
      register <= '0;
    end
    else begin
      if(rfif.wsel != 0 && rfif.WEN)begin
        register[rfif.wsel] <= rfif.wdat;
      end
    end
    register[0] <= '0;
  end

  //0th location consant value of 0
  //assign register[0] = '0;

  //read ports
  assign rfif.rdat1 = register[rfif.rsel1];
  assign rfif.rdat2 = register[rfif.rsel2];

endmodule
