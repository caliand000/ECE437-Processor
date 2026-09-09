`include "cpu_types_pkg.vh"

module alu
import cpu_types_pkg::*;
(
  input logic [31:0] A, B, // Input operands
  input logic [4:0] opcode, // Operation code
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
      5'b00011: intermediate_result = A + B; // ADD
      5'b00100: intermediate_result = A - B; // SUB
      5'b00101: intermediate_result = A & B; // AND
      5'b00110: intermediate_result = A | B; // OR
      5'b00111: intermediate_result = A ^ B; // XOR
      5'b00000: intermediate_result = A << B[4:0]; // SLL
      5'b00001: intermediate_result = A >> B[4:0]; // SRL
      5'b00010: intermediate_result = $signed(A) >>> B[4:0]; // SRA
      5'b01010: intermediate_result = ($signed(A) < $signed(B)) ? 32'b1 : 32'b0; // SLT
      5'b01011: intermediate_result = (A < B) ? 32'b1 : 32'b0; // SLTU
      default: intermediate_result = '0; // Default case
    endcase

    // Set flags
    zero = (intermediate_result == 32'b0);
    negative = intermediate_result[31];

    // Overflow detection for ADD and SUB
    if (opcode == 5'b00011) begin // ADD
      overflow = (A[31] & B[31] & ~intermediate_result[31]) | (~A[31] & ~B[31] & intermediate_result[31]);
    end else if (opcode == 5'b00100) begin // SUB
      overflow = (A[31] & ~B[31] & ~intermediate_result[31]) | (~A[31] & B[31] & intermediate_result[31]);
    end
  end

  assign out = intermediate_result;

endmodule
