"""Validate all Python reference implementations against their test cases.

Run: python validate_tests.py
"""
import json
from pathlib import Path

errors = []
ok = []

for f in sorted(Path("benchmarks/tasks").glob("*.json")):
    task = json.loads(f.read_text())
    code = task["python_reference"]
    tests = task["tests"]

    ns = {}
    try:
        exec(code, ns)
    except Exception as e:
        errors.append(f"{task['id']} {task['name']}: exec failed: {e}")
        continue

    # Look up by task name first (avoids picking up imported helpers like Counter, deque, etc.)
    fn = ns.get(task["name"])
    if fn is None:
        # Fallback: first callable defined in this module (not imported)
        # We distinguish by checking if the object's __module__ key etc. is set from exec
        for k, v in ns.items():
            if callable(v) and not k.startswith("_") and k not in ("__builtins__",):
                # Skip well-known imports that end up in the namespace
                if getattr(v, "__module__", None) is None or k[0].isupper():
                    continue
                fn = v
                break
    if fn is None:
        errors.append(f"{task['id']} {task['name']}: could not find callable '{task['name']}' in namespace")
        continue

    for t in tests:
        try:
            actual = str(fn(*t["args"]))
            exp = t["expected"]
            if actual != exp:
                errors.append(
                    f"  {task['id']} {task['name']} args={t['args']}\n"
                    f"    actual  : {actual!r}\n"
                    f"    expected: {exp!r}"
                )
            else:
                ok.append(f"{task['id']} {task['name']} args={t['args']} OK")
        except Exception as e:
            errors.append(f"  {task['id']} {task['name']} args={t['args']}: ERROR {e}")

print(f"PASS: {len(ok)} / {len(ok)+len(errors)}")
if errors:
    print(f"\nFAILURES ({len(errors)}):")
    for e in errors:
        print(e)
else:
    print("\nAll tests pass!")
