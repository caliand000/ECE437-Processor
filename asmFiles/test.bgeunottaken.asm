#--------------------------------------
# Test BGEU Not Taken
#--------------------------------------
org 0x0000
ori   $3,$0,15
ori   $1, $0, 0x2
ori   $2, $0, 0x3
bgeu   $1, $2, branch_not_taken
HALT
branch_not_taken:
  sw   $3, 13($2)  # Reached if taken
  HALT
