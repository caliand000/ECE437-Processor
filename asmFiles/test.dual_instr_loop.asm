org 0x000 #Core0
    ori x4, x0, 200
    ori x5, x0, 0
    ori x8, x0, 0
    li x7, 0x400
    ori x6, x0, 0
    ori x10, x0, 0 #Branch condition in the middle to store
    Loop_Core1:
        add x6, x6, x5
        BEQ x8, x10, Store_Current_Sum
        addi x8, x8, 1
        addi x5, x5, 1
        BNE x8, x4, Loop_Core1
    HALT

    Store_Current_Sum:
        add x7, x7, x5
        sw x6, 0x000(x7)
        addi x8, x8, 1
        addi x5, x5, 1
        addi x10, x10, 4
        BNE x8, x4, Loop_Core1

org 0x200 #Core1
    ori x4, x0, 200
    ori x5, x0, 0
    ori x8, x0, 0
    li x7, 0x400
    ori x6, x0, 0
    Loop_Core2:
        add x6, x6, x5
        addi x5, x5, 1
        addi x8, x8, 1
        BNE x8, x4, Loop_Core2
    HALT


org 0x400
