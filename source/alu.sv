`include "cpu_types_pkg.vh"

module alu
import cpu_types_pkg::*;
(
  input logic [31:0] A, B, // Input operands
  input logic [3:0] opcode, // Operation code
  output logic [31:0] out, // Result of the operation
  output logic zero, negative, overflow // Flags
);

  logic [31:0] intermediate_result;

  always_comb begin
    // Default outputs
    intermediate_result = '0;
    zero = 1'b0;
    negative = 1'b0;
    overflow = 1'b0;

    case (opcode)
      4'b0011: intermediate_result = A + B; // ADD
      4'b0100: intermediate_result = A - B; // SUB
      4'b0101: intermediate_result = A & B; // AND
      4'b0110: intermediate_result = A | B; // OR
      4'b0111: intermediate_result = A ^ B; // XOR
      4'b0000: intermediate_result = A << B[4:0]; // SLL
      4'b0001: intermediate_result = A >> B[4:0]; // SRL
      4'b0010: intermediate_result = $signed(A) >>> B[4:0]; // SRA
      4'b1010: intermediate_result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
      4'b1011: intermediate_result = (A < B) ? 32'b1 : 32'b0; // SLTU
      default: intermediate_result = '0; // Default case
    endcase

    // Set flags
    zero = (intermediate_result == 32'b0);
    negative = intermediate_result[31];

    // Overflow detection for ADD and SUB
    if (opcode == 4'b0011) begin // ADD
      overflow = (A[31] & B[31] & ~intermediate_result[31]) | (~A[31] & ~B[31] & intermediate_result[31]);
    end else if (opcode == 4'b0100) begin // SUB
      overflow = (A[31] & ~B[31] & ~intermediate_result[31]) | (~A[31] & B[31] & intermediate_result[31]);
    end
  end

  assign out = intermediate_result;

endmodule