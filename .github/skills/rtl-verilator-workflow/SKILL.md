---
name: spike-reference-checking
description: Verify CPU correctness against the Spike RISC-V reference simulator by diffing register-write traces. Use when adding or changing assembly tests, changing anything in the pipeline/control/ALU/caches that could affect architectural results, debugging a wrong-result bug, or when asked whether a change is "correct" rather than just "passing".
---

# Spike reference checking

The regression only proves programs halt. Spike is the golden model: it executes each program with exact ISA semantics, and we diff its register-write sequence against the CPU's. Passing the sim alone is not correctness.

## Files and where they live
- `scripts/setup_spike.sh`: builds Spike into `~/riscv` (honors `SPIKE_REF`, `SKIP_APT`).
- `scripts/spike_ref.sh prog.elf out.log [isa]`: runs Spike, writes a commit log.
- `scripts/compare_rf_trace.py dut.log spike.log`: compares the two. Exit 0 = match, 1 = mismatch, 2 = bad input.
- `testbench/rf_monitor.sv`: testbench-only module that logs `x<rd> 0x<value>` once per retired instruction. Never put it in `source/` and never include it in synthesis or ASIC builds.
- `.github/workflows/spike-regression.yml`: runs the regression with `SPIKE_CHECK=1` on pull requests.

## How to check a test
1. Assemble with `-march=rv32i -mabi=ilp32` (add `a` for LR/SC tests) and link at address 0 to get an ELF: `riscv64-unknown-elf-ld -m elf32lriscv -Ttext=0 -o prog.elf prog.o`.
2. `scripts/spike_ref.sh prog.elf spike.log`
3. Run the Verilator sim with `rf_monitor` enabled so it writes `cpu0_rfwrites.log`.
4. `python3 scripts/compare_rf_trace.py cpu0_rfwrites.log spike.log`

## Rules
- Any change that can affect architectural results must pass the Spike diff on every test, in addition to the regression and cycle-count comparison.
- Every new `.asm` test gets a Spike diff. Prefer tests that store a pass/fail word to a fixed address, so the result is also visible in `memcpu.hex`.
- **Never edit `compare_rf_trace.py`, skip tests, loosen comparisons, or add allow-lists to make a mismatch go away.** Fix the cause, or report it.
- A mismatch does not always mean the CPU is wrong. Before editing RTL, check the first differing instruction by hand against the RISC-V spec, and say which side is wrong and why.
- Don't describe a change as "verified correct" unless the Spike diff passed. Say what was and wasn't covered.

## Interpreting a mismatch
The script prints the first differing register write, the Spike PC and instruction, and the five previous matched writes. Debug from there with `rtl-verilator-workflow/references/debug-playbook.md`: put that PC's instruction on the waveform and find where the value first goes wrong.

## Known caveats (check these before blaming the RTL)
- Spike's boot ROM runs at `0x1000` first and leaves nonzero values in x5, x10, x11. The CPU resets registers to 0. A test that reads a register before writing it will diverge; initialize registers in the test.
- The ROM address range (`0x1000-0x1FFF`) may shadow RAM mapped at 0 in Spike. A diff on loads/stores in that range may be a Spike memory-map artifact.
- The custom HALT encoding is illegal to Spike. It traps, and the compare script stops at the first `exception` line (or the DUT length). A COUNT MISMATCH after a clean prefix usually means the `retire` condition in `rf_monitor` is wrong for that stall pattern.
- Coverage is register writes only. Stores and final memory are not compared; loads are covered through the value they write.
- Spike's log format can change between versions. If parsing fails, check the regex against a real line before changing anything else. CI pins the Spike version.
