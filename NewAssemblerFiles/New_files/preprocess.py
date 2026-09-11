#!/usr/bin/env python3
"""
Translates ECE437 processor .asm syntax into standard GNU RISC-V (riscv64-unknown-elf-as)
syntax. The underlying ISA is standard RV32I/RV32A per cpu_types_pkg.vh -- this is a thin
syntax shim, not a real assembler. It does three mechanical substitutions:

  $N              -> xN            (register syntax)
  cfw <value>      -> .word <value> (raw data word directive)
  halt             -> .word 0x0000007f  (this core's non-standard HALT opcode, 7'b1111111,
                                          with rd/rs1/rs2/funct3/funct7 fields all zero)
  org <addr>       -> .org <addr>  (location-counter directive, same semantics)

Everything else (addi, ori, lw, sw, add, sub, beq, bne, lui, labels, comments) is passed
through untouched -- it's already standard RISC-V assembly, since this ISA's opcode/funct3/
funct7 encodings in cpu_types_pkg.vh match the real RISC-V spec exactly (only the HALT
opcode is invented for this course).
"""
import re
import sys

REG_RE = re.compile(r'\$([a-zA-Z0-9]+)')
CFW_RE = re.compile(r'\bcfw\b', re.IGNORECASE)
HALT_RE = re.compile(r'\bhalt\b', re.IGNORECASE)
ORG_RE = re.compile(r'\borg\b', re.IGNORECASE)

# I-type ALU ops with a 12-bit sign-extended immediate field (matches the generic
# assignment in control_unit.sv's ITYPE case: cuif.Imm = {{20{itype.imm[11]}},itype.imm}).
# A literal outside -2048..2047 doesn't fit in the field; GNU as correctly rejects it,
# where the original course tool apparently didn't. This reproduces the exact bit
# pattern the field would actually hold (imm mod 4096, reinterpreted as signed), so
# behavior matches whatever the original hardware/assembler combination really did --
# it does NOT mean the literal's intended value is preserved semantically.
ITYPE_IMM_RE = re.compile(
    r'^(\s*)(addi|ori|andi|xori|slti|sltiu)(\s+)([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*(-?0[xX][0-9A-Fa-f]+|-?\d+)(.*)$'
)

# Bare label used as an I-type immediate (e.g. `ori x10, x10, start`). GNU as
# rejects this outright -- it wants an explicit relocation hint for symbol
# references, not a plain identifier. %lo(label) tells it to emit the
# label's low 12 bits via relocation, which is the correct general fix: it
# matches the same low-12-bits-sign-extended behavior the hardware applies
# to any I-type immediate, whether it came from a literal or a label address.
# Only correct when the label's actual address fits in 12 bits unsigned-wrapped
# (< 0x1000) -- for larger addresses this needs a real lui+addi/%hi()+%lo()
# pair instead, which this shim does not attempt to detect or generate.
ITYPE_LABEL_IMM_RE = re.compile(
    r'^(\s*)(addi|ori|andi|xori|slti|sltiu)(\s+)([a-zA-Z0-9_]+)\s*,\s*([a-zA-Z0-9_]+)\s*,\s*([A-Za-z_][A-Za-z0-9_]*)\s*$'
)

def fix_itype_label_immediate(line: str) -> str:
    m = ITYPE_LABEL_IMM_RE.match(line)
    if not m:
        return line
    indent, mnem, sp, rd, rs1, label = m.groups()
    return f"{indent}{mnem}{sp}{rd}, {rs1}, %lo({label})\n"

def fix_itype_immediate(line: str) -> str:
    m = ITYPE_IMM_RE.match(line)
    if not m:
        return line
    indent, mnem, sp, rd, rs1, imm_text, rest = m.groups()
    value = int(imm_text, 0)
    low12 = value & 0xFFF
    signed = low12 - 0x1000 if low12 >= 0x800 else low12
    if signed == value:
        return line
    note = f"  # NOTE: {imm_text} truncated to 12-bit field -> {signed} (was out of -2048..2047 range)"
    return f"{indent}{mnem}{sp}{rd}, {rs1}, {signed}{rest}{note}\n"

def convert_reg(m: re.Match) -> str:
    val = m.group(1)
    if val.isdigit():
        return f"x{val}"
    return val

def translate_line(line: str) -> str:
    line = REG_RE.sub(convert_reg, line)
    line = CFW_RE.sub('.word', line)
    line = ORG_RE.sub('.org', line)
    line = HALT_RE.sub('.word 0x0000007f', line)
    line = fix_itype_immediate(line)
    line = fix_itype_label_immediate(line)
    return line

def main():
    if len(sys.argv) != 3:
        print(f"usage: {sys.argv[0]} <input.asm> <output.s>", file=sys.stderr)
        sys.exit(1)
    src_path, dst_path = sys.argv[1], sys.argv[2]

    with open(src_path) as f:
        lines = f.readlines()

    out_lines = ['.section .text\n']
    out_lines.extend(translate_line(line) for line in lines)

    with open(dst_path, 'w') as f:
        f.writelines(out_lines)

    print(f"wrote {dst_path}")

if __name__ == '__main__':
    main()
