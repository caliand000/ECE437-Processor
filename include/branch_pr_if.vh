/*
  Andrew Cali
  acali@purdue.edu

  holds branch predictor interface signals
*/
`ifndef BRANCH_PR_IF_VH
`define BRANCH_PR_IF_VH


// types
`include "cpu_types_pkg.vh"

interface branch_pr_if;
  // import types
  import cpu_types_pkg::*;

  //signals
  logic [1:0] PCSrc;
  logic [6:0] opcode;
  logic Br_PC;
  word_t PC, old_PC;

  // control unit ports
  modport bp (
    input  PCSrc, PC, opcode, old_PC,
    output Br_PC
  );



endinterface

`endif