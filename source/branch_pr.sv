/*
  Andrew Cali
  acali@purdue.edu

  contains forwarding unit logic
*/

// forwarding unit interface
`include "branch_pr_if.vh"

// types interface include
`include "cpu_types_pkg.vh"

module branch_pr (
input logic CLK, nRST,
  branch_pr_if.bp bpif
);
  // import types
  import cpu_types_pkg::*;

  // pc init
  parameter PC_INIT = 0;

   typedef enum logic {
    NOTTAKEN     = 1'b0,
    TAKEN        = 1'b1
   } state_t;

  typedef struct packed {
    word_t              target;
    state_t             state;
  } branch_target_buffer_t;

  branch_target_buffer_t [255:0] branch_buffer;
  branch_target_buffer_t [255:0] branch_buffer_next; 

  always_comb begin
    bpif.Br_PC = 1'b0;
    bpif.target = '0;
    branch_buffer_next=branch_buffer;
    if(bpif.opcode == BTYPE) begin
        if(branch_buffer[bpif.PC_fet].state == TAKEN) begin
            bpif.Br_PC = 1'b1;
            bpif.target = branch_buffer[bpif.PC_fet].target;
        end 
    end
  
    if(bpif.PCSrc==2'b01) begin
        branch_buffer_next[bpif.PC_mem[9:2]].target = bpif.adderout;
        branch_buffer_next[bpif.PC_mem[9:2]].state = TAKEN;
    end

  end


always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      for(int i=0;i<256;i++) begin
        branch_buffer[i].target <= '0;
        branch_buffer[i].state  <= NOTTAKEN;
      end
    end
    else begin
        branch_buffer <= branch_buffer_next;
    end
end



endmodule
