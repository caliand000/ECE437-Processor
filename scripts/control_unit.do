onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /control_unit_tb/CLK
add wave -noupdate /control_unit_tb/nRST
add wave -noupdate /control_unit_tb/check_output/case_info
add wave -noupdate /control_unit_tb/stype
add wave -noupdate /control_unit_tb/rtype
add wave -noupdate -divider Inputs
add wave -noupdate /control_unit_tb/cuif/imemload
add wave -noupdate /control_unit_tb/cuif/zero
add wave -noupdate /control_unit_tb/cuif/neg
add wave -noupdate /control_unit_tb/cuif/overflow
add wave -noupdate -divider Outputs
add wave -noupdate /control_unit_tb/cuif/Aluop
add wave -noupdate /control_unit_tb/cuif/MemWr
add wave -noupdate /control_unit_tb/cuif/MemtoReg
add wave -noupdate /control_unit_tb/cuif/AluSrc
add wave -noupdate /control_unit_tb/cuif/RegWr
add wave -noupdate /control_unit_tb/cuif/jumpsel
add wave -noupdate /control_unit_tb/cuif/PCSrc
add wave -noupdate /control_unit_tb/cuif/pchalt
add wave -noupdate -radix decimal /control_unit_tb/cuif/Rd
add wave -noupdate -radix decimal /control_unit_tb/cuif/Rs1
add wave -noupdate -radix decimal /control_unit_tb/cuif/Rs2
add wave -noupdate -radix decimal /control_unit_tb/cuif/Imm
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {61091 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 314
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
WaveRestoreZoom {0 ps} {336 ns}
