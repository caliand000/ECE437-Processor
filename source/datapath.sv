`include "datapath_cache_if.vh"
`include "control_request_unit_if.vh"
`include "extender_if.vh"
`include "decider_if.vh"
`include "hazard_unit_if.vh"
`include "forward_unit_if.vh"
`include "cpu_types_pkg.vh"
`include "pipeline_types_pkg.vh"

module datapath #(
  parameter PC_INIT = 0
)(
  input logic CLK,
  input logic nRST,
  datapath_cache_if.dp dpif
);
  import pipeline_types_pkg::*;

  control_request_unit_if cruif();
  extender_if exif_in();
  decider_if deif();
  hazard_unit_if huif();
  forward_unit_if fuif();

  IF_ID if_id_in;
  IF_ID if_id_out;
  ID_EX id_ex_in;
  ID_EX id_ex_out;
  EX_MEM ex_mem_in;
  EX_MEM ex_mem_out;
  MEM_WB mem_wb_in;
  MEM_WB mem_wb_out;

  logic [31:0] rf_wdat, rf_rdat1, rf_rdat2;

  if_stage #(.PC_INIT(PC_INIT)) IF_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .deif(deif), .huif(huif),
    .ex_mem_out(ex_mem_out), .if_id_in(if_id_in)
  );
  id_stage ID_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_out(if_id_out),
    .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2), .id_ex_out(id_ex_out),
    .deif(deif),
    .cruif(cruif), .exif_in(exif_in), .huif(huif), .id_ex_in(id_ex_in)
  );
  ex_stage EX_STAGE(
    .dpif(dpif), .deif(deif), .fuif(fuif), .id_ex_out(id_ex_out),
    .ex_mem_out(ex_mem_out), .rf_wdat(rf_wdat), .mem_wb_in(mem_wb_in),
    .mem_wb_out(mem_wb_out),
    .ex_mem_in(ex_mem_in)
  );
  mem_stage MEM_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .huif(huif),
    .id_ex_out(id_ex_out), .ex_mem_out(ex_mem_out),
    .mem_wb_in(mem_wb_in)
  );
  wb_stage WB_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_out(if_id_out),
    .mem_wb_out(mem_wb_out), .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2),
    .rf_wdat(rf_wdat)
  );

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_out <= '0;
      id_ex_out <= '0;
      ex_mem_out <= '0;
      mem_wb_out <= '0;
    end
    else begin
      if(dpif.ihit && (!(dpif.dmemREN || dpif.dmemWEN) || dpif.dhit)) begin
        if(huif.Flush) begin
          if_id_out <= '0;
          id_ex_out <= '0;
          ex_mem_out <= '0;
        end
        else if(huif.latch_en) begin
          if_id_out <= if_id_in;
          id_ex_out <= id_ex_in;
          ex_mem_out <= ex_mem_in;
        end
        else begin
          if_id_out <= if_id_out;
          id_ex_out <= id_ex_in;
          ex_mem_out <= ex_mem_in;
        end
        mem_wb_out <= mem_wb_in;
      end
      else if(dpif.dhit) begin
        ex_mem_out.read_data <= ex_mem_in.read_data;
      end
    end
  end

endmodule
