`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "datapath_cache_if.vh"
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
  // DUT instances
    dcache DUT(.CLK(CLK), .nRST(nRST), .dcif(dcif), .cif(cif));

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
    input logic exp_dhit;
    input word_t exp_dmemload;
    input logic exp_flushed;
    input logic exp_dREN, exp_dWEN;
    input word_t exp_daddr;
    input word_t exp_dstore;
    input string case_info;
    
    begin
        // Compare each signal and display results
        if ((exp_dhit == dcif.dhit) && (exp_dmemload == dcif.dmemload) && (exp_flushed == dcif.flushed) && (exp_dREN
         == cif.dREN) && (exp_dWEN == if.dWEN) && (exp_daddr == cif.daddr) && (exp_dstore == cif.dstore)) 
        begin
            $display("Passed test case: %s", case_info);
        end
        else
        begin
            $display("Failed : %s", case_info);
            // Display the expected and actual values
            $display("Actual: %d; Expected: %d MemWr", dcif.dhit, exp_dhit);
            $display("Actual: %d; Expected: %d MemWr", dcif.dmemload, exp_dmemload);
            $display("Actual: %d; Expected: %d MemWr", dcif.flushed, exp_flushed);
            $display("Actual: %d; Expected: %d MemWr", cif.dREN, exp_dREN);
            $display("Actual: %d; Expected: %d MemWr", cif.dWEN, exp_dWEN);
            $display("Actual: %d; Expected: %d MemWr", cif.daddr, exp_daddr);
            $display("Actual: %d; Expected: %d MemWr", cif.dstore, exp_dstore);
        end

        
        // Small delay for simulation stability
        #(0.1ns);

      
    end
endtask

  initial begin

    //initialize interface ports
    dcif.halt = 0;
    dcif.dmemREN = 0;
    dcif.dmemWEN = 0;
    dcif.datomic = '0;
    dcif.dmemstore = '0;
    dcif.dmemaddr = '0;

    cif.dwait = 1'b1;
    cif.dload = '0;
    reset_if();

    // **********************************
    // Test Case 1: 
    // **********************************
    @(posedge CLK);
    #(PERIOD);
    check_output(0,"R type");
    @(posedge CLK);
    reset_if();


    $finish;
  end
endmodule
