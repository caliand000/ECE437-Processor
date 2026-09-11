#--------------------------------------
# Test BNE Taken
#--------------------------------------
org 0x0000
.globl _start
_start:
ori   $1, $0, 0x5
ori   $2, $0, 0x4
bne   $1, $2, branch_taken
HALT
branch_taken:
  sw   $3, 52($2)  # Reached if taken
  HALT
