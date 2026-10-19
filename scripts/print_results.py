#!/usr/bin/env python3
"""Print a regression results table from a TSV file.

usage: print_results.py results.tsv

results.tsv has one line per test, tab separated:
    test<TAB>halt<TAB>spike<TAB>cycles<TAB>detail
  halt   = PASS | FAIL
  spike  = PASS | FAIL | SKIP
  cycles = integer or '-'
  detail = optional, e.g. the first mismatching instruction (single line)

Writes a table to stdout (colored on a terminal; set FORCE_COLOR=1 to force it).
If $GITHUB_STEP_SUMMARY is set (GitHub Actions), also writes a Markdown table there
so results show on the workflow run page. Exit code is 1 if any test failed.
"""
import os
import sys

COL = {"PASS": "\033[32m", "FAIL": "\033[31m", "SKIP": "\033[33m"}
RST = "\033[0m"


def paint(text, status, color):
    return f"{COL[status]}{text}{RST}" if color and status in COL else text


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        return 2
    rows = []
    with open(sys.argv[1]) as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            p = line.split("\t")
            p += [""] * (5 - len(p))
            rows.append(p[:5])

    color = sys.stdout.isatty() or os.environ.get("FORCE_COLOR") == "1"
    w = max([len(r[0]) for r in rows] + [4])
    print(f"{'TEST':<{w}}  HALT   SPIKE  CYCLES")
    print("-" * (w + 24))
    failed = []
    for t, halt, spike, cyc, detail in rows:
        bad = halt == "FAIL" or spike == "FAIL"
        if bad:
            failed.append((t, halt, spike, detail))
        print(f"{t:<{w}}  {paint(f'{halt:<5}', halt, color)}  "
              f"{paint(f'{spike:<5}', spike, color)}  {cyc}")
    print("-" * (w + 24))

    n = len(rows)
    skipped = sum(1 for r in rows if r[2] == "SKIP")
    summary = f"{n} tests: {n - len(failed)} passed, {len(failed)} failed"
    if skipped:
        summary += f", {skipped} without a Spike check"
    print(paint(summary, "FAIL" if failed else "PASS", color))
    for t, halt, spike, detail in failed:
        print(f"  FAILED {t} (halt={halt}, spike={spike})" + (f": {detail}" if detail else ""))

    out = os.environ.get("GITHUB_STEP_SUMMARY")
    if out:
        with open(out, "a") as f:
            f.write("## Regression results\n\n")
            f.write(f"**{summary}**\n\n| Test | Halt | Spike | Cycles |\n|---|---|---|---|\n")
            for t, halt, spike, cyc, _ in rows:
                icon = {"PASS": "✅", "FAIL": "❌", "SKIP": "➖"}
                f.write(f"| {t} | {icon.get(halt, halt)} | {icon.get(spike, spike)} | {cyc} |\n")
            if failed:
                f.write("\n### Failures\n")
                for t, halt, spike, detail in failed:
                    f.write(f"- `{t}`: {detail or 'see uploaded logs'}\n")

    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
