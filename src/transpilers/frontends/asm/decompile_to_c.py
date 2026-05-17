# Ghidra post-script — runs after analyzeHeadless imports a binary.
#
# Walks every function, decompiles it via the DecompInterface, and writes
# all of them to a single C file. Output path comes from the
# TRANSPILER_OUTPUT environment variable so the Python wrapper can pick a
# fresh temp file per invocation.
#
# Ghidra runs this as Jython 2.7; keep the syntax compatible.

import os
import sys

from ghidra.app.decompiler import DecompInterface
from ghidra.util.task import ConsoleTaskMonitor


output_path = os.environ.get("TRANSPILER_OUTPUT")
if not output_path:
    print >> sys.stderr, "TRANSPILER_OUTPUT env var not set"
    sys.exit(2)

decomp = DecompInterface()
decomp.openProgram(currentProgram)

monitor = ConsoleTaskMonitor()
fragments = []
for fn in currentProgram.getFunctionManager().getFunctions(True):
    if fn.isExternal() or fn.isThunk():
        continue
    try:
        result = decomp.decompileFunction(fn, 60, monitor)
    except Exception as e:
        sys.stderr.write("decompile failed: %s: %s\n" % (fn.getName(), e))
        continue
    if not result.decompileCompleted():
        sys.stderr.write("decompile incomplete: %s: %s\n" % (fn.getName(), result.getErrorMessage()))
        continue
    fragments.append(result.getDecompiledFunction().getC())

with open(output_path, "w") as f:
    f.write("\n\n".join(fragments))
