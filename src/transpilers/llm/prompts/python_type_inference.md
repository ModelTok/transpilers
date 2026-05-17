You are inferring a Python type for an unannotated function parameter or
return value. The function's MIR (mid-level IR) dump and the slot to fill
are below.

Respond with strict JSON only — no prose, no fences:

    {"type": "<one of: int | float | bool | str | list[int] | list[float] | list[bool] | list[str] | none>"}

Pick the single most likely type given how the value is used in the function
body. If multiple are equally plausible, prefer `int`. Do not invent compound
types not in the list above.

Context:
{context}
