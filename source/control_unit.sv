/*
  Andrew Cali
  acali@purdue.edu

  control contains logic for decoding instructions and setting flag signals
*/

// data path interface
`include "control_request_unit_if.vh"

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"

module control_unit (
  input logic CLK, nRST,
  control_request_unit_if.cu cuif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;

  r_t rtype;
  i_t itype;
  j_t jtype;
  s_t stype;
  b_t btype;
  u_t utype;
  logic beq,bne,bge,blt,bgeu,bltu,jal,jalr;
  assign cuif.typ={beq,bne,bge,bgeu,blt,bltu,jal,jalr};

  always_comb begin
    beq=0;
    bne=0;
    bge=0;
    blt=0;
    bgeu=0;
    bltu=0;
    jal=0;
    jalr=0;
    rtype = cuif.imemload;
    itype = cuif.imemload;
    jtype = cuif.imemload;
    stype = cuif.imemload;
    btype = cuif.imemload;
    utype = cuif.imemload;

    cuif.MemWr = '0;
    cuif.MemtoReg = 0;
    cuif.Aluop = ALU_SLL;
    cuif.AluSrc = 0;
    cuif.RegWr = 0;
    cuif.Rd = '0;
    cuif.Rs1 = '0;
    cuif.Rs2 = '0;
    cuif.Imm = '0;
    cuif.PCSrc = '0;
    cuif.jumpsel = 0;
    cuif.pchalt = 0;

    case(rtype.opcode)
      RTYPE: begin    
        cuif.RegWr = 1;
        cuif.Rd = rtype.rd;
        cuif.Rs1 = rtype.rs1;
        cuif.Rs2 = rtype.rs2;

        case(rtype.funct3)
          SLL:cuif.Aluop = ALU_SLL;
          SRL_SRA: cuif.Aluop = (rtype.funct7 == SRA)? ALU_SRA:(rtype.funct7 == SRL)? ALU_SRL:ALU_SLL;
          ADD_SUB:cuif.Aluop = (rtype.funct7 == ADD)? ALU_ADD:(rtype.funct7 == SUB)? ALU_SUB:ALU_SLL;
          AND:cuif.Aluop = ALU_AND;
          OR:cuif.Aluop = ALU_OR;
          XOR:cuif.Aluop = ALU_XOR;
          SLT:cuif.Aluop = ALU_SLT;
          SLTU:cuif.Aluop = ALU_SLTU;
        endcase 
      end

      ITYPE: begin     
        cuif.RegWr = 1;                               //write to register enable
        cuif.AluSrc = 1;                              //select extended field
        cuif.Rd = rtype.rd;                           //destination register
        cuif.Rs1 = rtype.rs1;                         //first register field
        cuif.Imm = {{20{itype.imm[11]}},itype.imm};    //sign extend the immediate field
        
        case(itype.funct3)
          ADDI:cuif.Aluop = ALU_ADD;
          XORI: cuif.Aluop = ALU_XOR;
          ORI:cuif.Aluop = ALU_OR;
          ANDI:cuif.Aluop = ALU_AND;
          SLLI:cuif.Aluop = ALU_SLL;
          SRLI_SRAI: begin
            if(itype.imm[11:5] == 7'h00) begin
              cuif.Aluop = ALU_SRL;
            end
            else if(itype.imm[11:5] == 7'h20) begin
              cuif.Aluop = ALU_SRA;
            end
            // cuif.Aluop = ALU_SRA;
          end          
          SLTI:cuif.Aluop = ALU_SLT;
          SLTIU:begin 
            cuif.Aluop = ALU_SLTU;
            cuif.Imm = {{20{1'b0}},itype.imm};    //sign extend the immediate field
          end
        endcase 
      end

      ITYPE_LW: begin                                 //R[rd] <= M[R[rs1] + imm]
        cuif.RegWr = 1;                               //writing to rd
        cuif.AluSrc = 1;                              //select extended immediate field to add to rs1
        cuif.MemtoReg = 1;                            //select dmemload from request unit output
        cuif.MemWr = 2'b10;                           //read from memorys
        cuif.Aluop = ALU_ADD;                         //adding immediate field to rs1 
        cuif.Rd = itype.rd;                           //destination register
        cuif.Rs1 = itype.rs1;                         //first register field
        cuif.Imm = {{20{itype.imm[11]}},itype.imm};   //sign extend the immediate field
      end

      JALR: begin         
        jalr=1;                            //R[rd] <= PC + 4; PC <= R[rs1] + imm
        cuif.RegWr = 1;                               //writing to rd  
        cuif.jumpsel = 2'b11;                             //writing PC + 4 to rd
        cuif.PCSrc = 2'b10;                           //writing PC to rs1 + imm

        cuif.Rd = itype.rd;
        cuif.Rs1 = cuif.imemload[19:15];                           //destination register
        // cuif.Rs1 = itype.rs1;                         //first register field

        cuif.Imm = {{20{itype.imm[11]}},itype.imm};    //sign extend the immediate field

      end
      STYPE: begin                                      //M[R[rs1] + imm] <= R[rs2]
        cuif.AluSrc = 1;                                //select extended immediate field to add to rs1
        cuif.MemWr = 2'b01;                             //writing to location [R[rs1] + imm] in memory
        cuif.Aluop = ALU_ADD;
        cuif.PCSrc = 0;
        cuif.Rs1 = stype.rs1;
        cuif.Rs2 = stype.rs2;

        cuif.Imm = {{20{stype.imm2[6]}},stype.imm2, stype.imm1};


      end
      BTYPE: begin                                      //PC <= (R[rs1] == R[rs2])? PC + imm: PC + 4
        cuif.Rs1 = btype.rs1;
        cuif.Rs2 = btype.rs2;
        cuif.Imm = {{20{btype.imm2[6]}},btype.imm2[6], btype.imm1[0],btype.imm2[5:0], btype.imm1[4:1], 1'b0};

        case(btype.funct3)                              //branch type it is to update PCSrc, is it ok to do that here or will that delay?
          BEQ: begin
            beq=1;
            cuif.Aluop = ALU_SUB;
            cuif.PCSrc = (cuif.zero)? 2'b01:'0;
          end
          BNE: begin
            bne=1;
            cuif.Aluop = ALU_SUB;
            cuif.PCSrc = (!cuif.zero)? 2'b01: '0;
          end
          BLT: begin
            blt=1;
            cuif.Aluop = ALU_SUB;
            cuif.PCSrc = (cuif.neg)? 2'b01: '0;
          end
          BGE: begin
            bge=1;
            cuif.Aluop = ALU_SUB;
            cuif.PCSrc = (!cuif.neg || cuif.zero)? 2'b01: '0;
          end
          BLTU: begin
            bltu=1;
            cuif.Imm = {{20{1'b0}},cuif.Imm[11:0]};        //unsigned
            cuif.Aluop = ALU_SLTU;
            cuif.PCSrc = (cuif.neg)? 2'b01: '0;
          end
          BGEU: begin
            bgeu=1;
            cuif.Imm = {{20{1'b0}},cuif.Imm[11:0]};        //unsigned
            cuif.Aluop = ALU_SLTU;
            cuif.PCSrc = (!cuif.neg || cuif.zero)? 2'b01: '0;
          end
        endcase
      end
      JAL: begin        
        jal=1;                                //R[rd] <= PC+4; PC <= PC+imm
        cuif.RegWr = 1;
        cuif.jumpsel = 2'b11;
        cuif.PCSrc = 2'b01;
        cuif.Rd = jtype.rd;
        cuif.Imm = {{11{jtype.imm[19]}}, jtype.imm[19], jtype.imm[7:0], jtype.imm[8], jtype.imm[18:9], 1'b0};

      end
      LUI: begin                                        //R[rd] <= {imm, 12b'0}
        cuif.Rd = utype.rd;
        cuif.RegWr = 1;
        cuif.jumpsel = 2'b10;
        cuif.Imm = {{32{utype.imm[11]}},utype.imm, {12{1'b0}}};

      end
      AUIPC: begin           //R[rd] <= PC + {imm, 12b'0}
        cuif.Rd = utype.rd;
        cuif.RegWr = 1;
        cuif.jumpsel = 2'b01;
        cuif.Imm = {cuif.Imm, {12{1'b0}}};
      end
      // LR_SC: begin            //atomic instructions?
        
      // end;
      HALT: begin     
        cuif.pchalt = 1;
      end
    endcase

  end

endmodule
