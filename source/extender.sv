`include "cpu_types_pkg.vh"
`include "extender_if.vh"
import  cpu_types_pkg::*;
module extender (
  extender_if.ex exif
);
opcode_t opcode;
funct3_ld_i_t func3ild;
funct3_i_t func3i;
funct3_r_t func3r;
funct3_b_t func3b;
funct7_r_t func7r;
funct7_srla_r_t func7rs;
assign func7r=funct7_r_t'(exif.imemload[31:25]);
assign func7rs=funct7_srla_r_t'(exif.imemload[31:25]);
assign func3i=funct3_i_t'(exif.imemload[14:12]);
assign func3b=funct3_b_t'(exif.imemload[14:12]);
assign func3r=funct3_r_t'(exif.imemload[14:12]);
assign func3ild=funct3_ld_i_t'(exif.imemload[14:12]);
assign opcode =opcode_t'(exif.imemload[6:0]);

logic beq,bne,bgt,bgtu,blt,bltu,jal,jalr;
assign beq=(opcode==BTYPE&&func3b==BEQ);
assign bne=(opcode==BTYPE&&func3b==BNE);
assign blt=(opcode==BTYPE&&func3b==BLT);
assign bge=(opcode==BTYPE&&func3b==BGE);
assign bltu=(opcode==BTYPE&&func3b==BLTU);
assign bgeu=(opcode==BTYPE&&func3b==BGEU);
assign jal=(opcode==JAL);
assign jalr=(opcode==JALR);




always_comb begin:extender_block
    

     if(opcode==ITYPE) begin
        case(func3i)
            
            SLTIU: begin
              
            exif.extended_im={20'h0,exif.imemload[31:20]};
            end
            default begin
              if(exif.imemload[31])
                exif.extended_im={20'hfffff,exif.imemload[31:20]};
                else 
                exif.extended_im={20'h0,exif.imemload[31:20]};
            end
        endcase
    end
    else if (opcode==ITYPE_LW) begin
    if(exif.imemload[31])
                exif.extended_im={20'hfffff,exif.imemload[31:20]};
                else 
                exif.extended_im={20'h0,exif.imemload[31:20]};
    end
    else if (opcode==JALR) begin
    if(exif.imemload[31])
                exif.extended_im={20'hfffff,exif.imemload[31:20]};
                else 
                exif.extended_im={20'h0,exif.imemload[31:20]};
    end
    else if (opcode==STYPE) begin
      if(exif.imemload[31])
      exif.extended_im={20'hfffff,{exif.imemload[31:25],exif.imemload[11:7]}};
      else
    exif.extended_im={20'h0,{exif.imemload[31:25],exif.imemload[11:7]}};
    end

    else if(opcode==BTYPE) begin
     
      if(exif.imemload[31])
        exif.extended_im={19'hfffff,exif.imemload[31],exif.imemload[7],exif.imemload[30:25],exif.imemload[11:8],1'b0};
      else
        exif.extended_im={19'h0,exif.imemload[31],exif.imemload[7],exif.imemload[30:25],exif.imemload[11:8],1'b0};      
      
    end

    else if(opcode == JAL) begin
      if(exif.imemload[31])
        exif.extended_im={11'hff7,exif.imemload[31],exif.imemload[19:12],exif.imemload[20],exif.imemload[30:21],1'b0};
      else
        exif.extended_im={11'h0,exif.imemload[31],exif.imemload[19:12],exif.imemload[20],exif.imemload[30:21],1'b0};
    end
  
    else begin
        exif.extended_im={exif.imemload[31:12],12'h0};
    end
end

endmodule 