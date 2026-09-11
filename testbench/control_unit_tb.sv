`timescale 1ns/1ps


// interface
`include "caches_if.vh"
`include "control_request_unit_if.vh"
`include "datapath_cache_if.vh"
// types
`include "cpu_types_pkg.vh"


module control_unit_tb;

  initial begin
    $dumpfile("module.vcd");
    $dumpvars(0, control_unit_tb);
  end

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
  always #(PERIOD / 2) CLK <= ~CLK;

  //define test instruction types
  s_t stype;
  r_t rtype;
  i_t itype;
  b_t btype;
  j_t jtype;
  u_t utype;
  int tests_passed = 0;
  int tests_failed = 0;
  bit [127:0] opcode_seen;
  bit [7:0] funct3_seen;
  

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
      opcode_seen[cuif.imemload[6:0]] = 1'b1;
      funct3_seen[cuif.imemload[14:12]] = 1'b1;
        // Compare each signal and display results
        if ((exp_MemWr == cuif.MemWr) && (exp_MemtoReg == cuif.MemtoReg) && (exp_Aluop == cuif.Aluop)
            && (exp_AluSrc == cuif.AluSrc) && (exp_RegWr == cuif.RegWr) && (exp_Rd == cuif.Rd)
            && (exp_Rs1 == cuif.Rs1) && (exp_Rs2 == cuif.Rs2) && (exp_Imm == cuif.Imm)
            && (exp_PCSrc == cuif.PCSrc) && (exp_jumpsel == cuif.jumpsel) && (exp_pchalt == cuif.pchalt)) 
        begin
          tests_passed++;
            $display("Passed test case: %s", case_info);
        end
        else
        begin
          tests_failed++;
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
    // I-type immediates are 12 bits; the expected task argument is 32 bits.
    itype = {12'h0EA,5'hB,ANDI,5'h5,ITYPE};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_AND,5'h5,5'hB,0,32'h000000EA,"I type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 3: I type LW
    // **********************************
    itype = {12'h0EA,5'h1,LW,5'h3,ITYPE_LW};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(2'b10,1,1,1,0,0,0,ALU_ADD,5'h3,5'h1,0,32'h000000EA,"I type LW");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 3.5: I type JALR
    // **********************************
    // JALR uses the ADDI funct3 encoding with a JALR opcode.
    itype = {12'h0CC,5'h1,ADDI,5'h3,JALR};
    @(posedge CLK);
    cuif.imemload = itype;
    #(PERIOD);
    check_output(0,0,1,1,2'b10,3,0,ALU_ADD,5'h3,5'h1,0,32'h000000CC,"I type JALR");
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
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,5'h0,5'hC,5'hC,32'h00000062,"B type");
    @(posedge CLK);
    reset_if();

    // **********************************
    // Test Case 6: J type
    // **********************************
    jtype = {20'h000A,5'hA,JAL};
    @(posedge CLK);
    cuif.imemload = jtype;
    #(PERIOD);
    check_output(0,0,0,1,2'b01,3,0,ALU_SLL,5'hA,5'h0,5'h0,32'h0000A000,"J type (JAL)");
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

    // Additional R-type coverage: every ALU funct3 and both ADD/SUB variants.
    rtype = {ADD,5'h2,5'h1,ADD_SUB,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_ADD,5'h3,5'h1,5'h2,0,"R ADD");
    rtype = {SUB,5'h2,5'h1,ADD_SUB,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SUB,5'h3,5'h1,5'h2,0,"R SUB");
    rtype = {7'h00,5'h2,5'h1,SLL,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SLL,5'h3,5'h1,5'h2,0,"R SLL");
    rtype = {SRL,5'h2,5'h1,SRL_SRA,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SRL,5'h3,5'h1,5'h2,0,"R SRL");
    rtype = {SRA,5'h2,5'h1,SRL_SRA,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SRA,5'h3,5'h1,5'h2,0,"R SRA");
    rtype = {7'h00,5'h2,5'h1,OR,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_OR,5'h3,5'h1,5'h2,0,"R OR");
    rtype = {7'h00,5'h2,5'h1,XOR,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_XOR,5'h3,5'h1,5'h2,0,"R XOR");
    rtype = {7'h00,5'h2,5'h1,SLT,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SLT,5'h3,5'h1,5'h2,0,"R SLT");
    rtype = {7'h00,5'h2,5'h1,SLTU,5'h3,RTYPE};
    cuif.imemload = rtype; #(PERIOD);
    check_output(0,0,0,1,0,0,0,ALU_SLTU,5'h3,5'h1,5'h2,0,"R SLTU");

    // I-type coverage: all ALU immediates, including negative and shift cases.
    itype = {12'hFFF,5'h1,ADDI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_ADD,5'h3,5'h1,0,32'hFFFFFFFF,"I ADDI -1");
    itype = {12'h001,5'h1,XORI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_XOR,5'h3,5'h1,0,1,"I XORI");
    itype = {12'h001,5'h1,ORI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_OR,5'h3,5'h1,0,1,"I ORI");
    itype = {12'h001,5'h1,ANDI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_AND,5'h3,5'h1,0,1,"I ANDI");
    itype = {12'h002,5'h1,SLLI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_SLL,5'h3,5'h1,0,2,"I SLLI");
    itype = {12'h002,5'h1,SRLI_SRAI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_SRL,5'h3,5'h1,0,2,"I SRLI");
    itype = {12'h402,5'h1,SRLI_SRAI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_SRA,5'h3,5'h1,0,32'h402,"I SRAI");
    itype = {12'h001,5'h1,SLTI,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_SLT,5'h3,5'h1,0,1,"I SLTI");
    itype = {12'hFFF,5'h1,SLTIU,5'h3,ITYPE};
    cuif.imemload = itype; #(PERIOD);
    check_output(0,0,1,1,0,0,0,ALU_SLTU,5'h3,5'h1,0,32'h00000FFF,"I SLTIU");

    // Branch coverage: taken and not-taken paths for every branch family.
    btype = {7'h00,5'h2,5'h1,BEQ,5'h0,BTYPE}; cuif.imemload = btype; cuif.zero = 1; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,0,1,2,0,"BEQ taken");
    btype = {7'h00,5'h2,5'h1,BNE,5'h0,BTYPE}; cuif.imemload = btype; cuif.zero = 0; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,0,1,2,0,"BNE taken");
    btype = {7'h00,5'h2,5'h1,BLT,5'h0,BTYPE}; cuif.imemload = btype; cuif.neg = 1; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,0,1,2,0,"BLT taken");
    btype = {7'h00,5'h2,5'h1,BGE,5'h0,BTYPE}; cuif.imemload = btype; cuif.neg = 0; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SUB,0,1,2,0,"BGE taken");
    btype = {7'h00,5'h2,5'h1,BLTU,5'h0,BTYPE}; cuif.imemload = btype; cuif.neg = 1; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SLTU,0,1,2,0,"BLTU taken");
    btype = {7'h00,5'h2,5'h1,BGEU,5'h0,BTYPE}; cuif.imemload = btype; cuif.neg = 0; cuif.zero = 0; #(PERIOD);
    check_output(0,0,0,0,2'b01,0,0,ALU_SLTU,0,1,2,0,"BGEU taken");

    // Verify the complementary not-taken paths for equality branches.
    btype = {7'h00,5'h2,5'h1,BEQ,5'h0,BTYPE}; cuif.imemload = btype; cuif.zero = 0; #(PERIOD);
    check_output(0,0,0,0,0,0,0,ALU_SUB,0,1,2,0,"BEQ not taken");
    btype = {7'h00,5'h2,5'h1,BNE,5'h0,BTYPE}; cuif.imemload = btype; cuif.zero = 1; #(PERIOD);
    check_output(0,0,0,0,0,0,0,ALU_SUB,0,1,2,0,"BNE not taken");

    // Cover the second upper-immediate instruction and an unsupported opcode.
    utype = {20'h12345,5'h7,AUIPC}; cuif.imemload = utype; #(PERIOD);
    check_output(0,0,0,1,0,1,0,ALU_SLL,5'h7,0,0,32'h12345000,"AUIPC");
    cuif.imemload = {25'b0,LR_SC}; #(PERIOD);
    check_output(0,0,0,0,0,0,0,ALU_SLL,0,0,0,0,"Unsupported LR/SC");

    // Control-flow and terminal edge cases.
    cuif.imemload = {25'b0,HALT}; #(PERIOD);
    check_output(0,0,0,0,0,0,1,ALU_SLL,0,0,0,0,"HALT");
    cuif.imemload = 32'h00000000; #(PERIOD);
    check_output(0,0,0,0,0,0,0,ALU_SLL,0,0,0,0,"Invalid opcode");

    $display("CONTROL COVERAGE: %0d tests passed, %0d failed, %0d opcodes, %0d funct3 values",
             tests_passed, tests_failed, $countones(opcode_seen), $countones(funct3_seen));
    if (tests_failed != 0)
      $fatal(1, "CONTROL UNIT TESTS FAILED");
    $display("CONTROL UNIT TESTS PASSED");
    $finish;
  end
endmodule
