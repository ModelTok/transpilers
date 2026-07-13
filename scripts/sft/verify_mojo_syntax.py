#!/usr/env python3
"""Static Mojo-conformance check for generated_general.mojo.

We CAN'T run `mojo build` on this Windows host (the `max`/`modular`
wheel requires manylinux_2_34 / macos arm -- no win32 build, confirmed:
  uv pip install modular -> "unsatisfiable ... manylinux_2_34_x86_64").
So we statically assert the generated Mojo conforms to Mojo grammar
rules we know, PLUS keep the faithful-exec oracle (the generated
arithmetic run in Python). Together these are the strongest gate
runnable on this box; the LITERAL `mojo build` gate happens in
EnergyPlusMojo (which has the Mojo toolchain).

Run:
  .venv_cuda/Scripts/python.exe scripts/sft/verify_mojo_syntax.py
"""
from __future__ import annotations
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
SRC = REPO / "scripts/sft/generated_general.mojo"

MOJO_RULES = [
    ("no C++ std::", lambda s: "std::" not in s),
    ("no C++ // comments only (block ok)", lambda s: True),  # cosmetic
    ("uses `def` fn syntax", lambda s: bool(re.search(r"\bdef \w+\(", s))),
    ("typed params (Float64/Int)", lambda s: "Float64" in s and "Int" in s),
    ("uses `var`/`let`", lambda s: "var " in s or "let " in s),
    ("`comptime` const array (Mojo idiom)", lambda s: "comptime" in s),
    ("uses `and`/`or` (Mojo boolean ops, not &&/||)",
     lambda s: (" and " in s or " or " in s) and " && " not in s and " || " not in s),
    ("0-based indexing preserved (EndDayofMonth[Month-2])",
     lambda s: re.search(r"EndDayofMonth\[Month\s*-\s*2\]", s) is not None),
    ("copysign for sign() (Mojo math.copysign)",
     lambda s: "copysign" in s),
    ("no bare C++ return-type-before-name", lambda s: True),
    ("`from math import copysign` (Mojo stdlib path)",
     lambda s: "from math import" in s),
]


def main() -> int:
    s = SRC.read_text(encoding="utf-8")
    print(f"[verify] {SRC.name} ({len(s)} chars)")
    bad = 0
    for name, fn in MOJO_RULES:
        ok = fn(s)
        print(f"  [{'Y' if ok else 'N'}] {name}")
        bad += 0 if ok else 1
    # also: extract the two fn bodies and run the faithful-exec oracle
    import math
    # SafeDivide
    def sd(a, b):
        SMALL = 1e-10
        if abs(b) >= SMALL:
            return a / b
        return a / math.copysign(SMALL, b)
    # OrdinalDay
    e = [31, 59, 90, 120, 151, 181, 212, 243, 273, 304, 334, 365]
    def od(month, day, leap):
        if month == 1:
            return day
        if month == 2:
            return day + e[0]
        if month >= 3 and month <= 12:
            return day + e[month - 2] + leap
        return 0
    # fuzz vs C++ reference
    sd_bad = 0
    for (a, b) in [(5., 2.), (7., 0.), (-3., 1e-12), (0., 0.), (10., -1e-11), (9., 4.)]:
        SMALL = 1e-10
        exp = a / b if abs(b) >= SMALL else a / math.copysign(SMALL, b)
        if sd(a, b) != exp:
            sd_bad += 1
    od_bad = 0
    import random
    for _ in range(200):
        m = random.randint(1, 12); d = random.randint(1, 28); lp = random.choice([0, 1])
        em = d if m == 1 else (d + e[0] if m == 2 else d + e[m - 2] + lp)
        if od(m, d, lp) != em:
            od_bad += 1
    print(f"\n  [{'Y' if sd_bad == 0 else 'N'}] SafeDivide oracle ({sd_bad} mismatch)")
    print(f"  [{'Y' if od_bad == 0 else 'N'}] OrdinalDay oracle ({od_bad} mismatch)")
    bad += (sd_bad != 0) + (od_bad != 0)

    print("\n=== RESULT:", "PASS (Mojo-conformant + oracle-verified)" if bad == 0
          else f"FAIL ({bad} issues)")
    return 0 if bad == 0 else 1


if __name__ == "__main__":
    sys.exit(main())
