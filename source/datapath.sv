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
  extender_if exif();
  decider_if deif();
  // pc init
  parameter PC_INIT = 0;

  //internal signals
  word_t iaddr, Aluout, outdata, Alu_b;

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
  //instance of control unit and request unit
  control_unit      CONTROL(CLK, nRST, cruif);
  
  decider           Branch(deif);
  //need to create instance of ALU, and register file?
  register_file     REG_FILE(CLK, nRST, rfif);
  alu               ALU(.A(id_ex_out.rdat1), .B(Alu_b), .opcode(id_ex_out.Aluop), .out(Aluout), .zero(deif.Zero), .negative(deif.Negative));

  //interface/signal connections
  assign outdata = (mem_wb_out.MemtoReg)? mem_wb_out.read_data: mem_wb_out.AluOut; 

  //ALU
  assign Alu_b = (id_ex_out.AluSrc)? id_ex_out.immediate: id_ex_out.rdat2;

  //Immediate Generator(extender)
  assign exif.imemload = if_id_out.instruction;


  //register file
  assign rfif.rsel1 = if_id_out.instruction[19:15];
  assign rfif.rsel2 = if_id_out.instruction[24:20];
  assign rfif.wsel = mem_wb_out.rd;
  assign rfif.WEN = mem_wb_out.RegWr && (dpif.ihit || dpif.dhit);
    always_comb begin
    case(mem_wb_out.jumpsel) 
      2'b00:rfif.wdat = outdata;
      2'b01:rfif.wdat = mem_wb_out.AdderOut-mem_wb_out.immediate +4;
      2'b10:rfif.wdat = mem_wb_out.immediate;
      2'b11:rfif.wdat = mem_wb_out.AdderOut;
    endcase
  end


  //assigning values for latches propagation

  //ifid
  assign if_id_in.instruction = dpif.imemload;
  assign if_id_in.pc = dpif.imemaddr;

  //ifid -> idex
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
  assign id_ex_in.immediate = exif.extended_im;
  assign id_ex_in.rd = if_id_out.instruction[11:7];
  assign id_ex_in.jumpsel = cruif.jumpsel;

  //idex -> exmem
  assign ex_mem_in.pchalt = id_ex_out.pchalt;
  assign ex_mem_in.MemtoReg = id_ex_out.MemtoReg;
  assign ex_mem_in.MemWr = id_ex_out.MemWr;
  assign ex_mem_in.PCSrc = deif.PCsrc;
  assign ex_mem_in.RegWr = id_ex_out.RegWr;
  assign ex_mem_in.jumpsel = id_ex_out.jumpsel;
  assign ex_mem_in.AluOut = Aluout;
  assign ex_mem_in.AdderOut=id_ex_out.pc+id_ex_out.immediate;
  assign ex_mem_in.immediate = id_ex_out.immediate;
  assign ex_mem_in.rdat2 = id_ex_out.rdat2;
  assign ex_mem_in.rd = id_ex_out.rd;
  
  //exmem -> memwb
  assign mem_wb_in.pchalt=ex_mem_out.pchalt;
  assign mem_wb_in.MemtoReg=ex_mem_out.MemtoReg;
  assign mem_wb_in.RegWr=ex_mem_out.RegWr;
  assign mem_wb_in.immediate=ex_mem_out.immediate;
  assign mem_wb_in.jumpsel=ex_mem_out.jumpsel;
  assign mem_wb_in.rd=ex_mem_out.rd;
  assign mem_wb_in.AluOut=ex_mem_out.AluOut;
  assign mem_wb_in.AdderOut=ex_mem_out.AdderOut;
  assign mem_wb_in.read_data=dpif.dmemload;


  //assigning internal signals
  assign deif.typ=id_ex_out.branch;
  
 
  
  assign dpif.imemREN = 1;
  assign dpif.dmemstore = ex_mem_out.rdat2;
  assign dpif.dmemaddr = ex_mem_out.AluOut;

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
      else if(ex_mem_out.MemWr == 2'b01 && dpif.ihit) dpif.dmemWEN <= 1;
      else if(ex_mem_out.MemWr == 2'b10 && dpif.ihit) dpif.dmemREN <= 0;
    end
  end

  //control unit
  assign cruif.imemload = dpif.imemload;  

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      dpif.imemaddr <= '0;
      dpif.halt <= 0;
    end 
    else begin
      dpif.imemaddr <= iaddr;
      if(mem_wb_out.pchalt) dpif.halt <= 1;
    end
  end

  always_comb begin
    iaddr = dpif.imemaddr;
    if(mem_wb_out.pchalt) iaddr = '0;
    else if(dpif.ihit) begin // && !(memREN  || memWEN) && !dhit)
      case (deif.PCsrc)
        2'b00: iaddr =dpif.imemaddr+ 4;
        2'b01: iaddr = Aluout;
        2'b10: iaddr = id_ex_out.pc+id_ex_out.immediate;
      endcase
    end
    // else if(mem_wb_out.pchalt) iaddr = '0;
  end
  
  //output of the immediate generator
  // always_comb begin
  //   if_id_nxt = if_id_out;
  //   id_ex_nxt = id_ex_out;
  //   ex_mem_nxt = ex_mem_out;
  //   mem_wb_nxt = mem_wb_out;
  //   if(dpif.ihit) begin
  //     if_id_nxt = if_id_in;
  //     id_ex_nxt = id_ex_in;
  //     ex_mem_nxt = ex_mem_in;
  //     mem_wb_nxt = mem_wb_in;
  //   end
  // end

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_out <= '0;
      id_ex_out <= '0;
      ex_mem_out<= '0;
      mem_wb_out<= '0;
    end
    else begin
      if(dpif.ihit) begin
        if_id_out <= if_id_in;
        id_ex_out <= id_ex_in;
        ex_mem_out<= ex_mem_in;
        mem_wb_out<= mem_wb_in;
      end
    end
  end


endmodule
