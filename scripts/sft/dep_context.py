#!/usr/bin/env python3
"""Deterministic dependency-context extractor for EnergyPlus->Mojo migration.

The #1 production failure was the model emitting calls to symbols it didn't know
(pvstar, Le, Constant::*, TARCOGParams::*, pow_N). This is the "first 80%" of the
RAG idea, done with an exact symbol index instead of fuzzy embeddings: for a given
C++ function, find the symbols it references and emit their real declarations /
values as an in-scope CONTEXT block to inject into the transpilation prompt — so
the model knows what exists and how to call it.

Builds a symbol index from the EnergyPlus source (function decls + namespace
constants), plus the shim's known helpers. Usage:
  dep_context.py            # demo: print context it would inject for each prod_test fn
  import dep_context; dep_context.context_for(cpp_body)  # -> str
"""
import re, json, functools
from pathlib import Path
EP = Path("/home/bart/Github/EnergyPlus/src/EnergyPlus")
SFT = Path("/home/bart/Github/transpilers/data/sft/cpp_mojo")

SHIM = {  # always-available helpers (defined by ep_prelude.mojo / ep_oracle.h)
    "pow_2","pow_3","pow_4","pow_5","pow_6","pow_7","root_4","root_8","sign","mod",
}
FUNC_DECL = re.compile(r"^\s*(?:static\s+|inline\s+)?(Real64|double|int|bool|void|Int64)\s+([A-Za-z_]\w*)\s*\(([^;{)]*)\)\s*[;{]", re.M)
CONST_DECL = re.compile(r"\b(?:constexpr|const)\s+(?:Real64|double|int)\s+([A-Za-z_]\w*)\s*[\({]?\s*([-\d.eE+]+)")
NS_OPEN = re.compile(r"\bnamespace\s+(\w+)\s*\{")

@functools.lru_cache(maxsize=1)
def index():
    """name -> short declaration string (functions + namespaced constants)."""
    funcs, consts = {}, {}
    files = list(EP.glob("*.hh"))[:400] + list(EP.glob("*.cc"))[:400]
    for f in files:
        try: txt = f.read_text(errors="ignore")
        except Exception: continue
        for m in FUNC_DECL.finditer(txt):
            ret, nm, args = m.group(1), m.group(2), " ".join(m.group(3).split())
            funcs.setdefault(nm, f"{ret} {nm}({args[:80]})")
        # namespaced constants: track current namespace by brace scan (cheap heuristic)
        for nm_m in re.finditer(r"\bnamespace\s+(\w+)\s*\{([^}]{0,4000})", txt):
            ns = nm_m.group(1)
            for cm in CONST_DECL.finditer(nm_m.group(2)):
                consts[f"{ns}::{cm.group(1)}"] = f"{ns}::{cm.group(1)} = {cm.group(2)}"
    return funcs, consts

def referenced(cpp):
    calls = set(re.findall(r"\b([A-Za-z_]\w*)\s*\(", cpp))
    nsrefs = set(re.findall(r"\b(\w+::\w+)", cpp))
    return calls, nsrefs

def context_for(cpp):
    funcs, consts = index()
    calls, nsrefs = referenced(cpp)
    lines = []
    KEYWORDS = {"if","for","while","return","sizeof","switch","printf"}
    for c in sorted(calls):
        if c in KEYWORDS: continue
        if c in SHIM:
            lines.append(f"// `{c}` is an in-scope helper (ObjexxFCL) — call it directly")
        elif c in funcs and c != "main":
            lines.append(f"// dependency: {funcs[c]}")
    for n in sorted(nsrefs):
        if n in consts:
            lines.append(f"// constant: {consts[n]}")
        else:
            ns, mem = n.split("::", 1)
            lines.append(f"// `{n}` is a {ns} member referenced by this function")
    return "\n".join(dict.fromkeys(lines))   # dedupe, keep order

def main():
    recs = [json.loads(l) for l in (SFT/"prod_test_cpp.jsonl").read_text().splitlines() if l.strip()]
    f, c = index()
    print(f"symbol index: {len(f)} functions, {len(c)} namespaced constants\n")
    for r in recs:
        ctx = context_for(r["cpp"])
        print(f"=== {r['function_name']} — injectable context ===")
        print(ctx if ctx else "(no external deps found)")
        print()

if __name__ == "__main__":
    main()
