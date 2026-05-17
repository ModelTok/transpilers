"""Assembly frontend — deliberately unimplemented, with an architectural
explanation rather than a silent omission.

Assembly is below the abstraction level our MIR can represent:

  - **Registers, not variables.** The IR's notion of named locals with types
    doesn't map onto a register allocator's view. To lift assembly back to a
    typed IR you need decompilation (recovering control flow, structs,
    function boundaries), which is a research area in itself — not the
    inverse of a transpiler.

  - **Instructions, not expressions.** Our `MirBinOp` is symbolic; assembly
    has `add rax, rbx` whose semantics depend on the register state, flags,
    and target architecture. Mapping that to MIR loses the model.

  - **No portable type system.** Even between x86_64 and ARM64, register
    widths, calling conventions, and address modes differ. There's no shared
    HIR shape we could land assembly into without committing to a specific
    ISA — and at that point we're a disassembler/decompiler, not a transpiler.

A real assembly-to-high-language pipeline (Ghidra, IDA, Hex-Rays, retdec,
Binary Ninja) treats this as decompilation: type recovery, control-flow
reconstruction, idiom matching. That's a separate project shape from the
source-to-source transpiler this IR targets.

If you want to bring assembly into this system, the right move is to integrate
a decompiler that outputs C (Ghidra's exporter, retdec) and then run that
through our existing C frontend.
"""

from __future__ import annotations

from transpilers.ir import hir


class UnsupportedConstruct(Exception):
    pass


def parse_asm(source: str) -> hir.HirModule:
    raise UnsupportedConstruct(
        "assembly is below the MIR's abstraction level — registers and "
        "instructions don't map onto our typed-locals IR without "
        "decompilation. Run a decompiler (Ghidra, retdec) first, then feed "
        "the recovered C through the existing C frontend."
    )
