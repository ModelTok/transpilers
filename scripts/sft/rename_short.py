#!/usr/bin/env python3
"""Shorten internal variable/param names in verified pairs to cut token length
without changing behaviour or breaking 1:1 faithfulness.

Safe-rename rule: an identifier that appears in the unit but NOT in the driver is
a local/param (API names — functions, structs, methods, fields used by the
driver — appear in the driver, so they're left alone). Long internals (>=5 chars)
are mapped to short v1,v2,... applied IDENTICALLY to the C++ and Mojo unit, so the
source==target name-mapping the model learns is preserved.

Every renamed pair is re-verified (compile+run both, compare stdout); only pairs
that still pass are kept. Usage: rename_short.py <in.jsonl> <out.jsonl> [limit]
"""
import json, re, sys, importlib.util
from pathlib import Path
REPO = Path(__file__).resolve().parents[2]  # scripts/sft/<this file> -> repo root
_d = importlib.util.spec_from_file_location("dv", REPO/"scripts/sft/diff_verify.py")
dv = importlib.util.module_from_spec(_d); sys.modules["dv"] = dv; _d.loader.exec_module(dv)

RESERVED = {"out","ref","mut","var","def","fn","let","in","for","if","else","while",
            "self","Self","read","deinit","Int","Bool","String","List","Dict","True","False"}
IDENT = re.compile(r"[A-Za-z_]\w+")

def short_names(n):
    out = []
    i = 1
    while len(out) < n:
        nm = f"v{i}"; i += 1
        if nm not in RESERVED: out.append(nm)
    return out

def rename_pair(p):
    cu, mu = p["cpp_unit"], p["mojo_unit"]
    drv = (p["cpp_driver"] + " " + p["mojo_driver"])
    drv_ids = set(IDENT.findall(drv))
    unit_ids = set(IDENT.findall(cu)) | set(IDENT.findall(mu))
    # internal = in unit, not in driver, >=5 chars, not reserved, not a type-ish token
    internal = sorted(x for x in unit_ids
                      if len(x) >= 5 and x not in drv_ids and x not in RESERVED
                      and not x[0].isupper()          # skip Types/structs (Capitalized)
                      and not x.startswith("__"))      # skip dunders
    if not internal:
        return None
    shorts = short_names(len(internal))
    # avoid colliding with short names already present
    present = {x for x in unit_ids if len(x) < 5}
    shorts = [s for s in short_names(len(internal)+len(present)) if s not in present][:len(internal)]
    mapping = dict(zip(internal, shorts))
    def apply(s):
        for long, sh in mapping.items():
            s = re.sub(rf"\b{re.escape(long)}\b", sh, s)
        return s
    q = dict(p); q["cpp_unit"] = apply(cu); q["mojo_unit"] = apply(mu)
    return q

def main():
    inp, outp = Path(sys.argv[1]), Path(sys.argv[2])
    limit = int(sys.argv[3]) if len(sys.argv) > 3 else 10**9
    pairs = [json.loads(l) for l in inp.read_text().splitlines() if l.strip()][:limit]
    kept = []; renamed = 0; broke = 0; nochange = 0
    for p in pairs:
        q = rename_pair(p)
        if q is None:
            kept.append(p); nochange += 1; continue
        ok, why = dv.verify(q)
        if ok:
            kept.append(q); renamed += 1
        else:
            kept.append(p); broke += 1   # keep ORIGINAL if rename broke it
            print(f"  rename broke {p.get('name','?')}: {why} -> kept original")
    outp.write_text("\n".join(json.dumps(p, ensure_ascii=False) for p in kept) + "\n")
    print(f"renamed+verified {renamed}, unchanged {nochange}, rename-failed(kept orig) {broke}, total {len(kept)} -> {outp}")

if __name__ == "__main__":
    main()
