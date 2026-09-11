#----------------------------------------------------------
# RISC-V Assembly: Test Loop (Sum Array)
#----------------------------------------------------------
org   0x0000
.globl _start
_start:

# Initialize: sum in $1, counter in $2, pointer in $3.
addi  $1, $0, 0         # sum = 0
addi  $2, $0, 5         # counter = 5 elements
ori   $3, $0, 0x700     # pointer to start of array

loop:
    lw    $4, 0($3)     # load array element
    add   $1, $1, $4    # sum += element
    addi  $3, $3, 4     # move pointer to next element
    addi  $2, $2, -1    # decrement counter
    bne   $2, $0, loop  # loop until counter reaches 0

# Store the sum to memory at 0x800.
ori   $5, $0, 0x800
sw    $1, 0($5)

halt

# Data region: Array elements starting at 0x700.
org   0x0700
cfw   0x00000001
cfw   0x00000002
cfw   0x00000003
cfw   0x00000004
cfw   0x00000005

# Reserve space for the result at 0x0800.
org   0x0800
cfw   0x00000000
