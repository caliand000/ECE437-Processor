/*
  Andrew Cali
  acali@purdue.edu

  ALU Test Bench
*/

// Include necessary package
`include "cpu_types_pkg.vh"
`include "hazard_unit_if.vh"
// Define timing
`timescale 1 ns / 1 ns

module hazard_unit_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, hazard_unit_tb);
  end

  parameter PERIOD = 10;


  
  import cpu_types_pkg::*;
  // Clock generation
    hazard_unit_if huif();
    
  // DUT (Device Under Test) instantiation
  `ifndef MAPPED
  hazard_unit DUT(huif);
`else
  hazard_unit DUT (
    .\huif.rs1(huif.rs1),
    .\huif.rs2(huif.rs2),
    .\huif.Rd(huif.Rd),
    .\huif.Pcsrc(huif.Pcsrc),
    .\huif.Memtoreg(huif.Memtoreg),
    .\huif.Flush(huif.Flush),
    .\huif.Zero_controls(huif.Zero_controls),
    .\huif.Halt(huif.Halt),
    .\huif.latch_en(huif.latch_en),
  );
`endif
  // Test procedure
  initial begin
    // Initial reset
    huif.rs1=0;
    huif.rs2=0;
    huif.Rd = 0;
    huif.Pcsrc = 0;
    huif.Memtoreg = 0;

    #(PERIOD)

    // Test case 1: Read register following a load instruction that writes the same register
    huif.rs1 = 2;
    huif.Rd = 2;
    huif.Memtoreg = 1'b1;
    huif.Pcsrc = 2'b01;
    #(PERIOD);
    assert(huif.Halt == 1'b1) else $display("failed %t read register after write to same", $time);
    assert(huif.Zero_controls == 1'b1) else $display("failed %t", $time);
    
    // Test case 2: taking a branch
    // huif.Pcsrc = 2'b01;
    #(PERIOD);
    // huif.Pcsrc = 2'b00;
    assert(huif.Flush == 1'b1) else $display("failed %t taking branch", $time);
    assert(huif.Halt == 1'b1) else $display("failed %t", $time);
    assert(huif.Zero_controls == 1'b1) else $display("failed %t", $time);
    
    // Test case 3: Normal execution writing back to register file 
    huif.Pcsrc = 2'b00;
    huif.rs1 = 2;
    huif.Rd = 1;
    huif.Memtoreg = 1'b1;
    #(PERIOD)
    assert(huif.Halt == 1'b0) else $display("failed %t normal execution", $time);
    assert(huif.Zero_controls == 1'b0) else $display("failed %t", $time);

    // Test case 4: Normal execution writing to memory (sw) 
    huif.Pcsrc = 2'b00;
    huif.rs1 = 3;
    huif.Memtoreg = 1'b0;
    #(PERIOD)
    assert(huif.Halt == 1'b0) else $display("failed %t", $time);
    assert(huif.Zero_controls == 1'b0) else $display("failed %t", $time);

    // Test case 5: Normal execution not taking a branch
    huif.Pcsrc = 2'b00;
    #(PERIOD);
    assert(huif.Flush == 1'b0) else $display("failed %t", $time);
    assert(huif.Halt == 1'b0) else $display("failed %t", $time);
    assert(huif.Zero_controls == 1'b0) else $display("failed %t", $time);

    // Finish simulation
    $finish;
  end
  endmodule