#----------------------------------------------------------
# RISC-V Assembly Unit Tests
#----------------------------------------------------------

#--------------------------------------
# Test BEQ Taken
#--------------------------------------
org 0x0000
.globl _start
_start:
ori   $1, $0, 0x5
ori   $2, $0, 0x4
beq   $1, $2, branch_not_taken
HALT
branch_not_taken:
  sw   $1, 15($1)  # Reached if taken
  HALT
