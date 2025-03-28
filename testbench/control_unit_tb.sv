`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "control_request_unit_if.vh"
`include "datapath_cache_if.vh"
// types
`include "cpu_types_pkg.vh"


module control_unit_tb;

  parameter PERIOD = 10;

  // Clock and reset
  logic CLK = 0;
  logic nRST;

  // import types
  import cpu_types_pkg::*;

  // Interface signals
  control_request_unit_if cuif();

  // DUT instances
    control_unit DUT(.CLK(CLK), .nRST(nRST), .cuif(cuif));

  // Clock generation
  always #(PERIOD / 2) CLK = ~CLK;

  //define test instruction types
  s_t stype;
  r_t rtype;
  i_t itype;
  b_t btype;
  j_t jtype;
  u_t utype;
  

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
    input logic [1:0] exp_MemWr; 
    input logic exp_MemtoReg, exp_AluSrc, exp_RegWr;
    input logic [1:0] exp_PCSrc, exp_jumpsel;
    input logic exp_pchalt;
    input aluop_t exp_Aluop;
    input regbits_t exp_Rd, exp_Rs1, exp_Rs2; 
    input word_t exp_Imm; 
    input string case_info;
    
    begin
        // Compare each signal and display results
        if ((exp_MemWr == cuif.MemWr) && (exp_MemtoReg == cuif.MemtoReg) && (exp_Aluop == cuif.Aluop)
            && (exp_AluSrc == cuif.AluSrc) && (exp_RegWr == cuif.RegWr) && (exp_Rd == cuif.Rd)
            && (exp_Rs1 == cuif.Rs1) && (exp_Rs2 == cuif.Rs2) && (exp_Imm == cuif.Imm)
            && (exp_PCSrc == cuif.PCSrc) && (exp_jumpsel == cuif.jumpsel) && (exp_pchalt == cuif.pchalt)) 
        begin
            $display("Passed test case: %s", case_info);
        end
        else
        begin
            $display("Failed : %s", case_info);
            // Display the expected and actual values
            $display("Actual: %d; Expected: %d MemWr", cuif.MemWr, exp_MemWr);
            $display("Actual: %d; Expected: %d MemtoReg", cuif.MemtoReg, exp_MemtoReg);
            $display("Actual: %d; Expected: %d Aluop", cuif.Aluop, exp_Aluop);
            $display("Actual: %d; Expected: %d AluSrc", cuif.AluSrc, exp_AluSrc);
            $display("Actual: %d; Expected: %d RegWr", cuif.RegWr, exp_RegWr);
            $display("Actual: %d; Expected: %d Rd", cuif.Rd, exp_Rd);
            $display("Actual: %d; Expected: %d Rs1", cuif.Rs1, exp_Rs1);
            $display("Actual: %d; Expected: %d Rs2", cuif.Rs2, exp_Rs2);
            $display("Actual: %d; Expected: %d Imm", cuif.Imm, exp_Imm);
            $display("Actual: %d; Expected: %d PCSrc", cuif.PCSrc, exp_PCSrc);
            $display("Actual: %d; Expected: %d jumpsel", cuif.jumpsel, exp_jumpsel);
            $display("Actual: %d; Expected: %d pchalt", cuif.pchalt, exp_pchalt);
        end
        // Display case information
        // $display("%s", case_info);
        
        // Small delay for simulation stability
        #(0.1ns);

      
    end
endtask

  initial begin

    //initialize interface ports
    cuif.zero = 0;
    cuif.neg = 0;
    cuif.overflow = 0;
    cuif.imemload = '0;
    rtype = '0;
    stype = '0;
    itype = '0;
    btype = '0;
    jtype = '0;
    utype = '0;
    reset_if();


    // **********************************
    // Test Case 1: R type 
    // **********************************
    rtype = {ADD,5'hC,5'hC,AND,5'hA,RTYPE};
    @(posedge CLK);
    cuif.imemload = rtype;
    #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_AND,5'hA,5'hC,5'hC,0,"R type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 2: I type
    // **********************************
    itype = {11'hEA,5'hB,ANDI,5'h5,ITYPE};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_AND,5'h5,5'hB,0,11'hEA,"I type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 3: I type LW
    // **********************************
    itype = {11'hEA,5'h1,LW,5'h3,ITYPE_LW};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(2'b10,1,1,1,0,0,0,ALU_ADD,5'h3,5'h1,0,11'hEA,"I type LW");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 3.5: I type JALR
    // **********************************
    itype = {11'hCC,5'h1,LW,5'h3,JALR};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(0,0,1,1,2'b10,1,0,ALU_ADD,5'h3,5'h1,0,11'hCC,"I type JALR");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 4: S type
    // **********************************
    stype = {7'b1000011,5'h1,5'hA,SW,5'b00001,STYPE};
    @(posedge CLK);
    cuif.imemload = stype;
    #(PERIOD);
    check_output(1,0,1,0,2'b00,0,0,ALU_ADD,5'h0,5'hA,5'h1,32'hfffff861,"S type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 5: B type
    // **********************************
    btype = {7'h3,5'hC,5'hC,BEQ,5'h2,BTYPE};
    @(posedge CLK);
    cuif.imemload = btype;
    #(PERIOD);
    cuif.zero = 1;
    @(negedge CLK);
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,5'h0,5'hC,5'hC,32'h00000031,"B type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 6: J type
    // **********************************
    jtype = {20'h000A,5'hA,JAL};
    @(posedge CLK);
    cuif.imemload = jtype;
    #(PERIOD);
    check_output(0,0,0,1,2'b01,1,0,ALU_SLL,5'hA,5'h0,5'h0,32'h00005000,"J type (JAL)");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 7: U type
    // **********************************
    utype = {20'hBEAD,5'hA,LUI};
    @(posedge CLK);
    cuif.imemload = utype;
    #(PERIOD);
    check_output(0,0,0,1,2'b00,2'b10,0,ALU_SLL,5'hA,5'h0,5'h0,32'hBEAD000,"U type");
    @(posedge CLK);
    reset_if();
    $finish;
  end
endmodule
