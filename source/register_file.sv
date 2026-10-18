
`include "cpu_types_pkg.vh"

module register_file
import cpu_types_pkg::*;
(
  input  logic     CLK,
  input  logic     nRST,
  input  logic     WEN,
  input  regbits_t wsel,
  input  regbits_t rsel1,
  input  regbits_t rsel2,
  input  word_t    wdat,
  output word_t    rdat1,
  output word_t    rdat2
);

  word_t [31:0] register;

  always_ff @(negedge CLK, negedge nRST)
  begin
    if(!nRST)
    begin
      register <= '0;
    end
    else begin
      if(wsel != 0 && WEN)begin
        register[wsel] <= wdat;
      end
    end
    register[0] <= '0;
  end

  //0th location consant value of 0
  //assign register[0] = '0;

  //read ports
  assign rdat1 = register[rsel1];
  assign rdat2 = register[rsel2];

endmodule
