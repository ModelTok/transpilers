#!/usr/bin/env python3
"""Extract `void Name(...)` EnergyPlus functions whose params are all scalars
or scalar references (the out-params), with self-contained bodies. Dump as
JSONL candidates for LLM translation + behavioral verification.

Output record: {function_name, source_file, ret_type: "void",
                params: [[ctype, name, is_ref], ...], cpp_source}
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
from build_cpp_mojo_dataset import (_match_delims, _match_braces,  # noqa: E402
                                    _strip_comments, _split_top_level,
                                    _SCALAR_TYPE)

SIG = re.compile(
    r"(?<![\w:])(?P<ret>void|Real64|Real32|double|float|int|Int|Int64|long|bool)"
    r"\s+(?P<name>[A-Za-z_]\w*)\s*\(")
REJECT_BODY = re.compile(
    r"\bstate\b|->|\.dataptr|ShowSevereError|ShowWarningError|ShowFatalError"
    r"|GetCurrentScheduleValue|std::string|Array1D|Array2D|std::vector"
    r"|ObjexxFCL|\bnew\b|\bdelete\b|\bthis\b")


def parse_params(arg_str: str):
    arg_str = _strip_comments(arg_str).strip()
    if not arg_str or arg_str == "void":
        return None
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
        if not _SCALAR_TYPE.match(ptype) or not re.match(r"^[A-Za-z_]\w*$", pname):
            return None
        params.append([ptype, pname, is_ref])
        n_out += is_ref
    return params if params and n_out >= 1 else None


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--ep-src", type=Path, required=True)
    ap.add_argument("--out", type=Path, required=True)
    ap.add_argument("--max-lines", type=int, default=120,
                    help="skip bodies longer than this many lines")
    args = ap.parse_args()

    out, seen = [], set()
    files = sorted(list(args.ep_src.glob("**/*.cc")) + list(args.ep_src.glob("**/*.hh")))
    for cc in files:
        text = cc.read_text(errors="ignore")
        for m in SIG.finditer(text):
            name = m.group("name")
            if name in seen:
                continue
            paren_open = m.end() - 1
            paren_end = _match_delims(text, paren_open, "(", ")")
            if paren_end < 0:
                continue
            params = parse_params(text[paren_open + 1:paren_end - 1])
            if params is None:
                continue
            # plain definition check: only qualifiers/comments between `)` and `{`
            # (linear scan — the original _POST_PAREN regex backtracks badly)
            brace_open = text.find("{", paren_end)
            if brace_open < 0 or brace_open - paren_end > 400:
                continue
            between = _strip_comments(text[paren_end:brace_open])
            if between.strip() not in ("", "const", "noexcept", "const noexcept"):
                continue
            end = _match_braces(text, brace_open)
            if end < 0:
                continue
            body = text[m.start():end]
            if REJECT_BODY.search(body):
                continue
            if body.count("\n") + 1 > args.max_lines:
                continue
            seen.add(name)
            out.append({"function_name": name,
                        "source_file": str(cc.relative_to(args.ep_src)),
                        "ret_type": m.group("ret"), "params": params,
                        "cpp_source": body})

    args.out.parent.mkdir(parents=True, exist_ok=True)
    with args.out.open("w") as f:
        for r in out:
            f.write(json.dumps(r, ensure_ascii=False) + "\n")
    print(f"void+out-param candidates: {len(out)} -> {args.out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
