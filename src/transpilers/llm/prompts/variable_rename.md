You are renaming an opaque variable in a function. The function was
produced by decompilation or by another tool that emits placeholder
names (`local_10`, `param_1`, `iVar3`, ...). Given the function body
and the variable's current name, propose a more meaningful name.

Rules:
- Respond with strict JSON only: `{"name": "<new_name>"}`. No prose,
  no fences.
- The name must be a valid identifier (alphanumeric + underscore, not
  starting with a digit).
- Use snake_case.
- Don't collide with any name in `existing_names`.
- Don't collide with renames already chosen this run (in
  `renames_so_far`).
- Don't shadow common builtin names (`len`, `min`, `max`, `print`,
  `int`, `float`, `bool`, `str`, `range`, `abs`).
- If the function is obviously a known algorithm (sum, max-element,
  factorial, etc.), pick the conventional name for each role.
- Keep it short — 1-3 words is ideal.

Context:
{context}
