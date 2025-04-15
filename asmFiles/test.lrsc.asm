#----------------------------------------------------------
# RISC-V Assembly
#----------------------------------------------------------
#------------------------------------------------------------------
# Test lrsc test
# Note: SW/SC should invalidate the link register if there is an
#       address match in the opposite core or in the same core.
#------------------------------------------------------------------

  org   0x0000
  li      sp, 0xFFFC    # core 1 stack
  jal     mainc1        # core 1 main program

  halt

#----------------------------------------------------------
# Shared Lock Functions
#----------------------------------------------------------
  lock:
    acquire:
        lr.w    t0, (a0)              # load lock location
        bne     t0, zero, acquire     # wait on lock to be open
        li      t1, 1
        sc.w    t2, t1, (a0)
        bne     t2, zero, lock        # if sc.w failed, retry (In case of SC failure, rd gets written 1 (!= 0))
        ret

  unlock:
    sw      zero, 0(a0)               # exclusive writer safe to clear the lock
    ret


#----------------------------------------------------------
# Core 1 Main
#----------------------------------------------------------
  mainc1:      
    push ra
    li   t3, 10      
    ori t4, t4, stack_ptr
    ori a0, zero, lock_var
    jal lock

    lw t5, 0(t4)
    add t3, t3, t5
    sw t3, 0(t4)

    ori   a0, zero, lock_var
    jal   unlock


  halt      # that's all





  org   0x0200
  li      sp, 0x7FFC    # core 1 stack
  jal     mainc2        # core 1 main program
  halt

#----------------------------------------------------------
# Core 2 Main
#----------------------------------------------------------
  mainc2:
    push ra
    li   t3, 5     
    ori t4, t4, stack_ptr
    ori a0, zero, lock_var
    jal lock


    lw t5, 0(t4)
    add t3, t3, t5
    sw t3, 0(t4)

    ori   a0, zero, lock_var
    jal   unlock

  halt      # that's all






#----------------------------------------------------------
# Shared Data Segment
#----------------------------------------------------------

  org 0x300

  lock_var:
    cfw 0x0

  stack_ptr:
    cfw 0x0
