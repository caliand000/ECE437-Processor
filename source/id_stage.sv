`include "control_request_unit_if.vh"
`include "decider_if.vh"
`include "extender_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_types_pkg.vh"

module id_stage(
  input logic CLK,
  input logic nRST,
  pipeline_types_pkg::IF_ID if_id_out,
  input logic [31:0] rf_rdat1,
  input logic [31:0] rf_rdat2,
  pipeline_types_pkg::ID_EX id_ex_out,
  decider_if deif,
  control_request_unit_if cruif,
  extender_if exif_in,
  hazard_unit_if huif,
  output pipeline_types_pkg::ID_EX id_ex_in
);
  assign cruif.imemload = if_id_out.instruction;
  assign exif_in.imemload = if_id_out.instruction;

  assign huif.rs1 = if_id_out.instruction[19:15];
  assign huif.rs2 = if_id_out.instruction[24:20];
  assign huif.Rd = id_ex_out.rd;
  assign huif.Pcsrc = deif.PCsrc;
  assign huif.Memtoreg = id_ex_out.MemtoReg;

  control_unit CONTROL(CLK, nRST, cruif);
  hazard_unit HAZARD(huif);
  extender EX(exif_in);

  assign id_ex_in.pc = huif.Zero_controls ? 0 : if_id_out.pc;
  assign id_ex_in.pchalt = huif.Zero_controls ? 0 : cruif.pchalt;
  assign id_ex_in.MemtoReg = huif.Zero_controls ? 0 : cruif.MemtoReg;
  assign id_ex_in.AluSrc = huif.Zero_controls ? 0 : cruif.AluSrc;
  assign id_ex_in.Aluop = huif.Zero_controls ? 0 : cruif.Aluop;
  assign id_ex_in.MemWr = huif.Zero_controls ? 0 : cruif.MemWr;
  assign id_ex_in.RegWr = huif.Zero_controls ? 0 : cruif.RegWr;
  assign id_ex_in.branch = huif.Zero_controls ? 0 : cruif.typ;
  assign id_ex_in.rdat1 = huif.Zero_controls ? 0 : rf_rdat1;
  assign id_ex_in.rdat2 = huif.Zero_controls ? 0 : rf_rdat2;
  assign id_ex_in.immediate = huif.Zero_controls ? 0 : exif_in.extended_im;
  assign id_ex_in.rd = huif.Zero_controls ? 0 : if_id_out.instruction[11:7];
  assign id_ex_in.jumpsel = huif.Zero_controls ? 0 : cruif.jumpsel;
  assign id_ex_in.rs1 = huif.Zero_controls ? 0 : if_id_out.instruction[19:15];
  assign id_ex_in.rs2 = huif.Zero_controls ? 0 : if_id_out.instruction[24:20];

endmodule
