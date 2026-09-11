#--------------------------------------
# Test BLTU Not Taken
#--------------------------------------
org 0x0000
.globl _start
_start:
ori   $1, $0, 0x3
ori   $2, $0, 0x2
bltu   $1, $2, branch_not_taken
HALT
branch_not_taken:
  sw   $3, 12($2)  # Reached if taken
  HALT
