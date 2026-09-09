.DEFAULT_GOAL := help

ASM ?= asmFiles/loop.asm
ASM_BUILDER := NewAssemblerFiles/New_files/build_asm.sh
MODULE ?= alu
SYSTEM_SOURCES := testbench/system_tb.sv source/*.sv
MODULE_SOURCES := testbench/$(MODULE)_tb.sv source/*.sv
VERILATOR_FLAGS := --timing --Wno-fatal -Iinclude --top-module system_tb

.PHONY: help assemble lint alu-lint module-lint module.compile module.sim system.compile system.sim sim test clean

help:
	@printf '%s\n' \
		'Usage: make [target] [ASM=path/to/program.asm]' \
		'' \
		'  assemble       Assemble ASM and write meminit.hex' \
		'  lint           Lint the complete system with Verilator' \
		'  alu-lint       Lint only source/alu.sv' \
		'  module-lint    Lint MODULE (default: alu)' \
		'  module.sim     Build and run testbench/MODULE_tb.sv' \
		'  system.compile Build the Verilator system executable' \
		'  system.sim     Assemble, build, and run the full-system simulation' \
		'  sim            Alias for system.sim' \
		'  test           Run the updated assembly test runner' \
		'  clean          Remove generated builds, logs, reports, and simulator data'

assemble:
	bash $(ASM_BUILDER) $(ASM)

lint:
	verilator --lint-only --language 1800-2012 -Wall $(VERILATOR_FLAGS) $(SYSTEM_SOURCES)

alu-lint:
	verilator --lint-only --language 1800-2012 -Wall -Wno-fatal -Iinclude --top-module alu source/alu.sv

module-lint:
	verilator --lint-only --language 1800-2012 -Wall --timing --Wno-fatal -Iinclude --top-module $(MODULE)_tb $(MODULE_SOURCES)

module.compile:
	verilator --binary --timing --Wno-fatal -Iinclude --top-module $(MODULE)_tb $(MODULE_SOURCES)

module.sim: module.compile
	./obj_dir/V$(MODULE)_tb

system.compile:
	verilator --binary $(VERILATOR_FLAGS) $(SYSTEM_SOURCES)

system.sim: assemble system.compile
	./obj_dir/Vsystem_tb

sim: system.sim

test:
	bash NewAssemblerFiles/New_files/run_all_asm_tests.sh

clean:
	rm -rf .build obj_dir work build_* asm_test_outputs
	rm -f memcpu.hex meminit.hex system_tb.out
	rm -f asm_test_report_*.txt sweep_report_*.txt
	rm -f *.log transcript out.txt output.txt temp.txt wlft*
