#--------------------------------------
# Test JALR Instruction
#--------------------------------------
org 0x0000
    ori   $2, $0, 0x2       
    jal   $1, target     
    ori   $4, $0, 0x1           
    HALT   

target:
    sw   $3, 12($2)  # Reached if taken       
    jalr  $1   
