#--------------------------------------
# Test BGE Taken
#--------------------------------------
org 0x0000
ori   $1, $0, 0x5
ori   $2, $0, 0x4
bge   $1, $2, branch_taken
HALT
branch_taken:
  sw   $3, 12($2)  # Reached if taken
  HALT
