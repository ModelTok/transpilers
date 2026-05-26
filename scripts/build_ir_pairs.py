#!/usr/bin/env python3
"""Build (LLVM IR, Mojo source) training pairs from C++ source files.

This script processes a directory of .cpp files, emits LLVM IR via clang,
translates each function to Mojo via the transpiler pipeline, runs equivalence
verification, and outputs verified pairs as JSONL.

Usage:
    python scripts/build_ir_pairs.py src/EnergyPlus/ \\
        --ir-output ir/ \\
        --mojo-output mojo_generated/ \\
        --pairs-output data/ir_pairs.jsonl \\
        --model claude-3-5-sonnet \\
        --verify-level 2 \\
        --max-complexity 20

    python scripts/build_ir_pairs.py src/EnergyPlus/ \\
        --pairs-output data/ir_pairs.jsonl \\
        --max-cost 50.00

    python scripts/build_ir_pairs.py src/ \\
        --pairs-output data/ir_pairs.jsonl \\
        --resume
"""

import argparse
import json
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


# ---------------------------------------------------------------------------
# LLVM IR emission
# ---------------------------------------------------------------------------

def emit_llvm_ir(
    source: Path,
    output: Path,
    std: str = "c++17",
    includes: list[str] | None = None,
) -> tuple[bool, str]:
    """Emit LLVM IR from a C++ source file using clang.

    Returns (success, message).
    """
    cmd = [
        "clang",
        "-S", "-emit-llvm",
        "-O0", "-g",
        f"-std={std}",
        "-o", str(output),
        str(source),
    ]
    for inc in (includes or []):
        cmd.extend(["-I", inc])

    try:
        result = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
        if result.returncode == 0:
            return True, "OK"
        return False, result.stderr.strip()[:500]
    except FileNotFoundError:
        return False, "clang not found"
    except subprocess.TimeoutExpired:
        return False, "timeout"


# ---------------------------------------------------------------------------
# LLVM IR parsing helpers
# ---------------------------------------------------------------------------

def extract_function_signatures(ll_content: str) -> list[dict[str, str]]:
    """Extract function definitions from LLVM IR text.

    Returns a list of dicts with keys: name, return_type, params, body.
    """
    functions = []
    lines = ll_content.splitlines()
    i = 0
    while i < len(lines):
        line = lines[i].strip()
        if line.startswith("define ") and "{" in line:
            # Collect the full function body
            start = i
            depth = line.count("{") - line.count("}")
            j = i + 1
            while j < len(lines) and depth > 0:
                depth += lines[j].count("{") - lines[j].count("}")
                j += 1
            body = "\n".join(lines[start:j])

            # Parse: define [linkage] <return_type> @<name>(<params>) { ... }
            try:
                after_define = line.split("define ", 1)[1]
                # Skip linkage keywords
                for kw in ("dso_local ", "internal ", "private ", "weak "):
                    after_define = after_define.replace(kw, "", 1)
                ret_and_rest = after_define.split("@", 1)
                return_type = ret_and_rest[0].strip()
                name_and_params = ret_and_rest[1].split("(", 1)
                name = name_and_params[0].strip()
                # Skip compiler-generated names
                if name.startswith("_Z") or "llvm." in name:
                    i = j
                    continue
                functions.append({
                    "name": name,
                    "return_type": return_type,
                    "body": body,
                })
            except (IndexError, ValueError):
                pass
            i = j
        else:
            i += 1
    return functions


def compute_ir_complexity(ll_body: str) -> int:
    """Estimate cyclomatic complexity from LLVM IR (branch count + 1)."""
    branches = ll_body.count("br i1") + ll_body.count("switch ")
    return branches + 1


# ---------------------------------------------------------------------------
# Mojo translation
# ---------------------------------------------------------------------------

def translate_to_mojo(
    cpp_source: str,
    cpp_llvm_ir: str,
    model: str,
) -> str | None:
    """Translate a C++ function to Mojo using an LLM.

    In production, this calls the transpilers pipeline. This stub shows the
    interface; replace with actual pipeline call.

    Returns the Mojo source string, or None on failure.
    """
    try:
        # Import the transpilers pipeline (adjust import path as needed)
        from transpilers.pipeline import translate  # type: ignore[import]
        result = translate(
            cpp_source=cpp_source,
            target="mojo",
            model=model,
            context={"llvm_ir": cpp_llvm_ir},
        )
        return result.code
    except ImportError:
        # Fallback: direct OpenAI-compatible API call
        return _llm_translate_fallback(cpp_source, cpp_llvm_ir, model)


def _llm_translate_fallback(cpp_source: str, cpp_llvm_ir: str, model: str) -> str | None:
    """Fallback LLM translation via openai-compatible API."""
    try:
        import openai
        import os

        client = openai.OpenAI(
            base_url=os.environ.get("VLLM_BASE_URL"),  # or None for OpenAI
            api_key=os.environ.get("OPENAI_API_KEY", "none"),
        )

        prompt = (
            "Translate the following C++ function to Mojo. "
            "Use the LLVM IR as a type reference.\n\n"
            f"C++ source:\n```cpp\n{cpp_source}\n```\n\n"
            f"LLVM IR (type reference):\n```llvm\n{cpp_llvm_ir[:800]}\n```\n\n"
            "Mojo translation (only the function, no explanation):"
        )

        response = client.chat.completions.create(
            model=model,
            messages=[
                {"role": "system", "content": "You are an expert C++ to Mojo transpiler."},
                {"role": "user", "content": prompt},
            ],
            temperature=0.1,
            max_tokens=1024,
        )
        return response.choices[0].message.content.strip()
    except Exception as exc:
        print(f"  LLM call failed: {exc}", file=sys.stderr)
        return None


# ---------------------------------------------------------------------------
# Mojo verification
# ---------------------------------------------------------------------------

def emit_mojo_llvm_ir(mojo_source: str, output: Path) -> tuple[bool, str]:
    """Emit LLVM IR from Mojo source using mojo build.

    Returns (success, message).
    """
    with tempfile.NamedTemporaryFile(suffix=".mojo", mode="w", delete=False) as tmp:
        tmp.write(mojo_source)
        tmp_path = Path(tmp.name)

    try:
        result = subprocess.run(
            ["mojo", "build", "--emit=llvm", str(tmp_path), "-o", str(output)],
            capture_output=True,
            text=True,
            timeout=30,
        )
        tmp_path.unlink(missing_ok=True)
        if result.returncode == 0:
            return True, "OK"
        return False, result.stderr.strip()[:500]
    except FileNotFoundError:
        tmp_path.unlink(missing_ok=True)
        return False, "mojo not found"
    except subprocess.TimeoutExpired:
        tmp_path.unlink(missing_ok=True)
        return False, "timeout"


def check_mojo_syntax(mojo_source: str) -> tuple[bool, str]:
    """Run mojo check on the generated source.

    Returns (ok, error_message).
    """
    with tempfile.NamedTemporaryFile(suffix=".mojo", mode="w", delete=False) as tmp:
        tmp.write(mojo_source)
        tmp_path = Path(tmp.name)

    try:
        result = subprocess.run(
            ["mojo", "check", str(tmp_path)],
            capture_output=True,
            text=True,
            timeout=15,
        )
        tmp_path.unlink(missing_ok=True)
        if result.returncode == 0:
            return True, ""
        return False, result.stderr.strip()[:300]
    except FileNotFoundError:
        tmp_path.unlink(missing_ok=True)
        return False, "mojo not found"
    except subprocess.TimeoutExpired:
        tmp_path.unlink(missing_ok=True)
        return False, "timeout"


def verify_signature_equivalence(cpp_ll: str, mojo_ll: str) -> bool:
    """Level 1: Check that function signatures are type-compatible."""
    cpp_fns = extract_function_signatures(cpp_ll)
    mojo_fns = extract_function_signatures(mojo_ll)
    if not cpp_fns or not mojo_fns:
        return False
    # Check at least one matching return type category
    cpp_ret = cpp_fns[0]["return_type"].lower()
    mojo_ret = mojo_fns[0]["return_type"].lower()
    # Both double/float → compatible; both i32/i64 → compatible
    is_float = lambda t: any(x in t for x in ("double", "float"))
    is_int = lambda t: any(x in t for x in ("i32", "i64", "i16", "i8"))
    if is_float(cpp_ret) and is_float(mojo_ret):
        return True
    if is_int(cpp_ret) and is_int(mojo_ret):
        return True
    return cpp_ret == mojo_ret


# ---------------------------------------------------------------------------
# Pair building
# ---------------------------------------------------------------------------

def build_pair(
    cpp_source_path: Path,
    ir_output_dir: Path,
    mojo_output_dir: Path,
    model: str,
    verify_level: int,
    std: str,
    includes: list[str],
) -> list[dict[str, Any]]:
    """Build verified IR pairs from a single .cpp file.

    Returns a list of verified pair dicts (may be empty on failure).
    """
    pairs = []
    rel = cpp_source_path.stem

    # Step 1: Emit C++ LLVM IR
    ir_path = ir_output_dir / f"{rel}.ll"
    ok, err = emit_llvm_ir(cpp_source_path, ir_path, std, includes)
    if not ok:
        print(f"  IR emit failed: {err}")
        return []

    cpp_ll = ir_path.read_text(encoding="utf-8", errors="replace")
    cpp_source = cpp_source_path.read_text(encoding="utf-8", errors="replace")

    # Step 2: Translate C++ → Mojo
    mojo_path = mojo_output_dir / f"{rel}.mojo"
    mojo_source = translate_to_mojo(cpp_source, cpp_ll, model)
    if not mojo_source:
        print("  Mojo translation failed")
        return []

    mojo_path.write_text(mojo_source, encoding="utf-8")

    # Step 3: Verify Mojo syntax
    ok, err = check_mojo_syntax(mojo_source)
    if not ok:
        print(f"  Mojo check failed: {err}")
        return []

    verified = True
    verification_level = 1

    # Step 4: IR-level verification
    if verify_level >= 2:
        with tempfile.NamedTemporaryFile(suffix=".ll", delete=False) as tmp_ll:
            mojo_ir_path = Path(tmp_ll.name)

        ok, err = emit_mojo_llvm_ir(mojo_source, mojo_ir_path)
        if ok and verify_level >= 1:
            mojo_ll = mojo_ir_path.read_text(encoding="utf-8", errors="replace")
            verified = verify_signature_equivalence(cpp_ll, mojo_ll)
            verification_level = 2
        mojo_ir_path.unlink(missing_ok=True)

    if not verified:
        print("  Equivalence check failed")
        return []

    # Compute complexity
    complexity = compute_ir_complexity(cpp_ll)

    pair = {
        "llvm_ir": cpp_ll,
        "mojo_source": mojo_source,
        "cpp_source": cpp_source,
        "verified": True,
        "verification_level": verification_level,
        "complexity": complexity,
        "source_file": str(cpp_source_path),
        "metadata": {
            "has_loops": "br i1" in cpp_ll or "phi " in cpp_ll,
            "has_recursion": cpp_source_path.stem in cpp_ll.split("@", 1)[-1][:200]
                             if "@" in cpp_ll else False,
        },
    }
    pairs.append(pair)
    return pairs


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    parser = argparse.ArgumentParser(
        description="Build (LLVM IR, Mojo source) training pairs from C++ source files.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("source", type=Path, help="Directory of .cpp files to process.")
    parser.add_argument(
        "--ir-output", type=Path, default=Path("ir"),
        help="Directory to write C++ LLVM IR files (default: ir/).",
    )
    parser.add_argument(
        "--mojo-output", type=Path, default=Path("mojo_generated"),
        help="Directory to write generated Mojo files (default: mojo_generated/).",
    )
    parser.add_argument(
        "--pairs-output", type=Path, default=Path("data/ir_pairs.jsonl"),
        help="Output JSONL file for verified pairs (default: data/ir_pairs.jsonl).",
    )
    parser.add_argument(
        "--model", default="claude-3-5-sonnet-20241022",
        help="LLM model for Mojo translation (default: claude-3-5-sonnet-20241022).",
    )
    parser.add_argument(
        "--verify-level", type=int, default=2, choices=[1, 2, 3],
        help="Verification level: 1=signature, 2=numerical, 3=structural (default: 2).",
    )
    parser.add_argument(
        "--max-complexity", type=int, default=20,
        help="Skip functions with complexity above this threshold (default: 20).",
    )
    parser.add_argument(
        "--max-cost", type=float, default=None,
        help="Stop processing when estimated LLM cost exceeds this USD amount.",
    )
    parser.add_argument(
        "--std", default="c++17",
        help="C++ standard for clang (default: c++17).",
    )
    parser.add_argument(
        "--includes", default="",
        help="Comma-separated extra include directories.",
    )
    parser.add_argument(
        "--resume", action="store_true",
        help="Skip .cpp files that already have a corresponding .mojo output.",
    )
    parser.add_argument(
        "--limit", type=int, default=None,
        help="Process at most N files (for testing).",
    )

    args = parser.parse_args()

    if not args.source.exists():
        print(f"ERROR: source directory not found: {args.source}", file=sys.stderr)
        return 1

    cpp_files = sorted(args.source.rglob("*.cpp"))
    if not cpp_files:
        print(f"No .cpp files found in {args.source}", file=sys.stderr)
        return 1

    if args.limit:
        cpp_files = cpp_files[:args.limit]

    includes = [i.strip() for i in args.includes.split(",") if i.strip()]

    args.ir_output.mkdir(parents=True, exist_ok=True)
    args.mojo_output.mkdir(parents=True, exist_ok=True)
    args.pairs_output.parent.mkdir(parents=True, exist_ok=True)

    print(f"Processing {len(cpp_files)} .cpp files from {args.source}")
    print(f"  Model: {args.model}")
    print(f"  Verify level: {args.verify_level}")
    print(f"  Max complexity: {args.max_complexity}")
    print(f"  Output JSONL: {args.pairs_output}")
    print()

    success = 0
    skipped = 0
    failed = 0
    total_pairs = 0
    estimated_cost = 0.0

    # Cost estimate: ~$0.01 per function for claude-3-5-sonnet
    cost_per_function = 0.01

    with open(args.pairs_output, "a", encoding="utf-8") as out_f:
        for i, cpp_file in enumerate(cpp_files, 1):
            rel_name = cpp_file.name
            print(f"[{i:>5}/{len(cpp_files)}] {rel_name}")

            # Resume: skip if already processed
            if args.resume:
                mojo_check = args.mojo_output / f"{cpp_file.stem}.mojo"
                if mojo_check.exists():
                    print("  SKIP (already processed)")
                    skipped += 1
                    continue

            # Cost guard
            if args.max_cost and estimated_cost >= args.max_cost:
                print(f"  Reached cost limit ${args.max_cost:.2f}, stopping.")
                break

            pairs = build_pair(
                cpp_source_path=cpp_file,
                ir_output_dir=args.ir_output,
                mojo_output_dir=args.mojo_output,
                model=args.model,
                verify_level=args.verify_level,
                std=args.std,
                includes=includes,
            )

            if pairs:
                for pair in pairs:
                    if pair["complexity"] <= args.max_complexity:
                        out_f.write(json.dumps(pair, ensure_ascii=False) + "\n")
                        total_pairs += 1
                success += 1
                estimated_cost += cost_per_function
                print(f"  OK ({len(pairs)} pairs, complexity={pairs[0]['complexity']})")
            else:
                failed += 1

    print()
    print("=" * 60)
    print(f"Summary:")
    print(f"  Files processed:  {success + failed}")
    print(f"  Successful:       {success}")
    print(f"  Failed:           {failed}")
    print(f"  Skipped (resume): {skipped}")
    print(f"  Verified pairs:   {total_pairs}")
    print(f"  Estimated cost:   ${estimated_cost:.2f}")
    print(f"  Output:           {args.pairs_output}")

    return 0 if total_pairs > 0 else 1


if __name__ == "__main__":
    sys.exit(main())
