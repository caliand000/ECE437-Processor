/*
  Andrew Cali
  acali@purdue.edu

  ALU Test Bench
*/

// Include necessary package
`include "cpu_types_pkg.vh"
`include "forward_unit_if.vh"
// Define timing
`timescale 1 ns / 1 ns

module forward_unit_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, forward_unit_tb);
  end

  parameter PERIOD = 10;


  
  import cpu_types_pkg::*;
  // Clock generation
    forward_unit_if fuif();
    
  // DUT (Device Under Test) instantiation
  `ifndef MAPPED
  forward_unit DUT(fuif);
`else
  forward_unit DUT (
    .\fuif.rs1(fuif.rs1),
    .\fuif.rs2(fuif.rs2),
    .\fuif.Rd_Mem(fuif.Rd_Mem),
    .\fuif.Rd_WB(fuif.Rd_WB),
    .\fuif.RegWR_mem(fuif.RegWR_mem),
    .\fuif.RegWR_WB(fuif.RegWR_WB),
    .\fuif.Alu_in1(fuif.Alu_in1),
    .\fuif.Alu_in2(fuif.Alu_in2)
  );
`endif
  // Test procedure
  initial begin
    // Initial reset
    fuif.rs1=0;
    fuif.rs2=0;
    fuif.Rd_Mem=0;
    fuif.Rd_WB=0;
    fuif.RegWR_mem=0;
    fuif.RegWR_WB=0;
    #(PERIOD)

    // Test case 1: ADD operation
    fuif.rs1=10;fuif.Rd_Mem=10;fuif.RegWR_mem=1;
    
    #(PERIOD);
    assert(fuif.Alu_in1 == 2'b10) else $display("failed %t", $time);
    fuif.Rd_Mem=0;
    fuif.rs1=10;fuif.Rd_WB=10;fuif.RegWR_WB=1;
    
    #(PERIOD);
    assert(fuif.Alu_in1 == 2'b01) else $display("failed %t", $time);
    fuif.Rd_Mem=0;
    fuif.rs1=10;fuif.Rd_WB=5;fuif.RegWR_WB=1;
   

     #(PERIOD)
      assert(fuif.Alu_in1 == 2'b00) else $display("failed %t", $time);
    fuif.Rd_WB=0;
    // Test case 1: ADD operation
    fuif.rs2=10;fuif.Rd_Mem=10;fuif.RegWR_mem=1;
    
    #(PERIOD);
    assert(fuif.Alu_in2 == 2'b10) else $display("failed %t", $time);
    fuif.Rd_Mem=0;
    fuif.rs2=10;fuif.Rd_WB=10;fuif.RegWR_WB=1;
    
    #(PERIOD);
    assert(fuif.Alu_in2 == 2'b01) else $display("failed %t", $time);
    fuif.Rd_Mem=0;
    fuif.rs2=10;fuif.Rd_WB=5;fuif.RegWR_WB=1;
    
    #(PERIOD);
    assert(fuif.Alu_in2 == 2'b00) else $display("failed %t", $time);
    // Finish simulation
    $finish;
  end
  endmodule