"""RunPod serverless handler for the transpilers API.

Deployment:
    1. Build image: docker build -f deploy/Dockerfile -t transpilers-api .
    2. Push to registry (Docker Hub / GHCR)
    3. Create RunPod Serverless Endpoint, point to your image
    4. Set env vars: ANTHROPIC_API_KEY, TRANSPILER_API_KEY (optional)

Input schema (matches TranspileRequest / RepairRequest):
    {
        "input": {
            "action": "transpile" | "verify" | "repair",
            "source": "<code>",
            "source_lang": "python",  // default
            "target": "rust",          // default
            "use_llm": false,
            "max_passes": 3            // repair only
        }
    }

Output:
    {
        "output": "<transpiled code>",
        "passed": true,
        ...
    }
"""

from __future__ import annotations

import runpod

from transpilers.pipeline.stages import FRONTENDS, TARGETS, run_stages


def _get_llm_client():
    import os
    has_key = bool(os.getenv("ANTHROPIC_API_KEY") or os.getenv("OPENAI_API_KEY"))
    if not has_key:
        return None
    from transpilers.llm import LlmClient
    return LlmClient()


_CLIENT = None


def handler(event: dict) -> dict:
    global _CLIENT
    inp = event.get("input", {})

    action = inp.get("action", "transpile")
    source = inp.get("source", "")
    source_lang = inp.get("source_lang", "python")
    target = inp.get("target", "rust")
    use_llm = inp.get("use_llm", False)

    if not source:
        return {"error": "source is required"}
    if source_lang not in FRONTENDS:
        return {"error": f"unknown source_lang {source_lang!r}"}
    if target not in TARGETS:
        return {"error": f"unknown target {target!r}"}

    if use_llm or action == "repair":
        if _CLIENT is None:
            _CLIENT = _get_llm_client()
        if _CLIENT is None:
            return {"error": "LLM features require ANTHROPIC_API_KEY or OPENAI_API_KEY"}

    from transpilers.llm import make_llm_inferencer
    llm_fill = make_llm_inferencer(_CLIENT) if (use_llm and _CLIENT) else None

    if action == "repair":
        from transpilers.repair.repair import repair
        max_passes = int(inp.get("max_passes", 3))
        result = repair(source, source_lang=source_lang, target=target, llm_client=_CLIENT, max_passes=max_passes)
        return {
            "output": result.code,
            "passed": result.passed,
            "passes": result.passes,
            "source_lang": source_lang,
            "target": target,
        }

    try:
        trace = run_stages(source, source_lang=source_lang, target=target, llm_fill=llm_fill)
    except Exception as exc:
        return {"error": str(exc)}

    result = {"output": trace.output, "source_lang": source_lang, "target": target}

    if action == "verify":
        _, _, verify_fn = TARGETS[target]
        cr = verify_fn(trace.output)
        result["compile"] = {"ok": cr.ok, "stderr": cr.stderr}

    return result


runpod.serverless.start({"handler": handler})
