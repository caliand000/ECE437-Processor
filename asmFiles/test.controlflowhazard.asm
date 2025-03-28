#--------------------------------------
# Test Control Flow Hazard
#--------------------------------------
org 0x0000
ori   $1, $0, 0x4
ori   $2, $0, 0x5
ori   $3, $0, 0x6
ori   $4, $0, 0x7
beq   $1, $1, branch_taken
sw    $2, 4($1)
sw    $3, 8($1)
sw    $4, 12($1)
HALT
branch_taken:
  sw   $1, 16($1)  # Reached if taken
  HALT
