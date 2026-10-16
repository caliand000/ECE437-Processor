`include "pipeline_types_pkg.vh"

module wb_stage(
  input logic CLK,
  input logic nRST,
  input pipeline_types_pkg::IF_ID if_id_out,
  input pipeline_types_pkg::MEM_WB mem_wb_out,
  output logic [31:0] rf_rdat1,
  output logic [31:0] rf_rdat2,
  output logic [31:0] rf_wdat
);
  logic [4:0] rf_rsel1, rf_rsel2;
  logic [4:0] rf_wsel;
  logic rf_WEN;

  assign rf_rsel1 = if_id_out.instruction[19:15];
  assign rf_rsel2 = if_id_out.instruction[24:20];
  assign rf_wsel = mem_wb_out.rd;
  assign rf_WEN = mem_wb_out.RegWr;
  assign rf_wdat = mem_wb_out.MemtoReg ? mem_wb_out.read_data : mem_wb_out.wrb;

  register_file REG_FILE(
    .CLK(CLK),
    .nRST(nRST),
    .WEN(rf_WEN),
    .wsel(rf_wsel),
    .rsel1(rf_rsel1),
    .rsel2(rf_rsel2),
    .wdat(rf_wdat),
    .rdat1(rf_rdat1),
    .rdat2(rf_rdat2)
  );

endmodule
