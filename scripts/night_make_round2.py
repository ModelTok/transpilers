#!/usr/bin/env python3
"""Build round-2 verify input from round-1 rejects: prepend missing constant
definitions to candidates whose C++ wasn't self-contained; drop class methods
that can't be freestanding."""
import json
import sys

CONST_FIX = {
    "SafeDiv": "Real64 constexpr SMALL = 1.e-10;\n\n",
    "BBConvergeCheck": ("int constexpr BBSteamRadConvNum = 5;\n"
                        "int constexpr BBWaterRadConvNum = 6;\n\n"),
}
DROP = {"can_instantiate"}

src, dst = sys.argv[1], sys.argv[2]
n = 0
with open(dst, "w") as f:
    for l in open(src):
        if not l.strip():
            continue
        rec = json.loads(l)
        if not rec.get("mojo_source") or rec["function_name"] in DROP:
            continue
        fix = CONST_FIX.get(rec["function_name"])
        if fix:
            rec["cpp_source"] = fix + rec["cpp_source"]
        rec.pop("reject_reason", None)
        f.write(json.dumps(rec, ensure_ascii=False) + "\n")
        n += 1
print(f"round2 input: {n} candidates -> {dst}")
