org 0x0000
ori x1,x1,12;
sw x1 500(x0);
nop
halt

org 0x0200
ori x1,x1,16;
sw x1 600(x0);
sw x1 500(x0);
halt
