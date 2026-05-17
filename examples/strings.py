# Strings: target divergence in action.
# Rust:  format!() for concat, String::from() for literals
# Zig:   native string literals; concat raises (needs allocator)

def shout() -> str:
    return "loud"


def greet(name: str) -> str:
    return "hello, " + name


def banner(title: str) -> str:
    return "=== " + title + " ==="
