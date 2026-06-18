#!/usr/bin/env python3
"""Size the void+scalar-out-param candidate class in EnergyPlus.

Candidates: `void Name(...)` definitions whose params are all scalars or
scalar references (Real64&, int&, bool&), with a self-contained body
(no state / -> / Show*Error / strings / arrays).
"""
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_cpp_mojo_dataset import (_match_delims, _match_braces, _POST_PAREN,
                                    _strip_comments, _split_top_level, _SCALAR_TYPE)

SIG = re.compile(r"(?<![\w:])void\s+(?P<name>[A-Za-z_]\w*)\s*\(")
EP = Path("/home/amd/EnergyPlus/src/EnergyPlus")

def parse_params(arg_str):
    arg_str = _strip_comments(arg_str).strip()
    if not arg_str or arg_str == "void":
        return None  # void fn with no out-params is useless
    params, n_out = [], 0
    for raw in _split_top_level(arg_str):
        p = raw.strip()
        if not p:
            continue
        if any(tok in p for tok in ("*", "<", "[", "=", "...", "::", "EnergyPlusData")):
            return None
        is_ref = "&" in p
        p = p.replace("&", " ").replace("const", " ").replace("volatile", " ")
        toks = p.split()
        if len(toks) < 2:
            return None
        ptype, pname = toks[0], toks[-1]
        if not _SCALAR_TYPE.match(ptype):
            return None
        if not re.match(r"^[A-Za-z_]\w*$", pname):
            return None
        params.append((ptype, pname, is_ref))
        n_out += is_ref
    return params if n_out >= 1 else None

count = 0
names = []
for cc in sorted(list(EP.glob("**/*.cc")) + list(EP.glob("**/*.hh"))):
    text = cc.read_text(errors="ignore")
    for m in SIG.finditer(text):
        paren_open = m.end() - 1
        paren_end = _match_delims(text, paren_open, "(", ")")
        if paren_end < 0:
            continue
        tail = text[paren_end:paren_end + 400]
        mt = _POST_PAREN.match(tail)
        if not mt:
            continue
        params = parse_params(text[paren_open + 1:paren_end - 1])
        if params is None:
            continue
        brace_open = paren_end + mt.end() - 1
        end = _match_braces(text, brace_open)
        if end < 0:
            continue
        body = text[m.start():end]
        if re.search(r"\bstate\b|->|\.dataptr|ShowSevereError|ShowWarningError"
                     r"|ShowFatalError|GetCurrentScheduleValue|std::string|Array1D", body):
            continue
        count += 1
        names.append((m.group("name"), str(cc.relative_to(EP)), len(params),
                      sum(1 for *_x, r in params if r)))

print(f"void+out-param candidates: {count}")
for n, f, np, no in names[:40]:
    print(f"  {n}  ({np} params, {no} out)  @ {f}")
