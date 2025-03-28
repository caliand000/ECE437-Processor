#----------------------------------------------------------
# RISC-V Assembly
#----------------------------------------------------------
#--------------------------------------
# Multiply Two Unsigned Integers
#--------------------------------------
  org 0x0000

  ori   $10, $10, start      # Initialize pointer to start
  lw    $11, 0($10)          # Load Operand1
  lw    $12, 4($10)          # Load Operand2
  ori   $13, $13, 0          # Initialize result register

loop:
  beq   $12, $0, done        # If Operand2 is 0, exit loop
  add   $13, $13, $11        # Add Operand1 to result
  addi  $12, $12, -1         # Decrement Operand2
  j     loop                 # Repeat loop

done:
  sw    $13, 8($10)          # Store result
  halt                       # End of program

  org 0x80

start:
  cfw 4                      # Operand1
  cfw 100                      # Operand2
  cfw 0                      # Placeholder for result
