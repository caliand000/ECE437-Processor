#--------------------------------------
# Test BGE Not Taken
#--------------------------------------
org 0x0000
.globl _start
_start:
ori   $1, $0, 0x5
ori   $2, $0, 0x6
bge   $1, $2, branch_not_taken
HALT
branch_not_taken:
  sw   $1, 16($1)  # Reached if taken
  HALT
