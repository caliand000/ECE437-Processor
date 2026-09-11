.DEFAULT_GOAL := help
SHELL := /bin/bash

# Allow passing .asm file either via ASM=... or directly as a target (e.g. `make assemble test.beqtaken.asm`)
RAW_ASM_GOAL := $(firstword $(filter %.asm,$(MAKECMDGOALS)))
RESOLVED_ASM := $(if $(RAW_ASM_GOAL),$(if $(wildcard $(RAW_ASM_GOAL)),$(RAW_ASM_GOAL),$(if $(wildcard asmFiles/$(RAW_ASM_GOAL)),asmFiles/$(RAW_ASM_GOAL),$(RAW_ASM_GOAL))))
ASM_FILE := $(if $(RESOLVED_ASM),$(RESOLVED_ASM),$(if $(ASM),$(ASM),asmFiles/loop.asm))

ASM_BUILDER := NewAssemblerFiles/New_files/build_asm.sh
# Accept lowercase `module=...` too, since make variable names are case-sensitive.
MODULE ?= $(if $(module),$(module),alu)
SYSTEM_SOURCES := testbench/system_tb.sv source/*.sv
MODULE_SOURCES := testbench/$(MODULE)_tb.sv source/*.sv
VERILATOR_FLAGS := --timing --Wno-fatal -Iinclude --top-module system_tb
# These are isolated-module/interface or legacy testbench warnings; keep
# substantive width, latch, and case diagnostics enabled for module targets.
MODULE_WARNING_FLAGS := -Wno-EOFNEWLINE -Wno-IMPORTSTAR -Wno-UNUSEDPARAM -Wno-PINCONNECTEMPTY -Wno-UNUSEDSIGNAL -Wno-UNDRIVEN -Wno-TIMESCALEMOD -Wno-SELRANGE -Wno-BLKSEQ

.PHONY: help assemble assemble-all assemble.all lint alu-lint module-lint module.compile module.sim system.compile system.sim sim test clean

help:
	@printf '%s\n' \
		'Usage: make [target] [ASM=path/to/program.asm]' \
		'' \
		'  assemble       Assemble ASM and write meminit.hex' \
		'  assemble-all   Assemble all .asm files in asmFiles/' \
		'  lint           Lint the complete system with Verilator' \
		'  alu-lint       Lint only source/alu.sv' \
		'  module-lint    Lint MODULE (default: alu)' \
		'  module.sim     Build and run testbench/MODULE_tb.sv' \
		'  system.compile Build the Verilator system executable' \
		'  system.sim     Assemble, build, and run the full-system simulation' \
		'  sim            Alias for system.sim' \
		'  test           Run the assembly test runner' \
		'  clean          Remove generated builds, logs, reports, and simulator data'

assemble:
	bash $(ASM_BUILDER) $(ASM_FILE)

assemble-all:
	bash run_all_asm_tests.sh

assemble.all: assemble-all

# Catch-all rule for direct .asm file targets (e.g. `make test.beqtaken.asm` or `make assemble test.beqtaken.asm`)
%.asm:
	@if [ "$(findstring assemble,$(MAKECMDGOALS))" = "" ] && [ "$(findstring system.sim,$(MAKECMDGOALS))" = "" ] && [ "$(findstring sim,$(MAKECMDGOALS))" = "" ]; then \
		bash $(ASM_BUILDER) $(ASM_FILE); \
	fi

lint:
	verilator --lint-only --language 1800-2012 -Wall $(VERILATOR_FLAGS) $(SYSTEM_SOURCES)

alu-lint:
	verilator --lint-only --language 1800-2012 -Wall -Wno-fatal -Wno-UNUSEDPARAM -Iinclude --top-module alu source/alu.sv

module-lint:
	verilator --lint-only --language 1800-2012 -Wall --timing --Wno-fatal $(MODULE_WARNING_FLAGS) -Iinclude --top-module $(MODULE)_tb $(MODULE_SOURCES)

module.compile:
	verilator --binary --trace --timing --Wno-fatal $(MODULE_WARNING_FLAGS) -Iinclude --top-module $(MODULE)_tb $(MODULE_SOURCES)

module.sim: module.compile
	@mkdir -p waves
	@set -o pipefail; log=$$(mktemp); trap 'rm -f "$$log"' EXIT; \
		./obj_dir/V$(MODULE)_tb 2>&1 | tee "$$log"; \
		if grep -Eiq '(^|[[:space:]])(Failed|FAIL|failure|error|fatal)(:|[[:space:]]|$$)' "$$log" | grep -Eiv '0 failed' >/dev/null; then \
			printf '\033[31mFAIL: %s testbench reported a failure\033[0m\n' '$(MODULE)'; \
			exit 1; \
		fi; \
		printf '\033[32mPASS: %s testbench completed without reported failures\033[0m\n' '$(MODULE)'; \
		mv module.vcd waves/$(MODULE).vcd; \
		printf 'Waveform written to waves/%s.vcd\n' '$(MODULE)'; \
		if command -v gtkwave >/dev/null 2>&1; then \
			gtkwave waves/$(MODULE).vcd >/tmp/gtkwave-$(MODULE).log 2>&1 & \
			printf 'GTKWave opened for waves/%s.vcd\n' '$(MODULE)'; \
		else \
			printf 'GTKWave not found; open waves/%s.vcd manually.\n' '$(MODULE)'; \
		fi

system.compile:
	verilator --binary $(VERILATOR_FLAGS) $(SYSTEM_SOURCES)

system.sim: assemble system.compile
	./obj_dir/Vsystem_tb

sim: system.sim

test:
	bash run_all_asm_tests.sh

clean:
	rm -rf .build obj_dir work build_* asm_test_outputs
	rm -f memcpu.hex meminit.hex system_tb.out
	rm -f asm_test_report_*.txt sweep_report_*.txt
	rm -f *.log transcript out.txt output.txt temp.txt wlft* module.vcd waves/*.vcd
