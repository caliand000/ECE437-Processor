#--------------------------------------
# Test JAL Instruction
#--------------------------------------
org 0x0000
.globl _start
_start:
    ori   $2, $0, 0x3       
    ori   $3, $0, 0x4
            
    jal   $1, target     
    HALT            

target:
    sw   $1, 12($3)  # Reached if taken
    HALT   
