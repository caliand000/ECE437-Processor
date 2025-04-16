`include "cpu_types_pkg.vh"
import cpu_types_pkg::*;
typedef struct packed {
    dcache_frame [1:0] way;
    logic  [1:0]ru;
} dcache;


module dcache (
  input logic CLK, nRST,
  datapath_cache_if.dcache dcif,
  caches_if.dcache cif
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



    typedef enum logic[4:0] {Idle,read_first_word,read_second_word,write_first_word,write_second_word,incrementing,halt_cleaned,flushed,Got_Snoop,Cache_transfer1,Cache_Transfer2} state_type;
    state_type state, nextstate;
    dcache[15:0] cur_dcache,nxt_dcache, snoop_dcache, nxt_snoop_dcache;
    logic [4:0] halt_cnt,nxt_halt_cnt;
    word_t hit_cnt,nxt_hit_cnt;
    logic hit0,hit1, shit0, shit1,shit, enable_hit_counter,enable_hit_counter_sub,hit,offset,enable_halt_counter, soffset,sshit1,sshit2;
    logic [2:0] index, sindex;
    word_t[1:0] read_block,nxt_read_block;
    word_t rsv_set,nxt_rsv_set;
    assign nxt_snoop_dcache = nxt_dcache;

    assign offset=dcif.dmemaddr[2];
    assign soffset=cif.ccsnoopaddr[2];
    assign index=dcif.dmemaddr[5:3];
    assign sindex=cif.ccsnoopaddr[5:3];
    assign hit0=(cur_dcache[index].way[0].tag==dcif.dmemaddr[31:6]&&cur_dcache[index].way[0].valid);
    assign hit1=(cur_dcache[index].way[1].tag==dcif.dmemaddr[31:6]&&cur_dcache[index].way[1].valid);

    assign shit0=((snoop_dcache[sindex].way[0].tag==cif.ccsnoopaddr[31:6])&&(snoop_dcache[sindex].way[0].valid));
    assign shit1=((snoop_dcache[sindex].way[1].tag==cif.ccsnoopaddr[31:6])&&snoop_dcache[sindex].way[1].valid);
   //  assign sshit0=(snoop_dcache[sindex].way[0].tag==cif.ccsnoopaddr[31:6]);
   //  assign sshit1=(snoop_dcache[sindex].way[1].tag==cif.ccsnoopaddr[31:6]);
    assign cif.ccwrite=dcif.dmemWEN;
    always_ff@(posedge CLK,negedge nRST) begin
      if(!nRST) begin
         cur_dcache<='0;
         snoop_dcache <= '0;
         hit_cnt<='0;
         state<=Idle;
         read_block<='0;
         halt_cnt<=0;
         rsv_set<=0;
      end
      else begin
         cur_dcache<=nxt_dcache;
         snoop_dcache <= nxt_snoop_dcache;
         hit_cnt<=nxt_hit_cnt; //dcache frame
          state<=nextstate;
         read_block<=nxt_read_block;
         halt_cnt<=nxt_halt_cnt;
         rsv_set<=nxt_rsv_set;
      end 
    end
     

    assign hit=hit0||hit1;
    assign shit=shit0||shit1;
    assign cif.cctrans=shit&&(cur_dcache[sindex].way[0].dirty||cur_dcache[sindex].way[1].dirty);
    always_comb begin : hit_counter
      nxt_hit_cnt=hit_cnt;
      if(enable_hit_counter) nxt_hit_cnt=hit_cnt+1;
      if(enable_hit_counter_sub) nxt_hit_cnt=hit_cnt-1;
    end

    always_comb begin: halt_counter
      nxt_halt_cnt=halt_cnt;
      if(enable_halt_counter) nxt_halt_cnt=halt_cnt+1;
    end

    always_comb begin : next_State_logic
    nextstate=state;
      case(state)
         Idle: begin
            nextstate=Idle;
            
            if(cif.ccwait) begin
               nextstate=Got_Snoop;
            end
            else if(dcif.halt) begin
               nextstate=incrementing;
            end
            else if(!hit && (dcif.dmemREN || dcif.dmemWEN))begin
               if((cur_dcache[index].way[0].dirty && !cur_dcache[index].ru[0])||(cur_dcache[index].way[1].dirty && !cur_dcache[index].ru[1])) begin
                  nextstate=write_first_word;
               end
               else  nextstate=read_first_word;
               
            end
            else if(((!cur_dcache[index].way[0].dirty && hit0)||(!cur_dcache[index].way[1].dirty && hit1))&&(dcif.dmemWEN)) nextstate=read_first_word;
         end

         read_first_word: begin
            nextstate=read_first_word;
            if(cif.ccwait) begin
               nextstate=Got_Snoop;
            end
            else if(!cif.dwait)
               nextstate = read_second_word;
            // else if(!cif.dwait&&dcif.dmemWEN) nextstate=Idle;
         end
         read_second_word: begin
            nextstate=read_second_word;
            if(!cif.dwait)
               nextstate=Idle;
         end
         
         write_first_word: begin
            nextstate=write_first_word;
            if(cif.ccwait) begin
               nextstate=Got_Snoop;
            end
            else if(!cif.dwait) nextstate=write_second_word;
         end
         write_second_word: begin
            nextstate=write_second_word;
             if(!cif.dwait && dcif.halt) 
               nextstate=incrementing;
            // else if(!cif.dwait&&dcif.dmemWEN)
            // nextstate=Idle;
            else if(!cif.dwait)
               nextstate=read_first_word;
            
         
         end
         incrementing: begin
            nextstate=incrementing;
            if(cif.ccwait) nextstate=Got_Snoop;
            else if(halt_cnt==5'd16) nextstate=flushed;
            else if(cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty)
               nextstate=write_first_word;
            
         end
         
         halt_cleaned: begin
            nextstate=halt_cleaned;
            if(!cif.dwait) nextstate=flushed;
         end
         Got_Snoop: begin
         if(!cif.cctrans) nextstate=Idle;
         else nextstate=Cache_transfer1;
         end
         Cache_transfer1: begin
            if(!cif.dwait) nextstate=Cache_Transfer2;
         end  
         Cache_Transfer2: begin
            if(!cif.dwait&&dcif.halt) nextstate=incrementing;
            else if(!cif.dwait) nextstate=Idle;
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
   enable_hit_counter_sub=0;
   enable_halt_counter=0;
   nxt_rsv_set=rsv_set;
   case(state)
      Idle: begin
         if(dcif.dmemREN&&!dcif.halt&&!cif.ccwait) begin
            if(dcif.datomic) nxt_rsv_set={dcif.dmemaddr[31:3],3'b000};
            if(hit0) begin
               dcif.dmemload=cur_dcache[index].way[0].data[offset];
               nxt_dcache[index].ru[0]=1;
               nxt_dcache[index].ru[1]=0;
               enable_hit_counter=1;
               dcif.dhit=1;
            end
            else if(hit1) begin
               dcif.dmemload=cur_dcache[index].way[1].data[offset];
               nxt_dcache[index].ru[1]=1;
               nxt_dcache[index].ru[0]=0;
               enable_hit_counter=1;
               dcif.dhit=1;
            end
            else enable_hit_counter_sub=1;
         end
         else if(dcif.dmemWEN&&!dcif.halt&&!cif.ccwait) begin
            if(dcif.datomic&&{dcif.dmemaddr[31:3],3'b000}!=rsv_set) begin
               dcif.dhit=1;
               dcif.dmemload=1;
            end
            else if(hit0&&!cif.ccwait) begin
               nxt_dcache[index].way[0].data[offset]=dcif.dmemstore;
               //nxt_dcache[index].way[0].dirty=1;
               nxt_dcache[index].ru[0]=1;
               nxt_dcache[index].ru[1]=0;
               enable_hit_counter=1;
               if(cur_dcache[index].way[0].dirty)dcif.dhit=1;
            end
            else if(hit1&&!cif.ccwait) begin
               nxt_dcache[index].way[1].data[offset]=dcif.dmemstore;
               //nxt_dcache[index].way[1].dirty=1;
               nxt_dcache[index].ru[1]=1;
               nxt_dcache[index].ru[0]=0;
               enable_hit_counter=1;
               if(cur_dcache[index].way[1].dirty)dcif.dhit=1;
            end
            
            else enable_hit_counter_sub=1;
         end
         
         
      end
      read_first_word: begin
         cif.dREN=1;
         cif.daddr={dcif.dmemaddr[31:3],1'b0,dcif.dmemaddr[1:0]};
          if(hit0&&!cur_dcache[index].way[0].dirty&&cur_dcache[index].way[0].valid&&dcif.dmemWEN) begin
           nxt_dcache[index].way[0].data[0]=cif.dload;
           
            //  nxt_dcache[index].way[0].valid=1;
            // nxt_dcache[index].way[0].dirty=;
            
             nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
          end
          else if(hit1&&!cur_dcache[index].way[1].dirty&&cur_dcache[index].way[1].valid&&dcif.dmemWEN) begin
             nxt_dcache[index].way[1].data[0]=cif.dload;
           
            //  nxt_dcache[index].way[1].valid=1;
            // nxt_dcache[index].way[1].dirty=1;
            
             nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
          end
         else  if(!cur_dcache[index].ru[0]) begin
            
               
               nxt_dcache[index].way[0].data[0]=cif.dload;
           
            //  nxt_dcache[index].way[0].valid=1;
            // nxt_dcache[index].way[0].dirty=;
            
             nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
         end
         else if(!nxt_dcache[index].ru[1]) begin
            
               
               nxt_dcache[index].way[1].data[0]=cif.dload;
           
            //  nxt_dcache[index].way[1].valid=1;
            // nxt_dcache[index].way[1].dirty=1;
            
             nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
         end
            
      end

      read_second_word: begin
         cif.dREN=1;
         cif.daddr={dcif.dmemaddr[31:3],1'b1,dcif.dmemaddr[1:0]};
           if(hit0&&!cur_dcache[index].way[0].dirty&&cur_dcache[index].way[0].valid&&dcif.dmemWEN) begin
            nxt_dcache[index].way[0].data[1]=cif.dload;
           
            nxt_dcache[index].way[0].valid=1;
            nxt_dcache[index].way[0].dirty=!cif.dwait;
            
            nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
           end
           else if(hit1&&!cur_dcache[index].way[1].dirty&&cur_dcache[index].way[1].valid&&dcif.dmemWEN) begin
            nxt_dcache[index].way[1].data[1]=cif.dload;
           
            nxt_dcache[index].way[1].valid=1;
            nxt_dcache[index].way[1].dirty=!cif.dwait;
            
            nxt_dcache[index].way[1].tag=dcif.dmemaddr[31:6];
           end
           else if(!cur_dcache[index].ru[0]&&(dcif.dmemREN||dcif.dmemWEN)) begin
            
               
               nxt_dcache[index].way[0].data[1]=cif.dload;
           
            nxt_dcache[index].way[0].valid=1;
            nxt_dcache[index].way[0].dirty=dcif.dmemWEN;
            
            nxt_dcache[index].way[0].tag=dcif.dmemaddr[31:6];
         end
         else if(!nxt_dcache[index].ru[1]&&(dcif.dmemREN||dcif.dmemWEN)) begin
            
               
               nxt_dcache[index].way[1].data[1]=cif.dload;
           
            nxt_dcache[index].way[1].valid=1;
            nxt_dcache[index].way[1].dirty=dcif.dmemWEN;
            
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
            cif.daddr={cur_dcache[index].way[!cur_dcache[index].ru[1]].tag,index,3'b000};
            if(!cur_dcache[index].ru[0]) 
               cif.dstore=cur_dcache[index].way[0].data[0];
            else if(!cur_dcache[index].ru[1])
               cif.dstore=cur_dcache[index].way[1].data[0];
         end
      end
      write_second_word: begin
         if(dcif.halt) begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].tag,halt_cnt[2:0],3'b100}; 
            cif.dstore=cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].data[1];
            nxt_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty=0;
            if (!cif.dwait) begin
               enable_halt_counter=1;
            end
         end
         else begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[index].way[!cur_dcache[index].ru[1]].tag,index,3'b100};
            if(!cur_dcache[index].ru[0]) begin
               cif.dstore=cur_dcache[index].way[0].data[1];
               nxt_dcache[index].way[0].dirty=0;
            end
            else if(!cur_dcache[index].ru[1])begin
               cif.dstore=cur_dcache[index].way[1].data[1];
               nxt_dcache[index].way[1].dirty=0;
            end
         end
      end
      incrementing: begin
         enable_halt_counter=1;

         if(cur_dcache[halt_cnt[2:0]].way[halt_cnt[3]].dirty) begin
         
            enable_halt_counter=0;
         end
         
      end
      
      halt_cleaned: begin
         cif.dWEN=1;
         cif.daddr=32'h3100;
         cif.dstore=hit_cnt;
         
      end
      Got_Snoop: begin
         if({cif.ccsnoopaddr[31:3],3'b000}==rsv_set&&cif.ccinv) nxt_rsv_set=0;
         if(cif.ccinv&&shit0&&!cur_dcache[sindex].way[0].dirty) begin
            nxt_dcache[sindex].way[0].valid=0;
         end
         else if(cif.ccinv&&shit1&&!cur_dcache[sindex].way[1].dirty) begin
            nxt_dcache[sindex].way[1].valid=0;
         end
      end
      Cache_transfer1: begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[sindex].way[!shit0].tag,sindex,3'b000};
            cif.dstore=cur_dcache[sindex].way[!shit0].data[0];    
      end
      Cache_Transfer2:begin
            cif.dWEN=1;
            cif.daddr={cur_dcache[sindex].way[!shit0].tag,sindex,3'b100};
            cif.dstore=cur_dcache[sindex].way[!shit0].data[1];
            if (cif.ccinv) begin
            if(shit0)begin 
               nxt_dcache[sindex].way[0].dirty=0;
               nxt_dcache[sindex].way[0].valid=0;
            end
            else if(shit1) begin
               nxt_dcache[sindex].way[1].dirty=0;
               nxt_dcache[sindex].way[1].valid=0;
            end
         end
         else begin
            if(shit0)begin 
               nxt_dcache[sindex].way[0].dirty=0;
              
            end
            else if(shit1) begin
               nxt_dcache[sindex].way[1].dirty=0;
               
            end
         end   
      end
   endcase
      dcif.flushed=(state==flushed);
 end
endmodule