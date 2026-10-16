`include "datapath_cache_if.vh"
`include "decider_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_types_pkg.vh"

module if_stage #(
  parameter PC_INIT = 0
)(
  input logic CLK,
  input logic nRST,
  datapath_cache_if.dp dpif,
  decider_if deif,
  hazard_unit_if huif,
  pipeline_types_pkg::EX_MEM ex_mem_out,
  output pipeline_types_pkg::IF_ID if_id_in
);
  import cpu_types_pkg::*;

  word_t iaddr;

  assign if_id_in.instruction = dpif.imemload;
  assign if_id_in.pc = dpif.imemaddr;
  assign dpif.imemREN = !dpif.dmemREN && !dpif.dmemWEN;

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      dpif.imemaddr <= '0;
      dpif.halt <= 0;
    end
    else begin
      dpif.imemaddr <= iaddr;
      dpif.halt <= ex_mem_out.pchalt || dpif.halt;
    end
  end

  always_comb begin
    iaddr = dpif.imemaddr;
    if(dpif.ihit) begin
      case (deif.PCsrc)
        2'b00: iaddr = huif.Halt ? dpif.imemaddr : dpif.imemaddr + 4;
        2'b01: iaddr = ex_mem_out.AdderOut;
        2'b10: iaddr = ex_mem_out.rdat1 + ex_mem_out.immediate;
      endcase
    end
  end

endmodule
