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
