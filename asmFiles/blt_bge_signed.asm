# Signed BLT/BGE coverage, including subtraction-overflow cases.
org 0x0000
.globl _start
_start:
  lui   $1, 0x80000
  addi  $2, $0, -1
  lui   $3, 0x80000
  addi  $4, $0, 1
  addi  $5, $0, 3
  addi  $6, $0, 5

  # INT_MAX < -1 is false; INT_MAX >= -1 is true.
  lui   $1, 0x80000
  addi  $1, $1, -1
  addi  $2, $0, -1
  blt   $1, $2, case1_fail
  bge   $1, $2, case1_pass
case1_fail:
  addi  $10, $0, 0
  sw    $10, 0x200($0)
  jal   $0, case2
case1_pass:
  addi  $10, $0, 1
  sw    $10, 0x200($0)

case2:
  # -1 < INT_MAX is true; -1 >= INT_MAX is false.
  addi  $1, $0, -1
  lui   $2, 0x80000
  addi  $2, $2, -1
  blt   $1, $2, case2_blt_pass
  bge   $1, $2, case2_bge_fail
case2_blt_pass:
  addi  $10, $0, 1
  sw    $10, 0x204($0)
  jal   $0, case3
case2_bge_fail:
  addi  $10, $0, 0
  sw    $10, 0x204($0)

case3:
  # INT_MIN < 1 is true; INT_MIN >= 1 is false.
  lui   $1, 0x80000
  addi  $2, $0, 1
  blt   $1, $2, case3_blt_pass
  addi  $10, $0, 0
  sw    $10, 0x208($0)
  jal   $0, case4
case3_blt_pass:
  bge   $1, $2, case3_bge_fail
  addi  $10, $0, 1
  sw    $10, 0x208($0)
  jal   $0, case4
case3_bge_fail:
  addi  $10, $0, 0
  sw    $10, 0x208($0)

case4:
  # 1 < INT_MIN is false; 1 >= INT_MIN is true.
  addi  $1, $0, 1
  lui   $2, 0x80000
  blt   $1, $2, case4_blt_fail
  bge   $1, $2, case4_pass
case4_blt_fail:
  addi  $10, $0, 0
  sw    $10, 0x20c($0)
  jal   $0, case5
case4_pass:
  addi  $10, $0, 1
  sw    $10, 0x20c($0)

case5:
  # Normal small-number case: 3 < 5 and 5 >= 3.
  addi  $1, $0, 3
  addi  $2, $0, 5
  blt   $1, $2, case5_blt_pass
  addi  $10, $0, 0
  sw    $10, 0x210($0)
  jal   $0, done
case5_blt_pass:
  bge   $1, $2, case5_bge_fail
  addi  $10, $0, 1
  sw    $10, 0x210($0)
  jal   $0, done
case5_bge_fail:
  addi  $10, $0, 0
  sw    $10, 0x210($0)

done:
  HALT
