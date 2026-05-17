set shell := ["bash", "-cu"]
set dotenv-load := false

# List recipes
default:
    @just --list

# Install / refresh dependencies
setup:
    uv sync

# Run the test suite
test *args:
    uv run pytest {{args}}

# Transpile a file end-to-end with rustc verification
transpile file target="rust":
    uv run transpile {{file}} --target {{target}} --verify

# Transpile the bundled example
example:
    @just transpile examples/add.py

# Transpile every example to every supported target
examples-all:
    @for src in examples/*; do \
        case "$src" in *.py|*.c|*.cpp|*.java|*.cs|*.ts|*.js) ;; *) continue ;; esac; \
        for target in rust zig c mojo; do \
            echo "=== $src -> $target ==="; \
            just transpile $src $target || true; \
        done; \
    done

# Lint
lint:
    uv run ruff check src tests

# Format
fmt:
    uv run ruff format src tests

# Lint + tests — what CI should run
check: lint test

# Remove caches and build artefacts (leaves .venv)
clean:
    rm -rf .pytest_cache .ruff_cache build dist src/*.egg-info
    find . -type d -name __pycache__ -prune -exec rm -rf {} +
