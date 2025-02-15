/*
  Andrew Cali
  acali@purdue.edu

  holds control and request unit interface signals
*/
`ifndef FORWARD_UNIT_IF_VH
`define FORWARD_UNIT_IF_VH


// types
`include "cpu_types_pkg.vh"

interface forward_unit_if;
  // import types
  import cpu_types_pkg::*;

  //signals
    regbits_t rs1, rs2;
    regbits_t Rd_Mem, Rd_WB, RegWR_mem, RegWR_WB;
    logic [1:0] Alu_in1, Alu_in2;

  // control unit ports
  modport fu (
    input  rs1, rs2, Rd_Mem, RegWR_Mem, RegWR_WB, Rd_WB;
    output Alu_in1, Alu_in2;
  );



endinterface

`endif