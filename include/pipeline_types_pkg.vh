/*

  all types used to make life easier.
  
*/
`ifndef PIPELINE_TYPES_PKG_VH
`define PIPELINE_TYPES_PKG_VH

package pipeline_types_pkg;




  // word_t
  typedef logic [WORD_W-1:0] word_t;



  //internal pipeline signals
  typedef struct packed {
    word_t instruction;
    word_t pc;
  } IF_ID;

    typedef struct packed {
    word_t instruction;
    word_t pc;
    //control signals
    logic pchalt;
    logic MemtoReg;
    logic AluSrc;
    logic [4:0] Aluop;
    logic [2:0] MemWr;
    logic RegWr;
    logic [5:0] branch;
    //register file signals
    word_t rdat1;
    word_t rdat2;
    //immediate generator
    word_t immediate;
    } ID_EX;
