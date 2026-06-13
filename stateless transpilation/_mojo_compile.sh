#!/usr/bin/env bash
# Front-end compile check for the benchmark .mojo files.
# Activate the pixi env once (so the Mojo stdlib resolves), then compile each
# file with `--emit llvm` -> runs parse + typecheck + IR codegen but stops
# BEFORE native linking (the conda toolchain's link step has an unrelated glibc
# sysroot mismatch in this WSL distro, which is not a code-quality signal).
set -u
PROJ=/home/amd/energyplus-mojo
PIXI="$HOME/.pixi/bin/pixi"
BENCH="/mnt/c/Github/EnergyPlus-Mojo/stateless transpilation/bench_out"

cd "$PROJ" || { echo "no project dir"; exit 1; }
eval "$("$PIXI" shell-hook 2>/dev/null)"

# sanity: a trivial file must pass under this method
printf 'fn main():\n    print("hi")\n' > /tmp/hello.mojo
mojo build --emit llvm /tmp/hello.mojo -o /tmp/hello.ll >/tmp/h.log 2>&1 \
  && echo "sanity: hello.mojo front-end OK" \
  || { echo "sanity FAILED — env not activated:"; head -4 /tmp/h.log; exit 1; }
echo ""

pass=0; fail=0
for f in "$BENCH"/*/*.mojo; do
    model=$(basename "$(dirname "$f")")
    name=$(basename "$f")
    err=$(mojo build --emit llvm "$f" -o /tmp/_m.ll 2>&1)
    if [ $? -eq 0 ]; then
        echo "PASS  $model / $name"
        pass=$((pass+1))
    else
        echo "FAIL  $model / $name"
        echo "$err" | grep -E "error:" | head -3 | sed 's/^/        /'
        fail=$((fail+1))
    fi
done
echo ""
echo "mojo front-end compile (--emit llvm): $pass passed, $fail failed"
