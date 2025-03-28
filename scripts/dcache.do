onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /dcache_tb/CLK
add wave -noupdate /dcache_tb/CPUCLK
add wave -noupdate /dcache_tb/nRST
add wave -noupdate /dcache_tb/check_output/case_info
add wave -noupdate -divider Inputs
add wave -noupdate /dcache_tb/dcif/halt
add wave -noupdate /dcache_tb/dcif/dmemREN
add wave -noupdate /dcache_tb/dcif/dmemWEN
add wave -noupdate /dcache_tb/dcif/dmemstore
add wave -noupdate /dcache_tb/dcif/dmemaddr
add wave -noupdate -divider Outputs
add wave -noupdate /dcache_tb/dcif/dhit
add wave -noupdate /dcache_tb/dcif/flushed
add wave -noupdate /dcache_tb/dcif/dmemload
add wave -noupdate /dcache_tb/DUT/state
add wave -noupdate -expand /dcache_tb/DUT/cur_dcache
add wave -noupdate /dcache_tb/DUT/halt_cnt
add wave -noupdate /dcache_tb/DUT/hit_cnt
add wave -noupdate /dcache_tb/DUT/index
add wave -noupdate -divider {RAM connections}
add wave -noupdate /dcache_tb/cif1/dwait
add wave -noupdate /dcache_tb/cif1/dREN
add wave -noupdate /dcache_tb/cif1/dWEN
add wave -noupdate /dcache_tb/cif1/dload
add wave -noupdate /dcache_tb/cif1/dstore
add wave -noupdate /dcache_tb/cif1/daddr
add wave -noupdate /dcache_tb/RAM/rstate
add wave -noupdate /dcache_tb/RAM/ramif/ramstore
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {877351 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 150
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
WaveRestoreZoom {459 ns} {1445 ns}
