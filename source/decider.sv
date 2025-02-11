`include "cpu_types_pkg.vh"
`include "decider_if.vh"
import  cpu_types_pkg::*;
module decider (
  decider_if.de deif
);
logic beq,bne,bgt,bgtu,blt,bltu,jal,jalr;

assign beq=deif.typ[7];
assign bne=deif.typ[6];
assign bgt=deif.typ[5];
assign bgtu=deif.typ[4];
assign blt=deif.typ[3];
assign bltu=deif.typ[2];
assign jal=deif.typ[1];
assign jalr=deif.typ[0];
assign deif.PCsrc=(beq&&deif.Zero||bne&&!deif.Zero||bgt&&!deif.Negative||blt&&deif.Negative||jal||jalr||bltu&&!deif.Zero||bgtu&&deif.Zero);
endmodule