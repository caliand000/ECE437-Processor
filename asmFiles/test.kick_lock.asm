org 0x0000 #Core 0

    li a0, 0x0300
    lr.w t0, (a0)
    li a0, 0x0400
    lw t1, 0(a0)
    li a0, 0x0500
    lw t2, 0(a0) #lock address should be evicted now
    li a0, 0x0300 #load the lock address back to a0 to test atomicity
    sc.w t3, t2, (a0)
    sw t3, 16(zero) #store the returned value.

HALT



org 0x0200 #Core 1

HALT

org 0x0300
    data:
        cfw 0xDEAD

org 0x0400
    data2:
        cfw 0xDEA1

org 0x0500
    data3:
        cfw 0xDEA2
