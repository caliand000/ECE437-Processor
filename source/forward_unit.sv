/*
  Andrew Cali
  acali@purdue.edu

  contains forwarding unit logic
*/

// forwarding unit interface
`include "forward_unit_if.vh"

// types interface include
`include "cpu_types_pkg.vh"

module forward_unit (
 
  forward_unit_if.fu fuif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;


  always_comb begin
    fuif.Alu_in1 = 2'b00;
    fuif.Alu_in2 = 2'b00;
    fuif.imm_sel = 0;

    // if((fuif.rs1 == fuif.Rd_Mem && (fuif.Rd_Mem != 0)) && (fuif.RegWR_mem) && (!fuif.MemtoReg)) begin
    //   fuif.Alu_in1 = 2'b11; 
    // end

    if((fuif.rs1 == fuif.Rd_Mem && (fuif.Rd_Mem != 0)) && (fuif.RegWR_mem)) begin
        fuif.Alu_in1 = 2'b10; 
    end
    else if((fuif.rs1 == fuif.Rd_WB && (fuif.Rd_WB != 0)) && (fuif.RegWR_WB)) begin
        fuif.Alu_in1 = 2'b01;
    end


    // if((fuif.rs2 == fuif.Rd_Mem && (fuif.Rd_Mem != 0)) && (fuif.RegWR_mem) && (!fuif.MemtoReg)) begin
    //     fuif.Alu_in2 = 2'b11; 
    // end
    if((fuif.rs2 == fuif.Rd_Mem && (fuif.Rd_Mem != 0)) && (fuif.RegWR_mem)) begin
        fuif.Alu_in2 = 2'b10; 
    end
    else if((fuif.rs2 == fuif.Rd_WB && (fuif.Rd_WB != 0)) && (fuif.RegWR_WB)) begin
        fuif.Alu_in2 = 2'b01;
    end

    if((fuif.rs1 == fuif.Rd_Mem && (fuif.Rd_Mem != 0)) && (fuif.RegWR_mem) && fuif.jumpsel == 2'b10) begin
      fuif.imm_sel = 1;
    end
  end




endmodule
