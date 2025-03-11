`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "datapath_cache_if.vh"
`include "cpu_ram_if.vh"
`include "cache_control_if.vh"
// types
`include "cpu_types_pkg.vh"


module dcache_tb;

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;

  // Interface signals
  caches_if cif();
  datapath_cache_if dcif();
  cpu_ram_if prif ();
  cache_control_if ccif ();

  // DUT instances
  icache DUT(.CLK(CLK), .nRST(nRST), .dcif(dcif), .cif(cif));

  // memory
  ram RAM (CLK, nRST, prif);

  memory_control MEMCTRL (CLK, nRST, ccif);

  // Clock generation
  always #(PERIOD / 2) CLK = ~CLK;

  

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

  task check_output;
    input word_t exp_dmemload;
    
    input string case_info;
    
    begin
        if ((exp_dmemload == dcif.dmemload))
        begin
            $display("Passed test case: %s", case_info);
        end
        else
        begin
            $display("Failed : %s", case_info);
            $display("Actual: %d; Expected: %d MemWr", dcif.dmemload, exp_dmemload);
            $display("Actual: %d; Expected: %d MemWr", dcif.flushed, exp_flushed);
        end
        #(0.1ns);

      
    end
endtask

  initial begin

    //initialize interface ports
    dcif.halt = 0;
    dcif.dmemREN = 0;
    dcif.dmemWEN = 0;
    dcif.dmemstore = '0;
    dcif.dmemaddr = '0;

    reset_if();
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h0F006213
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h10006513
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h20006593
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h30006613;
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h40006693;
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00022703;
    @(posedge CLK);
    @(posedge CLK);
    prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00422783;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00822283;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h50006613;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h60006693;
    @(posedge CLK);
    @(posedge CLK);
      prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00E52023;
    @(posedge CLK);
    @(posedge CLK);
      prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00F52223;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00552423;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'hFFFFFFFF;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00007337;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00002701;
    @(posedge CLK);
    @(posedge CLK);
     prif.ramWEN=1;
    prif.ramaddr=0;
    prif.ramstore=32'h00001337;
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    @(posedge CLK);
    word_t i;
    for(i=0;i<17;i++) begin
    dcif.imemREN=1;
    @(posedge CLK);
    @(posedge CLK);
    end

    reset_if();


    $finish;
  end
endmodule
