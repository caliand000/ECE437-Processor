`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;
typedef struct packed {
    dcache_frame [1:0] way;
    logic  [1:0]ru;
} dcache;


module dcache (
  input logic CLK, nRST,
  datapath_cache_if.cache dcif,
  caches_if cif
);
    

    typedef enum logic[4:0] {Idle,read_first_word,read_second_word,write_first_word,write_second_word,nhitR_doneR,nhitR_doneC,nhitW_doneR,nhitW_doneC,incrementing,halt_cleaned} state_type;
    state_type state, nextstate;
    dcache[15:0] cur_dcache,nxt_dcache;
    logic [4:0] halt_cnt,nxt_halt_cnt;
    word_t hit_cnt,nxt_hit_cnt;
    logic hit0,hit1,enable_hit_counter,hit,offset,enable_halt_counter;
    logic [2:0] index;
    word_t[1:0] read_block,nxt_read_block;
    assign offset=dcif.dmemaddr[2];
    assign index=dcif.dmemaddr[5:3];
    assign hit0=(cur_dcache[index].way[0].tag==dcif.dmemaddr[31:6]&&cur_dcache[index].way[0].valid);
    assign hit1=(cur_dcache[index].way[1].tag==dcif.dmemaddr[31:6]&&cur_dcache[index].way[0].valid);
    always_ff@(posedge CLK,negedge nRST) begin
    if(!nRST) begin
    cur_dcache<='0;
    hit_cnt<='0;
    state<=Idle;
    read_block<='0;
    halt_cnt<=0;
    end
    else begin
    cur_dcache<=nxt_dcache;
    hit_cnt<=nxt_hit_cnt;
    state<=nextstate;
    read_block<=nxt_read_block;
    halt_cnt<=nxt_halt_cnt;
    end 
    end
    assign hit=hit0||hit1;
    always_comb begin : hit_counter
    nxt_hit_cnt=hit_cnt;
    if(enable_hit_counter) nxt_hit_cnt=hit_cnt+1;
    end
    always_comb begin: halt_counter
    nxt_halt_cnt=halt_cnt;
    if(enable_halt_counter) nxt_halt_cnt=halt_cnt+1;
    
    end
    always_comb begin : next_State_logic
    case(state)
    Idle: begin
    nextstate=Idle;
    if(dcif.halt) begin
        nextstate=write_first_word;
    end
   
    else if(!hit)begin
    nextstate=read_first_word;
    
    end
    
    end

    
    read_first_word: begin
    nextstate=read_first_word;
    if(!cif.dwait)
    nextstate=read_second_word;
    end
    read_second_word: begin
    nextstate=read_second_word;
    if(!cif.dwait&&dcif.dmemREN)
    nextstate=nhitR_doneR;
    else if(!cif.dwait&&dcif.dmemWEN)
    nextstate=nhitW_doneR;
    end
    nhitR_doneR: begin

    if((cur_dcache[index].way[0].dirty&&!cur_dcache[index].ru[0])||(cur_dcache[index].way[1].dirty&&!cur_dcache[index].ru[1])) 
    nextstate=write_first_word;
    else nextstate=nhitR_doneC;
    
    end

    nhitW_doneR: begin
   
    if((cur_dcache[index].way[0].dirty&&!cur_dcache[index].ru[0])||(cur_dcache[index].way[1].dirty&&!cur_dcache[index].ru[1])) begin
    nextstate=write_first_word;
    end
    else nextstate=nhitW_doneC;
    end

    write_first_word: begin
    nextstate=write_first_word;
    if(!cif.dwait) nextstate=write_second_word;
    end

    write_second_word: begin
    nextstate=write_second_word;
    if(!cif.dwait&&dcif.dmemREN)
    nextstate=nhitR_doneC;
    else if(!cif.dwait&&dcif.dmemWEN)
    nextstate=nhitW_doneC;
    else if(!cif.dwait&&dcif.halt) begin
    nextstate=incrementing;
    end
    end
    incrementing: begin
    nextstate=write_first_word;
    if(halt_cnt==15) nextstate=halt_cleaned;
    end
    nhitR_doneC: begin
    nextstate=Idle;
    end
    nhitW_doneC: begin
    nextstate=Idle;
    end
    halt_cleaned: begin
    nextstate=halt_cleaned;
    if(!cif.dwait) nextstate=Idle;
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
 nxt_read_block=read_block;
 enable_hit_counter=0;
 enable_halt_counter=0;

 case(state)
 Idle: begin
 if(dcif.dmemREN) begin
 if(hit0) begin
 dcif.dmemload=nxt_dcache[index].way[0].data[offset];
 nxt_dcache[index].ru[0]=1;
 nxt_dcache[index].ru[1]=0;
 enable_hit_counter=1;
 end
 else if(hit1) begin
 dcif.dmemload=nxt_dcache[index].way[1].data[offset];
 nxt_dcache[index].ru[1]=1;
 nxt_dcache[index].ru[0]=0;
 enable_hit_counter=1;
 end
 if(hit)
 dcif.dhit=1;
 end
 else if(dcif.dmemWEN) begin
 if(hit0) begin
 nxt_dcache[index].way[0].data[offset]=dcif.dmemstore;
 nxt_dcache[index].way[0].dirty=1;
 nxt_dcache[index].ru[0]=1;
 nxt_dcache[index].ru[1]=0;
 enable_hit_counter=1;
 end
 else if(hit1) begin
 nxt_dcache[index].way[1].data[offset]=dcif.dmemstore;
 nxt_dcache[index].way[1].dirty=1;
 nxt_dcache[index].ru[0]=0;
 nxt_dcache[index].ru[1]=1;
 enable_hit_counter=1;
 end
 dcif.dhit=1;
 end
 end
 
 
 read_first_word: begin
    cif.dREN=1;
    cif.daddr={dcif.dmemaddr[31:3],0,dcif.dmemaddr[1:0]};
 end

 read_second_word: begin
    cif.dREN=1;
    cif.daddr={dcif.dmemaddr[31:3],1,dcif.dmemaddr[1:0]};
    nxt_read_block[0]=cif.dload;
 end
 nhitR_doneR : begin
 nxt_read_block[1]=cif.dload;
 end
 nhitW_doneR: begin
     nxt_read_block[1]=cif.dload;
 end
 write_first_word: begin
    if(dcif.halt) begin
    cif.dWEN=1;
    cif.daddr={nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].tag,halt_cnt[2:0],3'b000};
    cif.dstore=nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].data[0];
    end
    else begin
    cif.dWEN=1;
    cif.daddr={dcif.dmemaddr[31:3],0,dcif.dmemaddr[1:0]};
    if(nxt_dcache[index].way[0].dirty&&!nxt_dcache[index].ru[0])
    cif.dstore=nxt_dcache[index].way[0].data[0];
    else if(nxt_dcache[index].way[1].dirty&&!nxt_dcache[index].ru[1])
    cif.dstore=nxt_dcache[index].way[1].data[0];
    end
 end
 write_second_word: begin
    if(dcif.halt) begin
    cif.dWEN=1;
    cif.daddr={nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].tag,halt_cnt[2:0],3'b100};
    cif.dstore=nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].data[1];
    end
    else begin
    cif.dWEN=1;
    cif.daddr={dcif.dmemaddr[31:3],1,dcif.dmemaddr[1:0]};
    if(nxt_dcache[index].way[0].dirty&&!nxt_dcache[index].ru[0])
    cif.dstore=nxt_dcache[index].way[0].data[1];
    else if(nxt_dcache[index].way[1].dirty&&!nxt_dcache[index].ru[1])
    cif.dstore=nxt_dcache[index].way[1].data[0];
 end
 end
 incrementing: begin
 enable_halt_counter=1;
 end
 nhitW_doneC: begin
     if(!nxt_dcache[index].ru[0]) begin
     if(dcif.dmemaddr[2])begin
     nxt_dcache[index].way[0].data[0]=read_block[0];
     nxt_dcache[index].way[0].data[1]=dcif.dmemstore;
     end
     else begin
     nxt_dcache[index].way[0].data[1]=read_block[1];
     nxt_dcache[index].way[0].data[0]=dcif.dmemstore;
     end
     nxt_dcache[index].way[0].valid=1;
     nxt_dcache[index].way[0].dirty=1;
     nxt_dcache[index].ru[0]=1;
     nxt_dcache[index].ru[1]=0;
     nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
     end
     else if(!nxt_dcache[index].ru[1]) begin
     if(dcif.dmemaddr[2])begin
     nxt_dcache[index].way[1].data[0]=read_block[0];
     nxt_dcache[index].way[1].data[1]=dcif.dmemstore;
     end
     else begin
     nxt_dcache[index].way[1].data[1]=read_block[1];
     nxt_dcache[index].way[1].data[0]=dcif.dmemstore;
     end
     nxt_dcache[index].way[1].valid=1;
     nxt_dcache[index].way[1].dirty=1;
     nxt_dcache[index].ru[0]=0;
     nxt_dcache[index].ru[1]=1;
     nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
     end
     dcif.dhit=1;
 end
 nhitR_doneC: begin
     if(!nxt_dcache[index].ru[0]) begin
     if(dcif.dmemaddr[2])begin
     nxt_dcache[index].way[0].data[0]=read_block[0];
     nxt_dcache[index].way[0].data[1]=dcif.dmemstore;
     end
     else begin
     nxt_dcache[index].way[0].data[1]=read_block[1];
     nxt_dcache[index].way[0].data[0]=dcif.dmemstore;
     end
     nxt_dcache[index].way[0].valid=1;
     nxt_dcache[index].way[0].dirty=0;
     nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
     nxt_dcache[index].ru[0]=1;
     nxt_dcache[index].ru[1]=0;
     end
     else if(!nxt_dcache[index].ru[1]) begin
     if(dcif.dmemaddr[2])begin
     nxt_dcache[index].way[1].data[0]=read_block[0];
     nxt_dcache[index].way[1].data[1]=dcif.dmemstore;
     end
     else begin
     nxt_dcache[index].way[1].data[1]=read_block[1];
     nxt_dcache[index].way[1].data[0]=dcif.dmemstore;
     end
     nxt_dcache[index].way[1].valid=1;
     nxt_dcache[index].way[1].dirty=0;
     nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
     nxt_dcache[index].ru[1]=1;
     nxt_dcache[index].ru[0]=0;
     end
     dcif.dhit=1;
 end
 halt_cleaned: begin
    cif.dWEN=1;
    cif.daddr=32'h3100;
    cif.dstore=halt_cnt;
    
 end


 endcase

 end
 assign dcif.flushed=(state==halt_cleaned&&!cif.dwait);
endmodule