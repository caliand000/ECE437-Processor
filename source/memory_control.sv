/*
  Eric Villasenor
  evillase@gmail.com

  this block is the coherence protocol
  and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
  input CLK, nRST,
  cache_control_if.cc ccif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  parameter CPUS = 1;

  word_t addr = 0; 

  assign ccif.dload = (ccif.dREN && (ccif.ramstate == ACCESS))? ccif.ramload:addr;                   //load dload from ram during access state
  assign ccif.iload = ((ccif.iREN && !(ccif.dWEN || ccif.dREN))  && (ccif.ramstate == ACCESS))? ccif.ramload: addr;                                              //load ramload into iload during access state?
  assign ccif.ramaddr = (ccif.dREN || ccif.dWEN)? ccif.daddr : (ccif.iREN)? ccif.iaddr: addr;                   //ram address stores instruction address 
  assign ccif.ramstore = (ccif.dWEN)? ccif.dstore: addr;

  assign ccif.iwait = (ccif.iload)? 1'b0: 1'b1;
  assign ccif.dwait = (ccif.dREN || ccif.dWEN && (ccif.ramstate == ACCESS))? 1'b0: 1'b1;

  assign ccif.ramWEN = (ccif.dWEN)? 1'b1: 1'b0;
  assign ccif.ramREN = (ccif.ramWEN)? 1'b0: 1'b1;


endmodule
