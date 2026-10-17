`include "control_request_unit_if.vh"
`include "decider_if.vh"
`include "extender_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_types_pkg.vh"

module id_stage(
  input logic CLK,
  input logic nRST,
  input pipeline_types_pkg::IF_ID if_id_q,
  input logic [31:0] rf_rdat1,
  input logic [31:0] rf_rdat2,
  input pipeline_types_pkg::ID_EX id_ex_q,
  decider_if deif,
  control_request_unit_if cruif,
  extender_if exif_in,
  hazard_unit_if huif,
  output pipeline_types_pkg::ID_EX id_ex_d
);
  import pipeline_types_pkg::*;

  assign cruif.imemload = if_id_q.instruction;
  assign exif_in.imemload = if_id_q.instruction;

  assign huif.rs1 = if_id_q.instruction[19:15];
  assign huif.rs2 = if_id_q.instruction[24:20];
  assign huif.Rd = id_ex_q.rd;
  assign huif.Pcsrc = deif.PCsrc;
  assign huif.Memtoreg = id_ex_q.MemtoReg;

  control_unit CONTROL(CLK, nRST, cruif);
  hazard_unit HAZARD(huif);
  extender EX(exif_in);

  ID_EX id_ex_raw;

  always_comb begin
    id_ex_raw = '0;
    id_ex_raw.pc = if_id_q.pc;
    id_ex_raw.pchalt = cruif.pchalt;
    id_ex_raw.MemtoReg = cruif.MemtoReg;
    id_ex_raw.AluSrc = cruif.AluSrc;
    id_ex_raw.Aluop = cruif.Aluop;
    id_ex_raw.MemWr = cruif.MemWr;
    id_ex_raw.RegWr = cruif.RegWr;
    id_ex_raw.branch = cruif.typ;
    id_ex_raw.rdat1 = rf_rdat1;
    id_ex_raw.rdat2 = rf_rdat2;
    id_ex_raw.immediate = exif_in.extended_im;
    id_ex_raw.rd = if_id_q.instruction[11:7];
    id_ex_raw.jumpsel = cruif.jumpsel;
    id_ex_raw.rs1 = if_id_q.instruction[19:15];
    id_ex_raw.rs2 = if_id_q.instruction[24:20];
  end

  assign id_ex_d = huif.Zero_controls ? '0 : id_ex_raw;

endmodule
