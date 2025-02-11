#----------------------------------------------------------
# Calculate Days Since 2000
#----------------------------------------------------------
  org 0x0000

calc_days:

  addi $17, $0, 21
  addi $12, $0, 1
  addi $13, $0, 2025


  addi  $12, $12, -1         # (CurrentMonth - 1)
  addi  $11, $0, 30          # Load 30 (days in a month)

  jal   multiply             # Call multiply for (CurrentMonth - 1) * 30
  add   $17, $15, $17        # Add month days to CurrentDay

  addi  $11, $13, -2000      # (CurrentYear - 2000)
  addi  $12, $0, 365         # Load 365 (days in a year)
  jal   multiply             # Call multiply for (CurrentYear - 2000) * 365
  add   $17, $17, $15        # Add year days to result
  addi $11, $17, 0 
  halt                       # End of program

multiply:
  addi   $15, $0, 0          # Initialize result register
loop:
  beq   $12, $0, done        # If second operand is 0, exit loop
  add   $15, $15, $11        # Add first operand to result
  addi  $12, $12, -1         # Decrement second operand
  j     loop                 # Repeat loop

done:
jr    $ra                  # Return from subroutine


start:
  cfw 0x15                     # CurrentDay
  cfw 1                      # CurrentMonth
  cfw 0x7E9                   # CurrentYear
  cfw 0                      # Placeholder for days result
