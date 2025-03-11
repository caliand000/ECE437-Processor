/*
  Andrew Cali
  acali@purdue.edu
  this block describes icache
*/
`include "cpu_types_pkg.vh"


module icache (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  caches_if cif
);
    import cpu_types_pkg::*;

    typedef enum logic {Idle, Miss} state_type;
    state_type state, nextstate;

    icache_frame [15:0] cache_block, next_cache_block;
    logic comparator;

    always_ff @(posedge CLK, negedge nRST) begin
        if(!nRST) begin
            state <= Idle;
            cache_block <= '0;
        end
        else begin
            state <= nextstate;
            cache_block <= next_cache_block;
        end
    end

    assign comparator = ((dcif.imemaddr[31:6] == cache_block[dcif.imemaddr[5:2]].tag)&&cache_block[dcif.imemaddr[5:2]].valid);

    always_comb begin
        nextstate = state;
        next_cache_block=cache_block;
        cif.iREN = 1'b0;
        cif.iaddr = '0;

        dcif.imemload = '0;
        dcif.ihit = 1'b0;

        case(state)
            Idle: begin
                if(dcif.imemREN) begin
                    if(!comparator) begin
                        nextstate = Miss;
                    end
                    else if(comparator) begin
                        dcif.imemload = cache_block[dcif.imemaddr[5:2]].data;
                        dcif.ihit = 1'b1;
                        nextstate = Idle;
                    end
                end
            end
            Miss:begin
                cif.iREN = 1'b1;
                
                cif.iaddr = dcif.imemaddr;
                if(!cif.iwait) begin
                    next_cache_block[dcif.imemaddr[5:2]].data = cif.iload;
                    next_cache_block[dcif.imemaddr[5:2]].valid = 1'b1;
                    next_cache_block[dcif.imemaddr[5:2]].tag = dcif.imemaddr[31:6];
                    nextstate = Idle;
                end
            end
        endcase
        
    end
endmodule
