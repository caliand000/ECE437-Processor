/*
  Eric Villasenor
  evillase@gmail.com

  this block is the coherence protocol
  and artibtration for ram
*/

// interface include
`include "cache_control_if.vh"

// memory types
`include "cpu_types_pkg.vh"

module memory_control (
  input CLK, nRST,
  cache_control_if.cc ccif
);
  // type import
  import cpu_types_pkg::*;

  // number of cpus for cc
  parameter CPUS = 1;

  word_t addr = 0; 
  word_t latched_snoopaddr = '0;


  typedef enum logic[3:0] {Idle, Snoop, Snoop_wait, WB1, WB2, RD1, RD2, WD1, WD2, Iread} state_type;
  state_type curr_state, next_state;

  logic curr_core, next_core;

  always_ff @(posedge CLK, negedge nRST) begin
    if(!nRST) begin
      curr_state <= Idle;
      curr_core <= '0;
    end
    else begin
      curr_state <= next_state;
      curr_core <= next_core;
    end
  end

  always_comb begin
    next_state = curr_state;
    next_core = curr_core;

    ccif.iwait = '1;
    ccif.dwait = '1;

    case(curr_state)
      Idle: begin
        if(ccif.dREN[curr_core]) begin
          next_state = Snoop_wait;
        end
        else if(ccif.dWEN[curr_core]) begin
          next_state = WD1;
        end
        else if(ccif.iREN[curr_core]) begin
          next_state = Iread;
        end
        else if(ccif.dREN[~curr_core]) begin
          next_state = Snoop_wait;
        end
        else if(ccif.dWEN[~curr_core]) begin
          next_state = WD1;
        end
        else if(ccif.iREN[~curr_core]) begin
          next_state = Iread;
        end
      end
      Snoop_wait: next_state = Snoop;
      Snoop: begin
        if(ccif.cctrans[~curr_core]) next_state = WB1;           //if its in a modified state, then we need to write it back and do cache to cache transfer
        else next_state = RD1;
      end
      WB1: begin
        if(ccif.ramstate == ACCESS) begin
           ccif.dwait[curr_core] = '0;
           ccif.dwait[~curr_core] = '0;
           next_state = WB2;
        end
      end
      WB2: begin
        if(ccif.ramstate == ACCESS && ccif.cctrans[curr_core]) next_state = RD1;
        else if(ccif.ramstate == ACCESS) begin
          ccif.dwait[curr_core] = '0;
          ccif.dwait[~curr_core] = '0;
          next_state = Idle;
          next_core = ~curr_core;
        end
        
      end
      RD1: begin
        if(ccif.ramstate == ACCESS) begin
          ccif.dwait[curr_core] = '0;
          next_state = RD2;
        end
      end
      RD2: begin
        if(ccif.ramstate == ACCESS) begin
            ccif.dwait[curr_core] = '0;
           next_state = Idle;
           next_core = ~curr_core;
        end
      end
      WD1: begin
        if(ccif.ramstate == ACCESS) begin
          next_state = WD2;
          ccif.dwait[curr_core] = '0;
        end
      end
      WD2: begin
        if(ccif.ramstate == ACCESS) begin
          next_state = Idle;
          ccif.dwait[curr_core] = '0;
          next_core = ~curr_core;
        end   
      end
      Iread: begin
        if(ccif.ramstate == ACCESS) begin
          ccif.iwait[curr_core] = '0;
          next_state = Idle;
          next_core = ~curr_core;
        end     
      end
    endcase
  end

  always_comb begin 
    //initialize outputs
    ccif.iload =       '0;
    ccif.dload =       '0;
    ccif.ramstore =    '0;
    ccif.ramaddr =     '0;
    ccif.ramWEN =      '0;
    ccif.ramREN =      '0;
    ccif.ccwait =      '0;
    ccif.ccinv =       '0;
    ccif.ccsnoopaddr = '0;

    case(curr_state) 
      Snoop_wait: begin
        ccif.ccwait[~curr_core] = 1'b1;
        ccif.ccsnoopaddr[~curr_core] = ccif.daddr[curr_core];
      end
      Snoop: begin
        ccif.ccsnoopaddr[~curr_core] = ccif.daddr[curr_core];
        if(ccif.ccwrite[curr_core]) ccif.ccinv[curr_core] = 1;          //if ccwrite, this means its read with intent to modify, need to set other cache data to invalid state
        ccif.ccwait[~curr_core] = 1'b1;
      end
      WB1: begin
        ccif.ccsnoopaddr[~curr_core] = ccif.daddr[curr_core];
        ccif.ramaddr = ccif.daddr[~curr_core];
        ccif.ramstore = ccif.dstore[~curr_core];
        ccif.ramWEN = 1'b1;

        ccif.dload[curr_core] = ccif.dstore[~curr_core];               //cache to cache transfer
        ccif.ccwait[~curr_core] = 1'b1;
      end
      WB2: begin
        ccif.ccsnoopaddr[~curr_core] = ccif.daddr[curr_core];
        ccif.ramaddr = ccif.daddr[~curr_core];
        ccif.ramstore = ccif.dstore[~curr_core];
        ccif.ramWEN = 1'b1;

        ccif.dload[curr_core] = ccif.dstore[~curr_core];                 //cache to cache transfer
        ccif.ccwait[~curr_core] = 1'b1;
      end
      RD1: begin
        ccif.ramaddr = ccif.daddr[curr_core];
        ccif.dload[curr_core] = ccif.ramload;
        ccif.ramREN = 1'b1;
      end
      RD2: begin
        ccif.ramaddr = ccif.daddr[curr_core];
        ccif.dload[curr_core] = ccif.ramload;
        ccif.ramREN = 1'b1;
      end
      WD1: begin
        ccif.ramaddr = ccif.daddr[curr_core];
        ccif.ramstore = ccif.dstore[curr_core];
        ccif.ramWEN = 1'b1;
      end
      WD2: begin
        ccif.ramaddr = ccif.daddr[curr_core];
        ccif.ramstore = ccif.dstore[curr_core];
        ccif.ramWEN = 1'b1;
      end
      Iread: begin
        ccif.ramaddr = ccif.iaddr[curr_core];
        ccif.ramREN = 1'b1;
        ccif.iload[curr_core]=ccif.ramload;
      end
    endcase
  end


  // assign ccif.dload = (ccif.dREN && (ccif.ramstate == ACCESS))? ccif.ramload:addr; 
  // assign ccif.iload = ccif.ramload;                
  // // assign ccif.iload = ((ccif.iREN && !(ccif.dWEN || ccif.dREN)) && (ccif.ramstate == ACCESS))? ccif.ramload: addr;                                              //load ramload into iload during access state?
  // assign ccif.ramaddr = (ccif.dREN || ccif.dWEN)? ccif.daddr : (ccif.iREN)? ccif.iaddr: addr;                   //ram address stores instruction address 
  // assign ccif.ramstore = (ccif.dWEN)? ccif.dstore: addr;

  // assign ccif.iwait = ((ccif.iREN && !(ccif.dWEN || ccif.dREN)) && (ccif.ramstate == ACCESS))? 0: 1; 
  // // assign ccif.iwait = (ccif.iload)? 1'b0: 1'b1;
  // assign ccif.dwait = ((ccif.dREN || ccif.dWEN) && (ccif.ramstate == ACCESS))? 1'b0: 1'b1;

  // assign ccif.ramWEN = (ccif.dWEN)? 1'b1: 1'b0;
  // assign ccif.ramREN = (ccif.ramWEN)? 1'b0: 1'b1;


endmodule
