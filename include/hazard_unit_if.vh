/*
  Andrew Cali
  acali@purdue.edu

  holds control and request unit interface signals
*/
`ifndef HAZARD_UNIT_IF_VH
`define HAZARD_UNIT_IF_VH


// types
`include "cpu_types_pkg.vh"

interface hazard_unit_if;
  // import types
  import cpu_types_pkg::*;

  //signals
    regbits_t rs1, rs2;
    regbits_t Rd;
    logic Flush,Zero_controls,Halt,latch_en,Pcsrc,Memtoreg; 

  // control unit ports
  modport hu (
    input  rs1, rs2, Rd,Pcsrc,Memtoreg,
    output Flush,Zero_controls,Halt,latch_en;
  );



endinterface

`endif