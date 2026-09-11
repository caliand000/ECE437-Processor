#--------------------------------------
# Test Data Hazard
#--------------------------------------
org 0x0000
.globl _start
_start:

ori   $3, $0, 0x5
sw    $3, 84($0)  
lw    $5, 84($0)
add   $6, $5, $3
sw    $6, 88($0)

HALT

#do a load then use value right after
