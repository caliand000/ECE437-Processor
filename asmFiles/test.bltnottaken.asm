#--------------------------------------
# Test BLT Not Taken
#--------------------------------------
org 0x0000
ori   $1, $0, 0x7
ori   $2, $0, 0x6
blt   $1, $2, branch_not_taken
HALT
branch_not_taken:
  sw   $3, 10($2)  # Reached if taken
  HALT
