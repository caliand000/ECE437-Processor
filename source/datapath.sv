/*
  Eric Villasenor
  evillase@gmail.com

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"
`include "control_request_unit_if.vh"
`include "extender_if.vh"
`include "decider_if.vh"
`include "hazard_unit_if.vh"
`include "forward_unit_if.vh"
// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"
`include "pipeline_types_pkg.vh"

module datapath(
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;
  import pipeline_types_pkg::*;

  //interface
  control_request_unit_if cruif();
  register_file_if rfif();
  extender_if exif_in();
  decider_if deif();
  hazard_unit_if huif();
  forward_unit_if fuif();
  // pc init
  parameter PC_INIT = 0;

  //internal signals
  word_t iaddr, Aluout, outdata, Alu_a, Alu_b, Alu_c, Alu_d;

  //internal pipelined signals
  IF_ID if_id_in;
  IF_ID if_id_out;
  IF_ID if_id_nxt;

  ID_EX id_ex_in;
  ID_EX id_ex_out;
  ID_EX id_ex_nxt;

  EX_MEM ex_mem_in;
  EX_MEM ex_mem_out;
  EX_MEM ex_mem_nxt;

  MEM_WB mem_wb_in;
  MEM_WB mem_wb_out;
  MEM_WB mem_wb_nxt;


  //================Instances================
  control_unit      CONTROL(CLK, nRST, cruif);
  decider           Branch(deif);
  register_file     REG_FILE(CLK, nRST, rfif);
  alu               ALU(.A(Alu_a), .B(Alu_c), .opcode(id_ex_out.Aluop), .out(ex_mem_in.AluOut), .zero(deif.Zero), .negative(deif.Negative));
  extender          EX(exif_in);
  hazard_unit       HAZARD(huif);
  forward_unit      FORWARD(fuif);

  //interface/signal connections


  //================ALU================
  always_comb begin
    case(fuif.Alu_in1)
      2'b00:Alu_a = id_ex_out.rdat1;
      2'b01:Alu_a = rfif.wdat;
      2'b10:Alu_a = mem_wb_in.wrb;
      2'b11:Alu_a = ex_mem_out.immediate;
    endcase

    

    case(fuif.Alu_in2)
      2'b00:Alu_b = id_ex_out.rdat2;
      2'b01:Alu_b = rfif.wdat;
      2'b10:Alu_b = mem_wb_in.wrb;
      2'b11:Alu_b = ex_mem_out.immediate;
    endcase
    Alu_c = (id_ex_out.AluSrc)? id_ex_out.immediate: Alu_b;
  end

  //================Immediate Generator(Extender)================
  assign exif_in.imemload = if_id_out.instruction;

  //================Register File================
  assign rfif.rsel1 = if_id_out.instruction[19:15];
  assign rfif.rsel2 = if_id_out.instruction[24:20];
  assign rfif.wsel = mem_wb_out.rd;
  assign rfif.WEN = mem_wb_out.RegWr;
  assign rfif.wdat = (mem_wb_out.MemtoReg)? mem_wb_out.read_data:mem_wb_out.wrb;

  //================IF/ID================
  assign if_id_in.instruction = dpif.imemload;
  assign if_id_in.pc = dpif.imemaddr;

  //================IF/ID -> ID/EX================
  assign id_ex_in.pc = if_id_out.pc;
  assign id_ex_in.pchalt = cruif.pchalt;
  assign id_ex_in.MemtoReg = cruif.MemtoReg;
  assign id_ex_in.AluSrc = cruif.AluSrc;
  assign id_ex_in.Aluop = cruif.Aluop;
  assign id_ex_in.MemWr = cruif.MemWr;
  assign id_ex_in.RegWr = cruif.RegWr;
  assign id_ex_in.branch = cruif.typ;
  assign id_ex_in.rdat1 = rfif.rdat1; 
  assign id_ex_in.rdat2 = rfif.rdat2;
  assign id_ex_in.immediate = exif_in.extended_im;
  assign id_ex_in.rd = if_id_out.instruction[11:7];
  assign id_ex_in.jumpsel = cruif.jumpsel;
  assign id_ex_in.rs1 = if_id_out.instruction[19:15];
  assign id_ex_in.rs2 = if_id_out.instruction[24:20];
 
  //================ID/EX -> EX/MEM================
  assign ex_mem_in.pchalt = id_ex_out.pchalt;
  assign ex_mem_in.MemtoReg = id_ex_out.MemtoReg;
  assign ex_mem_in.MemWr = id_ex_out.MemWr;
  assign ex_mem_in.PCSrc = deif.PCsrc;
  assign ex_mem_in.RegWr = id_ex_out.RegWr;
  assign ex_mem_in.jumpsel = id_ex_out.jumpsel;
  assign ex_mem_in.read_data = dpif.dhit ?dpif.dmemload: ex_mem_out.read_data;  // assign mem_wb_in.MemtoReg=ex_mem_out.MemtoReg;n.read_data =dpif.dhit ? dpif.dmemload : ex_mem_out.read_data;
  assign ex_mem_in.rd=id_ex_out.rd;
  assign ex_mem_in.rdat2=Alu_b;
  assign ex_mem_in.AdderOut= id_ex_out.pc + id_ex_out.immediate;
  assign ex_mem_in.immediate=id_ex_out.immediate;
  //================EX/MEM -> MEM/WB================
  assign mem_wb_in.pchalt=ex_mem_out.pchalt;
  assign mem_wb_in.RegWr=ex_mem_out.RegWr;
  assign mem_wb_in.rd=ex_mem_out.rd;
  assign mem_wb_in.MemtoReg=ex_mem_out.MemtoReg;
  assign mem_wb_in.read_data=ex_mem_out.read_data;
  always_comb begin
  case(ex_mem_out.jumpsel) 
    2'b00:mem_wb_in.wrb = ex_mem_out.AluOut;
    2'b01:mem_wb_in.wrb = ex_mem_out.AdderOut;
    2'b10:mem_wb_in.wrb = ex_mem_out.immediate;
    2'b11:mem_wb_in.wrb = ex_mem_out.AdderOut-ex_mem_out.immediate + 4;
  endcase
  end

  //assigning internal signals
  assign deif.typ=id_ex_out.branch; 
  assign dpif.imemREN = 1;
  assign dpif.dmemstore = ex_mem_out.rdat2;
  assign dpif.dmemaddr = ex_mem_out.AluOut;

  //================Connections to Data Memory/Memory Controller================
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
      else if(id_ex_out.MemWr == 2'b01 && dpif.ihit) dpif.dmemWEN <= 1;
      else if(id_ex_out.MemWr == 2'b10 && dpif.ihit) dpif.dmemREN <= 1;
    end
    end

  //================control unit================
  assign cruif.imemload = if_id_out.instruction;

  //================Forward unit================  
  assign fuif.rs1 = id_ex_out.rs1;
  assign fuif.rs2 = id_ex_out.rs2;
  assign fuif.Rd_Mem = ex_mem_out.rd;
  assign fuif.Rd_WB = mem_wb_out.rd;
  assign fuif.RegWR_mem = ex_mem_out.RegWr;
  assign fuif.RegWR_WB = mem_wb_out.RegWr;
  assign fuif.jumpsel = ex_mem_out.jumpsel;
  assign fuif.MemtoReg = ex_mem_out.MemtoReg;

  //================Hazard unit================ 
  assign huif.rs1= if_id_out.instruction[19:15];
  assign huif.rs2 = if_id_out.instruction[24:20];
  assign huif.Rd=id_ex_out.rd;
  assign huif.Pcsrc= deif.PCsrc;
  assign huif.Memtoreg=id_ex_out.MemtoReg;

  //================Program Count Logic================
  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      dpif.imemaddr <= '0;
      // dpif.halt <= 0;
    end 
    else begin
      dpif.imemaddr <= iaddr;
      // if(ex_mem_out.pchalt) dpif.halt <= 1;
    end 
  end
  assign dpif.halt = ex_mem_out.pchalt;
  always_comb begin
    iaddr = dpif.imemaddr;
    if(mem_wb_out.pchalt) iaddr = '0;
    else if(dpif.ihit) begin
      case (deif.PCsrc)
        2'b00: iaddr = huif.Halt?dpif.imemaddr:dpif.imemaddr+ 4;
        2'b01: iaddr = id_ex_out.pc + id_ex_out.immediate;
        2'b10: iaddr = id_ex_out.rdat1+id_ex_out.immediate;
      endcase
    end
  end

  //================Latch Logic================
  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_out <= '0;
      id_ex_out <= '0;
      ex_mem_out<= '0;
      mem_wb_out<= '0;
    end
    else begin
      if(dpif.ihit && huif.latch_en) begin
        if(huif.Flush) if_id_out <= '0;
        else if_id_out <= if_id_in;
      end
      if(dpif.ihit) begin
        if(huif.Flush) begin
          id_ex_out <= '0;
        end
        else begin
          id_ex_out <= id_ex_in;  
        end
        ex_mem_out<= ex_mem_in;
        mem_wb_out<= mem_wb_in;
      end
      else if(dpif.dhit) begin
        ex_mem_out.read_data<= ex_mem_in.read_data;
      end
    end
  end
endmodule
