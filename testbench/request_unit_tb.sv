`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "control_request_unit_if.vh"
`include "datapath_cache_if.vh"
// types
`include "cpu_types_pkg.vh"


module request_unit_tb;

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;

  // Interface signals
  control_request_unit_if ruif();

  // DUT instances
    request_unit DUT(.CLK(CLK), .nRST(nRST), .ruif(ruif));

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
    input logic exp_imemREN, exp_dmemREN, exp_dmemWEN;
    input word_t exp_imemaddr, exp_dmemstore, exp_dmemaddr;
    input string case_info;
    begin
        if((exp_imemREN == ruif.imemREN) && (exp_dmemREN == ruif.dmemREN) && (exp_dmemWEN == ruif.dmemWEN)
      && (exp_dmemstore == ruif.dmemstore) && (exp_dmemaddr == ruif.dmemaddr)
        ) $display("Passed test case: %s", case_info);
        else  begin $display("Failed : ");
            $display("Actual: %d; Expected: %d imemREN", ruif.imemREN, exp_imemREN);
            $display("Actual: %d; Expected: %ddmemREN", ruif.dmemREN, exp_dmemREN);
            $display("Actual: %d; Expected: %ddmemWEN", ruif.dmemWEN, exp_dmemWEN);
            $display("Actual: %d; Expected: %ddmemstore", ruif.dmemstore, exp_dmemstore);
            $display("Actual: %d; Expected: %ddmemaddr", ruif.dmemaddr, exp_dmemaddr);
            $display("%s", case_info);
            #(0.1ns);
        end
    end
    endtask

  initial begin

    //initialize interface ports
    ruif.rdat2 = '0;
    ruif.Aluout = '0;
    ruif.MemWr = 0;
    ruif.dhit = 0; 
    reset_if();

    // **********************************
    // Test Case 1: SW  M[R[rs1]+imm] <= R[rs2]
    // **********************************
    ruif.MemWr = 2'b01;
    ruif.rdat2 = 32'hABAB;             //should be the content to be stored
    ruif.Aluout = 32'h0000000A;        //should be the address to store at
    #(PERIOD);
    @(posedge CLK);
    ruif.dhit = 1'b1;
    @(posedge CLK);
    ruif.dhit = 0;
    ruif.MemWr = 0;
    check_output(1,0,1,0,32'hABAB,32'hA,"SW");
    reset_if();


    // **********************************
    // Test Case 2: LW  M[R[rs1]+imm] <= R[rs2]
    // **********************************
    ruif.MemWr = 2'b10;
    ruif.Aluout = 32'h0000000A;        //should be the address to store at
    #(PERIOD);
    @(posedge CLK);
    ruif.dhit = 1'b1;
    @(posedge CLK);
    ruif.dhit = 0;
    ruif.MemWr = 0;
    check_output(1,1,0,0,32'h0,32'hA,"LW");
        reset_if();

    // **********************************
    // Test Case 3: Reset test
    // **********************************
    ruif.MemWr = 0;
    ruif.Aluout = 32'h0000000A;        //should be the address to store at
    #(PERIOD / 2);
    ruif.dhit = 1'b1;
    #(PERIOD / 2);
    ruif.dhit = 0;
    nRST = 0;
    @(posedge CLK);
    @(posedge CLK);
    check_output(0,0,0,0,32'h0000,32'h0,"Reset");
    reset_if();

    $finish;
  end
endmodule
