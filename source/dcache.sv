`include "cpu_types_pkg.vh"

typedef struct packed {
    dcache_frame [1:0] way;
    logic  ru[1:0];
} dcache;


module icache (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  caches_if cif
);
    import cpu_types_pkg::*;

    typedef enum logic {Idle, hitR,hitW,nhitR,nhitW,Halt,read_first_word,read_second_word,write_first_word,write_second_word,nhitR_doneR,nhitR_doneC,nhitW_doneR,nhitW_doneC,} state_type;
    state_type state, nextstate;
    dcache[15:0] cur_dcache,nxt_dcache;
    word_t hit_cnt,nxt_hit_cnt;
    logic hit0,hit1,enable_hit_counter,hit,offset;
    logic [3:0] index;
    word_t[1:0] read_block;
    assign offset=dcif.dmemaddr[2];
    assign index=dcif.dmemaddr[6:3];
    assign hit0=(cur_dcache[index].way[0].tag==dcif.dmemaddr[31:7]&&cur_dcache[index].way[0].valid);
    assign hit1=(cur_dcache[index].way[1].tag==dcif.dmemaddr[31:7]&&cur_dcache[index].way[0].valid);
    always_ff@(posedge CLK,negedge nRST) begin
    if(!nRST) begin
    cur_dcache<='0;
    hit_cnt<='0;
    state<=Idle;
    end
    else begin
    cur_dcache<=nxt_dcache;
    hit_cnt<=nxt_hit_cnt;
    state<=nextstate;
    end 
    end
    assign hit=hit0||hit1;
    always_comb begin : hit_counter
    nxt_hit_cnt=hit_cnt;
    if(enable_hit_counter) nxt_hit_cnt=hit_cnt+1;
    end
    always_comb begin : next_State_logic
    case(state)
    Idle: begin
    nextstate=Idle;
    if(dcif.halt) begin
        nextstate=Halt;
    end
    else if(hit) begin
    if(dcif.dmemWEN) nextstate=hitW;
    else if(dcif.dmemREN) nextstate=hitR;
    end
    else begin
    if(dcif.dmemWEN) nextstate=nhitW;
    else if(dcif.dmemREN) nextstate=nhitR;
    end
    else
    end

    hitR: begin
    nextstate=Idle;
    end
    
    hitW: begin
    nextstate=Idle;
    end
    nhitR: begin
    nextstate=read_first_word;
    end
    nhitW: begin
    nextstate=read_first_word;
    end
    read_first_word: begin
    nextstate=read_first_word;
    if(!cif.dwait)
    nextstate=read_second_word;
    end
    read_second_word: begin
    nextstate=read_second_word;
    if(!cif.dhit&&dcif.dmemREN)
    nextstate=nhitR_doneR;
    else if(!cif.dhit&&dcif.dmemWEN)
    nextstate=nhitW_doneR;
    end
    nhit_doneR: begin
    nextstate=nhit_doneR;
    if((cur_dcache[index].way[0].dirty&&dcache.ru[0])||(cur_dcache[index].way[1].dirty&&dcache.ru[1])) begin
    nextstate=write_first_word;
    end
    end

    nhit_doneW: begin
    nextstate=nhit_doneW;
    if((cur_dcache[index].way[0].dirty&&dcache.ru[0])||(cur_dcache[index].way[1].dirty&&dcache.ru[1])) begin
    nextstate=write_first_word;
    end
    end

    write_first_word: begin
    nextstate=write_first_word;
    if(!cif.dwait) nextstate=write_second_word;
    end

    write_second_word: begin
    nextstate=write_second_word;
    if(!cif.dhit&&dcif.dmemREN)
    nextstate=nhitR_doneC;
    else if(!cif.dhit&&dcif.dmemWEN)
    nextstate=nhitW_doneC;
    end
    
    nhitR_doneC: begin
    nextstate=Idle;
    end
    nhitW_doneC: begin
    nextstate=Idle;
    end

    endcase
    end
 always_comb begin : output_logic
 cif.dREN=0;
 cif.dWEN=0;
 cif.daddr=0;
 cif.dstore=0;
 dcif.dhit=0;
 dcif.dmemload=0;
 nxt_dcache=cur_dcache;
 case(state)
 hitR: begin
 if(hit0) begin
 dicf.dmemload=cur_dcache[index].way[0].data[offset]
 end
 else if(hit1) begin
 dicf.dmemload=cur_dcache[index].way[1].data[offset]
 end
 dcif.dhit=1;
 end
 
 hitW: begin
 if(hit0) begin
 nxt_dcache[index].way[0].data[offset]=dcif.dmemstore;
 nxt_dcache[index].way[0].dirty=1;
 end
 else if(hit1) begin
 nxt_dcache[index].way[1].data[offset]=dcif.dmemstore;
 nxt_dcache[index].way[1].dirty=1;
 end
 dcif.dhit=1;
 end
 read_first_word: begin
    dcif.dmemaddr[0]
 end

 read_second_word: begin
 end

 endcase

 end
endmodule