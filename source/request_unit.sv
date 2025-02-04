/*
  Andrew Cali
  acali@purdue.edu

  contains request logic for interacting with caches/memory control
*/

// data path interface
`include "control_request_unit_if.vh"

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"

module request_unit (
  input logic CLK, nRST,
  control_request_unit_if.ru ruif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;


  always_ff @ (posedge CLK, negedge nRST) begin
    if(!nRST) begin
      ruif.dmemREN <= 0;
      ruif.dmemWEN <= 0;
    end
    else begin
      if(ruif.dhit) begin
        ruif.dmemREN <= 0;
        ruif.dmemWEN <= 0;
      end
      else if(ruif.MemWr == 2'b01 && ruif.ihit) ruif.dmemWEN <= 1;
      else if(ruif.MemWr == 2'b10 && ruif.ihit) ruif.dmemREN <= 1;
    end
  end

  assign ruif.dmemstore = ruif.rdat2;
  assign ruif.dmemaddr = ruif.Aluout;
  assign ruif.imemREN = 1'b1;
endmodule
