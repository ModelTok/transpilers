#!/usr/bin/env python3
"""Inference script for DiffusionGemma — run with llama.cpp, vLLM, or Unsloth.

Supports three backends, each with diffusion-aware sampling parameters:

1.  llama.cpp (default) — requires llama-diffusion-cli built from the
    gh pr 24423 branch of https://github.com/ggml-org/llama.cpp.

2.  vLLM — requires a running vLLM server serving diffusion-gemma-26b-it.
    Set DIFFUSION_VLLM_BASE_URL or pass --vllm-base-url.

3.  Unsloth — loads the model via unsloth.FastLanguageModel for
    in-process inference / fine-tuned adapter evaluation.
"""

from __future__ import annotations

import argparse
import sys
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(REPO_ROOT))

from transpilers.llm.diffusion import (
    DEFAULT_MAX_DENOISING_STEPS,
    DiffusionGenerationConfig,
    DiffusionSamplerConfig,
    download_gguf,
    make_diffusion_client,
)


def parse_args() -> argparse.Namespace:
    p = argparse.ArgumentParser(description="Inference with DiffusionGemma")
    p.add_argument("--backend", choices=["llamacpp", "vllm", "unsloth"], default="llamacpp")
    p.add_argument("--model", type=str, default="", help="Model ID or GGUF path")
    p.add_argument("--prompt", type=str, default="", help="Input prompt")
    p.add_argument("--interactive", "-i", action="store_true", help="Interactive mode")
    p.add_argument("--system-prompt", type=str, default="", help="System prompt")
    p.add_argument("--thinking", action="store_true", help="Enable thinking mode")
    p.add_argument("--max-tokens", type=int, default=1024, help="Max tokens")
    p.add_argument("--temperature-start", type=float, default=0.8)
    p.add_argument("--temperature-end", type=float, default=0.4)
    p.add_argument("--denoising-steps", type=int, default=DEFAULT_MAX_DENOISING_STEPS)
    p.add_argument("--entropy-bound", type=float, default=0.1)
    p.add_argument("--vllm-base-url", type=str, default="", help="vLLM server URL")
    p.add_argument("--llamacpp-binary", type=str, default="", help="llama-diffusion-cli path")
    p.add_argument("--download-gguf", type=str, default="", nargs="?", const="Q4_K_M",
                   help="Download GGUF (e.g., --download-gguf Q8_0)")
    p.add_argument("--stream", action="store_true", help="Stream output")
    p.add_argument("--quiet", "-q", action="store_true", help="Suppress info messages")
    return p.parse_args()


def run_interactive(client, cfg):
    """Interactive multi-turn conversation."""
    print("Interactive mode. Type /bye to exit, /reset to clear.")
    history: list[str] = []
    while True:
        try:
            user_input = input("\n>>> ")
        except (EOFError, KeyboardInterrupt):
            break
        if not user_input.strip():
            continue
        if user_input.strip().lower() == "/bye":
            break
        if user_input.strip().lower() == "/reset":
            history.clear()
            print("[Reset]")
            continue
        full = "\n".join(history + [user_input])
        resp = client.generate(full, config=cfg)
        print(f"\n{resp}")
        history.append(f"User: {user_input}")
        history.append(f"Assistant: {resp}")


def main():
    args = parse_args()

    if args.download_gguf and args.backend == "llamacpp" and not args.model:
        if not args.quiet:
            print(f"Downloading GGUF ({args.download_gguf})...")
        args.model = str(download_gguf(quant=args.download_gguf))
        if not args.quiet:
            print(f"  Saved to {args.model}")

    sampler = DiffusionSamplerConfig(
        temperature_start=args.temperature_start,
        temperature_end=args.temperature_end,
        max_steps=args.denoising_steps,
        entropy_bound=args.entropy_bound,
    )
    gen_config = DiffusionGenerationConfig(
        max_new_tokens=args.max_tokens,
        sampler=sampler,
        thinking=args.thinking,
        system_prompt=args.system_prompt,
    )

    kwargs = {}
    if args.vllm_base_url:
        kwargs["vllm_base_url"] = args.vllm_base_url
    if args.llamacpp_binary:
        kwargs["llamacpp_binary"] = args.llamacpp_binary

    client = make_diffusion_client(
        backend=args.backend, model=args.model, config=gen_config, **kwargs,
    )

    if not args.quiet:
        print(f"Backend: {args.backend}, Model: {client.model}")

    if args.interactive:
        run_interactive(client, gen_config)
    elif args.prompt:
        if args.stream:
            for tok in client.generate_stream(args.prompt, config=gen_config):
                print(tok, end="", flush=True)
            print()
        else:
            resp = client.generate(args.prompt, config=gen_config)
            if args.quiet:
                print(resp)
            else:
                print(f"\n--- Response ---\n{resp}\n")
    else:
        print("Use --prompt or --interactive")
        sys.exit(1)


if __name__ == "__main__":
    main()
