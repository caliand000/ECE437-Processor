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
beq   $1, $1, branch_taken
HALT
branch_taken:
  sw   $1, 31($1)  # Reached if taken
  HALT
