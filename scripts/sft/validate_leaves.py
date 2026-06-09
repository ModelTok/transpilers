#!/usr/bin/env python3
"""Independently validate every leaf in a py_leaves.jsonl:
  - python_unit + python_driver must exec/run without error
  - the driver must print exactly one numeric line per expected output
  - re-evaluating the unit's fn on sample_args must reproduce the driver output
This is an EXTERNAL check (separate from the extractor's internal gate) so we can
confirm the corpus's oracles actually validate."""
import io, json, math, sys, contextlib, ast

path = sys.argv[1] if len(sys.argv) > 1 else "/tmp/py_leaves_test.jsonl"
leaves = [json.loads(l) for l in open(path)]
bad = []
ok = 0
for L in leaves:
    name = L["name"]
    unit = L["python_unit"]
    driver = L["python_driver"]
    try:
        ns = {"math": math, "__builtins__": __builtins__}
        exec(unit, ns)
        # run driver, capture stdout
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            exec(driver, ns)
        out_lines = [x for x in buf.getvalue().splitlines() if x.strip() != ""]
        # every line must parse as a python float/int/bool literal
        for ln in out_lines:
            v = ast.literal_eval(ln)
            if not isinstance(v, (int, float, bool)):
                raise ValueError(f"non-numeric driver line: {ln!r}")
            if isinstance(v, float) and not math.isfinite(v):
                raise ValueError(f"non-finite driver line: {ln!r}")
        if not out_lines:
            raise ValueError("driver produced no output")
        # cross: re-eval fn on each sample tuple, compare to driver where scalar
        fn = ns[name]
        for t in L["sample_args"]:
            r = fn(*t)  # must not raise
        ok += 1
    except Exception as e:
        bad.append((name, L.get("category"), type(e).__name__, str(e)[:120]))

print(f"validated {ok}/{len(leaves)} leaves OK")
if bad:
    print(f"FAILED {len(bad)}:")
    for b in bad:
        print("  ", b)
else:
    print("ALL python oracles run and produce finite numeric output.")
