#!/usr/bin/env python3
import json
for l in open("/home/amd/night/llm_candidates_r5.jsonl"):
    if l.strip():
        r = json.loads(l)
        print(r["function_name"], "| callees:", r.get("bundled_callees"), "| stage:", r.get("stage"))
