/*
  Andrew Cali
  acali@purdue.edu

  holds control and request unit interface signals
*/
`ifndef CONTROL_REQUEST_UNIT_IF_VH
`define CONTROL_REQUEST_UNIT_IF_VH


// types
`include "cpu_types_pkg.vh"

interface control_request_unit_if;
  // import types
  import cpu_types_pkg::*;

  //signals
  aluop_t Aluop;

  logic zero, neg, overflow, MemtoReg, AluSrc, RegWr, pchalt, 
          dhit, ihit, imemREN, dmemREN, dmemWEN,lr,sc;

  logic [4:0] Rd, Rs1, Rs2;
  logic [7:0] typ;
  word_t Imm, rdat2, Aluout, imemaddr, imemload, dmemstore, dmemaddr, dmemload;

  logic [1:0] PCSrc, MemWr, jumpsel;

  // control unit ports
  modport cu (
    input   zero, neg, overflow, imemload,
    output  MemtoReg, MemWr, Aluop, AluSrc, RegWr, Rd, Rs1, Rs2, 
            Imm, PCSrc, jumpsel, pchalt,typ,lr,sc
  );

    // request unit ports
  modport ru (
    input   rdat2, Aluout, MemWr, dhit, ihit,
    output  imemREN, imemaddr, dmemREN, dmemWEN, dmemstore, 
              dmemload, dmemaddr
  );

endinterface

`endif //CACHES_IF_VH