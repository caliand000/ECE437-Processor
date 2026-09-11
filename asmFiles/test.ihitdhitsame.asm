#--------------------------------------
# Test IHIT and DHIT in the Same Cycle
#--------------------------------------
org 0x0000
.globl _start
_start:

ori   $3, $0, 0x4  
sw    $3, 64($0)    
ori   $5, $0, 0x0
Loop:
    addi  $5, $5, 0x1
    lw    $4, 64($0)

blt   $5, $3, Loop
HALT
