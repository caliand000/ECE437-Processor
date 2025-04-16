org   0x0000
  
  ori   $10, $0, 0x80
  lw    $11, 0($10)
  addi   $11, $11, 0x01
  sw    $11, 0($10)
 
 
  halt      # that's all

  org   0x0200
  nop
  nop
  nop
  ori   $10, $0, 0x80
  lw    $11, 0($10)
  addi   $11, $11, 0x02
  sw    $11, 0($10)
  halt      # that's all
