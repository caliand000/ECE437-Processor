`include "hazard_unit_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module hazard_unit (
  
  hazard_unit_if.hu huif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  

  always_comb begin
  if((huif.rs1==huif.Rd&&huif.rs1!=0||huif.rs2==huif.Rd&&huif.rs2!=0)&&huif.Memtoreg) begin
  huif.latch_en=0;
  huif.Halt=1;
  huif.Zero_controls=1;
  end
  else begin
  huif.latch_en=1;
  huif.Halt=0;
  huif.Zero_controls=0;
  end

  if(huif.Pcsrc) begin
  huif.latch_en=0;
  huif.Halt=1;
  huif.Zero_controls=1;
  huif.Flush=1;
  end
  else begin
  huif.latch_en=1;
  huif.Halt=0;
  huif.Zero_controls=0;
  huif.Flush=0;
  end
  end



endmodule