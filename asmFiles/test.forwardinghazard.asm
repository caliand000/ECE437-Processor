#--------------------------------------
# Test Forwarding Hazard
#--------------------------------------
org 0x0000

ori   $3, $0, 0x5
sw    $3, 64($0)  
nop
lw    $5, 64($0)
ori   $2, $0, 0x4
ori   $4, $0, 0x3
add   $6, $4, $5
sw    $6, 100($0)

#do consecutive stores, r type after sw, stuff using same hardware components

HALT

