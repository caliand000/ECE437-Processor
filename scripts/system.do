onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /system_tb/CLK
add wave -noupdate /system_tb/nRST
add wave -noupdate -divider {Instruction signals}
add wave -noupdate -color White /system_tb/DUT/CPU/dcif/imemREN
add wave -noupdate -color White -radix hexadecimal /system_tb/DUT/CPU/dcif/imemaddr
add wave -noupdate /system_tb/DUT/CPU/DP/iaddr
add wave -noupdate -color White /system_tb/DUT/CPU/dcif/imemload
add wave -noupdate -color White /system_tb/DUT/CPU/dcif/ihit
add wave -noupdate -divider {Data Signals}
add wave -noupdate /system_tb/DUT/CPU/dcif/dhit
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemload
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemREN
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemWEN
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemstore
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemaddr
add wave -noupdate -divider {Datapath Internal}
add wave -noupdate -color Salmon /system_tb/DUT/CPU/DP/Alu_b
add wave -noupdate -color Salmon /system_tb/DUT/CPU/DP/Aluout
add wave -noupdate -color Salmon /system_tb/DUT/CPU/DP/outdata
add wave -noupdate -divider {Register File}
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/WEN
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/wsel
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/rsel1
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/rsel2
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/wdat
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/rdat1
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/rdat2
add wave -noupdate -divider {Ram Signals}
add wave -noupdate /system_tb/DUT/prif/ramstate
add wave -noupdate /system_tb/DUT/prif/ramREN
add wave -noupdate /system_tb/DUT/prif/ramWEN
add wave -noupdate /system_tb/DUT/prif/ramaddr
add wave -noupdate /system_tb/DUT/prif/ramstore
add wave -noupdate /system_tb/DUT/prif/ramload
add wave -noupdate /system_tb/DUT/prif/memREN
add wave -noupdate /system_tb/DUT/prif/memWEN
add wave -noupdate /system_tb/DUT/prif/memaddr
add wave -noupdate /system_tb/DUT/prif/memstore
add wave -noupdate -divider {Memory Control Signals}
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/iwait
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/dwait
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/iREN
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/dREN
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/dWEN
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/iload
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/dload
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/dstore
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/iaddr
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/daddr
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramWEN
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramREN
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramstate
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramaddr
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramstore
add wave -noupdate -color Aquamarine /system_tb/DUT/CPU/ccif/ramload
add wave -noupdate -divider {Control Unit Signals}
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/AluSrc
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/RegWr
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/pchalt
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/dhit
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/PCSrc
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/MemWr
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/jumpsel
add wave -noupdate /system_tb/DUT/CPU/DP/CONTROL/cuif/Imm
add wave -noupdate -divider {Cache Signals}
add wave -noupdate -color Yellow /system_tb/DUT/CPU/cif0/iload
add wave -noupdate -color Yellow /system_tb/DUT/CPU/cif0/dload
add wave -noupdate -color Yellow /system_tb/DUT/CPU/cif0/dstore
add wave -noupdate -color Yellow /system_tb/DUT/CPU/cif0/iaddr
add wave -noupdate /system_tb/DUT/CPU/cif0/daddr
add wave -noupdate /system_tb/DUT/CPU/cif0/dREN
add wave -noupdate /system_tb/DUT/CPU/cif0/dWEN
add wave -noupdate -divider {Mem address}
add wave -noupdate /system_tb/DUT/CPU/scif/memaddr
add wave -noupdate /system_tb/DUT/CPU/scif/ramaddr
add wave -noupdate /system_tb/DUT/CPU/dcif/dmemaddr
add wave -noupdate /system_tb/DUT/CPU/cif0/daddr
add wave -noupdate /system_tb/DUT/CPU/ccif/daddr
add wave -noupdate /system_tb/DUT/CPU/ccif/ramaddr
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/dmemaddr
add wave -noupdate /system_tb/DUT/CPU/CM/dcif/ihit
add wave -noupdate -radix decimal /system_tb/DUT/CPU/DP/ex_mem_out.AdderOut
add wave -noupdate -radix decimal /system_tb/DUT/CPU/DP/ex_mem_out.AluOut
add wave -noupdate -radix decimal /system_tb/DUT/CPU/DP/ex_mem_out.immediate
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.AdderOut
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.AluOut
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.immediate
add wave -noupdate /system_tb/DUT/CPU/DP/REG_FILE/register
add wave -noupdate -radix decimal /system_tb/DUT/CPU/DP/cruif/Imm
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/Rs1
add wave -noupdate /system_tb/DUT/CPU/DP/cruif/Imm
add wave -noupdate -divider {Pipeline Latch Signals}
add wave -noupdate /system_tb/DUT/CPU/DP/if_id_out.pc
add wave -noupdate /system_tb/DUT/CPU/DP/id_ex_out.pc
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.pc
add wave -noupdate /system_tb/DUT/CPU/DP/mem_wb_out.pc
add wave -noupdate -divider PC's
add wave -noupdate -expand /system_tb/DUT/CPU/DP/if_id_out
add wave -noupdate -expand /system_tb/DUT/CPU/DP/id_ex_out
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out
add wave -noupdate /system_tb/DUT/CPU/DP/mem_wb_out
add wave -noupdate -divider {Forward Unit Signals}
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/Alu_in1
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/Alu_in2
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/rs1
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/rs2
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/Rd_Mem
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/Rd_WB
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/RegWR_mem
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/RegWR_WB
add wave -noupdate -divider {Data being selected from}
add wave -noupdate /system_tb/DUT/CPU/DP/rfif/wdat
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.immediate
add wave -noupdate /system_tb/DUT/CPU/DP/id_ex_out.rdat1
add wave -noupdate /system_tb/DUT/CPU/DP/id_ex_out.rdat2
add wave -noupdate /system_tb/DUT/CPU/DP/mem_wb_in.wrb
add wave -noupdate -divider {wrb pulling from}
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.immediate
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.AluOut
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.AdderOut
add wave -noupdate -divider {Alu Signals}
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/zero
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/negative
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/overflow
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/A
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/B
add wave -noupdate /system_tb/DUT/CPU/DP/ALU/out
add wave -noupdate /system_tb/DUT/CPU/DP/Alu_a
add wave -noupdate /system_tb/DUT/CPU/DP/Alu_b
add wave -noupdate /system_tb/DUT/CPU/DP/Alu_c
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/imm_sel
add wave -noupdate /system_tb/DUT/CPU/DP/fuif/jumpsel
add wave -noupdate -divider {PC source from Decider}
add wave -noupdate /system_tb/DUT/CPU/DP/deif/PCsrc
add wave -noupdate /system_tb/DUT/CPU/DP/ex_mem_out.AdderOut
add wave -noupdate /system_tb/DUT/CPU/DP/id_ex_out.pc
add wave -noupdate /system_tb/DUT/CPU/DP/id_ex_out.immediate
add wave -noupdate -divider Hazard
add wave -noupdate /system_tb/DUT/CPU/DP/huif/Flush
add wave -noupdate /system_tb/DUT/CPU/DP/huif/Zero_controls
add wave -noupdate /system_tb/DUT/CPU/DP/huif/Halt
add wave -noupdate /system_tb/DUT/CPU/DP/huif/latch_en
add wave -noupdate /system_tb/DUT/CPU/DP/huif/rs1
add wave -noupdate /system_tb/DUT/CPU/DP/huif/rs2
add wave -noupdate /system_tb/DUT/CPU/DP/huif/Rd
add wave -noupdate /system_tb/DUT/CPU/DP/huif/Memtoreg
add wave -noupdate -expand -subitemconfig {{/system_tb/DUT/CPU/CM/DCACHE/cur_dcache[2]} -expand} /system_tb/DUT/CPU/CM/DCACHE/cur_dcache
add wave -noupdate /system_tb/DUT/CPU/CM/dcif/flushed
add wave -noupdate -expand /system_tb/DUT/CPU/CM/ICACHE/cache_block
add wave -noupdate /system_tb/DUT/CPU/CM/cif/dWEN
add wave -noupdate /system_tb/DUT/CPU/CM/cif/daddr
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {875693 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 189
configure wave -valuecolwidth 100
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ns
update
WaveRestoreZoom {0 ps} {1696 ns}
