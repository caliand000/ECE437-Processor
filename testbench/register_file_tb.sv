/*
  Eric Villasenor
  evillase@gmail.com

  register file test bench
*/

// mapped needs this
`include "register_file_if.vh"

// mapped timing needs this. 1ns is too fast
`timescale 1 ns / 1 ns

module register_file_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, register_file_tb);
  end

  parameter PERIOD = 10;

  logic CLK = 0, nRST;
  // logic [31:0] wdat, rdat1, rdat2;
  // logic wen;
  // logic [4:0] wsel, rsel1, rsel2;

  // test vars

  // clock
  // Nonblocking clock update avoids a sequential blocking-assignment warning.
  always #(PERIOD/2) CLK <= ~CLK;

  // interface
  register_file_if rfif ();

  // test program
  // test #(.PERIOD (PERIOD)) PROG (
  //   .CLK,
  //   .nRST,
  //   .wdat,
  //   .wsel,
  //   .wen,
  //   .rsel1,
  //   .rsel2
  // );

  // DUT
`ifndef MAPPED
  register_file DUT(CLK, nRST, rfif);
`else
  register_file DUT(
    .\rfif.rdat2 (rfif.rdat2),
    .\rfif.rdat1 (rfif.rdat1),
    .\rfif.wdat (rfif.wdat),
    .\rfif.rsel2 (rfif.rsel2),
    .\rfif.rsel1 (rfif.rsel1),
    .\rfif.wsel (rfif.wsel),
    .\rfif.WEN (rfif.WEN),
    .\nRST (nRST),
    .\CLK (CLK)
  );
`endif

initial 
begin

  nRST = 1'b0;
  #(PERIOD)
  nRST = 1'b1;
  #(PERIOD)
  rfif.wdat = '0;
  rfif.wsel = '0;
  rfif.WEN = 0;
  rfif.rsel1 = '0;
  rfif.rsel2 = '0;

  #(PERIOD)
  rfif.wdat = 32'hDEADBEEF;
  rfif.wsel = 5'b00001;
  rfif.WEN = 1'b1;
  #(PERIOD)
  rfif.WEN = 1'b0;
  rfif.rsel1 = 5'b00001;
  #(PERIOD)

  assert(rfif.rdat1 == 32'hdeadbeef) else $display("Test failed: Expected 0xDEADBEEF at register 1, got %h", rfif.rdat1);
  

  rfif.wdat = 32'hDEADBEEF;
  rfif.wsel = 5'b00000;
  rfif.WEN = 1'b1;
  #(PERIOD)
  rfif.WEN = 1'b0;
  rfif.rsel1 = 5'b00000;
  #(PERIOD)
  assert(rfif.rdat1 == 32'h00000000) else $display("Test failed: Expected 0x00000000 at register 1, got %h", rfif.rdat1);

  rfif.wdat = 32'hBEEFDEAD;
  rfif.wsel = 5'b11111;
  rfif.WEN = 1'b1;
  #(PERIOD)
  rfif.WEN = 1'b0;
  rfif.rsel1 = 5'b11111;
  #(PERIOD)
  assert(rfif.rdat1 == 32'hbeefdead) else $display("Test failed: Expected 0xBEEFDEAD at register 1, got %h", rfif.rdat1);

  #(PERIOD)
  rfif.wdat = 32'hDADABEBE;
  rfif.wsel = 5'b00010;

  #(PERIOD);

  nRST = 1'b0;
  #(PERIOD)
  nRST = 1'b1;
  #(PERIOD)


  $finish;
end
endmodule

// program test(
//   input logic CLK,
//   output logic nRST, wdat, wsel, wen, rsel1, rsel2
// );
//   parameter PERIOD = 10;
//   initial begin
//     $monitor("@%00g WDAT = %b nRST = %b rdat1 = %b rdat2 = %0d",
//       $time, wdat, nRST, rdat1, rdat2);

      // wdat = '0;
      // wsel = '0;
      // wen = 0;
      // rsel1 = '0;
      // rsel2 = '0;
      // #(PERIOD)
      // wdat = 32'hDEADBEEF;
      // wsel = 5'b00001;
      // wen = 1'b1;
      // #(PERIOD)
      // wen = 1'b0;
      // rsel1 = 5'b00001;
      // #(PERIOD)
      
//       $finish;
//   end
// endprogram
