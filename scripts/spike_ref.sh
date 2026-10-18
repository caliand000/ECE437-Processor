#!/usr/bin/env bash
# Run a bare-metal RV32 ELF on Spike and write a per-instruction commit log.
# usage: spike_ref.sh prog.elf out.log [isa]
#
# Env overrides:
#   SPIKE_MEM      memory region(s), default 0x0:0x10000,0xffff0000:0x10000
#                  (matches the DUT's 16-bit address decode)
#   SPIKE_TIMEOUT  seconds before killing spike, default 3
#
# Why a timeout: the custom HALT instruction is illegal to Spike. It traps, jumps to
# mtvec (0), and re-runs the program forever. compare_rf_trace.py truncates the log
# at the first trap / at the DUT's length, so the extra output is harmless.
set -euo pipefail

ELF="${1:?usage: spike_ref.sh prog.elf out.log [isa]}"
OUT="${2:?usage: spike_ref.sh prog.elf out.log [isa]}"
ISA="${3:-rv32i}"
MEM="${SPIKE_MEM:-0x0:0x10000,0xffff0000:0x10000}"

# -l + --log=FILE write the log; --log-commits adds register/memory write info.
# --pc=0 overrides the ELF entry so execution starts at address 0 like the CPU.
timeout "${SPIKE_TIMEOUT:-3}" spike \
  --isa="$ISA" -m"$MEM" --pc=0 \
  -l --log-commits --log="$OUT" \
  "$ELF" || true

if [ ! -s "$OUT" ]; then
  echo "spike produced an empty log: $OUT" >&2
  exit 1
fi
echo "wrote $OUT ($(wc -l < "$OUT") lines)"
