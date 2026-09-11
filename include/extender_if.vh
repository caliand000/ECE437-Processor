/*
  Eric Villasenor
  evillase@gmail.com

  register file interface
*/
`ifndef EXTENDER_IF_VH
`define EXTENDER_IF_VH

// all types
`include "cpu_types_pkg.vh"

interface extender_if;
  // import types
  import cpu_types_pkg::*;

  word_t imemload,extended_im;

  // ALU ports
  modport ex (
    input   imemload,
    output  extended_im
  );
  // ALU tb
  modport tb (
    input   extended_im,
    output  imemload
  );
endinterface

`endif //ALU_IF_VH
