#--------------------------------------
# Test BLTU Taken
#--------------------------------------
org 0x0000
ori   $1, $0, 0x2
ori   $2, $0, 0x3
bltu   $1, $2, branch_taken
HALT
branch_taken:
  sw  $3, 13($2)  # Reached if taken
  HALT
