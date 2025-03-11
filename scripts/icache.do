onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /icache_tb/CLK
add wave -noupdate /icache_tb/nRST
add wave -noupdate /icache_tb/i
add wave -noupdate /icache_tb/DUT/dcif/halt
add wave -noupdate /icache_tb/DUT/dcif/ihit
add wave -noupdate /icache_tb/DUT/dcif/imemREN
add wave -noupdate /icache_tb/DUT/dcif/imemload
add wave -noupdate /icache_tb/DUT/dcif/imemaddr
add wave -noupdate /icache_tb/DUT/dcif/dhit
add wave -noupdate /icache_tb/DUT/dcif/datomic
add wave -noupdate /icache_tb/DUT/dcif/dmemREN
add wave -noupdate /icache_tb/DUT/dcif/dmemWEN
add wave -noupdate /icache_tb/DUT/dcif/flushed
add wave -noupdate /icache_tb/DUT/dcif/dmemload
add wave -noupdate /icache_tb/DUT/dcif/dmemstore
add wave -noupdate /icache_tb/DUT/dcif/dmemaddr
add wave -noupdate /icache_tb/RAM/ramif/ramload
add wave -noupdate /icache_tb/RAM/ramif/ramstate
add wave -noupdate /icache_tb/DUT/cif/dwait
add wave -noupdate /icache_tb/DUT/cif/dWEN
add wave -noupdate /icache_tb/DUT/cif/dstore
add wave -noupdate /icache_tb/DUT/cif/daddr
add wave -noupdate /icache_tb/ccif/cif0/iREN
add wave -noupdate /icache_tb/ccif/cif0/dREN
add wave -noupdate /icache_tb/DUT/state
add wave -noupdate /icache_tb/DUT/cache_block
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {285941 ps} 0}
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
WaveRestoreZoom {0 ps} {2268 ns}
