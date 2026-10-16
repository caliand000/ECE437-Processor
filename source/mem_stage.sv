`include "datapath_cache_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_types_pkg.vh"

module mem_stage(
  input logic CLK,
  input logic nRST,
  datapath_cache_if.dp dpif,
  hazard_unit_if huif,
  input pipeline_types_pkg::ID_EX id_ex_out,
  input pipeline_types_pkg::EX_MEM ex_mem_out,
  output pipeline_types_pkg::MEM_WB mem_wb_in
);
  assign dpif.dmemstore = ex_mem_out.rdat2;
  assign dpif.dmemaddr = ex_mem_out.AluOut;

  assign mem_wb_in.pc = ex_mem_out.pc;
  assign mem_wb_in.pchalt = ex_mem_out.pchalt;
  assign mem_wb_in.RegWr = ex_mem_out.RegWr;
  assign mem_wb_in.rd = ex_mem_out.rd;
  assign mem_wb_in.MemtoReg = ex_mem_out.MemtoReg;
  assign mem_wb_in.read_data = (dpif.ihit && dpif.dhit) ? dpif.dmemload : ex_mem_out.read_data;

  always_comb begin
    case(ex_mem_out.jumpsel)
      2'b00: mem_wb_in.wrb = ex_mem_out.AluOut;
      2'b01: mem_wb_in.wrb = ex_mem_out.AdderOut;
      2'b10: mem_wb_in.wrb = ex_mem_out.immediate;
      2'b11: mem_wb_in.wrb = ex_mem_out.AdderOut - ex_mem_out.immediate + 4;
    endcase
  end

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      dpif.dmemREN <= 0;
      dpif.dmemWEN <= 0;
    end
    else begin
      if(dpif.dhit) begin
        dpif.dmemREN <= 0;
        dpif.dmemWEN <= 0;
      end
      else if(id_ex_out.MemWr == 2'b01 && dpif.ihit && !huif.Flush)
        dpif.dmemWEN <= 1;
      else if(id_ex_out.MemWr == 2'b10 && dpif.ihit && !huif.Flush)
        dpif.dmemREN <= 1;
    end
  end

endmodule
