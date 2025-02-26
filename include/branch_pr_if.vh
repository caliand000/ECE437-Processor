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
  logic Br_PC,mispredict;
  logic [7:0] PC_fet;
  word_t PC_mem;
  word_t  branch_PC, target, adderout;

  // control unit ports
  modport bp (
    input  PCSrc, PC_fet, PC_mem, branch_PC, opcode, adderout,mispredict,
    output Br_PC, target
  );



endinterface

`endif