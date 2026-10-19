`include "datapath_cache_if.vh"

// Synthesis-only test harness for generating a standalone schematic of
// datapath.sv. Not part of the simulated/golden design -- exists purely to
// give Yosys/netlistsvg real input and output ports so `opt` has observable
// fanout to keep instead of stripping the whole datapath as dead logic.
module datapath_synth_wrapper (
  input  logic CLK, nRST,

  // cache-side stimulus into the datapath (mirrors dcif.dp modport inputs)
  input  logic ihit, dhit,
  input  logic [31:0] imemload, dmemload,

  // datapath outputs driven out for visibility (mirrors dcif.dp modport outputs)
  output logic halt, imemREN, dmemREN, dmemWEN, datomic,
  output logic [31:0] imemaddr, dmemstore, dmemaddr
);
  datapath_cache_if dcif();

  assign dcif.ihit     = ihit;
  assign dcif.dhit     = dhit;
  assign dcif.imemload = imemload;
  assign dcif.dmemload = dmemload;

  assign halt      = dcif.halt;
  assign imemREN   = dcif.imemREN;
  assign imemaddr  = dcif.imemaddr;
  assign dmemREN   = dcif.dmemREN;
  assign dmemWEN   = dcif.dmemWEN;
  assign datomic   = dcif.datomic;
  assign dmemstore = dcif.dmemstore;
  assign dmemaddr  = dcif.dmemaddr;

  datapath DP (CLK, nRST, dcif);
endmodule
