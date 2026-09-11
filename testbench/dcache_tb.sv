`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "datapath_cache_if.vh"
`include "cpu_ram_if.vh"
`include "cache_control_if.vh"
// types
`include "cpu_types_pkg.vh"


module dcache_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, dcache_tb);
  end

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;

  // Interface signals

  caches_if cif1();
  caches_if cif2();
  datapath_cache_if dcif();
  cpu_ram_if ramif ();
  cache_control_if ccif (cif1, cif2);

  //assign internal signals
  assign ccif.ramstate = ramif.ramstate;
  assign ccif.ramload = ramif.ramload;

  assign ramif.ramREN = ccif.ramREN;
  assign ramif.ramWEN = ccif.ramWEN;
  assign ramif.ramaddr = ccif.ramaddr;
  assign ramif.ramstore = ccif.ramstore;

  // Clock generation
  always #(PERIOD / 2) CLK = ~CLK;
    // clock division
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

  // DUT instances
  dcache DUT(.CLK(CPUCLK), .nRST(nRST), .dcif(dcif), .cif(cif1));

  // memory
  ram RAM (CLK, nRST, ramif);

  memory_control MEMCTRL (CLK, nRST, ccif);

  
  

  // Testbench tasks
  task reset_if;
    begin
      nRST = 0;
      #(10ns);
      nRST = 1;
      @(negedge CPUCLK);
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
            $display("Actual: %d; Expected: %d dmemload", dcif.dmemload, exp_dmemload);
            $display("Actual: %d; Expected: %d flushed", dcif.flushed, exp_flushed);
        end
        #(0.1ns);

      
    end
endtask

  dcachef_t frame;

  initial begin
    $timeformat(-9, 0, "ns");

    //initialize interface ports
    dcif.halt = 0;
    dcif.dmemREN = 0;
    dcif.dmemWEN = 0;
    dcif.dmemstore = '0;
    dcif.dmemaddr = '0;
    cif1.iREN = 0;
    cif1.iaddr = 0;
    frame = '0;

    reset_if();



    // **********************************
    // Test Case 1: Basic Cache Hit
    // **********************************
    @(posedge CPUCLK);
    dcif.dmemWEN = 1'b1;
    frame.idx = 4;
    dcif.dmemaddr = frame;
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;
    #(PERIOD);

    dcif.dmemREN = 1'b1;
    dcif.dmemaddr = frame;
    @(posedge dcif.dhit);
    check_output(32'hadadbf00,0,"Basic Cache Hit");

    @(posedge CPUCLK);
    dcif.dmemREN = 1'b0;
    // reset_if();

    // **********************************
    // Test Case 2: 2-way Associative Mapping Verification
    // **********************************
    @(posedge CPUCLK);
    dcif.dmemWEN = 1'b1;
    frame.idx = 2;
    dcif.dmemaddr = frame;     
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    frame.tag = 2;
    dcif.dmemaddr = frame;  
    dcif.dmemstore = 32'hfaad1234;

    @(posedge CPUCLK);
    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;

    #(PERIOD * 2);

    dcif.dmemREN = 1'b1;
    frame.tag = 0;
    dcif.dmemaddr = frame;   //reading first block
    @(posedge dcif.dhit);
    check_output(32'hadadbf00,0,"2-Way Mapping Associative Verification first value");

    #(PERIOD * 2);
    @(posedge CPUCLK);
    frame.tag = 2;
    dcif.dmemaddr = frame;   //reading second block
    @(posedge dcif.dhit);
    check_output(32'hfaad1234,0,"2-Way Mapping Associative Verification second value");

    @(posedge CPUCLK);
    dcif.dmemREN = 1'b0;
    // reset_if();


    // **********************************
    // Test Case 3: Block Eviction
    // **********************************
    @(posedge CPUCLK);
    dcif.dmemWEN = 1'b1;
    frame.tag = 0;
    frame.idx = 3;
    dcif.dmemaddr = frame;     
    dcif.dmemstore = 32'hadadbf00;

    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    frame.tag = 2;
    dcif.dmemaddr = frame;  
    dcif.dmemstore = 32'hfaad1234;

    @(posedge CPUCLK);
    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    frame.tag = 1;
    dcif.dmemaddr = frame;
    dcif.dmemstore = 32'hffffffff;

    @(posedge CPUCLK);
    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;

    #(PERIOD * 2);

    dcif.dmemREN = 1'b1;
    frame.tag = 1;
    dcif.dmemaddr = frame;   //reading first block
    @(posedge dcif.dhit);
    check_output(32'hffffffff,0,"Eviction");

    @(posedge CPUCLK);
    dcif.dmemREN = 1'b0;
    // reset_if();

    // // **********************************
    // // Test Case 4: Halt
    // // **********************************
    @(posedge CPUCLK);
    dcif.dmemWEN = 1'b1;
    frame.idx = 6;
    dcif.dmemaddr = frame;
    dcif.dmemstore = 32'hdeadbeef;

    @(posedge dcif.dhit);
    @(posedge CPUCLK);

    dcif.dmemWEN = 1'b0;
    dcif.dmemaddr = 32'h0;
    dcif.dmemstore = 32'h0;
    #(PERIOD);

    dcif.dmemREN = 1'b1;
    dcif.dmemaddr = frame;
    @(posedge dcif.dhit);

    @(posedge CPUCLK);
    dcif.dmemREN = 1'b0;
    dcif.halt = 1'b1;

    #(PERIOD * 100);
    check_output(32'hadadbf00,0,"Halt");




    reset_if();
    $finish;
  end
endmodule
