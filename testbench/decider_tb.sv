`include "decider_if.vh"

`timescale 1 ns / 1 ns

module decider_tb;
  decider_if deif();
  decider DUT(deif);

  initial begin
    // Exercise each redirect class and leave a clear terminal result.
    $dumpfile("module.vcd");
    $dumpvars(0, decider_tb);
    deif.Zero = 0;
    deif.Negative = 0;
    deif.typ = 8'b0;
    check(8'b00000010, 2'b01, "JAL");
    check(8'b00000001, 2'b10, "JALR");
    check(8'b10000000, 2'b01, "BEQ taken");
    check(8'b10000000, 2'b00, "BEQ not taken");
    check(8'b01000000, 2'b01, "BNE taken");
    check(8'b01000000, 2'b00, "BNE not taken");
    $display("DECIDER TESTS PASSED");
    $finish;
  end

  task automatic check(input logic [7:0] typ, input logic [1:0] expected, input string name);
    begin
      deif.typ = typ;
      deif.Zero = (name == "BEQ not taken" || name == "BNE taken") ? 1'b0 : 1'b1;
      #1;
      if (deif.PCsrc !== expected)
        $display("FAILED: %s actual=%b expected=%b", name, deif.PCsrc, expected);
    end
  endtask
endmodule
