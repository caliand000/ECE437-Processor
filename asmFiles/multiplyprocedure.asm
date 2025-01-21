#----------------------------------------------------------
# RISC-V Assembly
#----------------------------------------------------------
#--------------------------------------
# Multiply Procedure for Multiple Operands
#--------------------------------------
  org 0x0000

  ori   $10, $10, start      # Initialize pointer to start
  lw    $11, 0($10)          # Load first operand
  lw    $12, 4($10)          # Load second operand
  jal   multiply             # Call multiply subroutine
  sw    $13, 8($10)          # Store result
  halt                       # End of program

multiply:
  ori   $13, $13, 0          # Initialize result register
loop:
  beq   $12, $0, done        # If second operand is 0, exit loop
  add   $13, $13, $11        # Add first operand to result
  addi  $12, $12, -1         # Decrement second operand
  j     loop                 # Repeat loop

done:
  jr    $ra                  # Return from subroutine

  org 0x80

start:
  cfw 4                      # First operand
  cfw 100                      # Second operand
  cfw 0                      # Placeholder for result
