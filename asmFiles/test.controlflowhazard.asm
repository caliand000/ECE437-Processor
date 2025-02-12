#--------------------------------------
# Test Control Flow Hazard
#--------------------------------------
org 0x0000
ori   $1, $0, 0x5
beq   $1, $1, branch_taken
ori   $2, $0, 0x4
ori   $3, $0, 0x3
ori   $4, $0, 0x6
HALT
branch_taken:
  sw   $1, 15($1)  # Reached if taken
  HALT
