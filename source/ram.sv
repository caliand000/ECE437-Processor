/*
  Eric Villasenor
  evillase@gmail.com

  ram with variable latency
*/

// interface
`include "cpu_ram_if.vh"
// types
`include "cpu_types_pkg.vh"

module ram (input logic CLK, nRST, cpu_ram_if.ram ramif);
  // import types
  import cpu_types_pkg::*;

  parameter BAD = 32'hBAD1BAD1, LAT = 2;

  logic [3:0]   count;
  ramstate_t    rstate;
  word_t        q, addr = 0;
  word_t        memory [0:16383];
  logic         wren;
  logic [1:0]   en;

  initial $readmemh("meminit.hex", memory);

  assign q = memory[ramif.ramaddr[15:2]];

  always_ff @(posedge CLK)
  begin
    if (wren)
      memory[ramif.ramaddr[15:2]] <= ramif.ramstore;
  end

  assign ramif.ramload = (rstate == ACCESS) ? q : BAD;
  assign wren = (rstate == ACCESS) ? ramif.ramWEN : 0;
  assign ramif.ramstate = rstate;

  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
    begin
      count <= 0;
      addr <= 0;
      en <= 3;
    end
    else if (
      !(ramif.ramREN || ramif.ramWEN) ||
      ramif.ramaddr != addr ||
      en != {ramif.ramREN, ramif.ramWEN}
    )
    begin
      en  <= {ramif.ramREN, ramif.ramWEN};
      count <= 0;
      addr <= ramif.ramaddr;
    end
    else if ((ramif.ramREN || ramif.ramWEN) && count < LAT)
    begin
      count <= count + 1;
    end
  end

  always_comb
  begin
    casez({ramif.ramWEN,ramif.ramREN,nRST})
      3'b00z:   rstate = FREE;
      3'b011,
      3'b101:   rstate = BUSY;
      default:  rstate = ERROR;
    endcase
    if (!nRST || ((addr == ramif.ramaddr) && ((ramif.ramREN || ramif.ramWEN) && (count >= LAT))))
    begin
      rstate = ACCESS;
    end
  end

endmodule
