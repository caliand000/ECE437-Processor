`include "datapath_cache_if.vh"
`include "decider_if.vh"
`include "forward_unit_if.vh"
`include "pipeline_types_pkg.vh"

module ex_stage(
  datapath_cache_if.dp dpif,
  decider_if deif,
  forward_unit_if fuif,
  pipeline_types_pkg::ID_EX id_ex_out,
  pipeline_types_pkg::EX_MEM ex_mem_out,
  input logic [31:0] rf_wdat,
  input pipeline_types_pkg::MEM_WB mem_wb_in,
  pipeline_types_pkg::MEM_WB mem_wb_out,
  output pipeline_types_pkg::EX_MEM ex_mem_in
);
  import cpu_types_pkg::*;

  word_t Alu_a, Alu_b, Alu_c;
  logic Neg, Zero;

  forward_unit FORWARD(fuif);
  decider Branch(deif);
  alu ALU(.A(Alu_a), .B(Alu_c), .opcode(id_ex_out.Aluop),
    .out(ex_mem_in.AluOut), .zero(Zero), .negative(Neg), .overflow());

  always_comb begin
    Alu_a = '0;
    Alu_b = '0;
    case(fuif.Alu_in1)
      2'b00: Alu_a = id_ex_out.rdat1;
      2'b01: Alu_a = rf_wdat;
      2'b10: Alu_a = mem_wb_in.wrb;
      2'b11: Alu_a = ex_mem_out.immediate;
    endcase

    case(fuif.Alu_in2)
      2'b00: Alu_b = id_ex_out.rdat2;
      2'b01: Alu_b = rf_wdat;
      2'b10: Alu_b = mem_wb_in.wrb;
    endcase
    Alu_c = id_ex_out.AluSrc ? id_ex_out.immediate : Alu_b;
  end

  assign deif.Zero = ex_mem_out.Zero;
  assign deif.Negative = ex_mem_out.Neg;
  assign deif.typ = ex_mem_out.branch;

  assign fuif.rs1 = id_ex_out.rs1;
  assign fuif.rs2 = id_ex_out.rs2;
  assign fuif.Rd_Mem = ex_mem_out.rd;
  assign fuif.Rd_WB = mem_wb_out.rd;
  assign fuif.RegWR_mem = ex_mem_out.RegWr;
  assign fuif.RegWR_WB = mem_wb_out.RegWr;
  assign fuif.jumpsel = ex_mem_out.jumpsel;
  assign fuif.MemtoReg = ex_mem_out.MemtoReg;

  assign ex_mem_in.pc = id_ex_out.pc;
  assign ex_mem_in.pchalt = id_ex_out.pchalt;
  assign ex_mem_in.MemtoReg = id_ex_out.MemtoReg;
  assign ex_mem_in.MemWr = id_ex_out.MemWr;
  assign ex_mem_in.RegWr = id_ex_out.RegWr;
  assign ex_mem_in.Zero = Zero;
  assign ex_mem_in.Neg = Neg;
  assign ex_mem_in.branch = id_ex_out.branch;
  assign ex_mem_in.jumpsel = id_ex_out.jumpsel;
  assign ex_mem_in.read_data = dpif.dhit ? dpif.dmemload : ex_mem_out.read_data;
  assign ex_mem_in.rd = id_ex_out.rd;
  assign ex_mem_in.rdat1 = Alu_a;
  assign ex_mem_in.rdat2 = Alu_b;
  assign ex_mem_in.AdderOut = id_ex_out.pc + id_ex_out.immediate;
  assign ex_mem_in.immediate = id_ex_out.immediate;

endmodule
