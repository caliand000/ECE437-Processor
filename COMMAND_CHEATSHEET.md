# ECE 437 Processor Command Cheat Sheet

Run all commands from the repository root:

```bash
cd ~/dev/ECE437-Processor
```

## Assembly Programs

Compile one course-format `.asm` program and write dense `$readmemh` data to `meminit.hex`:

```bash
bash NewAssemblerFiles/New_files/build_asm.sh asmFiles/loop.asm
```

The default output is now for the behavioral RAM. The old Intel-hex format is still available for an FPGA primitive-based flow:

```bash
bash NewAssemblerFiles/New_files/build_asm.sh asmFiles/loop.asm --intelhex
```

The assembler also creates `build_<program>/` containing the preprocessed `.s`, `.o`, `.elf`, and `.bin` files. Inspect the generated binary:

```bash
riscv64-unknown-elf-objdump -d -Mnumeric build_loop/loop.elf
```

Compile every program in `asmFiles/`:

```bash
bash run_all_asm_tests.sh
```

Compile and simulate every program, saving per-program logs under `asm_test_outputs/`:

```bash
bash run_all_asm_tests.sh --simulate
```

The runner continues after individual build or simulation failures, prints a
pass/fail summary, and exits nonzero if any test failed. In simulation mode, a
test counts as successful only when its log contains a `Halted at ... ran for
<N> cycles.` line.

Compile one program through the batch script:

```bash
bash run_all_asm_tests.sh --single asmFiles/loop.asm
```

Options can be combined in either order:

```bash
bash run_all_asm_tests.sh --simulate --single asmFiles/loop.asm
```

## Full Processor Simulation

First assemble the program to load:

```bash
bash NewAssemblerFiles/New_files/build_asm.sh asmFiles/loop.asm
```

In the ECE 437 course environment, compile and run the full testbench:

```bash
make clean
make system.sim
```

The testbench reports the halt time and cycle count, then writes the final memory image to `memcpu.hex`.

### Icarus Compatibility Check

This repository's batch script uses the following Icarus command:

```bash
iverilog -g2012 -I./include -s system_tb -o system_tb.out testbench/system_tb.sv source/*.sv
vvp system_tb.out
```

It requires an Icarus version that supports this project's SystemVerilog interface and `program` declarations. The installed Icarus version in this workspace rejects those constructs, so use the course ModelSim/Questa flow above for full-system simulation here.

Remove the local Icarus executable when finished:

```bash
rm -f system_tb.out
```

### Verilator Debugging

Verilator is useful for detailed SystemVerilog parsing and lint diagnostics. Lint checks the design but does not run the processor:

```bash
verilator --lint-only --language 1800-2012 -Wall \
	-Iinclude \
	--top-module system_tb \
	testbench/system_tb.sv source/*.sv
```

The system testbench contains delays and clock/event controls, so include `--timing`:

```bash
verilator --lint-only --timing --Wno-fatal \
	-Iinclude \
	--top-module system_tb \
	testbench/system_tb.sv source/*.sv
```

Save the complete lint output for later review:

```bash
verilator --lint-only --timing --Wno-fatal \
	-Iinclude \
	--top-module system_tb \
	testbench/system_tb.sv source/*.sv \
	> verilator_system.log 2>&1
```

View only hard errors:

```bash
grep -E '^%Error' verilator_system.log
```

View likely design-quality warnings:

```bash
grep -E '^%Warning-(PINMISSING|IMPLICIT|WIDTH|UNOPTFLAT)' verilator_system.log
```

Lint one module while debugging it, replacing `alu` and its source file as needed:

```bash
verilator --lint-only --language 1800-2012 -Wall \
	-Iinclude \
	--top-module alu \
	source/alu.sv
```

Run Verilator's executable simulation mode experimentally:

```bash
verilator --binary --timing --Wno-fatal \
	-Iinclude \
	--top-module system_tb \
	testbench/system_tb.sv source/*.sv
```

The generated executable is normally placed under `obj_dir/`. This mode is separate from the course ModelSim/Questa flow and may require additional Verilator compatibility fixes in the testbench.

### Course Toolchain Shortcuts

When the ECE 437 course environment is loaded and the `Makefile` symlink is valid, this is the same supported command sequence:

```bash
make clean
make system.sim
```

Open the system waveform setup in ModelSim/Questa after compiling the design:

```tcl
do scripts/system.do
```

Other saved waveform setups are in `scripts/`, including `alu.do`, `dcache.do`, `icache.do`, and `forward_unit.do`.

## Unit-Test Simulation

Use the course Makefile when available, replacing `alu` with the module name:

```bash
make alu.sim
```

With the local Makefile and Verilator, run an individual testbench with:

```bash
make module.sim MODULE=alu
```

This expects a matching `testbench/alu_tb.sv`; other available module names
include `control_unit`, `dcache`, `forward_unit`, `hazard_unit`, `icache`,
`memory_control`, `register_file`, and `request_unit`.

In ModelSim/Questa, load the corresponding waveform file after launching the testbench:

```tcl
do scripts/alu.do
```

## Synthesis

Synthesize the top-level `system` using the course synthesis tool:

```bash
synthesize -t -f 80 system
```

The timing report is written to:

```text
._system/system.sta.rpt
```

Print the slow-corner Fmax summary:

```bash
grep -A 7 "Slow 1200mV 85C Model Fmax Summary" ._system/system.sta.rpt
```

## RAM-Latency Sweep

Run simulation at RAM latencies 0, 2, 6, and 10, then synthesize the supported points:

```bash
bash exec_data_sweep.sh
```

For the dual-core flow:

```bash
bash exec_data_sweep.sh -d
```

This script edits the `LAT` parameter in `source/ram.sv`; restore or retain that change intentionally after it completes.

## Tool Availability

Check which tools are visible in the current shell:

```bash
command -v verilator iverilog vvp vsim vlog vsim asm synthesize riscv64-unknown-elf-as
```

The local assembly path requires `python3` and `riscv64-unknown-elf-{as,ld,objcopy,objdump}`. Verilator is used for lint/debugging; Icarus requires additional SystemVerilog compatibility; and `make`, `vlog`, `vsim`, `asm`, and `synthesize` require the ECE 437 course environment.