/*

  all types used to make life easier.
  
*/
`ifndef PIPELINE_TYPES_PKG_VH
`define PIPELINE_TYPES_PKG_VH


`include "cpu_types_pkg.vh"
package pipeline_types_pkg;
  import cpu_types_pkg::*;
  // word_t




  //internal pipeline signals
  typedef struct packed {
    word_t instruction;
    word_t pc;
  } IF_ID;

    typedef struct packed {
    word_t pc;
    regbits_t rs1;
    regbits_t rs2;
    logic pchalt;
    logic MemtoReg;
    logic AluSrc;
    logic [4:0] Aluop;
    logic [1:0] MemWr;
    logic RegWr;
    logic [7:0] branch;
    word_t rdat1;
    word_t rdat2;
    word_t immediate;
    logic [4:0] rd;
    logic [1:0] jumpsel;
    } ID_EX;


  typedef struct packed {
    logic pchalt;
    logic MemtoReg;
    logic [1:0] MemWr;
    logic [1:0] PCSrc;
    logic RegWr;
    word_t AdderOut;
    word_t AluOut;
    word_t rdat2;
    logic [4:0] rd;
    word_t immediate;
    logic [1:0] jumpsel;
    word_t read_data;
  } EX_MEM;

    typedef struct packed {
    logic pchalt;
    logic MemtoReg;
    logic RegWr;
    word_t AdderOut;
    word_t AluOut;
    word_t immediate;
    word_t read_data;
    logic [4:0] rd;
    logic [1:0] jumpsel;
  } MEM_WB;
endpackage
`endif 