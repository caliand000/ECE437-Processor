`include "datapath_cache_if.vh"
`include "hazard_unit_if.vh"
`include "pipeline_types_pkg.vh"

module mem_stage(
  input logic CLK,
  input logic nRST,
  datapath_cache_if.dp dpif,
  hazard_unit_if huif,
  input pipeline_types_pkg::ID_EX id_ex_q,
  input pipeline_types_pkg::EX_MEM ex_mem_q,
  output pipeline_types_pkg::MEM_WB mem_wb_d
);
  assign dpif.dmemstore = ex_mem_q.rdat2;
  assign dpif.dmemaddr = ex_mem_q.AluOut;

  always_comb begin
    mem_wb_d = '0;
    mem_wb_d.pc = ex_mem_q.pc;
    mem_wb_d.pchalt = ex_mem_q.pchalt;
    mem_wb_d.RegWr = ex_mem_q.RegWr;
    mem_wb_d.rd = ex_mem_q.rd;
    mem_wb_d.MemtoReg = ex_mem_q.MemtoReg;
    mem_wb_d.read_data = (dpif.ihit && dpif.dhit) ? dpif.dmemload : ex_mem_q.read_data;

    case(ex_mem_q.jumpsel)
      2'b00: mem_wb_d.wrb = ex_mem_q.AluOut;
      2'b01: mem_wb_d.wrb = ex_mem_q.AdderOut;
      2'b10: mem_wb_d.wrb = ex_mem_q.immediate;
      2'b11: mem_wb_d.wrb = ex_mem_q.AdderOut - ex_mem_q.immediate + 4;
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
      else if(id_ex_q.MemWr == 2'b01 && dpif.ihit && !huif.Flush)
        dpif.dmemWEN <= 1;
      else if(id_ex_q.MemWr == 2'b10 && dpif.ihit && !huif.Flush)
        dpif.dmemREN <= 1;
    end
  end

endmodule
