/*
  Eric Villasenor
  evillase@gmail.com

  register file interface
*/
`ifndef DECIDER_IF_VH
`define DECIDER_IF_VH

// all types
`include "cpu_types_pkg.vh"

interface decider_if;
  // import types
  import cpu_types_pkg::*;

  logic     Zero,Negative;
<<<<<<< HEAD
  
=======
  logic [1:0] PCsrc;
>>>>>>> 0d7ec67ac6435c4f999f8535675111fffcd68007
  
  logic [7:0] typ;
  logic [1:0] PCsrc;

  // ALU ports
  modport de (
    input   Zero,Negative,typ,
    output  PCsrc
  );
  // ALU tb
  modport tb (
    input   PCsrc,
    output  Zero,Negative,typ
  );
endinterface

`endif //ALU_IF_VH
