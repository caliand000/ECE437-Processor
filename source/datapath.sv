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

module datapath (
  input logic CLK, nRST,
  datapath_cache_if.dp dpif
);
  // import types
  import cpu_types_pkg::*;

  //interface
  control_request_unit_if cruif();
  register_file_if rfif();

  //internal signals

  // pc init
  parameter PC_INIT = 0;

  //internal signals
  word_t iaddr, Aluout, outdata, next, Alu_b;

  //instance of control unit and request unit
  control_unit      CONTROL(CLK, nRST, cruif);
  request_unit      REQUEST(CLK, nRST, cruif);

  //need to create instance of ALU, and register file?
  register_file     REG_FILE(CLK, nRST, rfif);
  alu               ALU(.A(rfif.rdat1), .B(Alu_b), .opcode(cruif.Aluop), .out(Aluout),
                          .zero(cruif.zero), .negative(cruif.neg), .overflow(cruif.overflow));

  //interface/signal connections

  assign outdata = (cruif.MemtoReg)? dpif.dmemload: Aluout;   //might need to connect to request unit dmemload signal

  //ALU
  assign Alu_b = (cruif.AluSrc)? cruif.Imm: rfif.rdat2;


  assign next = dpif.imemaddr + 4;

  //register file
  assign rfif.wsel = cruif.Rd;
  assign rfif.rsel1 = cruif.Rs1;
  assign rfif.rsel2 = cruif.Rs2;
  assign rfif.WEN = cruif.RegWr && (dpif.ihit || dpif.dhit);

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
        2'b10: iaddr = cruif.Imm + rfif.rdat1;//cruif.Rs1;
      endcase
    end
    else if(cruif.pchalt) iaddr = '0;
  end





endmodule
