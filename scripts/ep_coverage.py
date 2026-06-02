#!/usr/bin/env python3
"""EnergyPlus -> Mojo transpile-coverage harness (autoresearch loop instrument).

For each function definition in the given EnergyPlus C++ files, try to transpile
it to Mojo and tally pass/fail + failure categories + lines-of-code covered.
This is the metric that decides "improve transpiler vs rewrite manually".

  python scripts/ep_coverage.py [FILE ...]            # default: Psychrometrics.hh
  ENERGYPLUS_SRC=.../src/EnergyPlus python scripts/ep_coverage.py --module Psychrometrics

Functions are extracted with libclang (definition extents), then each is fed to
the transpiler in isolation. Domain typedefs come from $TRANSPILERS_CPP_PREAMBLE.
"""
import os, re, sys, glob, collections
sys.path.insert(0, os.path.join(os.path.dirname(__file__), "..", "src"))

import clang.cindex as ci                                   # noqa: E402
from transpilers.frontends.cpp import parser as _cppparser  # configures libclang  # noqa: E402,F401
from transpilers.cli.main import transpile                  # noqa: E402

EP = os.environ.get("ENERGYPLUS_SRC", "/home/db/EnergyPlus/src/EnergyPlus")
# EnergyPlus core typedefs so Real64 etc. resolve (project preamble).
os.environ.setdefault("TRANSPILERS_CPP_PREAMBLE",
                      "typedef double Real64; typedef long long Int64; typedef int Int;")

def _files(argv):
    files, module = [], None
    for a in argv:
        if a == "--module":
            module = "__next__"
        elif module == "__next__":
            module = a
        else:
            files.append(a)
    if module and module != "__next__":
        files += glob.glob(os.path.join(EP, f"{module}.hh")) + glob.glob(os.path.join(EP, f"{module}.cc"))
    if not files:
        files = [os.path.join(EP, "Psychrometrics.hh")]
    return [f for f in files if os.path.isfile(f)]

def extract_functions(path):
    """(name, source_text, loc) for each function definition in `path`."""
    index = ci.Index.create()
    args = ["-std=c++17", "-x", "c++"]
    tu = index.parse(path, args=args, options=ci.TranslationUnit.PARSE_DETAILED_PROCESSING_RECORD)
    raw = open(path, "rb").read()
    out, seen = [], set()
    FN = {ci.CursorKind.FUNCTION_DECL, ci.CursorKind.CXX_METHOD}
    def walk(c):
        for ch in c.get_children():
            try:
                in_file = ch.location.file and os.path.samefile(ch.location.file.name, path)
            except Exception:
                in_file = False
            if in_file and ch.kind in FN and ch.is_definition():
                e = ch.extent
                if e.start.offset < e.end.offset and (e.start.offset, e.end.offset) not in seen:
                    seen.add((e.start.offset, e.end.offset))
                    text = raw[e.start.offset:e.end.offset].decode("utf-8", "ignore")
                    out.append((ch.spelling, text, text.count("\n") + 1))
            walk(ch)
    walk(tu.cursor)
    return out

def categorize(err: str) -> str:
    e = err.strip().splitlines()[0] if err.strip() else "empty"
    if "unknown type name" in err: return "unknown type (" + (re.search(r"unknown type name '([^']+)'", err) or [None, "?"])[1] + ")"
    if "undeclared identifier" in err:
        m = re.search(r"undeclared identifier '([^']+)'", err); return f"undeclared id ({m.group(1) if m else '?'})"
    if "top-level" in err: return "top-level " + (re.search(r"top-level (\w+)", err) or [None, "?"])[1]
    if "libclang parse errors" in err: return "parse error (other)"
    for tok in ("UnsupportedConstruct", "reference", "template", "lambda", "auto"):
        if tok in err: return tok
    return e[:60]

def main():
    argv = sys.argv[1:]
    emit_path = None
    if "--emit" in argv:
        i = argv.index("--emit"); emit_path = argv[i + 1]; del argv[i:i + 2]
    files = _files(argv)
    print(f"# EnergyPlus -> Mojo coverage  (preamble: {os.environ['TRANSPILERS_CPP_PREAMBLE']})")
    tot = ok = ok_loc = tot_loc = 0
    fails = collections.Counter(); fail_loc = collections.Counter()
    emitted = []
    for path in files:
        fns = extract_functions(path)
        for name, text, loc in fns:
            tot += 1; tot_loc += loc
            try:
                out = transpile(text, source_lang="cpp", target="mojo")
                ok += 1; ok_loc += loc
                if emit_path:
                    emitted.append(f"# from {os.path.basename(path)}: {name}\n{out.strip()}\n")
            except Exception as ex:
                cat = categorize(str(ex))
                fails[cat] += 1; fail_loc[cat] += loc
        print(f"  {os.path.basename(path):28s} {len(fns):4d} fns")
    if emit_path and emitted:
        with open(emit_path, "w") as f:
            f.write("# Auto-transpiled EnergyPlus numeric kernels (C++ -> Mojo via transpilers).\n"
                    "# Pure functions only; state-coupled code is hand-ported separately.\n\n")
            f.write("\n".join(emitted))
        print(f"\nemitted {len(emitted)} Mojo functions -> {emit_path}")
    print(f"\nTRANSPILED: {ok}/{tot} functions ({100*ok//max(tot,1)}%)  "
          f"| LOC {ok_loc}/{tot_loc} ({100*ok_loc//max(tot_loc,1)}%)")
    print("\nTop failure categories (count, loc):")
    for cat, n in fails.most_common(15):
        print(f"  {n:4d}  {fail_loc[cat]:6d} loc  {cat}")

if __name__ == "__main__":
    main()
