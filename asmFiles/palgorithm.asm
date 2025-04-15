#----------------------------------------------------------
# RISC-V Assembly
#----------------------------------------------------------
#------------------------------------------
# Parallel Algorithm
# Written by Andrew Cali
#------------------------------------------


#----------------------------------------------------------
# Core 1 Init - Producer
#----------------------------------------------------------
  org 0x0000    
  li      sp, 0xFFFC    # core 1 stack
  jal     mainc1        # core 1 main program
  halt



#----------------------------------------------------------
# Shared Lock Functions
#----------------------------------------------------------
# pass in an address to lock function in argument register 0
# returns when lock is available
lock:
    acquire:
        lr.w    t0, (a0)              # load lock location
        bne     t0, zero, acquire     # wait on lock to be open
        li      t1, 1
        sc.w    t2, t1, (a0)
        bne     t2, zero, lock        # if sc.w failed, retry (In case of SC failure, rd gets written 1 (!= 0))
        ret

# pass in an address to unlock function in argument register 0
# returns after freeing lock

unlock:
    sw      zero, 0(a0)               # exclusive writer safe to clear the lock
    ret

#----------------------------------------------------------
# Core 1 Main
#----------------------------------------------------------
# main function does something ugly but demonstrates beautifully
mainc1:
    push ra

    # Set initial seed for CRC random number generator (32-bit seed)
    li    a4, 0xdeadbeef        

    # Initialize counter (number of generated numbers)
    li    a3, 0 
    ori    t6, x0, stack_ptr    # t6 = current shared stack pointer.

random_loop:  

# Acquire lock on shared data
    ori a0, zero, lock_var
    jal lock 
    
# Generate new random number using the provided CRC subroutine:
    ori  a2, a4, 0                
    jal   crc32                  
    ori  a4, a0, 0    

   

# Begin critical section for push:
    sw    a4, 0(t6)             # Store new CRC value -> shared stack pointer
    addi  t6, t6, 4             # Increment
    ori a7, x0, stack_ptr_start
    sw    t6, 0(a7)

# Release the lock after finishing push.
    ori   a0, zero, lock_var
    jal   unlock


 # Increment counter and check if we are done:
    addi  a3, a3, 1
    li    t4, 256
    blt   a3, t4, random_loop

  pop ra


  crc32:
  lui $t1, 0x04C11
   ori $t1, $t1, 0x7B7
   addi $t1, $t1, 0x600
   or $t2, $0, $0
   ori $t3, $0, 32
 
l1:
  slt $t4, $t2, $t3
   beq $t4, $0, l2
 
  ori $t5, $0, 31
   srl $t4, $a2, $t5
   ori $t5, $0, 1
   sll $a2,$a2,$t5
   beq $t4, $0, l3
   xor $a2, $a2, $t1
 l3:
  addi $t2, $t2, 1
   j l1
l2:
  or $a0, $a2, $0
   jr $1
   
  ret

#----------------------------------------------------------
# Core 2 Init - Consumer
#----------------------------------------------------------
  org 0x0200    
  li      sp, 0x7FFC    # core 2 stack
  jal     mainc2        # core 2 main program
  halt

#----------------------------------------------------------
# Core 2 Main
#----------------------------------------------------------
# main function does something ugly but demonstrates beautifully
mainc2:
  push ra

# Initialize statistics:
  li    t3, 0                 # Count of numbers consumed
  li    t4, 0                 # Running sum (for average)
  li    t5, 0xFFFF            # Initial minimum (set high, 16-bit value)
  li    t6, 0                 # Initial maximum
  ori a4, x0, stack_ptr 

consumer_loop:
  # Pop a value from the shared stack using the shared lock
  ori   a0, zero, lock_var
  jal   lock

  ori a3, x0, stack_ptr_start
  lw a3, 0(a3)
  bne a3, x0, continue

  ori   a0, zero, lock_var  
  jal   unlock 
  j consumer_loop

  continue:             

  # Critical Section: Perform the pop operation.
  lw  a3, 0(a4)                 # Load the popped CRC value
  li    t0, 0
  sw    t0, 0(a4)               # Zero out that memory location
  addi  a4, a4, 4              # Decrement pointer by 4 to point to the last pushed item

  ori   a0, zero, lock_var  
  jal   unlock                

  # Process the popped value:
  li  a7, 0xFFFFFFFF        # Use only the lower 16 bits
  srli  a7, a7, 16
  and a3, a3, a7
  add   t4, t4, a3            # Add to running sum

  # Update minimum value
  blt   a3, t5, set_min
  j     check_max

set_min:
  ori  t5, a3, 0

# Update maximum value
check_max:
  bgt   a3, t6, set_max
  j     after_update

set_max:
  ori  t6, a3, 0

after_update:
  # Increment count and loop until all 256 numbers are consumed
  addi  t3, t3, 1
  li    a5, 256
  blt   t3, a5, consumer_loop

  # Compute average: Shift right by 8 bits to divide by 256
  srli   a6, t4, 8          # t10 contains the computed average


  # Restore return address and return from consumer_main
  pop ra
  ret


#----------------------------------------------------------
# Shared Data Segment
#----------------------------------------------------------
org 0x0800


lock_var:
  cfw 0x0     # lock starts unlocked, should end unlocked

# Shared stack pointer:
stack_ptr_start:
  cfw 0x0

stack_ptr:
  cfw 0x0   # Initialize pointer to the start of the buffer.



