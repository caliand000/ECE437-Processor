/*
  Andrew Cali
  acali@purdue.edu

  ALU Test Bench
*/

// Include necessary package
`include "cpu_types_pkg.vh"

// Define timing
`timescale 1 ns / 1 ns

module alu_tb;

  parameter PERIOD = 10;

  logic CLK = 0, nRST;
  logic [31:0] A, B, out;
  logic [3:0] opcode;
  logic zero, negative, overflow;

  // Clock generation
  always #(PERIOD/2) CLK = ~CLK;

  // DUT (Device Under Test) instantiation
  alu DUT (
    .A(A),
    .B(B),
    .opcode(opcode),
    .out(out),
    .zero(zero),
    .negative(negative),
    .overflow(overflow)
  );

  // Test procedure
  initial begin
    // Initial reset
    nRST = 1'b0;
    #(PERIOD)
    nRST = 1'b1;
    #(PERIOD)

    // Test case 1: ADD operation
    A = 32'h00000010; B = 32'h00000020; opcode = 4'b0011; // A + B = 0x30
    #(PERIOD);
    assert(out == 32'h00000030) else $display("ADD failed at time %t", $time);
    assert(zero == 0) else $display("Zero flag failed at time %t", $time);
    assert(negative == 0) else $display("Negative flag failed at time %t", $time);
    assert(overflow == 0) else $display("Overflow flag failed at time %t", $time);

    // Test case 2: SUB operation
    A = 32'h00000030; B = 32'h00000020; opcode = 4'b0100; // A - B = 0x10
    #(PERIOD);
    assert(out == 32'h00000010) else $display("SUB failed at time %t", $time);

    // Test case 3: AND operation
    A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; opcode = 4'b0101; // A & B = 0x00000000
    #(PERIOD);
    assert(out == 32'h00000000) else $display("AND failed at time %t", $time);

    // Test case 4: OR operation
    A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; opcode = 4'b0110; // A | B = 0xFFFFFFFF
    #(PERIOD);
    assert(out == 32'hFFFFFFFF) else $display("OR failed at time %t, got = %h", $time, out);

    // Test case 5: XOR operation
    A = 32'hF0F0F0F0; B = 32'h0F0F0F0F; opcode = 4'b0111; // A ^ B = 0xFFFFFFFF
    #(PERIOD);
    assert(out == 32'hFFFFFFFF) else $display("XOR failed at time %t, got = %h", $time, out);

    // Test case 6: Shift Left (SLL)
    A = 32'h00000010; B = 32'h00000002; opcode = 4'b0000; // A << 2 = 0x40
    #(PERIOD);
    assert(out == 32'h00000040) else $display("SLL failed at time %t", $time);

    // Test case 7: Shift Right (SRL)
    A = 32'h00000010; B = 32'h00000002; opcode = 4'b0001; // A >> 2 = 0x04
    #(PERIOD);
    assert(out == 32'h00000004) else $display("SRL failed at time %t", $time);

    // Test case 8: Arithmetic Shift Right (SRA)
    A = 32'h80000010; B = 32'h00000002; opcode = 4'b0010; // A >>> 2 = 0xC0000004
    #(PERIOD);
    assert(out == 32'he0000004) else $display("SRA failed at time %t, got = %h", $time, out);

    // Test case 9: Set Less Than (SLT)
    A = 32'h00000010; B = 32'h00000020; opcode = 4'b1010; // A < B => 0x1
    #(PERIOD);
    assert(out == 32'h00000001) else $display("SLT failed at time %t", $time);

    // Test case 10: Set Less Than Unsigned (SLTU)
    A = 32'h00000010; B = 32'h00000020; opcode = 4'b1011; // A < B => 0x1
    #(PERIOD);
    assert(out == 32'h00000001) else $display("SLTU failed at time %t", $time);

    // Test case 11: Overflow detection for ADD (overflow case)
    A = 32'h7FFFFFFF; B = 32'h00000001; opcode = 4'b0011; // ADD overflow (result = 0x80000000)
    #(PERIOD);
    assert(out == 32'h80000000) else $display("ADD overflow failed at time %t", $time);
    assert(overflow == 1) else $display("Overflow flag failed for ADD at time %t", $time);

    // Test case 12: Overflow detection for SUB (overflow case)
    A = 32'h80000000; B = 32'h00000001; opcode = 4'b0100; // SUB overflow (result = 0x7FFFFFFF)
    #(PERIOD);
    assert(out == 32'h7FFFFFFF) else $display("SUB overflow failed at time %t", $time);
    assert(overflow == 1) else $display("Overflow flag failed for SUB at time %t", $time);

    // Finish simulation
    $finish;
  end
endmodule
