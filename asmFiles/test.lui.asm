#--------------------------------------
# Test BGEU Not Taken
#--------------------------------------
org 0x0000
.globl _start
_start:
lui   $1, 0x2
lui   $2, 0x3

sw    $1, 64($0)
sw    $2, 100($0)
HALT
