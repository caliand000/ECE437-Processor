#--------------------------------------
# Test JALR Instruction
#--------------------------------------
org 0x0000
.globl _start
_start:
    ori   $2, $0, 0x4       
    jal   $1, target     
    
    sw   $1, 32($2)  # Reached if taken         
    HALT   

target:
    sw   $1, 28($2)  # Reached if taken       
    jalr  $1, 4($2)  
