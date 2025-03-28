#--------------------------------------
# Test Structural Hazard
#--------------------------------------
org 0x0000

ori   $3, $0, 0x5
ori   $2, $0, 0x4

#do consecutive stores, r type after sw, stuff using same hardware components

HALT

