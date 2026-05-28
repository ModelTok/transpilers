"""Block-level semantic alignment check (BabelCoder pattern).

After transpilation, executes corresponding functions from source and target
implementations on the same inputs and compares their outputs block-by-block.
This detects semantic drift that whole-program output comparison misses and
pinpoints exactly which function diverges — so repair effort targets the right
block rather than re-translating the whole file.

Python-source + Python-target:  full function-level tracing with sample inputs.
Python-source + compiled target: function-level compile+run I/O comparison.
Auto-transpile mode:             transpile the source file first, then align.

Usage
-----
    # Compare two already-translated files
    uv run python scripts/semantic_align.py source.py translated.py

    # Transpile then align in one step
    uv run python scripts/semantic_align.py source.py --auto-transpile --target python

    # Compiled target (per-function compile+run)
    uv run python scripts/semantic_align.py source.py translated.rs --target rust
"""

from __future__ import annotations

import argparse
import ast
import importlib.util
import inspect
import subprocess
import sys
import tempfile
import textwrap
import traceback
from dataclasses import dataclass
from pathlib import Path
from typing import Any

# ---------------------------------------------------------------------------
# Sample input generation
# ---------------------------------------------------------------------------

_SCALAR_SAMPLES: list[Any] = [0, 1, -1, 2, 10, 100, -5]
_LIST_SAMPLES: list[Any] = [[], [1], [1, 2, 3], [0, -1, 5]]


def _gen_inputs(n_params: int, max_samples: int = 4) -> list[tuple]:
    """Generate simple sample input tuples for a function with *n_params* params."""
    if n_params == 0:
        return [()]
    if n_params == 1:
        samples: list[Any] = _SCALAR_SAMPLES + _LIST_SAMPLES
        return [(s,) for s in samples[:max_samples]]
    # Multi-param: combine scalar samples
    from itertools import product
    scalars = _SCALAR_SAMPLES[:3]
    return list(product(scalars, repeat=n_params))[:max_samples]


# ---------------------------------------------------------------------------
# Python function extraction and execution
# ---------------------------------------------------------------------------

@dataclass
class FuncResult:
    name: str
    inputs: tuple
    source_output: Any
    target_output: Any
    source_error: str
    target_error: str

    @property
    def aligned(self) -> bool:
        if self.source_error or self.target_error:
            return False
        return self.source_output == self.target_output


def _load_module_from_source(source_code: str, module_name: str = "_transpiler_mod"):
    """Dynamically load a Python module from source code string."""
    spec = importlib.util.spec_from_loader(module_name, loader=None)
    mod = importlib.util.module_from_spec(spec)  # type: ignore[arg-type]
    exec(compile(source_code, module_name, "exec"), mod.__dict__)  # noqa: S102
    return mod


def _extract_python_functions(source_code: str) -> dict[str, Any]:
    """Return {name: callable} for all top-level functions in *source_code*."""
    try:
        mod = _load_module_from_source(source_code)
    except Exception:
        return {}
    return {
        name: obj
        for name, obj in vars(mod).items()
        if callable(obj) and not name.startswith("_")
    }


def _call_safe(fn: Any, args: tuple) -> tuple[Any, str]:
    """Call *fn* with *args*, returning (result, error_str)."""
    try:
        result = fn(*args)
        return result, ""
    except Exception as exc:
        return None, f"{type(exc).__name__}: {exc}"


def _get_arity(fn: Any) -> int:
    try:
        sig = inspect.signature(fn)
        return sum(
            1 for p in sig.parameters.values()
            if p.default is inspect.Parameter.empty
               and p.kind not in (p.VAR_POSITIONAL, p.VAR_KEYWORD)
        )
    except (ValueError, TypeError):
        return 1


# ---------------------------------------------------------------------------
# Python-to-Python alignment
# ---------------------------------------------------------------------------

def align_python_python(
    source_code: str,
    target_code: str,
) -> list[FuncResult]:
    """Compare each function between two Python implementations."""
    src_fns = _extract_python_functions(source_code)
    tgt_fns = _extract_python_functions(target_code)

    common = set(src_fns) & set(tgt_fns)
    results: list[FuncResult] = []

    for name in sorted(common):
        src_fn = src_fns[name]
        tgt_fn = tgt_fns[name]
        arity = _get_arity(src_fn)
        for inputs in _gen_inputs(arity):
            src_out, src_err = _call_safe(src_fn, inputs)
            tgt_out, tgt_err = _call_safe(tgt_fn, inputs)
            res = FuncResult(
                name=name,
                inputs=inputs,
                source_output=src_out,
                target_output=tgt_out,
                source_error=src_err,
                target_error=tgt_err,
            )
            results.append(res)
            if not res.aligned:
                break  # first diverging input is enough to flag the function

    return results


# ---------------------------------------------------------------------------
# Python-to-compiled alignment (function-level run)
# ---------------------------------------------------------------------------

_RUST_WRAPPER = """\
{code}

#[cfg(test)]
mod _align_tests {{
    use super::*;
    {tests}
}}
"""

_C_WRAPPER = """\
{code}
#include <stdio.h>
{main}
"""


def _run_compiled_function(
    fn_name: str,
    source_fn: Any,
    target_code: str,
    target: str,
    arity: int,
) -> list[FuncResult]:
    """Run a single function from the compiled target against the Python source."""
    results: list[FuncResult] = []
    for inputs in _gen_inputs(arity):
        src_out, src_err = _call_safe(source_fn, inputs)
        if src_err:
            continue  # skip if source errors on this input

        # Build a tiny compiled harness that calls fn with inputs and prints result
        args_str = ", ".join(str(a) for a in inputs)
        if target == "rust":
            harness = f"""
fn main() {{
    let result = {fn_name}({args_str});
    println!("{{}}", result);
}}
"""
            full = target_code + "\n" + harness
            tgt_out, tgt_err = _compile_and_run_rust(full)
        elif target == "c":
            harness = f"""
int main() {{
    printf("%d\\n", {fn_name}({args_str}));
    return 0;
}}
"""
            full = target_code + "\n" + harness
            tgt_out, tgt_err = _compile_and_run_c(full)
        else:
            continue  # unsupported compiled target for block-level alignment

        try:
            tgt_parsed: Any = int(tgt_out.strip()) if tgt_out.strip().lstrip("-").isdigit() else tgt_out.strip()
        except Exception:
            tgt_parsed = tgt_out.strip()

        res = FuncResult(
            name=fn_name,
            inputs=inputs,
            source_output=src_out,
            target_output=tgt_parsed,
            source_error=src_err,
            target_error=tgt_err,
        )
        results.append(res)
        if not res.aligned:
            break
    return results


def _compile_and_run_rust(code: str) -> tuple[str, str]:
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / "main.rs"
        p.write_text(code)
        exe = Path(td) / "prog"
        build = subprocess.run(
            ["rustc", "--edition", "2021", str(p), "-o", str(exe)],
            capture_output=True, text=True, timeout=30,
        )
        if build.returncode != 0:
            return "", build.stderr.strip().splitlines()[-1][:120] if build.stderr else "compile error"
        run = subprocess.run([str(exe)], capture_output=True, text=True, timeout=10)
        return run.stdout, run.stderr if run.returncode != 0 else ""


def _compile_and_run_c(code: str) -> tuple[str, str]:
    with tempfile.TemporaryDirectory() as td:
        p = Path(td) / "main.c"
        p.write_text(code)
        exe = Path(td) / "prog"
        build = subprocess.run(
            ["gcc", "-std=c11", str(p), "-o", str(exe)],
            capture_output=True, text=True, timeout=30,
        )
        if build.returncode != 0:
            return "", build.stderr.strip().splitlines()[-1][:120] if build.stderr else "compile error"
        run = subprocess.run([str(exe)], capture_output=True, text=True, timeout=10)
        return run.stdout, run.stderr if run.returncode != 0 else ""


# ---------------------------------------------------------------------------
# Auto-transpile
# ---------------------------------------------------------------------------

def auto_transpile(source_path: Path, target: str) -> str | None:
    """Transpile *source_path* to *target* and return the output code, or None."""
    proc = subprocess.run(
        ["uv", "run", "transpile", str(source_path), "--target", target],
        capture_output=True, text=True, timeout=90,
    )
    return proc.stdout if proc.returncode == 0 else None


# ---------------------------------------------------------------------------
# Report
# ---------------------------------------------------------------------------

def _fmt_val(v: Any) -> str:
    s = repr(v)
    return s[:60] + "…" if len(s) > 60 else s


def print_report(results: list[FuncResult], source_path: Path, target_path: Path) -> int:
    """Print alignment report. Returns exit code (0 = all aligned, 1 = drift found)."""
    by_fn: dict[str, list[FuncResult]] = {}
    for r in results:
        by_fn.setdefault(r.name, []).append(r)

    aligned: list[str] = []
    drifted: list[str] = []
    errors: list[str] = []

    for fn, fn_results in sorted(by_fn.items()):
        all_ok = all(r.aligned for r in fn_results)
        any_err = any(r.source_error or r.target_error for r in fn_results)
        if any_err:
            errors.append(fn)
        elif all_ok:
            aligned.append(fn)
        else:
            drifted.append(fn)

    print(f"\n=== Semantic alignment: {source_path.name} vs {target_path.name} ===\n")
    print(f"  Aligned:  {len(aligned)} functions")
    print(f"  Drifted:  {len(drifted)} functions  ← fix these")
    print(f"  Errors:   {len(errors)} functions  ← execution/compile failures")
    print()

    if drifted:
        print("DRIFTED FUNCTIONS:")
        for fn in drifted:
            fn_results = by_fn[fn]
            for r in fn_results:
                if not r.aligned:
                    print(f"  {fn}({', '.join(_fmt_val(a) for a in r.inputs)})")
                    print(f"    source → {_fmt_val(r.source_output)}")
                    print(f"    target → {_fmt_val(r.target_output)}")
                    break

    if errors:
        print("\nEXECUTION ERRORS:")
        for fn in errors:
            fn_results = by_fn[fn]
            for r in fn_results:
                if r.source_error:
                    print(f"  {fn}: source error: {r.source_error}")
                elif r.target_error:
                    print(f"  {fn}: target error: {r.target_error}")
                break

    return 1 if drifted else 0


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser(
        prog="semantic_align",
        description="Block-level semantic alignment check between source and translated code.",
    )
    parser.add_argument("source", type=Path, help="Source file (Python).")
    parser.add_argument(
        "target_file", type=Path, nargs="?",
        help="Already-translated target file. Omit with --auto-transpile.",
    )
    parser.add_argument(
        "--auto-transpile", action="store_true",
        help="Transpile source first, then align.",
    )
    parser.add_argument(
        "--target", default="python",
        choices=["python", "rust", "c"],
        help="Target language when using --auto-transpile (default: python).",
    )
    args = parser.parse_args(argv)

    source_code = args.source.read_text(errors="replace")

    if args.auto_transpile:
        print(f"Transpiling {args.source.name} → {args.target} …")
        target_code = auto_transpile(args.source, args.target)
        if target_code is None:
            print("Transpilation failed. Check output above.", file=sys.stderr)
            return 1
        target_path = args.source.with_suffix(f".{args.target}")
    elif args.target_file is not None:
        target_code = args.target_file.read_text(errors="replace")
        target_path = args.target_file
        # Detect target language from extension
        ext_to_target = {".py": "python", ".rs": "rust", ".c": "c"}
        args.target = ext_to_target.get(args.target_file.suffix, "python")
    else:
        parser.error("Provide a target_file or use --auto-transpile.")
        return 2

    source_fns = _extract_python_functions(source_code)
    if not source_fns:
        print("No Python functions found in source.", file=sys.stderr)
        return 1

    print(f"Aligning {len(source_fns)} functions …")

    if args.target == "python":
        results = align_python_python(source_code, target_code)
    else:
        results = []
        for fn_name, fn_obj in source_fns.items():
            arity = _get_arity(fn_obj)
            results.extend(
                _run_compiled_function(
                    fn_name, fn_obj, target_code, args.target, arity
                )
            )

    if not results:
        print("No comparable functions found between source and target.", file=sys.stderr)
        return 1

    return print_report(results, args.source, target_path)


if __name__ == "__main__":
    raise SystemExit(main())
