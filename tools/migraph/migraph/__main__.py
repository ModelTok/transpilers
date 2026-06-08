#!/usr/bin/env python3
"""migraph command dispatcher.

  python -m migraph migration  [--map ... --repo ... --cpp-src ... --out ...]
  python -m migraph code       (symbol graph)
  python -m migraph module     (subpackage import graph)
  python -m migraph cpp        (C++ symbol + module graphs)
"""
import sys, runpy

CMDS = {
    "migration": "migraph.migration_graph",
    "classify": "migraph.classify_kernels",
    "code": "migraph.code_graph",
    "module": "migraph.module_graph",
    "cpp": "migraph.cpp_graph",
}

def main():
    if len(sys.argv) < 2 or sys.argv[1] not in CMDS:
        print(__doc__)
        print("commands:", ", ".join(CMDS))
        sys.exit(0 if len(sys.argv) < 2 else 2)
    cmd = sys.argv[1]
    sys.argv = [f"migraph {cmd}"] + sys.argv[2:]      # hand remaining args to the module
    runpy.run_module(CMDS[cmd], run_name="__main__")

if __name__ == "__main__":
    main()
