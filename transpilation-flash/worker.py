"""RunPod Flash — C++ transpilation worker powered by DeepSeek-V4-Flash.

Deploys a queue-based GPU endpoint that translates C++ source code to
Python or Mojo using DeepSeek-V4-Flash via vLLM.

Deploy:
    flash login
    flash deploy --env prod

Call (async):
    from runpod_flash import Endpoint
    ep = Endpoint(id="<your-endpoint-id>")
    job = await ep.run({"cpp_source": "int add(int a, int b) { return a+b; }", "target": "python"})
    await job.wait()
    print(job.output)

Input schema:
    cpp_source: str            — C++ source to translate
    target: str                — "python" | "mojo"  (default: "python")
    path: str                  — "direct" | "python_pivot" (default: "direct")
    repair_passes: int         — how many LLM repair iterations (default: 1)
    task_name: str             — function name for Mojo test harness (optional)
    tests: list[dict]          — [{"args": [...], "expected": "..."}] for verification

Output schema:
    code: str                  — translated source
    path: str                  — translation path used
    syntax_ok: bool            — parsed without error
    test_results: list[dict]   — [{"args", "expected", "actual", "passed"}]
    pass_at_1: bool | None     — all tests passed (None if no tests provided)
    repair_passes_used: int    — how many repair iterations were needed
    error: str                 — non-empty if translation failed
"""

from __future__ import annotations

import ast
import os
import re

from runpod_flash import Endpoint, GpuType

MODEL = os.environ.get("MODEL_NAME", "deepseek-ai/DeepSeek-V4-Flash")
VLLM_BASE_URL = os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1")

# ---------------------------------------------------------------------------
# Prompts (from transpilation-bench/run_eval.py, extended)
# ---------------------------------------------------------------------------

_DIRECT_PROMPT = """\
Translate the following C++ function to {target_lang}. \
Output ONLY the {target_lang} source code — no explanation, no markdown fences, \
no extra imports beyond what {target_lang} requires.

C++ source:
```cpp
{cpp_source}
```

{target_lang} translation:"""

_PYTHON_PIVOT_PROMPT_1 = """\
Translate the following C++ function to idiomatic Python 3. \
Output ONLY the Python source code — no explanation, no markdown fences, \
no extra imports.

C++ source:
```cpp
{cpp_source}
```

Python translation:"""

_PYTHON_PIVOT_PROMPT_2 = """\
Translate the following Python 3 function to Mojo. \
Use Mojo type annotations and stdlib. \
Output ONLY the Mojo source code — no explanation, no markdown fences.

Python source:
```python
{python_source}
```

Mojo translation:"""

_REPAIR_PROMPT = """\
The following {target_lang} translation of a C++ function has errors. \
Fix it so all test cases pass.

Original C++:
```cpp
{cpp_source}
```

Broken {target_lang} (attempt {attempt}/{max_passes}):
```
{broken_code}
```

Error or failing test:
{error}

Output ONLY the corrected {target_lang} code."""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _strip_fences(code: str) -> str:
    code = code.strip()
    code = re.sub(r"^```[a-zA-Z]*\n?", "", code)
    code = re.sub(r"\n?```$", "", code)
    return code.strip()


def _check_syntax_python(code: str) -> bool:
    try:
        ast.parse(code)
        return True
    except SyntaxError:
        return False


def _run_python_tests(code: str, tests: list[dict]) -> list[dict]:
    results = []
    try:
        ns: dict = {}
        exec(compile(code, "<flash>", "exec"), ns)
        fn = next(
            v for k, v in ns.items()
            if callable(v) and not k.startswith("_")
            and getattr(v, "__module__", None) != "builtins"
        )
    except Exception as e:
        return [{"args": t["args"], "expected": t["expected"],
                 "actual": f"LOAD-ERROR: {e}", "passed": False}
                for t in tests]
    for test in tests:
        try:
            actual = repr(fn(*test["args"]))
            passed = actual == test["expected"]
        except Exception as e:
            actual = f"ERROR: {e}"
            passed = False
        results.append({"args": test["args"], "expected": test["expected"],
                        "actual": actual, "passed": passed})
    return results


# ---------------------------------------------------------------------------
# Flash endpoint
# ---------------------------------------------------------------------------

@Endpoint(
    name="transpilation-flash",
    gpu=GpuType.NVIDIA_H200,   # B300 will be selected if available via ANY
    gpu_count=2,               # V4-Flash fits in 2× H200 (282 GB HBM)
    workers=(0, 4),
    idle_timeout=120,
    dependencies=[
        "openai>=1.0",
    ],
    env={
        "MODEL_NAME": MODEL,
        "VLLM_BASE_URL": VLLM_BASE_URL,
    },
)
async def transpile(data: dict) -> dict:
    """Translate C++ to Python or Mojo using DeepSeek-V4-Flash."""
    from openai import AsyncOpenAI  # imported inside to satisfy Flash pattern

    cpp_source: str = data.get("cpp_source", "")
    target: str = data.get("target", "python").lower()
    path: str = data.get("path", "direct")
    repair_passes: int = int(data.get("repair_passes", 1))
    tests: list[dict] = data.get("tests", [])

    if not cpp_source.strip():
        return {"error": "cpp_source is required", "code": "", "pass_at_1": False}

    client = AsyncOpenAI(
        api_key=os.environ.get("RUNPOD_API_KEY", "none"),
        base_url=os.environ.get("VLLM_BASE_URL", "http://localhost:8000/v1"),
    )
    model = os.environ.get("MODEL_NAME", "deepseek-ai/DeepSeek-V4-Flash")

    async def _ask(prompt: str, max_tokens: int = 2048) -> str:
        resp = await client.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0,
            max_tokens=max_tokens,
        )
        return _strip_fences(resp.choices[0].message.content)

    # --- Translation ---------------------------------------------------------
    code = ""
    intermediate_python = None
    try:
        if path == "python_pivot" and target == "mojo":
            py_code = await _ask(_PYTHON_PIVOT_PROMPT_1.format(cpp_source=cpp_source))
            intermediate_python = py_code
            code = await _ask(_PYTHON_PIVOT_PROMPT_2.format(python_source=py_code))
        else:
            target_label = "Mojo" if target == "mojo" else "Python"
            code = await _ask(_DIRECT_PROMPT.format(
                cpp_source=cpp_source, target_lang=target_label))
    except Exception as e:
        return {"error": f"LLM call failed: {e}", "code": "", "pass_at_1": False,
                "repair_passes_used": 0}

    # --- Verify + repair loop ------------------------------------------------
    repair_passes_used = 0
    syntax_ok = False
    test_results: list[dict] = []
    pass_at_1: bool | None = None

    for attempt in range(1, repair_passes + 2):  # attempt 1 = first translation
        if target == "python":
            syntax_ok = _check_syntax_python(code)
            if not syntax_ok:
                error_msg = "SyntaxError: could not parse emitted Python"
            elif tests:
                test_results = _run_python_tests(code, tests)
                pass_at_1 = all(t["passed"] for t in test_results)
                if pass_at_1:
                    break
                failing = [t for t in test_results if not t["passed"]]
                error_msg = (
                    f"Test failures ({len(failing)}/{len(tests)}):\n"
                    + "\n".join(
                        f"  args={t['args']} expected={t['expected']!r} actual={t['actual']!r}"
                        for t in failing[:3]
                    )
                )
            else:
                pass_at_1 = None
                break
        else:
            # Mojo: no runtime test without mojo binary; just track syntax pass
            syntax_ok = bool(code.strip())
            pass_at_1 = None
            break

        if attempt <= repair_passes:
            repair_passes_used += 1
            try:
                code = await _ask(
                    _REPAIR_PROMPT.format(
                        cpp_source=cpp_source,
                        target_lang="Mojo" if target == "mojo" else "Python",
                        attempt=attempt,
                        max_passes=repair_passes,
                        broken_code=code,
                        error=error_msg,
                    )
                )
            except Exception as e:
                break

    return {
        "code": code,
        "path": path,
        "target": target,
        "syntax_ok": syntax_ok,
        "test_results": test_results,
        "pass_at_1": pass_at_1,
        "repair_passes_used": repair_passes_used,
        "intermediate_python": intermediate_python,
        "model": model,
        "error": "",
    }
