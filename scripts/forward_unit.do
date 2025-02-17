onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate -divider Inputs
add wave -noupdate /forward_unit_tb/fuif/rs1
add wave -noupdate /forward_unit_tb/fuif/rs2
add wave -noupdate /forward_unit_tb/fuif/Rd_Mem
add wave -noupdate /forward_unit_tb/fuif/Rd_WB
add wave -noupdate /forward_unit_tb/fuif/RegWR_mem
add wave -noupdate /forward_unit_tb/fuif/RegWR_WB
add wave -noupdate -divider Outputs
add wave -noupdate /forward_unit_tb/fuif/Alu_in1
add wave -noupdate /forward_unit_tb/fuif/Alu_in2
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {192 ns} 0}
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
WaveRestoreZoom {0 ns} {1054 ns}
