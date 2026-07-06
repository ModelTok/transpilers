#!/usr/bin/env python3
"""Transpiler capability: transitive scalar-dependency BUNDLING for C++->Mojo.

Many EnergyPlus functions fail to transpile standalone only because they call
sibling scalar functions ("use of undeclared identifier"). This resolves the
call graph over the pure-scalar candidate set and transpiles a function together
with its transitive scalar callees as one module — then behaviorally verifies the
entry function. Recovers pairs the single-function pipeline cannot, and makes the
transpiler dependency-aware.

Emits additional verified C++->Mojo pairs to data/cpp_mojo_pairs_bundled.jsonl.
"""
from __future__ import annotations

import importlib.util, json, os, re, sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO / "src"))
_b = importlib.util.spec_from_file_location("bcm", REPO / "scripts/build_cpp_mojo_dataset.py")
bcm = importlib.util.module_from_spec(_b); sys.modules["bcm"] = bcm; _b.loader.exec_module(bcm)

OUT = REPO / "data/cpp_mojo_pairs_bundled.jsonl"
_CALL = re.compile(r"\b([A-Za-z_]\w+)\s*\(")


def entry_params(mojo: str, name: str):
    """Params of the ENTRY function's def (not the first def in the bundle)."""
    m = re.search(rf"def\s+{re.escape(name)}\(([^)]*)\)\s*->\s*\w+", mojo)
    if not m:
        return None
    out = []
    for part in m.group(1).split(","):
        part = part.strip()
        if not part or ":" not in part:
            continue
        nm, ty = part.split(":", 1)
        out.append((nm.strip(), ty.strip()))
    return out


def callees(body: str, names: set[str]) -> set[str]:
    return {c for c in _CALL.findall(body) if c in names}


def topo(entry: str, byname: dict, names: set[str]) -> list[str] | None:
    """Post-order (callees before callers) over the scalar-candidate call graph.
    Returns ordered names incl. entry, or None if any dependency is external."""
    order, seen, stack = [], set(), set()

    def visit(n):
        if n in seen:
            return True
        if n in stack:                       # cycle — still fine for one TU, but skip self-recursion dups
            return True
        stack.add(n)
        for c in callees(byname[n].body, names):
            if c not in byname:
                return False
            if not visit(c):
                return False
        stack.discard(n)
        seen.add(n); order.append(n)
        return True

    return order if visit(entry) else None


def main():
    fns = bcm.extract_fns(Path(os.environ.get("EP_SRC", "/home/bart/Github/EnergyPlus/src/EnergyPlus")))
    byname = {f.name: f for f in fns}
    names = set(byname)
    from transpilers.cli.main import transpile_cpp_to_mojo

    # find functions that FAIL standalone but whose full closure is in-set
    targets = []
    for f in fns:
        try:
            transpile_cpp_to_mojo(f.body)
            continue                          # already works standalone
        except Exception:
            pass
        order = topo(f.name, byname, names)
        if order and len(order) > 1:          # has resolvable scalar deps
            targets.append((f, order))

    print(f"bundling candidates (fail standalone, closure in-set): {len(targets)}")
    pairs = []; ok = 0; tp = 0; vf = 0
    for entry, order in targets:
        # combined C++: callees (definition order) then entry last
        combined = "\n\n".join(byname[n].body for n in order)
        bundle = bcm.CppFn(name=entry.name, ret=entry.ret, params=entry.params,
                           body=combined, source_file=entry.source_file)
        mojo = bcm.transpile(bundle)
        if not mojo:
            tp += 1; print(f"  {entry.name:30s} transpile_fail (deps: {order[:-1]})"); continue
        mp = entry_params(mojo, entry.name)
        if mp is None or len(mp) != len(entry.params):
            tp += 1; print(f"  {entry.name:30s} sig_fail"); continue
        v = bcm.verify(bundle, mojo, mp)
        if v is None:
            vf += 1; print(f"  {entry.name:30s} verify_fail (deps: {order[:-1]})"); continue
        ok += 1
        pairs.append({"cpp_source": combined, "mojo_source": mojo,
                      "function_name": entry.name, "source_file": entry.source_file,
                      "n_args": len(entry.params), "arg_types": [t for t, _ in entry.params],
                      "ret_type": entry.ret, "verification": {"method": "behavioral", **v},
                      "provenance": "energyplus-cpp-generate-verify-bundled",
                      "bundled_deps": order[:-1], "direction": "cpp->mojo"})
        print(f"  {entry.name:30s} OK  (bundled {order[:-1]}, finite {v['samples_finite']}, "
              f"rel {v['max_rel_err']:.0e}, cov {v['branch_coverage']})")

    OUT.write_text("\n".join(json.dumps(p, ensure_ascii=False) for p in pairs))
    print(f"\nbundled recovery: {ok} verified  (transpile_fail={tp} verify_fail={vf})")
    print(f"  -> {OUT}")


if __name__ == "__main__":
    main()
