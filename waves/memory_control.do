onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /memory_control_tb/CLK
add wave -noupdate /memory_control_tb/nRST
add wave -noupdate /memory_control_tb/rstate
add wave -noupdate /memory_control_tb/addr
add wave -noupdate -divider instruction
add wave -noupdate /memory_control_tb/ccif/iwait
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/iREN
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/iaddr
add wave -noupdate /memory_control_tb/ccif/iload
add wave -noupdate -divider data
add wave -noupdate /memory_control_tb/ccif/dwait
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/dREN
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/dWEN
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/daddr
add wave -noupdate /memory_control_tb/ccif/dload
add wave -noupdate /memory_control_tb/ccif/dstore
add wave -noupdate -divider ram
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/ramstate
add wave -noupdate /memory_control_tb/ccif/ramREN
add wave -noupdate /memory_control_tb/ccif/ramWEN
add wave -noupdate /memory_control_tb/ccif/ramaddr
add wave -noupdate /memory_control_tb/ccif/ramstore
add wave -noupdate -color {Orange Red} /memory_control_tb/ccif/ramload
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {22124 ps} 0}
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
WaveRestoreZoom {0 ps} {73500 ps}
