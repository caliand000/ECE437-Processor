#--------------------------------------
# Test Data Hazard
#--------------------------------------
org 0x0000

ori   $3, $0, 0x5
ori   $2, $0, 0x4

add   $1, $2, $3            #using x1 in WB
sub   $4, $1, $3            #using x1 in ID/RF
and   $6, $1, $7            #using x1 in ID/RF
or    $8, $1, $9            #using x1 in ID/RF
XOR   $10, $1, $11          #using x1 in OD/RF 

HALT

