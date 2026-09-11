#----------------------------------------------------------
# RISC-V Assembly: Quicksort
# Updated for standard GNU RISC-V syntax compliance:
#   - %lo(array) relocation used for label address in addi
#----------------------------------------------------------
org 0x0000
.globl _start
_start:

main:
    addi a0, x0, %lo(array) # Load array base address (0x400)
    addi a1, x0, 0       # Left index = 0
    addi a2, x0, 9       # Right index = 9
    call quicksort        # Call quicksort
    halt

quicksort:
    bge a1, a2, quicksort_end  # If left >= right, return
    addi sp, sp, -16      # Allocate stack space
    sw a1, 0(sp)          # Save left
    sw a2, 4(sp)          # Save right
    sw ra, 8(sp)          # Save return address
    call partition        # Partition the array
    sw a3, 12(sp)         # Save partition index
    lw a1, 0(sp)         # Restore left
    lw a2, 12(sp)        # Load partition index
    addi a2, a2, -1      # Right = partition index - 1
    call quicksort        # Recursively sort left partition
    lw a1, 12(sp)        # Load partition index
    addi a1, a1, 1       # Left = partition index + 1
    lw a2, 4(sp)         # Restore original right
    call quicksort        # Recursively sort right partition
    lw ra, 8(sp)         # Restore return address
    addi sp, sp, 16      # Deallocate stack
quicksort_end:
    jalr x0, 0(ra)       # Return to caller

partition:
    slli t0, a2, 2       # Calculate pivot address (right * 4)
    add t0, a0, t0
    lw t1, 0(t0)         # Load pivot value
    addi t2, a1, -1      # i = left - 1
    addi t3, a1, 0       # j = left
partition_loop:
    bge t3, a2, end_loop # Exit loop if j >= right
    slli t4, t3, 2       # Calculate array[j] address
    add t4, a0, t4
    lw t5, 0(t4)         # Load array[j]
    blt t1, t5, skip_swap # Skip swap if array[j] > pivot
    addi t2, t2, 1       # i += 1
    slli t6, t2, 2       # Calculate array[i] address
    add t6, a0, t6
    lw x15, 0(t6)         # Load array[i]
    sw t5, 0(t6)         # Swap array[i] and array[j]
    sw x15, 0(t4)
skip_swap:
    addi t3, t3, 1       # j += 1
    j partition_loop
end_loop:
    addi t2, t2, 1       # i + 1 for pivot swap
    slli t4, t2, 2       # Calculate array[i+1] address
    add t4, a0, t4
    lw t5, 0(t4)         # Load array[i+1]
    slli t6, a2, 2       # Calculate pivot address
    add t6, a0, t6
    lw x15, 0(t6)         # Load pivot value
    sw x15, 0(t4)         # Swap pivot with array[i+1]
    sw t5, 0(t6)
    addi a3, t2, 0       # Return partition index (i+1)
    jalr x0, 0(ra)       # Return to caller

org 0x400
array:
cfw 10
cfw 3
cfw 7
cfw 5
cfw 2
cfw 8
cfw 4
cfw 1
cfw 6
cfw 9
