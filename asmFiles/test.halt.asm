#--------------------------------------
# Test HALT Instruction
#--------------------------------------
org 0x0000
    ori   $2, $0, 0x4       
    HALT    
    sw   $3, 12($2)  # Reached if taken         

    
