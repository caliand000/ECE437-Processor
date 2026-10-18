---
name: hdl-authoring-patterns
description: Code-structure and style patterns for writing clean SystemVerilog in this RV32I CPU repo, covering pipeline stage modules, struct-based stage-to-stage signals, one-place bubble/flush gating, generic pipeline registers, naming (_d/_q), interfaces vs ports, and avoiding long runs of repetitive assign statements. Use when writing or refactoring any RTL module, especially pipeline stages, datapath glue, or control decoding.
---

# HDL authoring patterns (repo-specific)

**Precedence:** if a company-wide HDL skill is installed (for example `authoring-hdl`), read it first. Its rules win on any conflict. This skill adds the patterns specific to this repo. For toolchain, lint, simulation, and verification workflow, use `rtl-verilator-workflow`.

## Core rules
1. **State a rule once.** If the same gating expression (`cond ? 0 : x`) appears on more than a couple of lines, build the whole struct first and apply the condition once to the struct.
2. **Pass structs between stages, not loose signals.** Stage-to-stage data is one packed struct from `pipeline_types_pkg`. Adding a field must not require touching every stage.
3. **Default-then-override in `always_comb`.** Start from `'0` and set only the fields the stage produces. Never leave a field implicitly unassigned.
4. **Registers live in one place.** Stage modules are combinational (plus the submodules they own). Pipeline registers are instances of a generic `pipe_reg #(.T(...))` in `datapath`. Stall and flush policy is written there, once.
5. **Cross-stage units live at the top.** Hazard and forwarding units look at several stages, so instantiate them in `datapath` and feed stages plain signals (`bubble`, `stall`, `flush`, forward selects).
6. **Every signal has exactly one driver module.** Don't drive an interface's signals from a sibling or parent while also reading its outputs elsewhere; give the submodule plain ports, or let the owning module drive the whole interface.
7. **Explicit ports.** Declare `input`/`output`, the type, and the modport on every port. Never rely on direction or type being inherited from the previous port.
8. **No magic numbers.** Use enums or named constants for `jumpsel`, PC source, ALU op, and forward selects. Use `unique case` where the cases are meant to be exclusive.

## Naming
- `_q` = register output (value this cycle), `_d` = register input (value next cycle). A stage's inputs are `*_q`; its outputs are `*_d`.
- `_n` suffix for active-low signals (`nRST` is the existing exception).
- One module per file; filename equals module name; interfaces end in `_if`.
- Stage modules: `if_stage`, `id_stage`, `ex_stage`, `mem_stage`, `wb_stage`.

## Don't
- Don't write 10+ consecutive `assign` lines that share a condition.
- Don't hide cross-stage logic (forwarding, hazards, PC redirect) inside a single stage.
- Don't generalize cache-hit-gated special cases without checking the original behavior (see `references/pipeline-stage-pattern.md`, "Quirks to preserve").
- Don't change behavior while restructuring. Compare regression pass count and cycle counts before and after.

## Templates
Copy-ready templates (stage module, bubble gating, `pipe_reg`, control struct) are in `references/pipeline-stage-pattern.md`.
