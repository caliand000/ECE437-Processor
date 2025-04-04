
//multi core tb

`timescale 1ns/1ps


// interface
`include "cpu_ram_if.vh"
`include "cache_control_if.vh"
`include "caches_if.vh"
// types
`include "cpu_types_pkg.vh"


module memory_control_tb;

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;

  // Interface signals
  caches_if cif0 ();
  caches_if cif1 ();
  cache_control_if ccif (cif0, cif1);
  cpu_ram_if ramif ();

  //connecting internal signals
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



  // DUT instances
  `ifndef MAPPED
    memory_control #(.CPUS(1)) memDUT (.CLK(CLK), .nRST(nRST), .ccif(ccif));
    ram ramDUT(.CLK(CLK), .nRST(nRST), .ramif(ramif));
  `else
    memory_control #(.CPUS(1)) memDUT (
    .\ccif.iREN (ccif.iREN),
    .\ccif.dREN (ccif.dREN),
    .\ccif.dWEN (ccif.dWEN),
    .\ccif.dstore (ccif.dstore),
    .\ccif.iaddr (ccif.iaddr),
    .\ccif.daddr (ccif.daddr),
    .\ccif.ramload (ccif.ramload),
    .\ccif.ramstate (ccif.ramstate),
    .\ccif.ccwrite (ccif.ccwrite),
    .\ccif.cctrans (ccif.cctrans),
    .\ccif.iwait (ccif.iwait),
    .\ccif.dwait (ccif.dwait),
    .\ccif.iload (ccif.iload),
    .\ccif.dload (ccif.dload),
    .\ccif.ramstore (ccif.ramstore),
    .\ccif.ramaddr (ccif.ramaddr),
    .\ccif.ramWEN (ccif.ramWEN),
    .\ccif.ramREN (ccif.ramREN),
    .\ccif.ccwait (ccif.ccwait),
    .\ccif.ccinv (ccif.ccinv),
    .\ccif.ccsnoopaddr (ccif.ccsnoopaddr),
    .\nRST (nRST),
    .\CLK (CLK)
   );

   ram ramDUT (
    .\ramif.ramaddr (ramif.ramaddr),
    .\ramif.ramstore (ramif.ramstore),
    .\ramif.ramREN (ramif.ramREN),
    .\ramif.ramWEN (ramif.ramWEN),
    .\ramif.ramstate (ramif.ramstate),
    .\ramif.ramload (ramif.ramload),
    .\nRST (nRST),
    .\CLK (CLK)
   );
  `endif
  

  // Clock generation
  always #(PERIOD / 2) CLK = ~CLK;

  //=================================================================
  // Helper Tasks
  //=================================================================
  // Task to drive transaction inputs. This task sets all the
  // input signals for both cores and prints a start message with a timestamp.
  task automatic send_transaction(
    input string test_name,
    // Core 0 instruction and data signals
    input logic    iREN0,    input logic [31:0] iaddr0,
    input logic    dREN0,    input logic dWEN0,    input logic [31:0] daddr0,    input logic [31:0] dstore0,
    input logic    ccwrite0, input logic cctrans0,
    // Core 1 instruction and data signals
    input logic    iREN1,    input logic [31:0] iaddr1,
    input logic    dREN1,    input logic dWEN1,    input logic [31:0] daddr1,    input logic [31:0] dstore1,
    input logic    ccwrite1, input logic cctrans1
  );
    begin
      $display("[%0t] Starting %s", $time, test_name);
      // Core 0 inputs
      cif0.iREN   = iREN0;
      cif0.iaddr  = iaddr0;
      cif0.dREN   = dREN0;
      cif0.dWEN   = dWEN0;
      cif0.daddr  = daddr0;
      cif0.dstore = dstore0;
      cif0.ccwrite = ccwrite0;
      cif0.cctrans = cctrans0;
      // Core 1 inputs
      cif1.iREN   = iREN1;
      cif1.iaddr  = iaddr1;
      cif1.dREN   = dREN1;
      cif1.dWEN   = dWEN1;
      cif1.daddr  = daddr1;
      cif1.dstore = dstore1;
      cif1.ccwrite = ccwrite1;
      cif1.cctrans = cctrans1;
    end
  endtask


  task automatic check_signals(
  input string test_name,
  // Core interface expected outputs
  input logic [1:0] expected_iwait,
  input logic [1:0] expected_dwait,
  input logic [31:0] expected_iload,
  input logic [31:0] expected_dload,
  // RAM interface expected outputs
  input logic [31:0] expected_ramstore,
  input logic [31:0] expected_ramaddr,
  input logic expected_ramWEN,
  input logic expected_ramREN,
  // Coherence expected outputs
  input logic [1:0] expected_ccwait,
  input logic [1:0] expected_ccinv,
  input logic [31:0] expected_ccsnoopaddr
);
  begin
    // Use a temporary flag to capture if all signals match
    bit pass = 1;
    if (ccif.iwait !== expected_iwait) pass = 0;
    if (ccif.dwait !== expected_dwait) pass = 0;
    if (ccif.iload !== expected_iload) pass = 0;
    if (ccif.dload !== expected_dload) pass = 0;
    if (ccif.ramstore !== expected_ramstore) pass = 0;
    if (ccif.ramaddr  !== expected_ramaddr)  pass = 0;
    if (ccif.ramWEN  !== expected_ramWEN)  pass = 0;
    if (ccif.ramREN  !== expected_ramREN)  pass = 0;
    if (ccif.ccwait  !== expected_ccwait)  pass = 0;
    if (ccif.ccinv   !== expected_ccinv)   pass = 0;
    if (ccif.ccsnoopaddr !== expected_ccsnoopaddr) pass = 0;

    if (pass)
      $display("[%0t] %s: PASSED", $time, test_name);
    else begin
      $display("[%0t] %s: FAILED", $time, test_name);
      $display("   iwait:      expected = %0h, got = %0h", expected_iwait, ccif.iwait);
      $display("   dwait:      expected = %0h, got = %0h", expected_dwait, ccif.dwait);
      $display("   iload:      expected = %0h, got = %0h", expected_iload, ccif.iload);
      $display("   dload:      expected = %0h, got = %0h", expected_dload, ccif.dload);
      $display("   ramstore:   expected = %0h, got = %0h", expected_ramstore, ccif.ramstore);
      $display("   ramaddr:    expected = %0h, got = %0h", expected_ramaddr, ccif.ramaddr);
      $display("   ramWEN:     expected = %0h, got = %0h", expected_ramWEN, ccif.ramWEN);
      $display("   ramREN:     expected = %0h, got = %0h", expected_ramREN, ccif.ramREN);
      $display("   ccwait:     expected = %0h, got = %0h", expected_ccwait, ccif.ccwait);
      $display("   ccinv:      expected = %0h, got = %0h", expected_ccinv, ccif.ccinv);
      $display("   ccsnoopaddr:expected = %0h, got = %0h", expected_ccsnoopaddr, ccif.ccsnoopaddr);
    end
  end
endtask



  // Testbench tasks
  task reset_if;
    begin
      nRST = 1;
      #(PERIOD);
      nRST = 0;
      #(PERIOD);
      nRST = 1;
    end
  endtask

  task automatic dump_memory();
    string filename = "memcpu.hex";
    int memfd;

    // syif.tbCTRL = 1;
    cif0.iaddr = 0;
    cif0.dWEN = 0;
    cif0.dREN = 0;

    memfd = $fopen(filename,"w");
    if (memfd)
      $display("Starting memory dump.");
    else
      begin $display("Failed to open %s.",filename); $finish; end

    for (int unsigned i = 0; memfd && i < 16384; i++)
    begin
      int chksum = 0;
      bit [7:0][7:0] values;
      string ihex;

      cif0.iaddr = i << 2;
      cif0.iREN = 1;
      repeat (4) @(posedge CLK);
      if (cif0.iload === 0)
        continue;
      values = {8'h04,16'(i),8'h00,cif0.iload};
      foreach (values[j])
        chksum += values[j];
      chksum = 16'h100 - chksum;
      ihex = $sformatf(":04%h00%h%h",16'(i),cif0.iload,8'(chksum));
      $fdisplay(memfd,"%s",ihex.toupper());
    end //for
    if (memfd)
    begin
      // syif.tbCTRL = 0;
      // syif.REN = 0;
      $fdisplay(memfd,":00000001FF");
      $fclose(memfd);
      $display("Finished memory dump.");
    end
  endtask

  //initialize interface ports

  ramstate_t rstate = BUSY;
  word_t addr = 0;

  string testcase = "";

  task init;
    begin
      cif0.iREN = 0;
      cif0.dREN = 0;
      cif0.dWEN = 0;
      cif0.dstore = addr;
      cif0.iaddr = addr;
      cif0.daddr = addr;
      cif0.ccwrite = 0;
      cif0.cctrans = 0;
      cif1.iREN = 0;
      cif1.dREN = 0;
      cif1.dWEN = 0;
      cif1.dstore = addr;
      cif1.iaddr = addr;
      cif1.daddr = addr;
      cif1.ccwrite = 0;
      cif1.cctrans = 0;

    end
  endtask

  // Test sequences
  initial begin
    // Initialize signals
    init();
    reset_if();

    $timeformat(-9, 2, " ns", 20);

    //-----------------------------------------------------------
    // Test 1: Instruction Fetch
    // Goal: Verify that an instruction fetch returns a valid iload
    //-----------------------------------------------------------
    testcase = "Test 1: Instruction Fetch";
    send_transaction("Test 1: Instruction Fetch",
                     /* Core 0: */ 1, 32'h10, 0, 0, 32'h0,  32'h0,/* cc signals */ 0, 0,
                     /* Core 1: */ 1, 32'h204, 0, 0, 32'h0, 32'h0, /* cc signals */ 0, 0);
    wait (ccif.iwait[0] == 0);
    @(negedge CLK);
    // Check expected outputs for each core.
    check_signals("Test 1: Instruction Fetch",
                       /* Core 0 expected outputs: */
                       2,    // iwait should go low
                       3,    // dwait remains high (1)
                       32'hABCD0001, // iload (nonzero value from RAM)
                       32'h0,       // dload not used
                       32'h0,       // ramstore
                       32'h10,      // ramaddr should match iaddr
                       0,           // ramWEN off
                       1,           // ramREN on
                       0,           // ccwait
                       0,           // ccinv
                       32'h0);      // ccsnoopaddr

    wait (ccif.iwait[1] == 0);
    @(negedge CLK);
    check_signals("Test 1: Instruction Fetch",
                       /* Core 1 expected outputs: */
                       1,    // iwait low
                       1,    // dwait high
                       32'hABCD0002, // iload (nonzero value)
                       32'h0,
                       32'h0,
                       32'h204,     // ramaddr matches iaddr
                       0,
                       1,
                       0,
                       0,
                       32'h0);
    reset_if(); 
    cif0.iREN = 0;
    cif0.dREN = 0;
    cif0.dWEN = 0;
    cif1.iREN = 0;
    cif1.dREN = 0;
    cif1.dWEN = 0;
    
    //-----------------------------------------------------------
    // Test 2: write memory
    // Goal: Verify that memory write operation takes place
    //-----------------------------------------------------------
    testcase = "Test 2: write memory";
    send_transaction("Test 2: write memory",
                     /* Core 0: */ 1, 32'h10, 0, 0, 32'h0,  32'h0,/* cc signals */ 0, 0,
                     /* Core 1: */ 0, 32'h204, 0, 1, 32'h0840, 32'hABABEFEF, /* cc signals */ 0, 0);
    
    wait (ccif.dwait[1] == 0);
    @(negedge CLK);

    // Check expected outputs for each core.
    check_signals("Test 2: write memory first core",
                       /* Core 0 expected outputs: */
                       3,    // iwait should go low
                       1,    // dwait remains high (1)
                       32'hABCD0001, // iload (nonzero value from RAM)
                       32'h0,       // dload not used
                       32'h0,       // ramstore
                       32'h10,      // ramaddr should match iaddr
                       0,           // ramWEN off
                       1,           // ramREN on
                       0,           // ccwait
                       0,           // ccinv
                       32'h0);      // ccsnoopaddr
    check_signals("Test 2: write memory second core",
                       /* Core 1 expected outputs: */
                       0,    // iwait low
                       1,    // dwait high
                       32'hABCD0002, // iload (nonzero value)
                       32'h0,
                       32'h0,
                       32'h204,     // ramaddr matches iaddr
                       0,
                       1,
                       0,
                       0,
                       32'h0);
    reset_if(); 

    cif0.iREN = 0;
    cif0.dREN = 0;
    cif0.dWEN = 0;
    cif1.iREN = 0;
    cif1.dREN = 0;
    cif1.dWEN = 0;


    //test one core doing read exclusive (with intent to modify, this means cctrans should be high from other core)

    //test one core reading, and other core is in invalid/shared state

    //test priority, with one core trying to read instruction, and other core doing write request

    //test priority, with one core trying to read instruction, and other core doing instruction read as well

    //test priority, with one core trying to read instruction, and other core doing read request


    // Test 1: Instruction fetch
    cif0.iREN = 1;
    cif0.iaddr = 32'h10;
    cif1.iREN=1;
    cif1.iaddr=32'h204;   
    
    @(negedge cif0.iwait);
    if(cif0.iload==0) $display("instruction load for core 0 failed");
    @(negedge cif1.iwait);
   
  
    
    if(cif1.iload==0) $display("instruction load for core 1 failed");
    #(PERIOD);

    //Test 3: Both cores read from same address 
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1;
    @(negedge cif0.dwait);
    if(cif0.dload==0) $display("Failed to read data to core 0");
    @(negedge cif1.dwait);
    if(cif1.dload==0) $display("Failed to read data to core 1");
    #(PERIOD);
     //Test 2: both cores write to same address
     cif0.dREN=0;
     cif1.dREN=0;
    cif0.dWEN = 1'b1;
    cif0.daddr = 32'h00000002;
    cif0.dstore=10;
    cif1.dWEN = 1'b1;
    cif1.daddr = 32'h00000002;
    cif1.dstore=11;
    @(negedge cif0.dwait);
    @(negedge cif1.dwait);
    //Test 4: cc trans 
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b0;
    cif0.ccwrite = 0;
    cif0.cctrans = 0;
    cif1.ccwrite = 0;
    cif1.cctrans = 0;

    #(PERIOD);
    cif1.cctrans=1;
    cif0.dREN=0;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1;
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    //Test 5: cc write 
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    

    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b0;
    cif0.ccwrite = 0;
    cif0.cctrans = 0;
    cif1.ccwrite = 0;
    cif1.cctrans = 0;

    #(PERIOD);
    cif0.ccwrite=1;
    cif0.dREN=0;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1;
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    //Test 6: cc write &trans
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b0;
    cif0.ccwrite = 0;
    cif0.cctrans = 0;
    cif1.ccwrite = 0;
    cif1.cctrans = 0;

    #(PERIOD);
    cif0.ccwrite=1;
    cif1.cctrans=1;
    cif0.dREN=0;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1;
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    //Test 6: clear
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b0;
    
    #(PERIOD);
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1;
    cif0.ccwrite = 0;
    cif0.cctrans = 0;
    cif1.ccwrite = 0;
    cif1.cctrans = 0;

    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    dump_memory();
    cif0.dREN = 1'b0;
    cif0.daddr = 32'h00000000;
    if (cif0.iwait == 0) $display("Instruction fetch failed");

    //#(PERIOD);
    reset_if();

    //Test 2: Load instruction
    cif0.iREN = 1'b1;
    cif0.iaddr = 32'h00000004;
    #(PERIOD);
    cif0.dWEN = 1'b1;
    cif0.dstore = 32'hDEADBEEF;
    cif0.daddr = 32'h00000100;
    #(PERIOD * 2);
    cif0.dWEN = 1'b0;

    dump_memory();

    // Test 2: Data read
    // ccif.dREN = 1;
    // ccif.daddr = 32'h0000_2000;
    // ccif.ramstate = ACCESS;
    // #(PERIOD);
    // #(PERIOD);
    // ccif.dREN = 0;
    // assert(ccif.dwait == 0) else $display("Data read failed");

    // Test 3: Data write
    // ccif.dWEN = 1;
    // ccif.daddr = 32'h0000_3000;
    // ccif.dstore = 32'hDEADBEEF;
    // ccif.ramstate = ACCESS;
    // #(PERIOD);
    // #(PERIOD);
    // ccif.dWEN = 0;
    // assert(ccif.dwait == 0) else $display("Data write failed");

    // Test 4: Reset behavior
    // reset_if();
    // #(PERIOD);
    // assert(ccif.iwait == 1 && ccif.dwait == 1) else $display("Reset behavior failed");

    // Finish simulation
    $finish;
  end
endmodule

//single core tb

// `timescale 1ns/1ps


// // interface
// `include "cpu_ram_if.vh"
// `include "cache_control_if.vh"
// `include "caches_if.vh"
// // types
// `include "cpu_types_pkg.vh"


// module memory_control_tb;

//   parameter PERIOD = 10;

//   // Clock and reset
//   logic CLK = 0;
//   logic nRST;

//   // import types
//   import cpu_types_pkg::*;

//   // Interface signals
//   caches_if cif0 ();
//   caches_if cif1 ();
//   cache_control_if ccif (cif0, cif1);
//   cpu_ram_if ramif ();

//   //connecting internal signals
//   assign ccif.ramstate = ramif.ramstate;
//   assign ccif.ramload = ramif.ramload;

//   // assign ramif.memaddr = ccif.ramaddr;      //&*****Change back to ram if doesnt work instead of mem **************
//   // assign ramif.memstore = ccif.ramstore;
//   // assign ramif.memREN = ccif.ramREN;
//   // assign ramif.memWEN = ccif.ramWEN;
//   assign ramif.ramREN = ccif.ramREN;
//   assign ramif.ramWEN = ccif.ramWEN;
//   assign ramif.ramaddr = ccif.ramaddr;
//   assign ramif.ramstore = ccif.ramstore;



//   // DUT instances
//   `ifndef MAPPED
//     memory_control #(.CPUS(1)) memDUT (.CLK(CLK), .nRST(nRST), .ccif(ccif));
//     ram ramDUT(.CLK(CLK), .nRST(nRST), .ramif(ramif));
//   `else
//     memory_control #(.CPUS(1)) memDUT (
//     .\ccif.iREN (ccif.iREN),
//     .\ccif.dREN (ccif.dREN),
//     .\ccif.dWEN (ccif.dWEN),
//     .\ccif.dstore (ccif.dstore),
//     .\ccif.iaddr (ccif.iaddr),
//     .\ccif.daddr (ccif.daddr),
//     .\ccif.ramload (ccif.ramload),
//     .\ccif.ramstate (ccif.ramstate),
//     .\ccif.ccwrite (ccif.ccwrite),
//     .\ccif.cctrans (ccif.cctrans),
//     .\ccif.iwait (ccif.iwait),
//     .\ccif.dwait (ccif.dwait),
//     .\ccif.iload (ccif.iload),
//     .\ccif.dload (ccif.dload),
//     .\ccif.ramstore (ccif.ramstore),
//     .\ccif.ramaddr (ccif.ramaddr),
//     .\ccif.ramWEN (ccif.ramWEN),
//     .\ccif.ramREN (ccif.ramREN),
//     .\ccif.ccwait (ccif.ccwait),
//     .\ccif.ccinv (ccif.ccinv),
//     .\ccif.ccsnoopaddr (ccif.ccsnoopaddr),
//     .\nRST (nRST),
//     .\CLK (CLK)
//    );

//    ram ramDUT (
//     .\ramif.ramaddr (ramif.ramaddr),
//     .\ramif.ramstore (ramif.ramstore),
//     .\ramif.ramREN (ramif.ramREN),
//     .\ramif.ramWEN (ramif.ramWEN),
//     .\ramif.ramstate (ramif.ramstate),
//     .\ramif.ramload (ramif.ramload),
//     .\nRST (nRST),
//     .\CLK (CLK)
//    );
//   `endif
  

//   // Clock generation
//   always #(PERIOD / 2) CLK = ~CLK;

//   // Testbench tasks
//   task reset_if;
//     begin
//       nRST = 1;
//       #(PERIOD);
//       nRST = 0;
//       #(PERIOD);
//       nRST = 1;
//     end
//   endtask

//   task automatic dump_memory();
//     string filename = "memcpu.hex";
//     int memfd;

//     // syif.tbCTRL = 1;
//     cif0.iaddr = 0;
//     cif0.dWEN = 0;
//     cif0.dREN = 0;

//     memfd = $fopen(filename,"w");
//     if (memfd)
//       $display("Starting memory dump.");
//     else
//       begin $display("Failed to open %s.",filename); $finish; end

//     for (int unsigned i = 0; memfd && i < 16384; i++)
//     begin
//       int chksum = 0;
//       bit [7:0][7:0] values;
//       string ihex;

//       cif0.iaddr = i << 2;
//       cif0.iREN = 1;
//       repeat (4) @(posedge CLK);
//       if (cif0.iload === 0)
//         continue;
//       values = {8'h04,16'(i),8'h00,cif0.iload};
//       foreach (values[j])
//         chksum += values[j];
//       chksum = 16'h100 - chksum;
//       ihex = $sformatf(":04%h00%h%h",16'(i),cif0.iload,8'(chksum));
//       $fdisplay(memfd,"%s",ihex.toupper());
//     end //for
//     if (memfd)
//     begin
//       // syif.tbCTRL = 0;
//       // syif.REN = 0;
//       $fdisplay(memfd,":00000001FF");
//       $fclose(memfd);
//       $display("Finished memory dump.");
//     end
//   endtask

//   //initialize interface ports

//   ramstate_t rstate = BUSY;
//   word_t addr = 0;

//   task init;
//     begin
//       cif0.iREN = 0;
//       cif0.dREN = 0;
//       cif0.dWEN = 0;
//       cif0.dstore = addr;
//       cif0.iaddr = addr;
//       cif0.daddr = addr;
//       cif0.ccwrite = 0;
//       cif0.cctrans = 0;

//     end
//   endtask

//   // Test sequences
//   initial begin
//     // Initialize signals
//     init();
//     reset_if();


//     // Test 1: Instruction fetch
//     cif0.iREN = 1;
//     cif0.iaddr = 32'h00000001;   
//     #(PERIOD);
//     cif0.dREN = 1'b1;
//     cif0.daddr = 32'h00000002;
//     #(PERIOD);
//     cif0.dREN = 1'b0;
//     cif0.daddr = 32'h00000000;
//     if (cif0.iwait == 0) $display("Instruction fetch failed");

//     //#(PERIOD);
//     reset_if();

//     //Test 2: Load instruction
//     cif0.iREN = 1'b1;
//     cif0.iaddr = 32'h00000004;
//     #(PERIOD);
//     cif0.dWEN = 1'b1;
//     cif0.dstore = 32'hDEADBEEF;
//     cif0.daddr = 32'h00000100;
//     #(PERIOD * 2);
//     cif0.dWEN = 1'b0;

//     dump_memory();

//     // Test 2: Data read
//     // ccif.dREN = 1;
//     // ccif.daddr = 32'h0000_2000;
//     // ccif.ramstate = ACCESS;
//     // #(PERIOD);
//     // #(PERIOD);
//     // ccif.dREN = 0;
//     // assert(ccif.dwait == 0) else $display("Data read failed");

//     // Test 3: Data write
//     // ccif.dWEN = 1;
//     // ccif.daddr = 32'h0000_3000;
//     // ccif.dstore = 32'hDEADBEEF;
//     // ccif.ramstate = ACCESS;
//     // #(PERIOD);
//     // #(PERIOD);
//     // ccif.dWEN = 0;
//     // assert(ccif.dwait == 0) else $display("Data write failed");

//     // Test 4: Reset behavior
//     // reset_if();
//     // #(PERIOD);
//     // assert(ccif.iwait == 1 && ccif.dwait == 1) else $display("Reset behavior failed");

//     // Finish simulation
//     $finish;
//   end
// endmodule
