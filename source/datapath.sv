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

  IF_ID if_id_d;
  IF_ID if_id_q;
  ID_EX id_ex_d;
  ID_EX id_ex_q;
  EX_MEM ex_mem_d;
  EX_MEM ex_mem_q;
  MEM_WB mem_wb_d;
  MEM_WB mem_wb_q;

  logic [31:0] rf_wdat, rf_rdat1, rf_rdat2;

  if_stage #(.PC_INIT(PC_INIT)) IF_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .deif(deif), .huif(huif),
    .ex_mem_q(ex_mem_q), .if_id_d(if_id_d)
  );
  id_stage ID_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_q(if_id_q),
    .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2), .id_ex_q(id_ex_q),
    .deif(deif),
    .cruif(cruif), .exif_in(exif_in), .huif(huif), .id_ex_d(id_ex_d)
  );
  ex_stage EX_STAGE(
    .dpif(dpif), .deif(deif), .fuif(fuif), .id_ex_q(id_ex_q),
    .ex_mem_q(ex_mem_q), .rf_wdat(rf_wdat), .mem_wb_d(mem_wb_d),
    .mem_wb_q(mem_wb_q), .ex_mem_d(ex_mem_d)
  );
  mem_stage MEM_STAGE(
    .CLK(CLK), .nRST(nRST), .dpif(dpif), .huif(huif),
    .id_ex_q(id_ex_q), .ex_mem_q(ex_mem_q), .mem_wb_d(mem_wb_d)
  );
  wb_stage WB_STAGE(
    .CLK(CLK), .nRST(nRST), .if_id_q(if_id_q),
    .mem_wb_q(mem_wb_q), .rf_rdat1(rf_rdat1), .rf_rdat2(rf_rdat2),
    .rf_wdat(rf_wdat)
  );

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_q <= '0;
      id_ex_q <= '0;
      ex_mem_q <= '0;
      mem_wb_q <= '0;
    end
    else begin
      if(dpif.ihit && (!(dpif.dmemREN || dpif.dmemWEN) || dpif.dhit)) begin
        if(huif.Flush) begin
          if_id_q <= '0;
          id_ex_q <= '0;
          ex_mem_q <= '0;
        end
        else if(huif.latch_en) begin
          if_id_q <= if_id_d;
          id_ex_q <= id_ex_d;
          ex_mem_q <= ex_mem_d;
        end
        else begin
          if_id_q <= if_id_q;
          id_ex_q <= id_ex_d;
          ex_mem_q <= ex_mem_d;
        end
        mem_wb_q <= mem_wb_d;
      end
      else if(dpif.dhit) begin
        ex_mem_q.read_data <= ex_mem_d.read_data;
      end
    end
  end

endmodule
