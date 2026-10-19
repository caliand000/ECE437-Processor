# Synthesizable SystemVerilog rules (FPGA + sky130 ASIC)

## Coding rules
- Sequential logic: `always_ff` only, nonblocking `<=`. Combinational: `always_comb` only, blocking `=`, and **assign a default to every output at the top** so no latch is inferred.
- No latches. Every `case` has a `default`, or the outputs have defaults above it.
- No `initial` blocks, `#` delays, `$display`, or `$readmemh` in synthesizable RTL, except inside a memory model that is explicitly excluded from the ASIC build (e.g. the behavioral RAM). Keep those in testbenches or clearly separated files.
- Don't mix edge types on one register. The register file uses `negedge CLK`: this halves timing budget and complicates ASIC clocking. Flag it, don't spread it.
- Async-assert reset (`negedge nRST`) is the repo convention. If adding reset synchronizers or changing reset style, call it out.
- Avoid driving the same signal from two `always` blocks or from both a module and a testbench.
- Beware of `x`/`z`-dependent behavior (`casez`, `==` vs `===`) outside testbenches.
- Don't use vendor primitives (`altsyncram`, etc.) in core RTL. Memories go behind a wrapper so they can be swapped for FPGA BRAM or an ASIC macro/flop array.
- Width discipline: size every literal, avoid implicit truncation, and match index widths to array depth (e.g. a 3-bit index into a 16-entry array is a bug).
- Prefer packed structs and enums from the shared packages over raw bit slices.

## SystemVerilog interfaces and the tools
- Verilator handles interfaces + modports well, so it is the reference simulator.
- **Yosys's built-in Verilog frontend does not handle SV interfaces well.** For synthesis experiments use one of:
  1. the `yosys-slang` plugin (reads SystemVerilog directly, including interfaces), or
  2. `sv2v` to flatten to plain Verilog first.
  Check which is installed before choosing. Don't "fix" this by rewriting interfaces away unless asked.
- Vivado generally accepts interfaces for Artix-7, but check its warnings on any new construct.

## Quick synthesis sanity check (adapt to what is installed)
Goal: confirm the design elaborates, has no latches or multi-driven nets, and see rough area.
- Elaborate the chosen top, run `synth -top <top>`, then `stat`.
- Grep the log for `latch`, `multiple drivers`, `unresolved`, `no driver`.
- Record cell count / flop count before and after a refactor. A pure refactor should not change them noticeably.

## ASIC-specific notes (Tiny Tapeout / sky130)
- Area is tiny. Count flops: caches built from flip-flops are expensive. Flag any change that grows storage.
- Avoid large combinational structures (wide multipliers, big shifters) unless needed; the ALU shifter and any dcache comparators are the first places to look.
- No tri-states or internal buses with multiple drivers.
- Keep clock domains to one. The `system.sv` clock divider is a simulation/FPGA convenience, not something to carry into the ASIC top.
- Everything must be reachable through the limited I/O of the tapeout wrapper, so memory interfaces (e.g. an AHB-Lite bus) need to be narrow or serialized.

## FPGA-specific notes (Artix-7)
- Large arrays should infer BRAM/LUTRAM; confirm in the Vivado utilization report.
- Use proper clock enables instead of a divided fabric clock for real hardware.
