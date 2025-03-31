
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


    // Test 1: Instruction fetch
    cif0.iREN = 1;
    cif0.iaddr = 32'h00000001;
    cif1.iREN=1;
    cif1.iaddr=32'h204   
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
    #(PERIOD);
   

    //Test 3: Both cores read from same address 
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1
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
    #(PERIOD);
    #(PERIOD);
     //Test 2: both cores write to same address
    cif0.dWEN = 1'b1;
    cif0.daddr = 32'h00000002;
    cif0.dstore=10;
    cif1.dWEN = 1'b1;
    cif1.daddr = 32'h00000002;
    cif1.dstore=11;
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
    #(PERIOD);
    #(PERIOD);
    //Test 4: cc trans 
    cif0.dWEN = 1'b0;
    cif0.dREN = 1'b1;
    cif0.daddr = 32'h00000002;
    
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b0
    cif0.ccwrite = 0;
    cif0.cctrans = 0;
    cif1.ccwrite = 0;
    cif1.cctrans = 0;

    #(PERIOD);
    cif1.cctrans=1;
    cif0.dREN=0;
    cif1.dWEN = 1'b0;
    cif1.daddr = 32'h00000002;
    cif1.dREN = 1'b1
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
    (PERIOD);
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
