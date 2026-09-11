#--------------------------------------
# Test IHIT Before DHIT During LW, SW
#--------------------------------------
org 0x0000
.globl _start
_start:

ori   $3, $0, 0x4
ori   $2, $0, 0x4  
sw    $3, 64($0)    
ori   $5, $0, 0x0
Loop:
    add  $2, $2, $3
    addi  $5, $5, 0x1
    lw    $4, 64($2)

blt   $5, $3, Loop
HALT
