onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate /system_tb/CLK
add wave -noupdate /system_tb/nRST
add wave -noupdate -divider {Core 0}
add wave -noupdate -divider {Datapath signals}
add wave -noupdate -color Gold /system_tb/DUT/CPU/dcif0/ihit
add wave -noupdate /system_tb/DUT/CPU/dcif0/imemREN
add wave -noupdate /system_tb/DUT/CPU/dcif0/imemload
add wave -noupdate /system_tb/DUT/CPU/dcif0/imemaddr
add wave -noupdate -color Gold /system_tb/DUT/CPU/dcif0/dhit
add wave -noupdate /system_tb/DUT/CPU/dcif0/dmemREN
add wave -noupdate /system_tb/DUT/CPU/dcif0/dmemWEN
add wave -noupdate /system_tb/DUT/CPU/dcif0/dmemload
add wave -noupdate /system_tb/DUT/CPU/dcif0/dmemstore
add wave -noupdate /system_tb/DUT/CPU/dcif0/dmemaddr
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Core 1}
add wave -noupdate -divider {Datapath Signals}
add wave -noupdate -color Gold /system_tb/DUT/CPU/dcif1/ihit
add wave -noupdate /system_tb/DUT/CPU/dcif1/imemREN
add wave -noupdate /system_tb/DUT/CPU/dcif1/imemload
add wave -noupdate /system_tb/DUT/CPU/dcif1/imemaddr
add wave -noupdate -color Gold /system_tb/DUT/CPU/dcif1/dhit
add wave -noupdate /system_tb/DUT/CPU/dcif1/dmemREN
add wave -noupdate /system_tb/DUT/CPU/dcif1/dmemWEN
add wave -noupdate /system_tb/DUT/CPU/dcif1/dmemload
add wave -noupdate /system_tb/DUT/CPU/dcif1/dmemstore
add wave -noupdate /system_tb/DUT/CPU/dcif1/dmemaddr
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider RAM
add wave -noupdate /system_tb/DUT/CPU/ccif/ramstate
add wave -noupdate /system_tb/DUT/CPU/ccif/ramWEN
add wave -noupdate /system_tb/DUT/CPU/ccif/ramREN
add wave -noupdate /system_tb/DUT/CPU/ccif/ramaddr
add wave -noupdate /system_tb/DUT/CPU/ccif/ramstore
add wave -noupdate /system_tb/DUT/CPU/ccif/ramload
TreeUpdate [SetDefaultTree]
quietly WaveActivateNextPane
add wave -noupdate -divider {Bus Controller}
add wave -noupdate /system_tb/DUT/CPU/CC/curr_state
add wave -noupdate /system_tb/DUT/CPU/CC/curr_core
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/iwait
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/dwait
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/iREN
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/dREN
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/dWEN
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/iload
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/dload
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/dstore
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/iaddr
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/daddr
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/ccwait
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/ccinv
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/ccwrite
add wave -noupdate /system_tb/DUT/CPU/ccif/cctrans
add wave -noupdate -expand /system_tb/DUT/CPU/CC/ccif/ccsnoopaddr
add wave -noupdate -divider dcache0
add wave -noupdate /system_tb/DUT/CPU/CM0/cif/ccwait
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/state
add wave -noupdate -expand -subitemconfig {{/system_tb/DUT/CPU/CM0/DCACHE/cur_dcache[0]} -expand {/system_tb/DUT/CPU/CM0/DCACHE/cur_dcache[0].way} -expand} /system_tb/DUT/CPU/CM0/DCACHE/cur_dcache
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/hit0
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/hit1
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/shit0
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/shit1
add wave -noupdate -divider dcache1
add wave -noupdate /system_tb/DUT/CPU/CM1/cif/ccwait
add wave -noupdate /system_tb/DUT/CPU/CM0/DCACHE/shit
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/state
add wave -noupdate -expand -subitemconfig {{/system_tb/DUT/CPU/CM1/DCACHE/cur_dcache[0]} -expand} /system_tb/DUT/CPU/CM1/DCACHE/cur_dcache
add wave -noupdate /system_tb/DUT/CPU/CC/ccif/cctrans
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/hit0
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/hit1
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/shit0
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/shit1
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/shit
add wave -noupdate /system_tb/DUT/CPU/CM1/DCACHE/snoop_dcache
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {1720000 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 123
configure wave -valuecolwidth 219
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
WaveRestoreZoom {1434 ns} {2207 ns}
