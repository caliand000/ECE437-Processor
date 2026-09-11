`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "datapath_cache_if.vh"
`include "cpu_ram_if.vh"
`include "cache_control_if.vh"
// types
`include "cpu_types_pkg.vh"


module icache_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, icache_tb);
  end

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;
  // Nonblocking clock update avoids a sequential blocking-assignment warning.
  always #(PERIOD / 2) CLK <= ~CLK;
   parameter CLKDIV = 2;
  logic CPUCLK;
  logic [3:0] count;
  //logic CPUnRST;

  always_ff @(posedge CLK, negedge nRST)
  begin
    if (!nRST)
    begin
      count <= 0;
      CPUCLK <= 0;
    end
    else if (count == CLKDIV-2)
    begin
      count <= 0;
      CPUCLK <= ~CPUCLK;
    end
    else
    begin
      count <= count + 1;
    end
  end
  // Interface signals
  caches_if cif();
  caches_if cif1();
  datapath_cache_if dcif();
  cpu_ram_if ramif ();
  cache_control_if ccif (cif,cif1);

  // DUT instances
  icache DUT(.CLK(CPUCLK), .nRST(nRST), .dcif(dcif), .cif(cif));

  // memory
  ram RAM (CLK, nRST, ramif);

  memory_control MEMCTRL (CLK, nRST, ccif);

  // Clock generation
  
  word_t i;

  // Testbench tasks
  task reset_if;
    begin
      nRST = 0;
      @(posedge CLK);
      @(posedge CLK);
      @(negedge CLK);
      nRST = 1;
      @(negedge CLK);
      @(negedge CLK);
    end
  endtask

  
  assign ccif.ramstate = ramif.ramstate;
  assign ccif.ramload = ramif.ramload;

  // assign ramif.memaddr = ccif.ramaddr;      //&*****Change back to ram if doesnt work instead of mem **************
  // assign ramif.memstore = ccif.ramstore;
  // assign ramif.memREN = ccif.ramREN;
  // assign ramif.memWEN = ccif.ramWEN;
  assign ramif.ramREN = ccif.ramREN;
  assign ramif.ramWEN = ccif.ramWEN;
  assign ramif.ramaddr = ccif.ramaddr;
  assign ramif.ramstore = ccif.ramstore;
  initial begin

    //initialize interface ports
    dcif.halt = 0;
    dcif.dmemREN = 0;
    dcif.dmemWEN = 0;
    dcif.dmemstore = '0;
    dcif.dmemaddr = '0;
    dcif.imemREN=0;
    reset_if();
    cif.dREN=0;
    cif.dWEN=0;
    cif.daddr=0;
   /* @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=0;
    cif.dstore=32'h0F006213;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=4;
    cif.dstore=32'h10006513;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=8;
    cif.dstore=32'h20006593;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=12;
    cif.dstore=32'h30006613;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=16;
    cif.dstore=32'h40006693;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=20;
    cif.dstore=32'h00022703;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=1;
    cif.daddr=24;
    cif.dstore=32'h00422783;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=28;
    cif.dstore=32'h00822283;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=32;
    cif.dstore=32'h50006613;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=36;
    cif.dstore=32'h60006693;
    @(posedge CLK);
    @(posedge CLK);
      cif.dWEN=1;
    cif.daddr=40;
    cif.dstore=32'h00E52023;
    @(posedge CLK);
    @(posedge CLK);
      cif.dWEN=1;
    cif.daddr=44;
    cif.dstore=32'h00F52223;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=48;
    cif.dstore=32'h00552423;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=52;
    cif.dstore=32'hFFFFFFFF;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=56;
    cif.dstore=32'h00007337;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=60;
    cif.dstore=32'h00002701;
    @(posedge CLK);
    @(posedge CLK);
     cif.dWEN=1;
    cif.daddr=64;
    cif.dstore=32'h00001337;
    @(posedge CLK);
    @(posedge CLK);
    cif.dWEN=0;*/
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    
    for(i=0;i<17;i++) begin
    dcif.imemREN=1;
    dcif.imemaddr=i*4;
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    
    end

    reset_if();


    $finish;
  end
endmodule
