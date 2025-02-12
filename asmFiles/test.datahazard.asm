#--------------------------------------
# Test Data Hazard
#--------------------------------------
org 0x0000

ori   $3, $0, 0x5
sw    $3, 4($0)  
nop
lw    $5, 4($0)
add   $6, $5, $3
sw    $6, 8($0)

HALT

#do a load then use value right after
