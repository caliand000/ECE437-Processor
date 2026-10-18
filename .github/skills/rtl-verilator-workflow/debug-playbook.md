# Debug playbook: failing test or testbench

## 1. Classify
- Did it fail on the baseline (before your change)? If yes, it is pre-existing: report, don't fix as part of this task.
- Is it a hang/timeout, a wrong result, a Verilator build error, or a lint regression?

## 2. Reproduce small
- Reduce to the smallest `.asm` test that shows it. Assemble through the repo's pipeline (preprocessor, then riscv64 assembler), not a hand-rolled command.
- Run with tracing on (`--trace` / `--trace-fst`) and open in GTKWave or Surfer.

## 3. Find the first divergence
- Compare against ISA-expected behavior. Compute by hand the expected register/memory state per instruction.
- Find the **first** cycle where state is wrong, not the last. Symptoms downstream of the first wrong value are noise.
- Signals to put on the wave first:
  - PC, instruction, `ihit`, `dhit`, `dmemREN/WEN`, `dmemaddr`
  - stall/flush: `latch_en`, `Flush`, `Halt`, `Zero_controls`
  - forwarding selects and the values they chose
  - each pipeline register's valid/rd/RegWr
  - cache FSM state and `cif` wait signals

## 4. Hypothesis before edit
- Write the hypothesis in one sentence and say what waveform evidence would confirm or refute it.
- Check the evidence. If it refutes the hypothesis, drop it. Do not keep patching around a wrong theory.
- Prefer adding an `assert` or a targeted test over speculative RTL changes.

## 5. Typical culprits in this design
- Load-use hazard: stall interacting with a cache miss.
- Branch/jump flush while a data-cache request is in flight.
- Forwarding priority (MEM vs WB) and forwarding of values that are not yet loaded (loads, LUI/AUIPC/JAL results).
- Cache index/tag width mismatches; replacement (LRU) bit updates on write hits.
- `halt` flush sequence in the dcache FSM and the final memory dump.

## 6. Close out
- Add a regression test that fails before and passes after.
- Rerun the full regression and lint. Compare cycle counts to baseline.
- Report root cause, evidence (cycle/time and signals), the fix, and anything you ruled out.
