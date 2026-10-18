#!/usr/bin/env python3
"""Compare the CPU's register-write log against Spike's commit log.

usage: compare_rf_trace.py dut_rfwrites.log spike.log [--entry 0x0] [--context 5]

DUT log lines:    x<rd> 0x<value>                (from rf_monitor.sv)
Spike log lines:  core   0: 3 0x<pc> (0x<instr>) x<rd> 0x<value> ...

Exit code 0 = match, 1 = mismatch, 2 = bad input.
"""
import argparse
import re
import sys

DUT_RE = re.compile(r"^x(\d+)\s+0x([0-9a-fA-F]+)")
SPIKE_RE = re.compile(r"core\s+\d+:\s+\d+\s+0x([0-9a-fA-F]+)\s+\(0x([0-9a-fA-F]+)\)\s*(.*)")
REGW_RE = re.compile(r"\bx(\d+)\s+0x([0-9a-fA-F]+)")


def load_dut(path):
    writes = []
    with open(path) as f:
        for line in f:
            m = DUT_RE.match(line)
            if m:
                writes.append((int(m.group(1)), int(m.group(2), 16)))
    return writes


def load_spike(path, entry):
    """Return (writes, trapped). Skips Spike's boot ROM (runs at 0x1000 before the
    program) by starting at the first instruction whose pc == entry. Stops at the
    first exception line, which is where the custom HALT instruction traps."""
    writes, started, trapped = [], False, False
    with open(path) as f:
        for line in f:
            if started and "exception" in line:
                trapped = True
                break
            m = SPIKE_RE.match(line)
            if not m:
                continue
            pc = int(m.group(1), 16)
            if not started:
                if pc != entry:
                    continue
                started = True
            w = REGW_RE.search(m.group(3))
            if w and int(w.group(1)) != 0:
                writes.append((int(w.group(1)), int(w.group(2), 16), pc, int(m.group(2), 16)))
    return writes, trapped, started


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("dut")
    ap.add_argument("spike")
    ap.add_argument("--entry", type=lambda s: int(s, 0), default=0)
    ap.add_argument("--context", type=int, default=5)
    a = ap.parse_args()

    dut = load_dut(a.dut)
    ref, trapped, started = load_spike(a.spike, a.entry)

    if not started:
        print(f"ERROR: Spike log never reached entry pc 0x{a.entry:x}; check --pc and -m.")
        return 2
    if not dut:
        print("ERROR: DUT log has no register writes; check the rf_monitor hookup.")
        return 2

    n = min(len(dut), len(ref))
    for i in range(n):
        d_reg, d_val = dut[i]
        r_reg, r_val, pc, instr = ref[i]
        if (d_reg, d_val) != (r_reg, r_val):
            print(f"MISMATCH at register write #{i}")
            print(f"  Spike: x{r_reg} = 0x{r_val:08x}   (pc 0x{pc:08x}, instr 0x{instr:08x})")
            print(f"  DUT  : x{d_reg} = 0x{d_val:08x}")
            lo = max(0, i - a.context)
            print("  preceding Spike writes (all matched):")
            for j in range(lo, i):
                rr, rv, rpc, rin = ref[j]
                print(f"    #{j}: pc 0x{rpc:08x} instr 0x{rin:08x} -> x{rr} = 0x{rv:08x}")
            return 1

    if trapped and len(dut) != len(ref):
        print(f"COUNT MISMATCH: all {n} compared writes match, but DUT has {len(dut)} "
              f"and Spike has {len(ref)} before its trap (HALT).")
        print("  Fewer DUT writes usually means the last instructions never retired "
              "(check the 'retire' condition); more means duplicates.")
        return 1

    note = "" if trapped else " (Spike log was not cut by a trap; compared up to the DUT length)"
    print(f"PASS: {n} register writes match{note}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
