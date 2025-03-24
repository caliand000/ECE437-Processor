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
    

     //dcache frame
//   typedef struct packed {
// 	logic valid;
// 	logic dirty;
// 	logic [DTAG_W - 1:0] tag;
// 	word_t [1:0] data;
//   } dcache_frame; --> ARRAY OF THIS = CACHEE TABLE

// typdef struct cache_row{
//    dcache_frame right
//    dcache_frame left
// }

//cache_row [8] ht;
//address that i want to replace = ht[dcache_info.idx].right/left.tag

//   // dcache format type
//   typedef struct packed {
//     logic [DTAG_W-1:0]  tag;
//     logic [DIDX_W-1:0]  idx;
//     logic [DBLK_W-1:0]  blkoff;
//     logic [DBYT_W-1:0]  bytoff;
//   } dcachef_t; --> REQUEST INFORMATION



    typedef enum logic[4:0] {Idle,read_first_word,read_second_word,write_first_word,write_second_word,nhitR_doneR,nhitW_doneR,incrementing,halt_cleaned} state_type;
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
         hit_cnt<=nxt_hit_cnt; //dcache frame
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
               
               nextstate=incrementing;
            end
            else if(!hit && (dcif.dmemREN || dcif.dmemWEN))begin
            if((cur_dcache[index].way[0].dirty&&!cur_dcache[index].ru[0])||(cur_dcache[index].way[1].dirty&&!cur_dcache[index].ru[1])) begin
            nextstate=write_first_word;
            end
            else if(dcif.dmemWEN&&dcif.dmemaddr[2]) nextstate=read_second_word;
            else nextstate=read_first_word;
            end
         end

         read_first_word: begin
            nextstate=read_first_word;
            if(!cif.dwait&&dcif.dmemREN)
            nextstate=read_second_word;
            else if(!cif.dwait&&dcif.dmemWEN) nextstate=nhitW_doneR;
         end
         read_second_word: begin
            nextstate=read_second_word;
            if(!cif.dwait&&dcif.dmemREN)
            nextstate=nhitR_doneR;
            else if(!cif.dwait&&dcif.dmemWEN)
            nextstate=nhitW_doneR;
         end
         nhitR_doneR: begin
   
            nextstate=Idle;
         end
         nhitW_doneR: begin
            nextstate=Idle;
         end
         write_first_word: begin
            nextstate=write_first_word;
            if(!cif.dwait) nextstate=write_second_word;
         end
         write_second_word: begin
            nextstate=write_second_word;
            if(!cif.dwait&&dcif.halt) 
            nextstate=incrementing;
            else if(!cif.dwait&&dcif.dmemWEN)
            nextstate=read_first_word;
            else if(!cif.dwait&&dcif.dmemREN)
            nextstate=read_first_word;
            
         
         end
         incrementing: begin
            nextstate=incrementing;
            if(cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty)
            nextstate=write_first_word;
            if(halt_cnt==16) nextstate=halt_cleaned;
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
            dcif.dmemload=cur_dcache[index].way[0].data[offset];
            nxt_dcache[index].ru[0]=1;
            nxt_dcache[index].ru[1]=0;
            enable_hit_counter=1;
         end
         else if(hit1) begin
            dcif.dmemload=cur_dcache[index].way[1].data[offset];
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
         if(hit)
            dcif.dhit=1;
         end
      end
      read_first_word: begin
         cif.dREN=1;
         cif.daddr={dcif.dmemaddr[31:3],1'b0,dcif.dmemaddr[1:0]};
            
      end

      read_second_word: begin
         cif.dREN=1;
         cif.daddr={dcif.dmemaddr[31:3],1'b1,dcif.dmemaddr[1:0]};
            if(!cur_dcache[index].ru[0]&&dcif.dmemREN) begin
            
               
               nxt_dcache[index].way[0].data[0]=cif.dload;
           
            nxt_dcache[index].way[0].valid=1;
            nxt_dcache[index].way[0].dirty=1;
            nxt_dcache[index].ru[0]=1;
            nxt_dcache[index].ru[1]=0;
            nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
         end
         else if(!nxt_dcache[index].ru[1]&&dcif.dmemREN) begin
            
               
               nxt_dcache[index].way[1].data[0]=cif.dload;
           
            nxt_dcache[index].way[1].valid=1;
            nxt_dcache[index].way[1].dirty=1;
            nxt_dcache[index].ru[0]=0;
            nxt_dcache[index].ru[1]=1;
            nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
         end
      end
     
      write_first_word: begin
         if(dcif.halt) begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].tag,halt_cnt[2:0],3'b000};
            cif.dstore=cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].data[0];
         end
         else begin
            cif.dWEN=1;
            cif.daddr={dcif.dmemaddr[31:3],0,dcif.dmemaddr[1:0]};
            if(cur_dcache[index].way[0].dirty&&!cur_dcache[index].ru[0])
               cif.dstore=cur_dcache[index].way[0].data[0];
            else if(cur_dcache[index].way[1].dirty&&!cur_dcache[index].ru[1])
               cif.dstore=cur_dcache[index].way[1].data[0];
         end
      end
      write_second_word: begin
         if(dcif.halt) begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].tag,halt_cnt[2:0],3'b100};
            cif.dstore=cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].data[1];
         end
         else begin
            cif.dWEN=1;
            cif.daddr={dcif.dmemaddr[31:3],1,dcif.dmemaddr[1:0]};
            if(cur_dcache[index].way[0].dirty&&!cur_dcache[index].ru[0])
               cif.dstore=cur_dcache[index].way[0].data[1];
            else if(cur_dcache[index].way[1].dirty&&!cur_dcache[index].ru[1])
               cif.dstore=cur_dcache[index].way[1].data[0];
         end
      end
      incrementing: begin
         enable_halt_counter=1;

         if(cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty) begin
         nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty=0;
         enable_halt_counter=0;
         end
         
      end
      nhitW_doneR: begin
         if(!cur_dcache[index].ru[0]) begin
            if(dcif.dmemaddr[2])begin
               nxt_dcache[index].way[0].data[1]=dcif.dmemstore;
               nxt_dcache[index].way[0].data[0]=cif.dload;
            end
            else begin
               nxt_dcache[index].way[0].data[0]=dcif.dmemstore;
               nxt_dcache[index].way[0].data[1]=cif.dload;
               
            end
            nxt_dcache[index].way[0].valid=1;
            nxt_dcache[index].way[0].dirty=1;
            nxt_dcache[index].ru[0]=1;
            nxt_dcache[index].ru[1]=0;
            nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
         end
         else if(!nxt_dcache[index].ru[1]) begin
            if(dcif.dmemaddr[2])begin
               
               nxt_dcache[index].way[1].data[1]=dcif.dmemstore;
               nxt_dcache[index].way[1].data[0]=cif.dload;
            end
            else begin
               
               nxt_dcache[index].way[1].data[0]=dcif.dmemstore;
               nxt_dcache[index].way[1].data[1]=cif.dload;
            end
            nxt_dcache[index].way[1].valid=1;
            nxt_dcache[index].way[1].dirty=1;
            nxt_dcache[index].ru[0]=0;
            nxt_dcache[index].ru[1]=1;
            nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
         end
         dcif.dhit=1;
      end
      nhitR_doneR: begin
          if(!cur_dcache[index].ru[0]) begin
            if(dcif.dmemaddr[2])begin
               dcif.dmemload=nxt_dcache[index].way[0].data[0];
               
            end
            else begin
               dcif.dmemload=nxt_dcache[index].way[0].data[1];
               
            end
            
         end
         else if(!nxt_dcache[index].ru[1]) begin
            if(dcif.dmemaddr[2])begin
               
               dcif.dmemload=nxt_dcache[index].way[1].data[1];
            end
            else begin
               
               dcif.dmemload=nxt_dcache[index].way[1].data[0];
            end
           
         end
         
         dcif.dhit=1;
      end
      halt_cleaned: begin
         cif.dWEN=1;
         cif.daddr=32'h3100;
         cif.dstore=hit_cnt;
         
      end
   endcase
      dcif.flushed=(state==halt_cleaned&&!cif.dwait);
 end
endmodule