#!/bin/bash
set -uo pipefail

ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ASM_DIR="$ROOT_DIR/asmFiles"
OUT_DIR="$ROOT_DIR/asm_test_outputs"
BUILD_DIR="$ROOT_DIR/build"
RESULTS_FILE="$BUILD_DIR/results.tsv"
REPORT_FILE="$ROOT_DIR/asm_test_report_$(date +"%Y_%m_%d_%I_%M_%p").txt"
SIMULATE=0
SINGLE_FILE=""
SPIKE_CHECK="${SPIKE_CHECK:-0}"
SPIKE_DIR="$ROOT_DIR/asm_test_outputs"

if (( SPIKE_CHECK )); then
  SIMULATE=1
fi

# ANSI Colors for clean terminal display
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

while (( "$#" )); do
  case "$1" in
    --simulate)
      SIMULATE=1
      shift
      ;;
    --single)
      SINGLE_FILE="${2:-}"
      shift 2
      ;;
    --spike)
      SPIKE_CHECK=1
      SIMULATE=1
      shift
      ;;
    *)
      shift
      ;;
  esac
done

mkdir -p "$OUT_DIR" "$BUILD_DIR"
exec > >(tee "$BUILD_DIR/regression.log") 2>&1
: > "$RESULTS_FILE"

append_result() {
  local test_name="$1"
  local halt_status="$2"
  local spike_status="$3"
  local cycles="$4"
  local detail="$5"
  detail="$(printf '%s' "$detail" | tr '\t\r\n' '   ')"
  printf '%s\t%s\t%s\t%s\t%s\n' \
    "$test_name" "$halt_status" "$spike_status" "$cycles" "$detail" >> "$RESULTS_FILE"
}

echo "==================================================" > "$REPORT_FILE"
echo "Assembly Test Report - $(date +"%Y-%m-%d %I:%M:%S %p")" >> "$REPORT_FILE"
echo "Root Directory: $ROOT_DIR" >> "$REPORT_FILE"
echo "Simulate Mode: $SIMULATE" >> "$REPORT_FILE"
echo "Spike Check: $SPIKE_CHECK" >> "$REPORT_FILE"
echo "==================================================" >> "$REPORT_FILE"

shopt -s nullglob
default_files=("$ASM_DIR"/*.asm)
if [[ -n "$SINGLE_FILE" ]]; then
  if [[ ! -f "$SINGLE_FILE" ]]; then
    echo "error: --single file not found: $SINGLE_FILE"
    exit 1
  fi
  asm_files=("$SINGLE_FILE")
else
  asm_files=("${default_files[@]}")
fi

count=${#asm_files[@]}
if (( count == 0 )); then
  echo "No .asm files found in $ASM_DIR"
  exit 1
fi

echo "Executing $count assembly test files..."
echo "" >> "$REPORT_FILE"

if (( SIMULATE )); then
  if (( SPIKE_CHECK )) || [[ ! -x "$ROOT_DIR/obj_dir/Vsystem_tb" ]]; then
    echo "Compiling system testbench with Verilator..."
    if ! (cd "$ROOT_DIR" && verilator --binary --timing --Wno-fatal -Iinclude --top-module system_tb testbench/system_tb.sv testbench/rf_monitor.sv source/*.sv > "$OUT_DIR/verilator_compile.log" 2>&1); then
      echo -e "${RED}FAIL${NC}: Verilator testbench compilation failed (see $OUT_DIR/verilator_compile.log)"
      echo "VERILATOR COMPILE FAILED" >> "$REPORT_FILE"
      for asm_file in "${asm_files[@]}"; do
        append_result "$(basename "$asm_file" .asm)" FAIL SKIP - "Verilator testbench compilation failed"
      done
      exec python3 "$ROOT_DIR/scripts/print_results.py" "$RESULTS_FILE"
    fi
  fi
fi

pass_count=0
fail_count=0
spike_pass_count=0
spike_fail_count=0

for i in "${!asm_files[@]}"; do
  asm_file="${asm_files[$i]}"
  name="$(basename "$asm_file" .asm)"
  rel_path="${asm_file#$ROOT_DIR/}"

  out_subdir="$OUT_DIR/$name"
  mkdir -p "$out_subdir"
  cp "$asm_file" "$out_subdir/${name}.asm"

  asm_path="$(cd "$(dirname "$asm_file")" && pwd)/$(basename "$asm_file")"
  march="rv32i"
  spike_isa="rv32i"
  if grep -Eiq '(^|[^[:alnum:]_])(lr\.|sc\.)' "$asm_file"; then
    march="rv32ia"
    spike_isa="rv32ia"
  fi
  build_args=("$asm_path")
  if (( SPIKE_CHECK )); then
    build_args+=(--keep)
  fi
  if ! (cd "$out_subdir" && ASM_MARCH="$march" bash "$ROOT_DIR/NewAssemblerFiles/New_files/build_asm.sh" "${build_args[@]}" > "$out_subdir/build.log" 2>&1); then
    echo -e "${RED}FAIL${NC}: $rel_path (Build Failed)"
    echo "[FAIL] $rel_path - Build Failed (See $out_subdir/build.log)" >> "$REPORT_FILE"
    append_result "$name" FAIL SKIP - "Build failed"
    fail_count=$((fail_count + 1))
    continue
  fi

  cp "$out_subdir/meminit.hex" "$ROOT_DIR/meminit.hex"

  spike_status=0
  if (( SPIKE_CHECK )); then
    if ! command -v spike >/dev/null 2>&1; then
      echo -e "${RED}FAIL${NC}: $rel_path (SPIKE_CHECK=1 but spike is not installed)"
      echo "[FAIL] $rel_path - Spike is not installed" >> "$REPORT_FILE"
      append_result "$name" FAIL FAIL - "Spike is not installed"
      fail_count=$((fail_count + 1))
      spike_fail_count=$((spike_fail_count + 1))
      continue
    fi

    elf_path="$out_subdir/build_$name/$name.elf"
    spike_log="$out_subdir/spike.log"
    dut_log="$out_subdir/${name}_rfwrites.log"
    if ! bash "$ROOT_DIR/scripts/spike_ref.sh" "$elf_path" "$spike_log" "$spike_isa" > "$out_subdir/spike_run.log" 2>&1; then
      echo -e "${RED}FAIL${NC}: $rel_path (Spike run failed)"
      echo "[FAIL] $rel_path - Spike run failed" >> "$REPORT_FILE"
      append_result "$name" FAIL FAIL "-" "Spike run failed"
      fail_count=$((fail_count + 1))
      spike_fail_count=$((spike_fail_count + 1))
      continue
    fi
  fi

  if (( SIMULATE )); then
    if (( SPIKE_CHECK )); then
      sim_command=("$ROOT_DIR/obj_dir/Vsystem_tb" "+RF_LOG=$dut_log")
    else
      sim_command=("$ROOT_DIR/obj_dir/Vsystem_tb")
    fi
    if ! (cd "$ROOT_DIR" && "${sim_command[@]}" > "$out_subdir/system_run.log" 2>&1); then
      echo -e "${RED}FAIL${NC}: $rel_path (Simulation Run Failed)"
      echo "[FAIL] $rel_path - Simulation Run Failed (See $out_subdir/system_run.log)" >> "$REPORT_FILE"
      append_result "$name" FAIL SKIP - "Simulation run failed"
      fail_count=$((fail_count + 1))
      continue
    fi

    halt_line="$(grep -o "Halted at.*ran for[[:space:]]*[0-9]*[[:space:]]*cycles\." "$out_subdir/system_run.log" || true)"
    if [[ -z "$halt_line" ]]; then
      echo -e "${RED}FAIL${NC}: $rel_path (No Halt Detected)"
      echo "[FAIL] $rel_path - No Halt Detected (See $out_subdir/system_run.log)" >> "$REPORT_FILE"
      append_result "$name" FAIL SKIP - "No halt detected"
      fail_count=$((fail_count + 1))
      continue
    fi

    cycles="$(echo "$halt_line" | grep -o '[0-9]\+' | tail -1)"
    if (( SPIKE_CHECK )); then
      if ! python3 "$ROOT_DIR/scripts/compare_rf_trace.py" "$dut_log" "$spike_log" > "$out_subdir/spike_compare.log" 2>&1; then
        echo -e "${RED}FAIL${NC}: $rel_path (Spike diff failed; see $out_subdir/spike_compare.log)"
        cat "$out_subdir/spike_compare.log"
        echo "[FAIL] $rel_path - Simulation OK ($cycles cycles) | Spike diff failed" >> "$REPORT_FILE"
        compare_detail="$(grep -m1 -E '^(MISMATCH|COUNT MISMATCH|ERROR:)' "$out_subdir/spike_compare.log" || sed -n '1p' "$out_subdir/spike_compare.log")"
        append_result "$name" PASS FAIL "$cycles" "$compare_detail"
        fail_count=$((fail_count + 1))
        spike_fail_count=$((spike_fail_count + 1))
        continue
      fi
      echo -e "${GREEN}PASS${NC}: $rel_path ($cycles cycles; Spike diff PASS)"
      echo "[PASS] $rel_path - Assembly OK | Simulation OK ($cycles cycles) | Spike diff OK" >> "$REPORT_FILE"
      append_result "$name" PASS PASS "$cycles" ""
      spike_pass_count=$((spike_pass_count + 1))
    else
      echo -e "${GREEN}PASS${NC}: $rel_path ($cycles cycles)"
      echo "[PASS] $rel_path - Assembly OK | Simulation OK ($cycles cycles)" >> "$REPORT_FILE"
      append_result "$name" PASS SKIP "$cycles" "Spike check skipped"
    fi
  else
    echo -e "${GREEN}PASS${NC}: $rel_path"
    echo "[PASS] $rel_path - Assembly OK" >> "$REPORT_FILE"
    append_result "$name" PASS SKIP - "Simulation skipped"
  fi

  pass_count=$((pass_count + 1))
done

echo ""
echo "==================================================" >> "$REPORT_FILE"
echo "Summary: $count total | $pass_count passed | $fail_count failed" >> "$REPORT_FILE"
if (( SPIKE_CHECK )); then
  echo "Spike diff summary: $spike_pass_count passed | $spike_fail_count failed" >> "$REPORT_FILE"
fi
echo "Outputs stored in $OUT_DIR" >> "$REPORT_FILE"

if (( fail_count == 0 )); then
  echo -e "${GREEN}Completed $count assembly tests: $pass_count passed, $fail_count failed${NC}"
else
  echo -e "${RED}Completed $count assembly tests: $pass_count passed, $fail_count failed${NC}"
fi
echo "Report log: ${REPORT_FILE#$ROOT_DIR/}"

exec python3 "$ROOT_DIR/scripts/print_results.py" "$RESULTS_FILE"
