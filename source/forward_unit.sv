/*
  Andrew Cali
  acali@purdue.edu

  contains forwarding unit logic
*/

// forwarding unit interface
`include "control_request_unit_if.vh"

// types interface include
`include "cpu_types_pkg.vh"

module forward_unit (
  input logic CLK, nRST,
  forward_unit_if.fu fuif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;


  always_comb begin
    fuif.Alu_in1 = 2'b00;
    fuif.Alu_in2 = 2'b00;

    if((fuif.rs1 == fuif.Rd_Mem) && (RegWr_Mem)) begin
        fuif.Alu_in1 = 2'b10; 
    end
    else if((fuif.rs1 == fuif.Rd_WB) && (RegWr_WB)) begin
        fuif.Alu_in1 = 2'b01;
    end

    if((fuif.rs2 == fuif.Rd_Mem) && (RegWr_Mem)) begin
        fuif.Alu_in1 = 2'b10; 
    end
    else if((fuif.rs2 == fuif.Rd_WB) && (RegWr_WB)) begin
        fuif.Alu_in2 = 2'b01;
    end
  end




endmodule
