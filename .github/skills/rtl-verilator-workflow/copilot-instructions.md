# Copilot instructions

This repo is a pipelined RV32I CPU written in SystemVerilog, being revived on an open-source toolchain with FPGA (Artix-7) and ASIC (sky130 / Tiny Tapeout) goals.

- Simulator is **Verilator**. Never suggest Icarus, ModelSim, or Quartus flows: Icarus cannot handle this design's SV interfaces.
- Lint with Verible and Verilator `-Wall`. Don't silence warnings with blanket `-Wno-*`.
- All RTL must be synthesizable (see the `rtl-verilator-workflow` skill). No latches, no vendor primitives in core RTL.
- Work on a branch, never main. Small commits, one logical change each.
- Before and after any RTL change, run the full regression and compare pass count **and cycle counts**. Passing alone only proves the program halted; there is no golden-output comparison yet, so don't claim "verified correct" from it.
- Behavior-preserving refactors must not change behavior. Report suspected bugs instead of fixing them in the same change.
- Verify assumptions against waveforms or code before stating a root cause. If a theory is disproved, say so and move on.
- Give concrete commands alongside explanations.
