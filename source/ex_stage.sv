`include "datapath_cache_if.vh"
`include "decider_if.vh"
`include "forward_unit_if.vh"
`include "pipeline_types_pkg.vh"

module ex_stage(
  datapath_cache_if.dp dpif,
  decider_if deif,
  forward_unit_if fuif,
  input pipeline_types_pkg::ID_EX id_ex_q,
  input pipeline_types_pkg::EX_MEM ex_mem_q,
  input logic [31:0] rf_wdat,
  input pipeline_types_pkg::MEM_WB mem_wb_d,
  input pipeline_types_pkg::MEM_WB mem_wb_q,
  output pipeline_types_pkg::EX_MEM ex_mem_d
);
  import cpu_types_pkg::*;
  import pipeline_types_pkg::*;

  word_t Alu_a, Alu_b, Alu_c;
  logic Neg, Zero;
  word_t alu_out;
  EX_MEM ex_mem_raw;

  forward_unit FORWARD(fuif);
  decider Branch(deif);
  alu ALU(.A(Alu_a), .B(Alu_c), .opcode(id_ex_q.Aluop),
    .out(alu_out), .zero(Zero), .negative(Neg), .overflow());

  always_comb begin
    Alu_a = '0;
    Alu_b = '0;
    case(fuif.Alu_in1)
      2'b00: Alu_a = id_ex_q.rdat1;
      2'b01: Alu_a = rf_wdat;
      2'b10: Alu_a = mem_wb_d.wrb;
      2'b11: Alu_a = ex_mem_q.immediate;
    endcase

    case(fuif.Alu_in2)
      2'b00: Alu_b = id_ex_q.rdat2;
      2'b01: Alu_b = rf_wdat;
      2'b10: Alu_b = mem_wb_d.wrb;
    endcase
    Alu_c = id_ex_q.AluSrc ? id_ex_q.immediate : Alu_b;
  end

  assign deif.Zero = ex_mem_q.Zero;
  assign deif.Negative = ex_mem_q.Neg;
  assign deif.typ = ex_mem_q.branch;

  assign fuif.rs1 = id_ex_q.rs1;
  assign fuif.rs2 = id_ex_q.rs2;
  assign fuif.Rd_Mem = ex_mem_q.rd;
  assign fuif.Rd_WB = mem_wb_q.rd;
  assign fuif.RegWR_mem = ex_mem_q.RegWr;
  assign fuif.RegWR_WB = mem_wb_q.RegWr;
  assign fuif.jumpsel = ex_mem_q.jumpsel;
  assign fuif.MemtoReg = ex_mem_q.MemtoReg;

  always_comb begin
    ex_mem_raw = '0;
    ex_mem_raw.pc = id_ex_q.pc;
    ex_mem_raw.pchalt = id_ex_q.pchalt;
    ex_mem_raw.MemtoReg = id_ex_q.MemtoReg;
    ex_mem_raw.MemWr = id_ex_q.MemWr;
    ex_mem_raw.RegWr = id_ex_q.RegWr;
    ex_mem_raw.Zero = Zero;
    ex_mem_raw.Neg = Neg;
    ex_mem_raw.branch = id_ex_q.branch;
    ex_mem_raw.jumpsel = id_ex_q.jumpsel;
    ex_mem_raw.read_data = dpif.dhit ? dpif.dmemload : ex_mem_q.read_data;
    ex_mem_raw.rd = id_ex_q.rd;
    ex_mem_raw.rdat1 = Alu_a;
    ex_mem_raw.rdat2 = Alu_b;
    ex_mem_raw.AdderOut = id_ex_q.pc + id_ex_q.immediate;
    ex_mem_raw.AluOut = alu_out;
    ex_mem_raw.immediate = id_ex_q.immediate;
    ex_mem_d = ex_mem_raw;
  end

endmodule
