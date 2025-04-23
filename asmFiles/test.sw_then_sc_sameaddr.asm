org 0x0000 #Core0
    li t0, 0xE00C
    lr.w a0, (t0)
    li a1, 0xDEAD
    sw a1, 0(t0)
    sc.w t1, a0, (t0)
    sw t1, 4(t0)
    HALT









org 0x200 #Core1
    HALT




org 0xE00C #Lock ADDR
    cfw 0x0000
