// Logs every register-file write (excluding x0) as:  x<rd> 0x<value>
// One line per retired instruction, in program order. Testbench only.
//
// Hook it up inside system_tb.sv (adjust the hierarchical paths to your design;
// after the refactor the register file interface may live in wb_stage):
//
//   rf_monitor #(.FILE("cpu0_rfwrites.log")) rfmon0 (
//     .CLK   (DUT.CPU.DP.CLK),
//     .WEN   (DUT.CPU.DP.rfif.WEN),
//     .wsel  (DUT.CPU.DP.rfif.wsel),
//     .wdat  (DUT.CPU.DP.rfif.wdat),
//     .retire(DUT.CPU.DP.advance),
//     .pchalt(DUT.CPU.DP.mem_wb_q.pchalt)
//   );
//
// "retire" must be high exactly once per instruction leaving WB. The expression
// above is the pipeline's own "advance" condition from the old latch block; if
// stalls (cache misses, load-use) create duplicate or missing lines, this is the
// first thing to check. Use the actual advance signal if you now have one.
module rf_monitor #(parameter string FILE = "rf_writes.log") (
  input logic        CLK,
  input logic        WEN,
  input logic [4:0]  wsel,
  input logic [31:0] wdat,
  input logic        retire,
  input logic        pchalt
);
  int fd;
  string log_file;
  logic halt_seen;

  initial begin
    log_file = FILE;
    void'($value$plusargs("RF_LOG=%s", log_file));
    fd = $fopen(log_file, "w");
    halt_seen = 1'b0;
  end

  // The register file writes on negedge CLK, so sample on the same edge.
  always @(negedge CLK) begin
    if (pchalt)
      halt_seen <= 1'b1;
    if (WEN && wsel != 5'd0 && retire && !halt_seen && !pchalt)
      $fdisplay(fd, "x%0d 0x%08x", wsel, wdat);
  end

  final $fclose(fd);
endmodule
