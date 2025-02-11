/*
  Eric Villasenor
  evillase@gmail.com

  datapath contains register file, control, hazard,
  muxes, and glue logic for processor
*/

// data path interface
`include "datapath_cache_if.vh"
`include "control_request_unit_if.vh"

// alu op, mips op, and instruction type
`include "cpu_types_pkg.vh"
`include "pipeline_types_pkg.vh"

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;
  import pipeline_types_pkg::*;

  //interface
  control_request_unit_if cruif();
  register_file_if rfif();

  // pc init
  parameter PC_INIT = 0;

  //internal signals
  word_t iaddr, Aluout, outdata, next, Alu_b;

  //internal pipelined signals
  IF_ID if_id_in;
  IF_ID if_id_out;

  ID_EX id_ex_in;
  ID_EX id_ex_out;

  //instance of control unit and request unit
  control_unit      CONTROL(CLK, nRST, cruif);
  request_unit      REQUEST(CLK, nRST, cruif);

  //need to create instance of ALU, and register file?
  register_file     REG_FILE(CLK, nRST, rfif);
  alu               ALU(.A(id_ex_out.rdat1), .B(Alu_b), .opcode(cruif.Aluop), .out(Aluout), .zero(cruif.zero), .negative(cruif.neg), .overflow(cruif.overflow));

  //interface/signal connections

  assign outdata = (cruif.MemtoReg)? dpif.dmemload: Aluout;   //might need to connect to request unit dmemload signal

  //ALU
  assign Alu_b = (cruif.AluSrc)? cruif.Imm: id_ex_out.rdat2;


  assign next = dpif.imemaddr + 4;

  //register file
  // assign rfif.wsel = cruif.Rd;
  // assign rfif.rsel1 = cruif.Rs1;
  // assign rfif.rsel2 = cruif.Rs2;
  // assign rfif.WEN = cruif.RegWr && (dpif.ihit || dpif.dhit);
  assign rfif.rsel1 = if_id_out.instruction[19:15];
  assign rfif.rsel2 = if_id_out.instruction[24:20];
  assign rfif.wsel = if_id_out.instruction[11:7];
  assign rfif.WEN = if_id_out.RegWr && (dpif.ihit || dpif.dhit);

  always_comb begin
    case(cruif.jumpsel) 
      2'b00:rfif.wdat = outdata;
      2'b01:rfif.wdat = next;
      2'b10:rfif.wdat = cruif.Imm;
      2'b11:rfif.wdat = cruif.Imm + dpif.imemaddr;
    endcase
  end

  //request unit
  assign cruif.dhit = dpif.dhit;
  assign cruif.ihit = dpif.ihit;
  assign cruif.Aluout = Aluout;
  assign cruif.rdat2 = rfif.rdat2;
  
  assign dpif.imemREN = cruif.imemREN;
  assign dpif.dmemREN = cruif.dmemREN;
  assign dpif.dmemWEN = cruif.dmemWEN;
  assign dpif.dmemstore = cruif.dmemstore;
  assign dpif.dmemaddr = cruif.dmemaddr;

  //control unit
  assign cruif.imemload = dpif.imemload;  


  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      dpif.imemaddr <= '0;
      dpif.halt <= 0;
    end 
    else begin
      dpif.imemaddr <= iaddr;
      if(cruif.pchalt) dpif.halt <= 1;
    end
  end

  always_comb begin
    iaddr = dpif.imemaddr;

    if(cruif.pchalt) iaddr = '0;
    else if(dpif.ihit) begin
      case (cruif.PCSrc)
        2'b00: iaddr += 4;
        2'b01: iaddr += cruif.Imm;
        2'b10: iaddr = cruif.Imm + rfif.rdat1;
      endcase
    end
    else if(cruif.pchalt) iaddr = '0;
  end


  //assigning piplined signals for IF_ID_in
  assign if_id_in.instruction = dpif.imemload;
  assign if_id_in.pc = dpif.imemaddr;

  //assigning pipelined signals for ID_EX_in
  assign id_ex_in.instruction = if_id_out.instruction;
  assign id_ex_in.pc = if_id_out.pc;

  assign id_ex_in.pchalt = dpif.halt;
  assign id_ex_in.MemtoReg = cruif.MemtoReg;
  assign id_ex_in.AluSrc = cruif.AluSrc;
  assign id_ex_in.Aluop = cruif.Aluop;
  assign id_ex_in.MemWr = cruif.MemWr;
  assign id_ex_in.RegWr = cruif.RegWr;
  // assign id_ex_in.branch

  assign id_ex_in.rdat1 = rfif.rdat1; 
  //need to update input to ALU to be registered output of rdat1 and rdat2
  assign id_ex_in.rdat2 = rfif.rdat2;
  //assign id_ex_in.immediate = 
  //output of the immediate generator

  //IF_ID
  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      if_id_out <= '0;
    end
    else begin
      if_id_out <= if_id_in;
    end
  end

    //ID_EX
  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      id_ex_out <= '0;
    end
    else begin
      id_ex_out <= id_ex_in;
    end
  end
endmodule
