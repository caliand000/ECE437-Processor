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
  
  caches_if cif0();
  caches_if cif1();
  datapath_cache_if dcif();
  cpu_ram_if prif ();
  cache_control_if ccif (cif0,cif1);

  // DUT instances
  dcache DUT(.CLK(CLK), .nRST(nRST), .dcif(dcif), .cif(cif0));

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
    input logic exp_flushed;
    input string case_info;
    
    begin
        if ((exp_dmemload == dcif.dmemload) && (exp_flushed == dcif.flushed))
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

    // **********************************
    // Test Case 1: Basic Cache Hit
    // **********************************
    @(posedge CLK);
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'h00000008;
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;
    #(PERIOD);

    dcif.dmemREN = 1'b1;
    dcif.dmemaddr = 32'h00000008;
    @(posedge dcif.dhit);
    check_output(32'hadadbf00,0,"Basic Cache Hit");

    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 2: 2-way Associative Mapping Verification
    // **********************************
    @(posedge CLK);
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'h00000018;     //writing to index 3
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemaddr = 32'h00000018;     //writing to index 3
    dcif.dmemstore = 32'hfaad1234;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;

    #(PERIOD);

    dcif.dmemREN = 1'b1;
    dcif.dmemaddr = 32'h0000001c;   //reading first block
    @(posedge dcif.dhit);
    check_output(32'hfaad1234,0,"2-Way Mapping Associative Verification first value");

    @(posedge CLK);

    dcif.dmemaddr = 32'h00000018;   //reading second block
    @(posedge dcif.dhit);
    check_output(32'hadadbf00,0,"2-Way Mapping Associative Verification second value");

    @(posedge CLK);
    reset_if();


    // **********************************
    // Test Case 3: Block Eviction
    // **********************************
    @(posedge CLK);
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'h00000010;       //writing to index 2
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemaddr = 32'h00000010;       //writing to index 2
    dcif.dmemstore = 32'hfaad1234;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemaddr = 32'h00000010;       //writing to index 2, this should evict old block ()
    dcif.dmemstore = 32'hffffffff;

    @(posedge dcif.dhit);
    @(posedge CLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;

    #(PERIOD);

    dcif.dmemREN = 1'b1;
    dcif.dmemaddr = 32'h0000001c;   //reading first block
    @(posedge dcif.dhit);
    check_output(32'hfaad1234,0,"Block Eviction");

    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 4: Duplicate Hit Counts
    // **********************************
    @(posedge CLK);
    dcif.dmemWEN = 1'b1;
    dcif.dmemaddr = 32'h00000050;       //writing to index 5
    dcif.dmemstore = 32'hbabababa;

    @(posedge dcif.dhit);
    @(posedge CLK);

    
    @(posedge CLK);
    reset_if();


    $finish;
  end
endmodule
